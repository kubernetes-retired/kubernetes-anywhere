#!/bin/bash -x

# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

etcd_instances=($(seq -s ' ' -f 'kube-etcd-%g' 1 3))
dynamic_firewall_rules=($(gcloud compute firewall-rules list --regexp 'k8s-fw-.*' --uri))

gcloud compute instances delete -q "${etcd_instances[@]}" 'kube-master-0'

gcloud compute instance-groups unmanaged delete -q 'kube-master-group'

gcloud compute instance-groups managed delete -q 'kube-node-group'

gcloud compute instance-templates delete -q 'kube-node-template'

gcloud compute firewall-rules delete -q 'kube-extfw' 'kube-intfw' 'kube-nodefw' "${dynamic_firewall_rules[@]}"

## TODO: handle cleanup of dynamically allocated resources (forwarding rules, static IPs etc)

gcloud compute networks delete -q 'kube-net'
