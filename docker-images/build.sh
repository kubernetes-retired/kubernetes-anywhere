#!/bin/sh -x
for i in kubectl kubelet proxy apiserver controller-manager scheduler
do docker $(docker-machine config kubedev) build -t weaveworks/kubernetes-anywhere:$i -f ./$i ./
done
