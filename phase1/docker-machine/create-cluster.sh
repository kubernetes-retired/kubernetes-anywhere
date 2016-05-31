#!/bin/bash -xe

# Copyright 2015-2016 Weaveworks Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## This example features TLS configuration, which leverages availability of remote Docker API to securely
## transfer images with certificates between the master and worker nodes
##
## WARNING: This is an advanced example with TLS, although usage of Docker Machine keeps it rather readable
## and provides an ability to quickly spawn a cluster on a local hypervisor of your choice or one of the public
## clouds that Docker Machine supports
##
## For example, if you would like to use Microsoft Azure, then set the following:
##
##    export DOCKER_MACHINE_DRIVER="azure"
##    export AZURE_SUBSCRIPTION_CERT="/path/to/mycert.pem"
##    export AZURE_SUBSCRIPTION_ID="MySubscriptionID"
##
## Or for Google Compute Engine:
##
##    export DOCKER_MACHINE_DRIVER="google"
##    export GOOGLE_PROJECT="my-awesome-project-1"
##    export GOOGLE_AUTH_TOKEN="MyAuthToken"
##
## Similarly, there are environment variables for all major cloud providers, please check Docker Machine docs
## for details

DOCKER_MACHINE_DRIVER=${DOCKER_MACHINE_DRIVER:-'virtualbox'}

vm_names=$(seq -f 'kube-%g' 1 7)

fix_systemd_unit_if_needed=" \
  if grep -q MountFlags=slave /etc/systemd/system/docker.service 2> /dev/null ; then \
    sudo sed 's/\(MountFlags=slave\)/# \1/' -i /etc/systemd/system/docker.service ; \
    sudo systemctl daemon-reload ; \
    sudo systemctl restart docker ; \
  fi
"

install_weave=" \
  sudo curl --silent --location http://git.io/weave --output /usr/local/bin/weave ; \
  sudo chmod +x /usr/local/bin/weave ; \
  /usr/local/bin/weave launch-router --init-peer-count 7 ; \
  /usr/local/bin/weave launch-proxy --no-detect-tls ; \
  /usr/local/bin/weave launch-plugin ; \
"

## TODO: with a private network we still need to find a way to obtain the IPs, as Docker Machine doesn't have it
if [ "${DOCKER_MACHINE_DRIVER}" = 'digitalocean' ] && ! [ "${DIGITALOCEAN_PRIVATE_NETWORKING}" = 'true' ]; then
  WEAVE_PASSWORD=$(openssl genrsa 2> /dev/null | openssl base64 | tr -d "=+/\n")
  install_weave="export WEAVE_PASSWORD=${WEAVE_PASSWORD} ; ${install_weave}"
  echo "WEAVE_PASSWORD='${WEAVE_PASSWORD}'" > weave_password
fi

docker_on() {
  m=$1
  shift
  docker-machine ssh ${m} "docker $*"
}

## Create 7 VMs and install weave

for m in $vm_names ; do
  docker-machine create --driver ${DOCKER_MACHINE_DRIVER} ${m}
  docker-machine ssh ${m} "${fix_systemd_unit_if_needed}"
  docker-machine ssh ${m} "${install_weave}"
done

## Connect Weave Net peers to `kube-1`

for m in $vm_names ; do
  docker-machine ssh ${m} "/usr/local/bin/weave connect $(docker-machine ip 'kube-1')"
done

## In most cases we need to SSH into the VM in order to communicate with Weave proxy via the UNIX socket,
## as exposing it remotely doesn't make sense in the context of the Kubernetes Anywhere project

weaveproxy_socket="-H unix:///var/run/weave/weave.sock"

## Start etcd on `kube-{1,2,3}`

docker_on 'kube-1' ${weaveproxy_socket} run --detach \
  --env="ETCD_CLUSTER_SIZE=3" \
  --name="etcd1" \
    weaveworks/kubernetes-anywhere:etcd-v1.2

docker_on 'kube-2' ${weaveproxy_socket} run --detach \
  --env="ETCD_CLUSTER_SIZE=3" \
  --name="etcd2" \
    weaveworks/kubernetes-anywhere:etcd-v1.2

docker_on 'kube-3' ${weaveproxy_socket} run --detach \
  --env="ETCD_CLUSTER_SIZE=3" \
  --name="etcd3" \
    weaveworks/kubernetes-anywhere:etcd-v1.2

