#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

doc=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document)
export AWS_DEFAULT_REGION=$(printf "${doc}" | jq -r .region)

instance_description=$(
  aws ec2 describe-instances \
    --instance-ids $(printf "${doc}" | jq -r .instanceId)
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
