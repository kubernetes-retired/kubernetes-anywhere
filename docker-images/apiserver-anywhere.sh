#!/bin/sh -x

etcd_cluster=$(seq -s , 1 $ETCD_CLUSTER_SIZE | sed 's|\([1-9]*\)|http://etcd\1:2379|g')

weave_ip=$(hostname -i)

config="/srv/kubernetes/"

if [ -d $config ]
then
  args="--tls-cert-file=${config}/kube-apiserver.crt --tls-private-key-file=${config}/kube-apiserver.key --client-ca-file=${config}/kube-ca.crt --token-auth-file=/srv/kubernetes/known_tokens.csv"
else
  args="--insecure-bind-address=${weave_ip} --port=8080"
fi

exec /hyperkube apiserver ${args} \
  --advertise-address="${weave_ip}" \
  --external-hostname="kube-apiserver.weave.local" \
  --etcd-servers="${etcd_cluster}" \
  --service-cluster-ip-range="10.16.0.0/12" \
  --cloud-provider="${CLOUD_PROVIDER}" \
  --allow-privileged="true" \
  --logtostderr="true"
