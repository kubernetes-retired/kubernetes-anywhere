#!/bin/sh -x

/hyperkube scheduler \
  --master=http://kube-apiserver.weave.local:8080 \
  --logtostderr=true
