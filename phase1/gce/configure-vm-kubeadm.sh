# This is not meant to run on its own, but extends phase1/gce/configure-vm.sh

TOKEN=$(get_metadata "k8s-kubeadm-token")
KUBEADM_VERSION=$(get_metadata "k8s-kubeadm-version")
KUBERNETES_VERSION=$(get_metadata "k8s-kubernetes-version")
KUBELET_VERSION=$(get_metadata "k8s-kubelet-version")
KUBEADM_DIR=/etc/kubeadm
KUBEADM_INIT_PARAM_FILE=$KUBEADM_DIR/kubeadm_init_params.txt

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
    KUBEADM_GS_DIR=${KUBEADM_VERSION%/}
    TMPDIR=/tmp/k8s-debs
    mkdir $TMPDIR
    gsutil cp "${KUBEADM_GS_DIR}/kubeadm" $TMPDIR/kubeadm
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
    PARAMS="--token ${TOKEN} --apiserver-bind-port 443 --apiserver-advertise-address ${ADVERTISE_ADDRESS}"
    OPTS='--skip-preflight-checks'
    if [[ -n "$KUBERNETES_VERSION" ]]; then
      OPTS="${OPTS} --kubernetes-version $KUBERNETES_VERSION"
    fi
    CNI=$(get_metadata "k8s-cni-plugin")
    if [[ "${CNI}" == "flannel" ]]; then
      PARAMS="${PARAMS} --pod-network-cidr 10.244.0.0/16"
    fi
    kubeadm init $PARAMS $OPTS
    mkdir $KUBEADM_DIR
    echo "${PARAMS}" | tee $KUBEADM_INIT_PARAM_FILE
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
