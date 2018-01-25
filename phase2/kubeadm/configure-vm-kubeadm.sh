
# This is not meant to run on its own, but extends phase1/<CLOUD_PROVIDER>/configure-vm.sh

# $1 - VER_A
# $2 - VER_B
# echo 0 - Either VER_A or VER_B does not match the regular expression
# echo 1 - VER_A -lt VER_B
# echo 2 - VER_A -eq VER_B
# echo 3 - VER_A -gt VER_B
semver_compare(){
  local RE='.*v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*).*'

  if [[ "$1" =~ $RE ]] && [[ "$2" =~ $RE ]]; then
    : #$1 & $2 are REs
  else
    echo 0
  fi

  MAJOR_A=$(echo $1 | sed -r -e "s#$RE#\1#")
  MAJOR_B=$(echo $2 | sed -r -e "s#$RE#\1#")
  MINOR_A=$(echo $1 | sed -r -e "s#$RE#\2#")
  MINOR_B=$(echo $2 | sed -r -e "s#$RE#\2#")
  PATCH_A=$(echo $1 | sed -r -e "s#$RE#\3#")
  PATCH_B=$(echo $2 | sed -r -e "s#$RE#\3#")

  if [[ $MAJOR_A -lt $MAJOR_B ]]; then
    echo 1
  elif [[ $MAJOR_A -gt $MAJOR_B ]]; then
    echo 3
  else
    if [[ $MINOR_A -lt $MINOR_B ]]; then
      echo 1
    elif [[ $MINOR_A -gt $MINOR_B ]]; then
      echo 3
    else
      if [[ $PATCH_A -lt $PATCH_B ]]; then
        echo 1
      elif [[ $PATCH_A -gt $PATCH_B ]]; then
        echo 3
      else
        echo 2
      fi
    fi
  fi
}

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
  # TODO: Remove the following mkdir when bazelbuild/bazel
  # issue #4651 gets resolved.
  mkdir -p /opt/cni/bin
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
