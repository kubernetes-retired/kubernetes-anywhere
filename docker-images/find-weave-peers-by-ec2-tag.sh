#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

export AWS_DEFAULT_REGION=$(curl --silent curl http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

aws ec2 describe-instances --filters \
    'Name=tag:KubernetesCluster,Values=kubernetes' \
    'Name=instance-state-name,Values=running,pending' \
  | jq -r '.Reservations[].Instances[].PrivateIpAddress | if . != null then . else empty end' \
  | xargs
