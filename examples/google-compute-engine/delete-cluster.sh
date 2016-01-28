#!/bin/bash -x

gcloud compute instances delete -q $(seq -f 'kube-etcd-%g' 1 3) 'kube-master-0'

gcloud compute instance-groups managed delete -q 'kubernetes-minion-group'

gcloud compute instance-templates delete -q 'kubernetes-minion-template'

gcloud compute firewall-rules delete -q 'kube-net-1-extfw' 'kube-net-1-intfw' 'kubernetes-minion-all'

## TODO: handle cleanup of dynamically allocated resources (forwarding rules, static IPs etc)

gcloud compute networks delete -q 'kube-net-1'
