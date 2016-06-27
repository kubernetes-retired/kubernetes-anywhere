#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

get_metadata() {
  curl \
    -sSL --fail \
    -H "Metadata-Flavor: Google" \
    "metadata/computeMetadata/v1/instance/attributes/${1}"
}

ROLE=$(get_metadata "k8s-role")

mkdir -p /etc/systemd/system/docker.service.d/
cat <<EOF > /etc/systemd/system/docker.service.d/clear_mount_propagtion_flags.conf
[Service]
MountFlags=shared
EOF

mkdir -p /etc/kubernetes/
get_metadata "k8s-config" > /etc/kubernetes/k8s_config.json

mkdir -p /srv/kubernetes
case "${ROLE}" in
  "master")
    get_metadata "k8s-ca-public-key" \
      > /srv/kubernetes/ca.pem
    get_metadata "k8s-apisever-public-key" \
      > /srv/kubernetes/apiserver.pem
    get_metadata "k8s-apisever-private-key" \
      > /srv/kubernetes/apiserver-key.pem
    ;;
  "node")
    get_metadata "k8s-node-kubeconfig" \
      > /srv/kubernetes/kubeconfig.json
    ;;
  "default")
    echo "'${ROLE}' is not a valid role"
    exit 1
esac

curl -sSL https://get.docker.com/ | sh
apt-get install bzip2
systemctl start docker || true

docker run \
  --net=host \
  -v /:/host_root \
  -v /etc/kubernetes/k8s_config.json:/opt/playbooks/config.json:ro \
  gcr.io/mikedanese-k8s/install-k8s:v2 \
  /opt/do_role.sh "${ROLE}"
