#!/bin/bash -x

etcd_instances=($(seq -s ' ' -f 'kube-etcd-%g' 1 3))

gcloud compute instances delete -q "${etcd_instances[@]}" 'kube-master-0'

gcloud compute instance-groups unmanaged delete -q 'kube-master-group'

gcloud compute instance-groups managed delete -q 'kube-node-group'

gcloud compute instance-templates delete -q 'kube-node-template'

gcloud compute firewall-rules delete -q 'kube-extfw' 'kube-intfw' 'kube-nodefw'

## TODO: handle cleanup of dynamically allocated resources (forwarding rules, static IPs etc)

gcloud compute networks delete -q 'kube-net'
