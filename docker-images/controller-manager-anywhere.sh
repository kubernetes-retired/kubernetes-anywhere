#!/bin/sh -x

/hyperkube controller-manager \
  --master=http://kube-apiserver.weave.local:8080 \
  --logtostderr=true
