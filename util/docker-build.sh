#!/bin/bash
set -eux -o pipefail

apk add --update git build-base wget curl jq autoconf automake pkgconfig ncurses libtool gperf flex bison ca-certificates

## Install kubectl
export KUBECTL_VERSION=1.4.0
wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

## Install Jsonnet
cd /tmp
git clone https://github.com/google/jsonnet.git
(cd jsonnet
make jsonnet
cp jsonnet /usr/local/bin)
rm -rf /tmp/jsonnet

## Install Terraform
export TERRAFORM_VERSION=0.7.2
export TERRAFORM_SHA256SUM=b337c885526a8a653075551ac5363a09925ce9cf141f4e9a0d9f497842c85ad5

mkdir -p /tmp/terraform/
(cd /tmp/terraform
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
sed -i '/terraform_${TERRAFORM_VERSION}_linux_amd64.zip/!d' /tmp/terraform/terraform_${TERRAFORM_VERSION}_SHA256SUMS
sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin)
rm -rf /tmp/terraform

## Install azure-xplat-cli
npm install -g azure-cli

## Install kconfig-conf
export KCONFIG_VERSION=4.7.0.0
mkdir -p /tmp/kconfig-frontends
(cd /tmp/kconfig-frontends
git clone "https://github.com/colemickens/kconfig-frontends" .
git checkout "v${KCONFIG_VERSION}"
autoreconf -fi
./configure nconf_EXTRA_LIBS=-lgpm --disable-shared --enable-static --disable-gconf --disable-qconf
make
make install)
rm -rf /tmp/kconfig-frontends
