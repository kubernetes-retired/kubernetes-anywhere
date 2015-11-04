IMG="weaveworks/kubernetes-anywhere"

docker run -d --name=etcd gcr.io/google_containers/etcd:2.0.13 \
  etcd \
  --listen-peer-urls 'http://etcd:2380,http://etcd:7001' \
  --listen-client-urls 'http://etcd:2379,http://etcd:4001' \
  --advertise-client-urls 'http://etcd:2379,http://etcd:4001'

docker run -d --name=kube-apiserver \
  $IMG:apiserver

docker run -d --name=kube-scheduler \
  $IMG:scheduler

docker run -d --name=kube-controller-manager \
  $IMG:controller-manager

docker run -d --name=kubelet \
  --privileged=true --net=host --net=host --pid=host \
  -v /var/run/weave/weave.sock:/weave.sock \
  $IMG:kubelet

docker run -d --name=kube-proxy \
  --privileged=true --net=host --net=host --pid=host \
  $IMG:proxy

docker run \
  $IMG:kubectl create -f /skydns-addon
