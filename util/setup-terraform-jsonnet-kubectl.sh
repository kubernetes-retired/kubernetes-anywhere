#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -x

## Install kubectl
mkdir -p /tmp/kubectl/
cd /tmp/kubectl
export KUBECTL_VERSION=$(curl https://storage.googleapis.com/kubernetes-release/release/latest.txt)
wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
cp kubectl /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl
cd /tmp
rm -rf /tmp/kubectl

## Install Jsonnet
cd /tmp
git clone https://github.com/google/jsonnet.git
(cd jsonnet
make jsonnet
cp jsonnet /usr/local/bin)
rm -rf /tmp/jsonnet

## Install Terraform
export TERRAFORM_VERSION=0.9.4

mkdir -p /tmp/terraform/
(cd /tmp/terraform
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
sed -i '/terraform_${TERRAFORM_VERSION}_linux_amd64.zip/!d' /tmp/terraform/terraform_${TERRAFORM_VERSION}_SHA256SUMS
sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin)
rm -rf /tmp/terraform
