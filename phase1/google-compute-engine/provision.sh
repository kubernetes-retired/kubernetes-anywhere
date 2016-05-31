#!/bin/bash -x

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

if ! /usr/bin/docker -v 2> /dev/null | grep -q "^Docker\ version\ 1\.10" ; then
  echo "Installing current version of Docker Engine 1.10"
  curl --silent --location  https://get.docker.com/builds/Linux/x86_64/docker-1.10.3  --output /usr/bin/docker
  chmod +x /usr/bin/docker
fi

systemd-run --unit=docker.service /usr/bin/docker daemon

/usr/bin/docker version

if ! [ -x /usr/bin/weave ] ; then
  echo "Installing current version of Weave Net"
  curl --silent --location http://git.io/weave --output /usr/bin/weave
  chmod +x /usr/bin/weave
  /usr/bin/weave setup
fi

/usr/bin/weave version

/usr/bin/weave launch-router --init-peer-count 7

/usr/bin/weave launch-proxy --rewrite-inspect

## Find nodes with `kube-weave` tag in an instance group

list_weave_peers_in_group() {
  ## There doesn't seem to be a native way to obtain instances with certain tags, so we use awk
  gcloud compute instance-groups list-instances $1 --uri --quiet \
    | xargs -n1 gcloud compute instances describe \
        --format='value(tags.items[], name, networkInterfaces[0].accessConfigs[0].natIP)' \
    | awk '$1 ~ /(^|\;)kube-weave($|\;).*/ && $2 ~ /^kube-.*$/ { print $2 }'
}

## This is very basic way of doing Weave Net peer discovery, one could potentially implement a pair of
## systemd units that write and watch an environment file and call `weave connect` when needed...
## However, the purpose of this script is only too illustrate the usage of Kubernetes Anywhere in GCE.

/usr/bin/weave connect \
  $(list_weave_peers_in_group kube-master-group) \
  $(list_weave_peers_in_group kube-node-group)

/usr/bin/weave expose -h $(hostname).weave.local

if ! [ -x /usr/bin/scope ] ; then
  echo "Installing current version of Weave Scope"
  curl --silent --location http://git.io/scope --output /usr/bin/scope
  chmod +x /usr/bin/scope
fi

/usr/bin/scope version

/usr/bin/scope launch --probe.kubernetes="true" --probe.kubernetes.api="http://kube-apiserver.weave.local:8080"

eval $(/usr/bin/weave env)

## We don't set a restart policy here, as this script re-runs on each boot, which is quite handy,
## however we need clear out previous container while saving the logs for future reference

save_last_run_log_and_cleanup() {
  if [[ $(docker inspect --format='{{.State.Status}}' $1) = 'exited' ]]
  then
    docker logs $1 > /var/log/$1_last_run 2>&1
    docker rm $1
  fi
}

case "$(hostname)" in
  kube-etcd-1)
    save_last_run_log_and_cleanup etcd1
    docker pull weaveworks/kubernetes-anywhere:etcd-v1.2
    docker run --detach \
      --env="ETCD_CLUSTER_SIZE=3" \
      --name="etcd1" \
        weaveworks/kubernetes-anywhere:etcd-v1.2
    ;;
  kube-etcd-2)
    save_last_run_log_and_cleanup etcd2
    docker pull weaveworks/kubernetes-anywhere:etcd-v1.2
    docker run --detach \
      --env="ETCD_CLUSTER_SIZE=3" \
      --name="etcd2" \
        weaveworks/kubernetes-anywhere:etcd-v1.2
    ;;
  kube-etcd-3)
    save_last_run_log_and_cleanup etcd3-v1.2
    docker pull weaveworks/kubernetes-anywhere:etcd-v1.2
    docker run --detach \
      --env="ETCD_CLUSTER_SIZE=3" \
      --name="etcd3" \
        weaveworks/kubernetes-anywhere:etcd-v1.2
    ;;
  kube-master-0)
    save_last_run_log_and_cleanup kube-apiserver
    save_last_run_log_and_cleanup kube-controller-manager
    save_last_run_log_and_cleanup kube-scheduler
    docker pull weaveworks/kubernetes-anywhere:apiserver-v1.2
    docker pull weaveworks/kubernetes-anywhere:controller-manager-v1.2
    docker pull weaveworks/kubernetes-anywhere:scheduler-v1.2
    docker run --detach \
      --env="ETCD_CLUSTER_SIZE=3" \
      --env="CLOUD_PROVIDER=gce" \
      --name="kube-apiserver" \
        weaveworks/kubernetes-anywhere:apiserver-v1.2
    docker run --detach \
      --env="CLOUD_PROVIDER=gce" \
      --name="kube-controller-manager" \
        weaveworks/kubernetes-anywhere:controller-manager-v1.2
    docker run --detach \
      --name="kube-scheduler" \
        weaveworks/kubernetes-anywhere:scheduler-v1.2
    ;;
  ## kube-[5..N] are the cluster nodes
  kube-node-*)
    save_last_run_log_and_cleanup kubelet
    save_last_run_log_and_cleanup kube-proxy
    docker pull weaveworks/kubernetes-anywhere:toolbox-v1.2
    docker pull weaveworks/kubernetes-anywhere:kubelet-v1.2
    docker pull weaveworks/kubernetes-anywhere:proxy-v1.2
    docker run \
      --env="USE_CNI=yes" \
      --volume="/:/rootfs" \
      --volume="/var/run/docker.sock:/docker.sock" \
        weaveworks/kubernetes-anywhere:toolbox-v1.2 \
          setup-kubelet-volumes
    docker run --detach \
      --env="USE_CNI=yes" \
      --env="CLOUD_PROVIDER=gce" \
      --name="kubelet" \
      --privileged="true" --net="host" --pid="host" \
      --volumes-from="kubelet-volumes" \
        weaveworks/kubernetes-anywhere:kubelet-v1.2
    docker run --detach \
      --name="kube-proxy" \
      --privileged="true" --net="host" --pid="host" \
        weaveworks/kubernetes-anywhere:proxy-v1.2
    ;;
esac
