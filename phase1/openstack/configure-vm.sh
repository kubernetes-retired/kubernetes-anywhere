#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

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
