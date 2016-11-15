# This is not meant to run on its own, but extends phase1/gce/configure-vm.sh

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
    get_metadata "k8s-master-kubeconfig" \
      > /srv/kubernetes/kubeconfig.json
    ;;
  "node")
    get_metadata "k8s-node-kubeconfig" \
      > /srv/kubernetes/kubeconfig.json
    ;;
  *)
    echo "'${ROLE}' is not a valid role"
    exit 1
    ;;
esac

docker run \
  --net=host \
  -v /:/mnt/root \
  -v /run:/run \
  -v /etc/kubernetes:/etc/kubernetes \
  -v /var/lib/ignition:/usr/share/oem \
  gcr.io/mikedanese-k8s/ignite:v3

systemctl enable kubelet
systemctl start kubelet
