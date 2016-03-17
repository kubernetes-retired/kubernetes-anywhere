#!/bin/bash -x

/fix-nameserver

config="/srv/kubernetes/kubelet/kubeconfig"
master="kube-apiserver.weave.local"

args=(
  --cluster-dns="10.16.0.3"
  --resolv-conf="/dev/null"
  --cluster-domain="cluster.local"
  --cloud-provider="${CLOUD_PROVIDER}"
  --allow-privileged="true"
  --logtostderr="true"
)

if [ -f $config ]
then
  args+=(
    --kubeconfig="${config}"
    --api-servers="https://${master}:6443"
  )
else
  args+=( --api-servers="http://${master}:8080" )
fi

if [ "${CLOUD_PROVIDER}" = "aws" ]
then ## TODO: check if not needed with v1.2.0 is out (see kubernetes/kubernetes#11543)
  args+=(
    --hostname-override="${AWS_LOCAL_HOSTNAME}"
  )
fi

case "${KUBERNETES_RELEASE}" in
  v1.1.*)
    args+=( --docker-endpoint="unix:/docker.sock" )
    ;;
  v1.2.*)
    args+=( --docker-endpoint="unix:///docker.sock" )
    if [ "${USE_CNI}" = "yes" ]
    then
      args+=(
        --network-plugin="cni"
        --network-plugin-dir="/etc/cni/net.d"
      )
    fi
    ;;
esac

exec /hyperkube kubelet "${args[@]}"
