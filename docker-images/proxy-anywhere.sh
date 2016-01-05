#!/bin/sh -x

/fix-nameserver

if [ -f '/srv/kubernetes/kube-proxy/kubeconfig' ]
then
  args="--kubeconfig=/srv/kubernetes/kube-proxy/kubeconfig"
else
  args="--api-servers=http://kube-apiserver.weave.local:8080"
fi

/hyperkube proxy ${args} \
  --logtostderr="true"
