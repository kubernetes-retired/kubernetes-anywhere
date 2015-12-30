#!/bin/sh -x

/fix-nameserver

/hyperkube proxy \
  --master=http://kube-apiserver.weave.local:8080 \
  --logtostderr=true
