#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
set -o verbose
get_metadata() {
  curl \
    -sSL --fail \
    -H "Metadata-Flavor: Google" \
    "metadata/computeMetadata/v1/instance/attributes/${1}" 2>/dev/null || true
}

KUBEADM_TOKEN=$(get_metadata "k8s-kubeadm-token")
KUBEADM_VERSION=$(get_metadata "k8s-kubeadm-version")
KUBEADM_KUBERNETES_VERSION=$(get_metadata "k8s-kubeadm-kubernetes-version")
KUBEADM_KUBELET_VERSION=$(get_metadata "k8s-kubeadm-kubelet-version")
KUBEADM_ENABLE_CLOUD_PROVIDER=$(get_metadata "k8s-kubeadm-enable-cloud-provider")
KUBEADM_ADVERTISE_ADDRESSES=$(get_metadata "k8s-kubeadm-advertise-addresses")
KUBEADM_CNI_PLUGIN=$(get_metadata "k8s-kubeadm-cni-plugin")
KUBEADM_MASTER_IP=$(get_metadata "k8s-kubeadm-master-ip")
KUBEPROXY_MODE=$(get_metadata "k8s-kubeproxy-mode")
KUBEADM_FEATURE_GATES=$(get_metadata "k8s-kubeadm-feature-gates")

CLOUD_PROVIDER="gce"

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
