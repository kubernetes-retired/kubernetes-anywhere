#!/bin/bash

# Copyright 2015-2016 Weaveworks Ltd.
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

INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names weave-ecs-demo-group --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output text)
DNS_NAMES=$(aws ec2 describe-instances --instance-ids $INSTANCE_IDS --query 'Reservations[0].Instances[*].PublicDnsName' --output text)

SSH_FLAGS="-o Compression=yes -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i weave-ecs-demo-key.pem"

for i in $DNS_NAMES
do echo $i:
  ssh $SSH_FLAGS ec2-user@$i docker ps
done
