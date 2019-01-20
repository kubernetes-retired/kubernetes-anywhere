#!/bin/bash

# WARNING: some of the tools in this build are VERY outdated!

set -o errexit
set -o pipefail
set -o nounset
set -x

apk add --update git build-base wget curl jq autoconf automake pkgconfig ncurses-dev libtool gperf flex bison ca-certificates python openssh-client

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
