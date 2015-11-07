#!/bin/bash

INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names weave-ecs-demo-group --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output text)
DNS_NAMES=$(aws ec2 describe-instances --instance-ids $INSTANCE_IDS --query 'Reservations[0].Instances[*].PublicDnsName' --output text)

SSH_FLAGS="-o Compression=yes -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i weave-ecs-demo-key.pem"

for i in $DNS_NAMES
do echo $i:
  ssh $SSH_FLAGS ec2-user@$i docker ps
done
