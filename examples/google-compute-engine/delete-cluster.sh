#!/bin/bash -ex
p="--project weave-testing-1"
z="--zone europe-west1-c"

gcloud compute instances delete -q $p $z \
  $(seq -f 'kube-%g' 1 7)
gcloud compute firewall-rules delete -q $p \
  'kube-net-1-fw'
gcloud compute networks delete -q $p \
  'kube-net-1'
