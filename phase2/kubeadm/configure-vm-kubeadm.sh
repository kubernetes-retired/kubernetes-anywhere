
# This is not meant to run on its own, but extends phase1/<CLOUD_PROVIDER>/configure-vm.sh

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

if [[ "$KUBEADM_KUBELET_VERSION" == stable ]]; then
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
  deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
  apt-get update
  # kubeadm is installed with the kubelet so that the
  # kubelet has the configuration at a matching version
  apt-get install -y kubelet kubeadm kubectl kubernetes-cni
elif [[ "$KUBEADM_KUBELET_VERSION" == "gs://"* ]]; then
  TMPDIR=/tmp/k8s-debs
  mkdir $TMPDIR
  gsutil rsync "$KUBEADM_KUBELET_VERSION" $TMPDIR
  # kubeadm is installed with the kubelet so that the
  # kubelet has the configuration at a matching version
  dpkg -i $TMPDIR/{kubelet,kubeadm,kubectl,kubernetes-cni}.deb || echo Ignoring expected dpkg failure
  apt-get install -f -y
  systemctl enable kubelet
  systemctl start kubelet
  rm -rf $TMPDIR
else
  echo "Don't know how to handle kubelet version: $KUBEADM_KUBELET_VERSION"
  exit 1
fi

if [[ "$KUBEADM_VERSION" != "$KUBEADM_KUBELET_VERSION" ]]; then
  if [[ "$KUBEADM_VERSION" == stable ]]; then
    # Cannot install packages as they will update the
    # kubelet configuration to a version that does not match
    # the installed kubelet
    echo "Kubeadm version of 'stable' is not supported with kubelet version that is not also 'stable'."
    exit 1
  elif [[ "$KUBEADM_VERSION" == "gs://"* ]]; then
    KUBEADM_GS_DIR=$(echo $KUBEADM_VERSION | sed 's|/$||')
    TMPDIR=/tmp/k8s-debs
    mkdir $TMPDIR
    gsutil cp "$KUBEADM_GS_DIR/kubeadm" $TMPDIR/kubeadm
    cp $TMPDIR/kubeadm /usr/bin/kubeadm
    rm -rf $TMPDIR
  else
    echo "Don't know how to handle kubeadm version: $KUBEADM_VERSION"
    exit 1
  fi
fi

if [[ "$KUBEADM_ENABLE_CLOUD_PROVIDER" == true ]]; then
  cat <<EOF > /etc/systemd/system/kubelet.service.d/20-cloud-provider.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=$CLOUD_PROVIDER"
EOF

  systemctl daemon-reload
  systemctl restart kubelet
fi
