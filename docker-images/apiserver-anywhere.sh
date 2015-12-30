#!/bin/sh -x

etcd_cluster=$(seq -s , 1 $ETCD_CLUSTER_SIZE | sed 's|\([1-9]*\)|http://etcd\1:2379|g')

weave_ip=$(hostname -i)

/hyperkube apiserver \
  --insecure-bind-address=$weave_ip \
  --advertise-address=$weave_ip \
  --external-hostname=kube-apiserver.weave.local \
  --port=8080 \
  --etcd-servers=$etcd_cluster \
  --service-cluster-ip-range=10.16.0.0/12 \
  --cloud-provider=$CLOUD_PROVIDER \
  --logtostderr=true
