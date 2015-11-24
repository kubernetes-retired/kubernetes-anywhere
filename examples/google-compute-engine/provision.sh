#!/bin/sh

gpasswd -a ilya docker

/etc/init.d/kubelet stop

curl --silent --location http://git.io/weave --output /usr/local/bin/weave
chmod +x /usr/local/bin/weave

/usr/local/bin/weave launch-router --init-peer-count 7

/usr/local/bin/weave launch-proxy --rewrite-inspect

/usr/local/bin/weave connect kube-1
/usr/local/bin/weave expose -h $(hostname).weave.local

eval $(/usr/local/bin/weave env)

etcd_cluster_list="-e ETCD_INITIAL_CLUSTER=etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380"

case "$(hostname)" in 
  kube-1)
    docker run -d \
      ${etcd_cluster_list} \
      --name=etcd1 \
      weaveworks/kubernetes-anywhere:etcd
    break
    ;;
  kube-2)
    docker run -d \
      ${etcd_cluster_list} \
      --name=etcd2 \
      weaveworks/kubernetes-anywhere:etcd
    break
    ;;
  kube-3)
    docker run -d \
      ${etcd_cluster_list} \
      --name=etcd3 \
      weaveworks/kubernetes-anywhere:etcd
    break
    ;;
  kube-4)
    docker run -d \
      -e ETCD_CLUSTER='http://etcd1:2379,http://etcd2:2379,http://etcd3:2379' \
      --name=kube-apiserver \
      weaveworks/kubernetes-anywhere:apiserver
    docker run -d \
      --name=kube-controller-manager \
      weaveworks/kubernetes-anywhere:controller-manager
    docker run -d \
      --name=kube-scheduler \
      weaveworks/kubernetes-anywhere:scheduler
    break
    ;;
  *)
    docker run -d \
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
    docker run -d \
      --name=kube-proxy \
      --privileged=true --net=host --pid=host \
      weaveworks/kubernetes-anywhere:proxy
    ;;
esac
