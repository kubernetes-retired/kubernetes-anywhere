#!/bin/sh -x

ETCD_INITIAL_CLUSTER=$(seq -s , 1 $ETCD_CLUSTER_SIZE | sed 's|\([1-9]*\)|etcd\1=http://etcd\1:2380|g')

export ETCD_INITIAL_CLUSTER

n="$(hostname -s)" c="http://${n}:2379" p="http://${n}:2380"

exec etcd --name=$n \
  --listen-peer-urls=$p \
  --initial-advertise-peer-urls=$p \
  --listen-client-urls=$c \
  --advertise-client-urls=$c
