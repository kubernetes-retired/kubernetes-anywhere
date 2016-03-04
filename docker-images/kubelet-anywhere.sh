#!/bin/sh -x

/fix-nameserver

config="/srv/kubernetes/kubelet/kubeconfig"
master="kube-apiserver.weave.local"

if [ -f $config ]
then
  args="--kubeconfig=${config} --api-servers=https://${master}:6443"
else
  args="--api-servers=http://${master}:8080"
fi

if [ ${CLOUD_PROVIDER} = 'aws' ]
then ## TODO: check if not needed with v1.2.0 is out (see kubernetes/kubernetes#11543)
  args="${args} --hostname-override=${AWS_LOCAL_HOSTNAME}"
fi

exec /hyperkube kubelet ${args} \
  --docker-endpoint="unix:/docker.sock" \
  --cluster-dns="10.16.0.3" \
  --resolv-conf="/dev/null" \
  --cluster-domain="cluster.local" \
  --cloud-provider="${CLOUD_PROVIDER}" \
  --allow-privileged="true" \
  --logtostderr="true"
