#!/bin/bash -x

/fix-nameserver

applet="proxy"
config="/srv/kubernetes/kube-${applet}/kubeconfig"
master="kube-apiserver.weave.local"

args=(
  --logtostderr="true"
)

if [ -f $config ]
then
  args+=( --kubeconfig="${config}" )
else
  args+=( --master="http://${master}:8080" )
fi

if ! [ "${USE_CNI}" = "yes" ]
then
  args+=( --proxy-mode="userspace" )
fi

exec /hyperkube ${applet} "${args[@]}"
