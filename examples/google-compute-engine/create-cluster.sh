#!/bin/bash -ex

gcloud compute networks create 'kube-net' \
  --mode 'auto'

gcloud compute firewall-rules create 'kube-extfw' \
  --network 'kube-net' \
  --allow 'tcp:22,tcp:4040' \
  --target-tags 'kube-ext' \
  --description 'External access for SSH and Weave Scope user interface'

gcloud compute firewall-rules create 'kube-intfw' \
  --network 'kube-net' \
  --allow 'tcp:6783,udp:6783-6784' \
  --source-tag 'kube-weave' \
  --target-tags 'kube-weave' \
  --description 'Internal access for Weave Net ports'

gcloud compute firewall-rules create 'kube-nodefw' \
  --network 'kube-net' \
  --allow 'tcp,udp,icmp,esp,ah,sctp' \
  --source-tag 'kube-node' \
  --target-tags 'kube-node' \
  --description 'Internal access to all ports on the nodes'

## The etcd nodes and master are in an unmanaged group, because it'd be hard
## for the provisioning script to decide which of the instances in a managed
## group should run `etcd1`, `etcd2` or `etcd3`. It's also not quite likelly
## that one will autoscale the etcd nodes, as that cannot be magic. Hence an
## unmanaged instance group is used and thereby our predefined hostnames are
## retained and provisioning script is kept simple. With Kubernetes 1.2 and
## the leader election feature we might put master nodes into a managed group.

gcloud compute instance-groups unmanaged create 'kube-master-group'

common_instace_flags=(
  --network kube-net
  --image debian-8
  --metadata-from-file startup-script=provision.sh
  --boot-disk-type pd-standard
)

etcd_instances=($(seq -s ' ' -f 'kube-etcd-%g' 1 3))

gcloud compute instances create "${etcd_instances[@]}" \
  "${common_instace_flags[@]}" \
  --tags 'kube-weave,kube-ext' \
  --boot-disk-size '20GB' \
  --scopes 'compute-ro'

gcloud compute instances create 'kube-master-0' \
  "${common_instace_flags[@]}" \
  --tags 'kube-weave,kube-ext' \
  --boot-disk-size '10GB' \
  --can-ip-forward \
  --scopes 'storage-ro,compute-rw,monitoring,logging-write'

gcloud compute instance-groups unmanaged add-instances 'kube-master-group' \
  --instances "$(echo "${etcd_instances[@]}" 'kube-master-0' | tr ' ' ',' )"

gcloud compute instance-templates create 'kube-node-template' \
  "${common_instace_flags[@]}" \
  --tags 'kube-weave,kube-ext,kube-node' \
  --boot-disk-size '30GB' \
  --can-ip-forward \
  --scopes 'storage-ro,compute-rw,monitoring,logging-write'

gcloud compute instance-groups managed create 'kube-node-group' \
  --template 'kube-node-template' \
  --base-instance-name 'kube-node' \
  --size 3
