# This is not meant to run on its own, but extends phase1/gce/configure-vm.sh

TOKEN=$(get_metadata "k8s-kubeadm-token")
KUBEADM_VERSION=$(get_metadata "k8s-kubeadm-version")
KUBERNETES_VERSION=$(get_metadata "k8s-kubernetes-version")
KUBELET_VERSION=$(get_metadata "k8s-kubelet-version")
KUBEADM_DIR=/etc/kubeadm
KUBEADM_CONFIG_FILE=$KUBEADM_DIR/kubeadm.yaml

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

if [[ "${KUBELET_VERSION}" == stable ]]; then
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
  deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
  apt-get update
  # kubeadm is installed with the kubelet so that the 
  # kubelet has the configuration at a matching version
  apt-get install -y kubelet kubeadm kubectl kubernetes-cni
elif [[ "${KUBELET_VERSION}" == "gs://"* ]]; then
  TMPDIR=/tmp/k8s-debs
  mkdir $TMPDIR
  gsutil rsync "${KUBELET_VERSION}" $TMPDIR
  # kubeadm is installed with the kubelet so that the 
  # kubelet has the configuration at a matching version
  dpkg -i $TMPDIR/{kubelet,kubeadm,kubectl,kubernetes-cni}.deb || echo Ignoring expected dpkg failure
  apt-get install -f -y
  systemctl enable kubelet
  systemctl start kubelet
  rm -rf $TMPDIR
else
  echo "Don't know how to handle kubelet version: $KUBELET_VERSION"
  exit 1
fi

if [[ "${KUBEADM_VERSION}" != "${KUBELET_VERSION}" ]]; then
  if [[ "${KUBEADM_VERSION}" == stable ]]; then
    # Cannot install packages as they will update the 
    # kubelet configuration to a version that does not match
    # the installed kubelet
    echo "Kubeadm version of 'stable' is not supported with kubelet version that is not also 'stable'."
    exit 1
  elif [[ "${KUBEADM_VERSION}" == "gs://"* ]]; then
    KUBEADM_DIR=${KUBEADM_VERSION%/}
    TMPDIR=/tmp/k8s-debs
    mkdir $TMPDIR
    gsutil cp "${KUBEADM_DIR}/kubeadm" $TMPDIR/kubeadm
    cp $TMPDIR/kubeadm /usr/bin/kubeadm
    rm -rf $TMPDIR
  else
    echo "Don't know how to handle kubeadm version: $KUBEADM_VERSION"
    exit 1
  fi
fi

case "${ROLE}" in
  "master")
    ADVERTISE_ADDRESS=$(get_metadata "k8s-advertise-addresses")
    CNI=$(get_metadata "k8s-cni-plugin")
    #TODO: we should probably be able to configure POD_NETWORK_CIDR from `make config` in future
    # and use the configured value by passing it on to CNI's. We resort to the below hard-coding
    # since the current CNI's are not enabled to be configured with the user provided pod-network-cidr.
    POD_NETWORK_CIDR=""
    if [[ "${CNI}" == "flannel" ]]; then
      POD_NETWORK_CIDR="10.244.0.0/16"
    elif [[ "${CNI}" == "weave" ]]; then
      POD_NETWORK_CIDR="10.32.0.0/12"
    fi

    mkdir -p $KUBEADM_DIR
    cat <<EOF |tee $KUBEADM_CONFIG_FILE
kind: MasterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha1
api:
  advertiseAddress: "${ADVERTISE_ADDRESS}"
  bindPort: 443
networking:
  podSubnet: "${POD_NETWORK_CIDR}"
kubernetesVersion: "${KUBERNETES_VERSION}"
token: "${TOKEN}"
EOF

    kubeadm init --skip-preflight-checks --config $KUBEADM_CONFIG_FILE
    ;;
  "node")
    MASTER=$(get_metadata "k8s-master-ip")
    kubeadm join --token "${TOKEN}" "${MASTER}:443" --skip-preflight-checks
    ;;
  *)
    echo invalid phase2 provider.
    exit 1
    ;;
esac
