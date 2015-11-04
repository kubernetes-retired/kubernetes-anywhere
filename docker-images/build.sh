#!/bin/sh -x
for i in kubelet proxy apiserver controller-manager scheduler tools
do docker $(docker-machine config kubedev) build -t weaveworks/kubernetes-anywhere:$i -f ./$i ./
done
