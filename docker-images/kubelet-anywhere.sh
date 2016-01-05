#!/bin/sh -x

/fix-nameserver

if [ -f '/srv/kubernetes/kubelet/kubeconfig' ]
then
  args="--kubeconfig=\"/srv/kubernetes/kubelet/kubeconfig\""
else
  args="--api-servers=\"http://kube-apiserver.weave.local:8080\""
fi

/hyperkube kubelet ${args} \
  --docker-endpoint="unix:/weave.sock" \
  --cluster-dns="10.16.0.3" \
  --cluster-domain="kube.local" \
  --containerized="true" \
  --logtostderr="true"
