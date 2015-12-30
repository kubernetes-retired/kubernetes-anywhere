#!/bin/sh -x

/fix-nameserver

/hyperkube kubelet \
  --docker-endpoint=unix:/weave.sock \
  --port=10250 \
  --api-servers=http://kube-apiserver.weave.local:8080 \
  --cluster-dns=10.16.0.3 \
  --cluster-domain=kube.local \
  --containerized=true \
  --logtostderr=true
