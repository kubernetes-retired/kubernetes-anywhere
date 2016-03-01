#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

setup-secure-cluster-config-volumes

doc=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document)
export AWS_DEFAULT_REGION=$(printf "${doc}" | jq -r .region)

instance_description=$(
  aws ec2 describe-instances \
    --instance-ids $(printf "${doc}" | jq -r .instanceId)
)

instance_kubernetescluster_tag=$(
  printf "${instance_description}" \
  | jq -r '.Reservations[].Instances[].Tags[] | select(.Key=="KubernetesCluster") .Value'
)

registry=$(printf "%s.dkr.ecr.%s.amazonaws.com" \
  $(printf "${doc}" | jq -r .accountId) \
  $(printf "${doc}" | jq -r .region) \
)

tag_and_push() {
  local ecr_tag="${registry}/${instance_kubernetescluster_tag}/${1}/secure-config:${2}"
  docker tag kubernetes-anywhere:${2}-secure-config $ecr_tag
  docker push $tag
}

for i in apiserver controller-manager scheduler
do tag_and_push master $i
done

for i in kubelet proxy tools ; do
do tag_and_push node $i
done
