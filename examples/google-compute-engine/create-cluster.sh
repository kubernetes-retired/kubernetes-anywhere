#!/bin/bash -ex

gcloud compute networks create 'kube-net-1' \
  --range '192.168.0.0/16'

gcloud compute firewall-rules create 'kube-net-1-extfw' \
  --network 'kube-net-1' --allow 'tcp:22,tcp:4040,tcp:30000-32767,udp:30000-32767'

gcloud compute firewall-rules create 'kube-net-1-intfw' \
  --network 'kube-net-1' --allow 'tcp:6783,udp:6783-6784' --source-ranges '192.168.0.0/16'

gcloud compute instances create $(seq -f 'kube-%g' 1 7) \
  --scopes "storage-ro,compute-rw,monitoring,logging-write" --can-ip-forward  \
  --network 'kube-net-1' --image 'debian-8' --metadata-from-file 'startup-script=provision.sh'
