#!/bin/bash
set -eux -o pipefail

apk add --update git build-base wget curl jq autoconf automake pkgconfig ncurses-dev libtool gperf flex bison ca-certificates python openssh-client

## Install kubectl
export KUBECTL_VERSION=1.6.0-beta.4
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
export TERRAFORM_VERSION=0.9.4

mkdir -p /tmp/terraform/
(cd /tmp/terraform
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
sed -i '/terraform_${TERRAFORM_VERSION}_linux_amd64.zip/!d' /tmp/terraform/terraform_${TERRAFORM_VERSION}_SHA256SUMS
sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin)
rm -rf /tmp/terraform

## Install kconfig-conf
export KCONFIG_VERSION=4.7.0.0
mkdir -p /tmp/kconfig-frontends
(cd /tmp/kconfig-frontends
git clone "https://github.com/colemickens/kconfig-frontends" .
git checkout "v${KCONFIG_VERSION}"
autoreconf -fi
./configure nconf_EXTRA_LIBS=-lgpm --disable-shared --enable-static --disable-gconf --disable-qconf --disable-nconf
make
make install)
rm -rf /tmp/kconfig-frontends

## Install gcloud, the CLI for GCE
export GOOGLE_SDK_VERSION=148.0.1
mkdir -p /tmp/google-sdk
(cd /tmp/google-sdk
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GOOGLE_SDK_VERSION}-linux-x86_64.tar.gz
tar xf google-cloud-sdk-${GOOGLE_SDK_VERSION}-linux-x86_64.tar.gz -C /
/google-cloud-sdk/install.sh -q --path-update true
source ~/.bashrc
)
rm -rf /tmp/google-sdk
