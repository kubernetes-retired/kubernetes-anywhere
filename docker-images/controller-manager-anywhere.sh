#!/bin/sh -x

applet="controller-manager"
config="/srv/kubernetes/kube-${applet}"
master="kube-apiserver.weave.local"

if [ -d $config ]
then
  args="--kubeconfig=${config}/kubeconfig --service-account-private-key-file=${config}/kube-apiserver.key --root-ca-file=${config}/kube-ca.crt"
else
  args="--master=http://${master}:8080"
fi

weave_ip=$(hostname -i)

exec /hyperkube ${applet} ${args} --address=${weave_ip} --logtostderr="true"
