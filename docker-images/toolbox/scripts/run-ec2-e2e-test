#!/bin/bash -ex

cd /tmp

tarball_url_prefix="https://storage.googleapis.com/kubernetes-release/release/${KUBE_RELEASE}"

curl --silent "${tarball_url_prefix}/kubernetes.tar.gz" | tar xz
curl --silent "${tarball_url_prefix}/kubernetes-test.tar.gz" | tar xz

cd ./kubernetes

cp ~/.kube/* ./

az=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .availabilityZone)

exec ./platforms/linux/amd64/e2e.test \
  --provider="aws" \
  --gce-zone="${az}" \
  --cluster-tag=KubernetesCluster \
  --kubeconfig="./config" \
  --repo-root="./" \
  $@
