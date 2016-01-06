#!/bin/sh -x

applet="controller-manager"
config="/srv/kubernetes/kube-${applet}/kubeconfig"
master="kube-apiserver.weave.local"

if [ -f $config ]
then
  args="--kubeconfig=${config} --service-account-private-key-file=/srv/kubernetes/kube-${applet}/kube-apiserver.key --root-ca-file=/srv/kubernetes/kube-${applet}/kube-ca.crt"
else
  args="--master=http://${master}:8080"
fi

exec /hyperkube ${applet} ${args} --logtostderr="true"
