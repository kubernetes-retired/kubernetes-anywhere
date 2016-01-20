#!/bin/bash -ex
p="--project weave-testing-1"
z="--zone europe-west1-c"

gcloud compute networks create $p 'kube-net-1' \
  --range '192.168.0.0/16'

gcloud compute firewall-rules create $p 'kube-net-1-extfw' \
  --network 'kube-net-1' --allow 'tcp:22,tcp:4040,tcp:30000-32767,udp:30000-32767'

gcloud compute firewall-rules create $p 'kube-net-1-intfw' \
  --network 'kube-net-1' --allow 'tcp:6783,udp:6783-6784' --source-ranges '192.168.0.0/16'

gcloud compute instances create $p $z $(seq -f 'kube-%g' 1 7) \
  --network 'kube-net-1' --image 'debian-8' --metadata-from-file 'startup-script=provision.sh'
