#!/bin/bash
set -eux -o pipefail

apk add --update git build-base wget jq autoconf automake pkgconfig ncurses libtool gperf flex bison ca-certificates

## Install kubectl
export KUBECTL_VERSION=1.3.5
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
export TERRAFORM_VERSION=0.7.1
export TERRAFORM_SHA256SUM=133766ed558af04255490f135fed17f497b9ba1e277ff985224e1287726ab2dc

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
#apt-get update && apt-get install -y autoconf automake pkg-config gperf libtool flex bison libncurses5-dev \
mkdir -p /tmp/kconfig-frontends
(cd /tmp/kconfig-frontends
git clone "https://github.com/colemickens/kconfig-frontends" .
git checkout "v${KCONFIG_VERSION}"
autoreconf -fi
./configure nconf_EXTRA_LIBS=-lgpm --disable-shared --enable-static --disable-gconf --disable-qconf
make
make install)
rm -rf /tmp/kconfig-frontends
