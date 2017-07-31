
OPTS=''
if [[ -n "${k8s_kubernetes_version}" ]]; then
  OPTS="--kubernetes-version ${k8s_kubernetes_version}"
fi
kubeadm init --token "${k8s_kubeadm_token}" --apiserver-bind-port 443 --skip-preflight-checks --apiserver-cert-extra-sans="${k8s_advertise_addresses}" $OPTS
