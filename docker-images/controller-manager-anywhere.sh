#!/bin/bash -x

applet="controller-manager"
config="/srv/kubernetes/kube-${applet}"
master="kube-apiserver.weave.local"

weave_ip=$(hostname -i)

args=(
  --address="${weave_ip}"
  --cloud-provider="${CLOUD_PROVIDER}"
  --logtostderr="true"
)

if [ -d $config ]
then
  args+=(
    --kubeconfig="${config}/kubeconfig"
    --service-account-private-key-file="${config}/kube-apiserver.key"
    --root-ca-file="${config}/kube-ca.crt"
  )
else
  args+=( --master="http://${master}:8080" )
fi

exec /hyperkube ${applet} "${args[@]}"
