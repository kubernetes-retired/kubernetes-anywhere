# This is not meant to run on its own, but extends phase1/gce/configure-vm.sh

TOKEN=$(get_metadata "k8s-kubeadm-token")

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

case "${ROLE}" in
  "master")
    kubeadm init --token "${TOKEN}" --api-port 443
    ;;
  "node")
    MASTER=$(get_metadata "k8s-master-ip")
    kubeadm join --token "${TOKEN}" "${MASTER}"
    ;;
  *)
    echo invalid phase2 provider.
    exit 1
    ;;
esac
