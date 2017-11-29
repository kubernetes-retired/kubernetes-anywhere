#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

KUBEADM_TOKEN="${k8s_kubeadm_token}"
KUBEADM_VERSION="${k8s_kubeadm_version}"
KUBEADM_KUBERNETES_VERSION="${k8s_kubeadm_kubernetes_version}"
KUBEADM_KUBELET_VERSION="${k8s_kubeadm_kubelet_version}"
KUBEADM_ENABLE_CLOUD_PROVIDER="${k8s_kubeadm_enable_cloud_provider}"
KUBEADM_ADVERTISE_ADDRESSES="${k8s_kubeadm_advertise_addresses}"
KUBEADM_CNI_PLUGIN="${k8s_kubeadm_cni_plugin}"
KUBEADM_MASTER_IP="${k8s_kubeadm_master_ip}"
KUBEPROXY_MODE="${k8s_kubeproxy_mode}"
KUBEADM_FEATURE_GATES=${k8s_kubeadm_feature_gates}

CLOUD_PROVIDER="openstack"

apt-get update
apt-get install -y apt-transport-https

cat <<EOF > /etc/apt/sources.list.d/k8s.list
deb [arch=amd64] https://apt.dockerproject.org/repo ubuntu-xenial main
EOF

mkdir -p /etc/systemd/system/docker.service.d/
cat <<EOF > /etc/systemd/system/docker.service.d/clear_mount_propagtion_flags.conf
[Service]
MountFlags=shared
EOF

apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys F76221572C52609D
apt-get update
apt-get install -y docker-engine=1.12.0-0~xenial
systemctl enable docker || true
systemctl start docker || true

ensure_gsutil_command(){
  if ! type "gsutil" > /dev/null; then
    TMPDIR=/tmp/gsutil
    mkdir $TMPDIR
    apt-get install -y python
    cd $TMPDIR
    wget https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz
    tar xzf google-cloud-sdk.tar.gz && \
      ./google-cloud-sdk/install.sh \
      --disable-installation-options \
      --bash-completion=false \
      --path-update=false \
      --usage-reporting=false
    export PATH=$PWD/google-cloud-sdk/bin:$PATH
    cd -
  fi
}

ensure_gsutil_command
