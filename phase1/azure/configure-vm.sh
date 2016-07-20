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
[Unit]
After=var-lib-docker.mount
Requires=var-lib-docker.mount
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --storage-driver=overlay
EOF

#Services to format and mount the Ephemerials SSDs

cat <<EOF > /etc/systemd/system/format-ephemeral.service
[Unit]
Description=Format Ephemeral Volume
Documentation=https://coreos.com/os/docs/latest/mounting-storage.html
Before=docker.service var-lib-docker.mount
After=dev-sdb.device
Requires=dev-sdb.device
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "umount -f /mnt/resource || /bin/true"
ExecStart=/bin/bash -c "umount -A /dev/sdb1 || /bin/true"
ExecStart=/bin/bash -c "rm -rf /mnt/resource"
ExecStart=/bin/bash -c "wipefs -f /dev/sdb1"
ExecStart=/bin/bash -c "mkfs.ext4 -F /dev/sdb"
[Install]
RequiredBy=var-lib-docker.mount
EOF

cat <<EOF > /etc/systemd/system/var-lib-docker.mount
[Unit]
Description=Mount /var/lib/docker
Documentation=https://coreos.com/os/docs/latest/mounting-storage.html
Before=docker.service
After=format-ephemeral.service
Requires=format-ephemeral.service
[Install]
RequiredBy=docker.service
[Mount]
What=/dev/sdb
Where=/var/lib/docker
Type=ext4
EOF

# Start formating and mouting the Docker lib on Ephemerial SSD (only D or DS series)
systemctl start format-ephemeral.service

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
  -v /:/host_root \
  -v /etc/kubernetes/k8s_config.json:/opt/playbooks/config.json:ro \
  "$installer_container" \
  /opt/do_role.sh "$ROLE"
