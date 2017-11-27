
# This is not meant to run on its own, but extends phase2/kubeadm/configure-vm-kubeadm.sh

OPTS=""
if [[ $KUBEADM_VERSION == "stable" ]] || [[ $(semver_compare $KUBEADM_VERSION "v1.8.0") -gt 1 ]]; then
  # `--discovery-token-unsafe-skip-ca-verification` flag is only supported from kubeadm version 1.8.0 onwards
  OPTS="--discovery-token-unsafe-skip-ca-verification"
fi

kubeadm join --token "$KUBEADM_TOKEN" "$KUBEADM_MASTER_IP:443" --skip-preflight-checks $OPTS
