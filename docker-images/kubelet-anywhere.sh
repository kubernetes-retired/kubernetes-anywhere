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

exec /hyperkube kubelet ${args} \
  --docker-endpoint="unix:/weave.sock" \
  --cluster-dns="10.16.0.3" \
  --resolv-conf="" \
  --cluster-domain="kube.local" \
  --allow-privileged="true" \
  --logtostderr="true"
