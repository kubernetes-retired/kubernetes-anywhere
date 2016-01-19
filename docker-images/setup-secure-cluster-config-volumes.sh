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
  "--subject-alt-name=DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,DNS:kubernetes.default.svc.kube.local,DNS:kube-apiserver.weave.local,IP:10.16.0.1" \
  build-server-full kube-apiserver nopass > /dev/null 2>&1

#./easyrsa build-client-full kubecfg nopass > /dev/null 2>&1
#cp -p pki/issued/kubecfg.crt "${cert_dir}/kubecfg.crt"
#cp -p pki/private/kubecfg.key "${cert_dir}/kubecfg.key"

function generate_token() {
  dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null
}

kubectl config --kubeconfig="cluster.conf" set-cluster secure-cluster \
  --server="https://kube-apiserver.weave.local:6443" \
  --certificate-authority="kube-ca.crt"

for user in kubelet proxy controller-manager scheduler admin; do
  cp cluster.conf "${user}.conf"
  token=$(generate_token)
  echo "${token},${user},${user}" >> known_tokens.csv
  kubectl config --kubeconfig="${user}.conf" set-credentials $user --token="${token}"
  kubectl config --kubeconfig="${user}.conf" set-context kubernetes-anywhere --cluster="secure-cluster" --user="${user}"
  kubectl config --kubeconfig="${user}.conf" use-context kubernetes-anywhere
done

vol="/srv/kubernetes"

cat > apiserver-secure-config.dockerfile <<EOF
FROM alpine
VOLUME ${vol}
ADD pki/ca.crt ${vol}/kube-ca.crt
ADD pki/issued/kube-apiserver.crt ${vol}/kube-apiserver.crt
ADD pki/private/kube-apiserver.key ${vol}/kube-apiserver.key
ADD known_tokens.csv ${vol}/known_tokens.csv
ENTRYPOINT [ "/bin/true" ]
EOF

cat > kubelet-secure-config.dockerfile <<EOF
FROM alpine
VOLUME ${vol}/kubelet
ADD pki/ca.crt ${vol}/kubelet/kube-ca.crt
ADD kubelet.conf ${vol}/kubelet/kubeconfig
ENTRYPOINT [ "/bin/true" ]
EOF

cat > proxy-secure-config.dockerfile <<EOF
FROM alpine
VOLUME ${vol}/kube-proxy
ADD pki/ca.crt ${vol}/kube-proxy/kube-ca.crt
ADD proxy.conf ${vol}/kube-proxy/kubeconfig
ENTRYPOINT [ "/bin/true" ]
EOF

cat > controller-manager-secure-config.dockerfile <<EOF
FROM alpine
VOLUME ${vol}/kube-controller-manager
ADD pki/ca.crt ${vol}/kube-controller-manager/kube-ca.crt
ADD pki/private/kube-apiserver.key ${vol}/kube-controller-manager/kube-apiserver.key
ADD controller-manager.conf ${vol}/kube-controller-manager/kubeconfig
ENTRYPOINT [ "/bin/true" ]
EOF

cat > scheduler-secure-config.dockerfile <<EOF
FROM alpine
VOLUME ${vol}/kube-scheduler
ADD pki/ca.crt ${vol}/kube-scheduler/kube-ca.crt
ADD scheduler.conf ${vol}/kube-scheduler/kubeconfig
ENTRYPOINT [ "/bin/true" ]
EOF

cat > tools-secure-config.dockerfile <<EOF
FROM alpine
VOLUME /root/.kube
ADD pki/ca.crt /root/.kube/kube-ca.crt
ADD admin.conf /root/.kube/config
ENTRYPOINT [ "/bin/true" ]
EOF

for i in apiserver kubelet proxy controller-manager scheduler tools
do docker build -t kubernetes-anywhere:${i}-secure-config -f ./${i}-secure-config.dockerfile ./
done
