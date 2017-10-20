
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

mkdir -p /var/lib/kubelet

if [[ "${k8s_kubeadm_version}" == stable ]]; then
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
  deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

  apt-get update
  apt-get install -y kubelet kubeadm kubectl kubernetes-cni
elif [[ "${k8s_kubeadm_version}" == "gs://"* ]]; then
  TMPDIR=/tmp/k8s-debs
  mkdir $TMPDIR
  apt-get install -y python
  cd $TMPDIR
  wget https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz
  tar xzf google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh \
    --disable-installation-options \
    --bash-completion=false \
    --path-update=false \
    --usage-reporting=false && \
  ./google-cloud-sdk/bin/gsutil rsync "${k8s_kubeadm_version}" $TMPDIR
  cd -
  dpkg -i $TMPDIR/{kubelet,kubeadm,kubectl,kubernetes-cni}.deb || echo Ignoring expected dpkg failure
  apt-get install -f -y
  systemctl enable kubelet
  systemctl start kubelet
  rm -rf $TMPDIR
else
  echo "Don't know how to handle version: ${k8s_kubeadm_version}"
  exit 1
fi
