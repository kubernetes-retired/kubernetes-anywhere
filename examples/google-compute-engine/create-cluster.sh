#!/bin/bash -ex
p="--project weave-testing-1"
z="--zone europe-west1-c"

gcloud compute networks create $p \
  'kube-net-1' \
  --range '192.168.0.0/16'
gcloud compute firewall-rules create $p \
  'kube-net-1-fw' \
  --network 'kube-net-1' \
  --allow 'icmp,tcp:22,tcp:6783,udp:6783'
gcloud compute instances create $p $z \
  $(seq -f 'kube-%g' 1 7) \
  --image 'container-vm' \
  --preemptible \
  --network 'kube-net-1' \
  --metadata-from-file 'startup-script=provision.sh'
