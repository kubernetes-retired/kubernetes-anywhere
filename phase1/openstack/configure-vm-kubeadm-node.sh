
kubeadm join --token "${k8s_kubeadm_token}" "${k8s_master_ip}:443" --skip-preflight-checks
