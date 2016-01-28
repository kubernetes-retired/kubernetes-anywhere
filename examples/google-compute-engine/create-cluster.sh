#!/bin/bash -ex

gcloud compute networks create 'kube-net-1' \
  --range '192.168.0.0/16'

gcloud compute firewall-rules create 'kube-net-1-extfw' \
  --network 'kube-net-1' \
  --allow 'tcp:22,tcp:4040' \
  --target-tags 'kube-ext'

gcloud compute firewall-rules create 'kube-net-1-intfw' \
  --network 'kube-net-1' \
  --allow 'tcp:6783,udp:6783-6784' \
  --source-ranges '192.168.0.0/16' \
  --target-tags 'kube-net-weave'

gcloud compute firewall-rules create 'kubernetes-minion-all' \
  --network 'kube-net-1' \
  --allow 'tcp,udp,icmp,esp,ah,sctp' \
  --source-ranges '192.168.0.0/16' \
  --target-tags 'kubernetes-minion'

## TODO: either figure out a sensible way to discover Weave Net peers
## and turn all the things into either one or more intance groups;
## OR figure out how what's missing to make it all a flat set of
## instances where cloud provider will still function as it is

gcloud compute instances create $(seq -f 'kube-etcd-%g' 1 3) \
  --network 'kube-net-1' \
  --tags 'kube-net-weave,kube-ext' \
  --image 'debian-8' \
  --metadata-from-file 'startup-script=provision.sh' \
  --boot-disk-type 'pd-standard' --boot-disk-size '20GB'

gcloud compute instances create 'kube-master-0' \
  --network 'kube-net-1' \
  --tags 'kube-net-weave,kube-ext' \
  --image 'debian-8' \
  --metadata-from-file 'startup-script=provision.sh' \
  --boot-disk-type 'pd-standard' --boot-disk-size '10GB' \
  --can-ip-forward \
  --scopes 'storage-ro,compute-rw,monitoring,logging-write'

gcloud compute instance-templates create 'kubernetes-minion-template' \
  --network 'kube-net-1' \
  --tags 'kube-net-weave,kube-ext,kubernetes-minion' \
  --image 'debian-8' \
  --metadata-from-file 'startup-script=provision.sh' \
  --boot-disk-type 'pd-standard' --boot-disk-size '30GB' \
  --can-ip-forward \
  --scopes 'storage-ro,compute-rw,monitoring,logging-write'

gcloud compute instance-groups managed create 'kubernetes-minion-group' \
  --base-instance-name 'kubernetes-minion' --size 3 --template 'kubernetes-minion-template'
