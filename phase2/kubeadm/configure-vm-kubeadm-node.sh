
# This is not meant to run on its own, but extends phase2/kubeadm/configure-vm-kubeadm.sh

kubeadm join --token "$KUBEADM_TOKEN" "$KUBEADM_MASTER_IP:443" --skip-preflight-checks
