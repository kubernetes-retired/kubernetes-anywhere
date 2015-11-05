#!/bin/sh -x
for i in etcd kubelet proxy apiserver controller-manager scheduler tools
do docker build -t weaveworks/kubernetes-anywhere:$i -f ./$i ./
done
