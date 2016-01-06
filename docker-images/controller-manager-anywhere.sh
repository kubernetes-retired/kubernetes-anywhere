#!/bin/sh -x

applet="kube-proxy"
config="/srv/kubernetes/kube-${applet}/kubeconfig"
master="kube-apiserver.weave.local"

if [ -f $config ]
then
  args="--kubeconfig=${config} --master=https://${master}:6443 --service-account-private-key-file=/srv/kubernetes/kube-${applet}/kube-apiserver.key --root-ca-file=/srv/kubernetes/kube-${applet}/kube-ca.crt"
else
  args="--master=http://${master}:8080"
fi

exec /hyperkube ${applet} ${args} --logtostderr="true"
