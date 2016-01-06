#!/bin/sh -x

applet="controller-manager"
config="/srv/kubernetes/kube-${applet}"
master="kube-apiserver.weave.local"

if [ -d $config ]
then
  args="--master=https://${master}:6443 --service-account-private-key-file=${config}/kube-apiserver.key --root-ca-file=${config}/kube-ca.crt"
else
  args="--master=http://${master}:8080"
fi

exec /hyperkube ${applet} ${args} --logtostderr="true"
