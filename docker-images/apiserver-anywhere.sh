#!/bin/bash -x

etcd_cluster=$(seq -s , 1 "${ETCD_CLUSTER_SIZE}" | sed 's|\([1-9]*\)|http://etcd\1:2379|g')

weave_ip=$(hostname -i)

args=(
  --advertise-address="${weave_ip}"
  --external-hostname="kube-apiserver.weave.local"
  --etcd-servers="${etcd_cluster}"
  --service-cluster-ip-range="10.16.0.0/12"
  --cloud-provider="${CLOUD_PROVIDER}"
  --allow-privileged="true"
  --logtostderr="true"
)

config="/srv/kubernetes/"

if [ -d $config ]
then
  args+=(
    --tls-cert-file="${config}/kube-apiserver.crt"
    --tls-private-key-file="${config}/kube-apiserver.key"
    --client-ca-file="${config}/kube-ca.crt"
    --token-auth-file="/srv/kubernetes/known_tokens.csv"
    --admission-control="NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"
  )
  if [ "${FORCE_LOCAL_APISERVER}" = "yes" ]
  then
    args+=(
      # It will have to listen on all interfaces, but local to the container,
      # however this means it will also be exposed unsecurelly on Weave Net
      # (`${weave_ip}:${APISERVER_LOCAL_PORT}`), hence it's only for local
      # single-node deployment.
      --insecure-bind-address="0.0.0.0"
      --insecure-port="${APISERVER_LOCAL_PORT}"
    )
  fi
else
  args+=(
    --insecure-bind-address="${weave_ip}"
    --port="8080"
  )
fi


exec /hyperkube apiserver "${args[@]}"
