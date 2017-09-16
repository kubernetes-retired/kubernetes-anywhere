# This is not meant to run on its own, but extends phase1/gce/configure-vm.sh

TOKEN=$(get_metadata "k8s-kubeadm-token")
KUBEADM_VERSION=$(get_metadata "k8s-kubeadm-version")
KUBERNETES_VERSION=$(get_metadata "k8s-kubernetes-version")
KUBELET_VERSION=$(get_metadata "k8s-kubelet-version")
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
    TMPDIR=/tmp/k8s-debs
    mkdir $TMPDIR
    gsutil cp "${KUBEADM_VERSION}/kubeadm" $TMPDIR/kubeadm
    cp $TMPDIR/kubeadm /usr/bin/kubeadm
    rm -rf $TMPDIR
  else
    echo "Don't know how to handle kubeadm version: $KUBEADM_VERSION"
    exit 1
  fi
fi

case "${ROLE}" in
  "master")
    OPTS=''
    if [[ -n "$KUBERNETES_VERSION" ]]; then
      OPTS="--kubernetes-version $KUBERNETES_VERSION"
    fi
    kubeadm init --token "${TOKEN}" --apiserver-bind-port 443 --skip-preflight-checks --apiserver-advertise-address "$(get_metadata "k8s-advertise-addresses")" $OPTS
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
