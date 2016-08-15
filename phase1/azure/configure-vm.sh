#! /bin/bash

set -x
set -o errexit
set -o pipefail
set -o nounset

mkdir -p /etc/systemd/system/docker.service.d/
cat <<EOF > /etc/systemd/system/docker.service.d/clear_mount_propagtion_flags.conf
[Service]
MountFlags=shared
EOF
cat <<EOF > /etc/systemd/system/docker.service.d/overlay.conf
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --storage-driver=overlay
EOF

# start hacky workaround (https://github.com/docker/docker/issues/23793)
  curl -sSL https://get.docker.com/ > /tmp/install-docker
  chmod +x /tmp/install-docker
  /tmp/install-docker || true
  systemctl start docker || true
# end hacky workaround

apt-get install -y jq

ROLE="node"
if [[ $(hostname) = *master* ]]; then
  ROLE="master"
fi

azure_file="/etc/kubernetes/azure.json"
config_file="/etc/kubernetes/k8s_config.json"

mkdir -p /etc/kubernetes
mkdir -p /srv/kubernetes

# the following values are populated by terraform
echo -n "${azure_json}" | base64 -d > "$azure_file"
echo -n "${k8s_config}" | base64 -d > "$config_file"
echo -n "${root_ca_public_pem}" | base64 -d > "/srv/kubernetes/ca.pem"
echo -n "${apiserver_cert_pem}" | base64 -d > "/srv/kubernetes/apiserver.pem"
echo -n "${apiserver_key_pem}" | base64 -d > "/srv/kubernetes/apiserver-key.pem"
cat << EOF > "/srv/kubernetes/kubeconfig.json"
${node_kubeconfig}
EOF

MASTER_IP="$(cat "$config_file" | jq -r '.phase1.azure.master_private_ip')"

jq ". + {\"role\": \"$ROLE\", \"master_ip\": \"$MASTER_IP\"}" "$config_file" > /etc/kubernetes/k8s_config.new; cp /etc/kubernetes/k8s_config.new "$config_file"

installer_container="$(jq -r '.phase2.installer_container' "$config_file")"

docker pull "$installer_container"

docker run \
  --net=host \
  -v /:/mnt/root \
  -v /run:/run \
  -v /etc/kubernetes:/etc/kubernetes \
  -v /var/lib/ignition:/usr/share/oem \
  "$installer_container"

systemctl enable kubelet
systemctl start kubelet
