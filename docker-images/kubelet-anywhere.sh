#!/bin/sh -x

/fix-nameserver

config="/srv/kubernetes/kubelet/kubeconfig"
master="kube-apiserver.weave.local"

if [ -f $config ]
then
  args="--kubeconfig=${config} --api-servers=https://${master}:6443"
else
  args="--api-servers=http://${master}:8080"
fi

exec nsenter --target=1 --mount --wd=. -- \
  ./hyperkube kubelet ${args} \
    --docker-endpoint="unix:/weave.sock" \
    --cluster-dns="10.16.0.3" \
    --cluster-domain="kube.local" \
    --containerized="true" \
    --allow-privileged="true" \
    --logtostderr="true"
