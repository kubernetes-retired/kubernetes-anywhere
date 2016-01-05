#!/bin/bash -x

cd /opt/EasyRSA

set -o errexit
set -o nounset
set -o pipefail

./easyrsa init-pki > /dev/null 2>&1

./easyrsa --batch \
  "--req-cn=kube-apiserver.weave.local@`date +%s`" \
  build-ca nopass > /dev/null 2>&1

./easyrsa \
  "--subject-alt-name=DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,DNS:kubernetes.default.svc.kube.local,DNS:kube-apiserver.weave.local" \
  build-server-full kubernetes-master nopass > /dev/null 2>&1

#./easyrsa build-client-full kubecfg nopass > /dev/null 2>&1
#cp -p pki/issued/kubecfg.crt "${cert_dir}/kubecfg.crt"
#cp -p pki/private/kubecfg.key "${cert_dir}/kubecfg.key"

CA_CERT_BASE64=$(cat "pki/ca.crt" | base64 | tr -d '\r\n')

function generate_token() {
  dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null
}

KUBELET_TOKEN=$(generate_token)
KUBE_PROXY_TOKEN=$(generate_token)
KUBE_USER_TOKEN=$(generate_token)

cat > known_tokens.csv <<EOF
$KUBELET_TOKEN,kubelet,kubelet
$KUBE_PROXY_TOKEN,kube_proxy,kube_proxy
$KUBE_USER_TOKEN,kube_user,kube_user
EOF

service_accounts=("system:scheduler" "system:controller_manager" "system:logging" "system:monitoring" "system:dns")
for account in "${service_accounts[@]}"; do
  token=$(generate_token)
  echo "${token},${account},${account}" >> known_tokens.csv
done

cat > kubelet.conf <<EOF
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    token: ${KUBELET_TOKEN}
clusters:
- name: local
  cluster:
    server: https://kube-apiserver.weavel.local
    certificate-authority-data: ${CA_CERT_BASE64}
contexts:
- context:
    cluster: local
    user: kubelet
  name: service-account-context
current-context: service-account-context
EOF

cat > kube-proxy.conf <<EOF
apiVersion: v1
kind: Config
users:
- name: kube-proxy
  user:
    token: ${KUBE_PROXY_TOKEN}
clusters:
- name: local
  cluster:
    server: https://kube-apiserver.weavel.local
    certificate-authority-data: ${CA_CERT_BASE64}
contexts:
- context:
    cluster: local
    user: kube-proxy
  name: service-account-context
current-context: service-account-context
EOF

vol="/srv/kubernetes"

cat > Dockerfile <<EOF
FROM alpine
VOLUME ${vol}
ADD pki/ca.crt ${vol}/ca.crt
ADD pki/issued/kubernetes-master.crt ${vol}/server.cert
ADD pki/private/kubernetes-master.key ${vol}/server.key
ADD known_tokens.csv ${vol}/known_tokens.csv
ADD kubelet.conf ${vol}/kubelet/kubeconfig
ADD kube-proxy.conf ${vol}/kube-proxy/kubeconfig
ENTRYPOINT [ "/bin/true" ]
EOF

docker build -t weaveworks/kubernetes-anywhere:conf .
