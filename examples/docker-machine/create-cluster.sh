#!/bin/bash -xe

## This example features TLS configuration, which leverages availability of remote Docker API to securelly
## transfer images whith certificates between the master and worker nodes
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

DOCKER_MACHINE_DRIVER=${DOCKER_MACHINE_DRIVER:-'vmwarefusion'}

vm_names=$(seq -f 'kube-%g' 1 7)

install_weave=" \
  sudo curl --silent --location http://git.io/weave --output /usr/local/bin/weave ; \
  sudo chmod +x /usr/local/bin/weave ; \
  /usr/local/bin/weave launch-router --init-peer-count 7 ; \
  /usr/local/bin/weave launch-proxy --rewrite-inspect ; \
"

## Create 7 VMs and install weave

for m in $vm_names ; do
  docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${m}
  docker-machine ssh ${m} "${install_weave}"
done

## Connect Weave Net peers to `kube-1`

for m in $vm_names ; do
  docker-machine ssh ${m} "/usr/local/bin/weave connect $(docker-machine ip 'kube-1')"
done


## In most cases we need to SSH into the VM in order to communicate with Weave proxy via the UNIX socket,
## as exposing it remotely doesn't make sense in the contex of the Kubernetes Anywhere project

weaveproxy_socket="-H unix:///var/run/weave/weave.sock"

## Start etcd on `kube-{1,2,3}`

docker-machine ssh 'kube-1' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name="etcd1" \
  weaveworks/kubernetes-anywhere:etcd

docker-machine ssh 'kube-2' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name="etcd2" \
  weaveworks/kubernetes-anywhere:etcd

docker-machine ssh 'kube-3' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name="etcd3" \
  weaveworks/kubernetes-anywhere:etcd

## Create TLS config volumes that will be transfered to worker nodes via `docker save | docker load` pipe
## In this instance it's easier to use remote Docker API, as Weave proxy is not required for this part

master_config=$(docker-machine config 'kube-4')

docker ${master_config} run \
  -v /var/run/weave/weave.sock:/weave.sock \
  weaveworks/kubernetes-anywhere:tools setup-secure-cluster-config-volumes

## Run intermediate containers to export the TLS config volumes for master components

for c in 'apiserver' 'controller-manager' 'scheduler' 'tools' ; do
  docker ${master_config} run \
    --name="kube-${c}-secure-config" \
    kubernetes-anywhere:${c}-secure-config
done

## Transfer TLS config images via a pipe between remote API, which is a neat trick to avoid having
## to setup a private registry, also rather safe as the network connection is encrypted

docker ${master_config} save \
    kubernetes-anywhere:kubelet-secure-config \
    kubernetes-anywhere:proxy-secure-config \
    kubernetes-anywhere:tools-secure-config \
  | tee \
    >(docker $(docker-machine config 'kube-5') load) \
    >(docker $(docker-machine config 'kube-6') load) \
    >(docker $(docker-machine config 'kube-7') load) \
  | cat > /dev/null

## Launch the master components using volumes provided as artefact of running the `*-secure-config` containers

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name="kube-apiserver" \
  --volumes-from="kube-apiserver-secure-config" \
  weaveworks/kubernetes-anywhere:apiserver

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run -d \
  --name="kube-scheduler" \
  --volumes-from="kube-scheduler-secure-config" \
  weaveworks/kubernetes-anywhere:scheduler

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run -d \
  --name="kube--controller-manager" \
  --volumes-from="kube-controller-manager-secure-config" \
  weaveworks/kubernetes-anywhere:controller-manager

## Launch kubelet and proxy on each of the worker nodes

for m in 'kube-5' 'kube-6' 'kube-7' ; do
  worker_config=$(docker-machine config ${m})

  ## Expose host to Weave Net and provide a DNS record that kubelet will pick up, as it runs in host namespace
  docker-machine ssh ${m} "/usr/local/bin/weave expose -h ${m}.weave.local"

  ## Run intermediate containers to export volumes kubelet wants
  docker ${worker_config} run \
    --name="kubelet-secure-config" \
    kubernetes-anywhere:kubelet-secure-config
  docker-machine ssh ${m} docker ${weaveproxy_socket} run \
    --volume="/:/rootfs" \
    --volume="/var/run/weave/weave.sock:/weave.sock" \
    weaveworks/kubernetes-anywhere:tools \
    setup-kubelet-volumes
  ## Start the kubelete itself now
  docker-machine ssh ${m} docker ${weaveproxy_socket} run -d \
    --name="kubelet" \
    --privileged=true --net=host --pid=host \
    --volumes-from="kubelet-volumes" \
    --volumes-from="kubelet-secure-config" \
    weaveworks/kubernetes-anywhere:kubelet

  ## Run intermediate container for proxy's TLS config volumes
  docker ${worker_config} run \
    --name="kube-proxy-secure-config" \
    kubernetes-anywhere:proxy-secure-config
  ## And now start the proxy itself
  docker-machine ssh ${m} docker ${weaveproxy_socket} run -d \
    --name="kube-proxy" \
    --privileged=true --net=host --pid=host \
    --volumes-from="kube-proxy-secure-config" \
    weaveworks/kubernetes-anywhere:proxy
done

## Run tools container to deploy SkyDNS addon
docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run \
  --volumes-from="kube-tools-secure-config" \
  weaveworks/kubernetes-anywhere:tools \
  kubectl create -f /kube-system-namespace.yaml
docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run \
  --volumes-from="kube-tools-secure-config" \
  weaveworks/kubernetes-anywhere:tools \
  kubectl create -f /skydns-addon/
