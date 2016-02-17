#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

export AWS_DEFAULT_REGION=$(curl --silent curl http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

instance_description=$(
  aws ec2 describe-instances \
    --instance-ids $(curl -s curl http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .instanceId) \
    --filters 'Name=tag:KubernetesCluster,Values=kubernetes'
)

instance_name_tag=$(
  printf "${instance_description}" \
  | jq -r '.Reservations[].Instances[].Tags[] | select(.Key=="Name") .Value'
)

etcd_node_name=$(
  printf "${instance_description}" \
  | jq -r '.Reservations[].Instances[].Tags[] | select(.Key=="KubernetesEtcdNodeName") .Value'
)

echo "NAME_TAG=\"${instance_name_tag}\""
test -z "${etcd_node_name}" || echo "ETCD_NODE_NAME=\"${etcd_node_name}\""
