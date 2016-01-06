#!/bin/sh -x

/fix-nameserver

applet="proxy"
config="/srv/kubernetes/kube-${applet}/kubeconfig"
master="kube-apiserver.weave.local"

if [ -f $config ]
then
  args="--kubeconfig=${config} --master=https://${master}:6443"
else
  args="--master=http://${master}:8080"
fi

exec /hyperkube ${applet} ${args} --logtostderr="true"
