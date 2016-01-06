#!/bin/sh -x

etcd_cluster=$(seq -s , 1 $ETCD_CLUSTER_SIZE | sed 's|\([1-9]*\)|http://etcd\1:2379|g')

weave_ip=$(hostname -i)

if [ -d '/srv/kubernetes/' ]
then
  args="--tls-cert-file=/srv/kubernetes/kube-apiserver.crt --tls-private-key-file=/srv/kubernetes/kube-apiserver.key --token-auth-file=/srv/kubernetes/known_tokens.csv"
else
  args="--insecure-bind-address=${weave_ip} --port=8080"
fi

exec /hyperkube apiserver ${args} \
  --advertise-address="${weave_ip}" \
  --external-hostname="kube-apiserver.weave.local" \
  --etcd-servers="${etcd_cluster}" \
  --service-cluster-ip-range="10.16.0.0/12" \
  --cloud-provider="${CLOUD_PROVIDER}" \
  --logtostderr="true"
