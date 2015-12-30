#!/bin/bash -x

DOCKER_MACHINE_DRIVER=${DOCKER_MACHINE_DRIVER:-'vmwarefusion'}

vm_names=$(seq -f 'kube-%g' 1 7)

install_weave=" \
  sudo curl --silent --location http://git.io/weave --output /usr/local/bin/weave ; \
  sudo chmod +x /usr/local/bin/weave ; \
  /usr/local/bin/weave launch-router --init-peer-count 7 ; \
  /usr/local/bin/weave launch-proxy --rewrite-inspect ; \
"

for m in $vm_names ; do
  docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${m}
  docker-machine ssh ${m} "${install_weave}"
done

for m in $vm_names ; do
  docker-machine ssh ${m} "/usr/local/bin/weave connect $(docker-machine ip 'kube-1')"
done

for m in $vm_names ; do
  docker-machine ssh ${m} "/usr/local/bin/weave expose -h ${m}.weave.local"
done

weaveproxy_socket="-H unix:///var/run/weave/weave.sock"

docker-machine ssh 'kube-1' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name=etcd1 \
  weaveworks/kubernetes-anywhere:etcd

docker-machine ssh 'kube-2' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name=etcd2 \
  weaveworks/kubernetes-anywhere:etcd

docker-machine ssh 'kube-3' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name=etcd3 \
  weaveworks/kubernetes-anywhere:etcd 

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run -d \
  -e ETCD_CLUSTER_SIZE=3 \
  --name=kube-apiserver \
  weaveworks/kubernetes-anywhere:apiserver

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run -d \
  --name=kube-scheduler \
  weaveworks/kubernetes-anywhere:scheduler

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run -d \
  --name=kube-controller-manager \
  weaveworks/kubernetes-anywhere:controller-manager

for m in 'kube-5' 'kube-6' 'kube-7' ; do
  docker-machine ssh ${m} docker ${weaveproxy_socket} run -d \
    --name=kubelet \
    --privileged=true --net=host --pid=host \
    -v "/var/run/weave/weave.sock:/weave.sock" \
    -v "/:/rootfs:ro" \
    -v "/sys:/sys:ro" \
    -v "/dev:/dev" \
    -v "/var/lib/docker/:/var/lib/docker:rw" \
    -v "/var/lib/kubelet/:/var/lib/kubelet:rw" \
    -v "/var/run:/var/run:rw" \
    -v "/mnt/sda1/var/lib/docker/:/mnt/sda1/var/lib/docker:rw" \
    weaveworks/kubernetes-anywhere:kubelet
  docker-machine ssh ${m} docker ${weaveproxy_socket} run -d \
    --name=kube-proxy \
    --privileged=true --net=host --pid=host \
    weaveworks/kubernetes-anywhere:proxy
done

docker-machine ssh 'kube-4' docker ${weaveproxy_socket} run \
  weaveworks/kubernetes-anywhere:tools \
  kubectl create -f /skydns-addon/
