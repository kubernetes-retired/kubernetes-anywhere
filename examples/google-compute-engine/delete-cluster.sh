#!/bin/bash -x

gcloud compute instances delete -q $(seq -f 'kube-%g' 1 7)

gcloud compute firewall-rules delete -q 'kube-net-1-extfw' 'kube-net-1-intfw'

gcloud compute networks delete -q 'kube-net-1'