## Create TLS config volumes that will be transfered to worker nodes via `docker save | docker load` pipe
## In this instance it's easier to use remote Docker API, as Weave proxy is not required for this part

master_config=$(docker-machine config 'kube-4')

docker ${master_config} run \
  -v /var/run/docker.sock:/docker.sock \
    weaveworks/kubernetes-anywhere:toolbox-v1.2 \
      create-pki-containers

## Run intermediate containers to export the TLS config volumes for master components

for c in 'apiserver' 'controller-manager' 'scheduler' 'toolbox' ; do
  docker ${master_config} run \
    --name="kube-${c}-pki" \
    kubernetes-anywhere:${c}-pki
done

## Transfer TLS config images via a pipe between remote API, which is a neat trick to avoid having
## to setup a private registry, also rather safe as the network connection is encrypted

docker ${master_config} save \
    kubernetes-anywhere:kubelet-pki \
    kubernetes-anywhere:proxy-pki \
    kubernetes-anywhere:toolbox-pki \
  | tee \
    >(docker $(docker-machine config 'kube-5') load) \
    >(docker $(docker-machine config 'kube-6') load) \
    >(docker $(docker-machine config 'kube-7') load) \
  | cat > /dev/null

## Launch the master components using volumes provided as artefact of running the `*-pki` containers

docker_on 'kube-4' ${weaveproxy_socket} run --detach \
  --env="ETCD_CLUSTER_SIZE=3" \
  --name="kube-apiserver" \
  --volumes-from="kube-apiserver-pki" \
    weaveworks/kubernetes-anywhere:apiserver-v1.2

docker_on 'kube-4' ${weaveproxy_socket} run --detach \
  --name="kube-scheduler" \
  --volumes-from="kube-scheduler-pki" \
    weaveworks/kubernetes-anywhere:scheduler-v1.2

docker_on 'kube-4' ${weaveproxy_socket} run --detach \
  --name="kube-controller-manager" \
  --volumes-from="kube-controller-manager-pki" \
    weaveworks/kubernetes-anywhere:controller-manager-v1.2

## Launch kubelet and proxy on each of the worker nodes

for m in 'kube-5' 'kube-6' 'kube-7' ; do
  worker_config=$(docker-machine config ${m})

  ## Expose host to Weave Net and provide a DNS record that kubelet will pick up, as it runs in host namespace
  docker-machine ssh ${m} "/usr/local/bin/weave expose -h ${m}.weave.local"

  ## Run intermediate containers to export volumes kubelet wants
  docker ${worker_config} run \
    --name="kubelet-pki" \
      kubernetes-anywhere:kubelet-pki
  docker_on ${m} ${weaveproxy_socket} run \
    --env="USE_CNI=yes" \
    --volume="/:/rootfs" \
    --volume="/var/run/docker.sock:/docker.sock" \
      weaveworks/kubernetes-anywhere:toolbox-v1.2 \
        setup-kubelet-volumes
  ## Start the kubelete itself now
  docker_on ${m} ${weaveproxy_socket} run --detach \
    --name="kubelet" \
    --privileged="true" --net="host" --pid="host" \
    --env="USE_CNI=yes" \
    --volumes-from="kubelet-volumes" \
    --volumes-from="kubelet-pki" \
      weaveworks/kubernetes-anywhere:kubelet-v1.2

  ## Run intermediate container for proxy's TLS PKI data containers
  docker ${worker_config} run \
    --name="kube-proxy-pki" \
      kubernetes-anywhere:proxy-pki
  ## And now start the proxy itself
  docker_on ${m} ${weaveproxy_socket} run --detach \
    --name="kube-proxy" \
    --privileged="true" --net="host" --pid="host" \
    --volumes-from="kube-proxy-pki" \
      weaveworks/kubernetes-anywhere:proxy-v1.2
  ## Create toolbox PKI data volume for convenience
  docker ${worker_config} create \
    --name=kube-toolbox-pki \
      kubernetes-anywhere:toolbox-pki
done

## Run toolbox container to deploy cluster addons
docker_on 'kube-4' ${weaveproxy_socket} run \
  --volumes-from="kube-toolbox-pki" \
    weaveworks/kubernetes-anywhere:toolbox-v1.2 \
      kubectl create -f addons.yaml
