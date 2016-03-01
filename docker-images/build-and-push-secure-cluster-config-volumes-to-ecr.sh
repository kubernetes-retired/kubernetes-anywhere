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

eval $(aws ecr get-login)

registry=$(printf "%s.dkr.ecr.%s.amazonaws.com" \
  $(printf "${doc}" | jq -r .accountId) \
  $(printf "${doc}" | jq -r .region) \
)

image_prefix=${registry}/${instance_kubernetescluster_tag}

print_image_variable() {
  u=${1^^};
  echo KUBERNETES_ANYWHERE_${u/-/_}_SECURE_CONFIG_IMAGE=\"${image_prefix}/master/secure-config:${1}\"
}

for i in apiserver controller-manager scheduler ; do
  docker tag kubernetes-anywhere:${i}-secure-config ${image_prefix}/master/secure-config:${i}
  print_image_variable $i >> /kubernetes-anywhere.env
done

for i in kubelet proxy tools ; do
  docker tag kubernetes-anywhere:${i}-secure-config ${image_prefix}/node/secure-config:${i}
  print_image_variable $i >> /kubernetes-anywhere.env
done
