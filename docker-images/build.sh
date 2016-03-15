#!/bin/sh -x

set -o errexit
set -o nounset
set -o pipefail

git_repo="https://github.com/weaveworks/weave-kubernetes-anywhere"
git_rev=$(git rev-parse @)

kubernetes_release=${1:-"v1.1.8"}

toolbox_docker_release="1.10.3"
toolbox_compose_release="1.6.2"
toolbox_jq_release="1.5"
toolbox_easyrsa_release="3.0.1"

image_prefix=${2:-"weaveworks/kubernetes-anywhere:"}

common_labels="
LABEL io.k8s.release=${kubernetes_release}
LABEL works.weave.role=system
LABEL com.git-scm.repo=${git_repo}
LABEL com.git-scm.rev=${git_rev}
"

echo "
FROM gcr.io/google_containers/hyperkube:${kubernetes_release}
ENV KUBERNETES_RELEASE=${kubernetes_release}
${common_labels}
" | docker build --tag="temp/hyperkube" -

for i in kubelet proxy apiserver controller-manager scheduler ; do
  docker build \
    --tag="${image_prefix}${i}-${kubernetes_release}" \
    --file="./${i}.dockerfile" ./
done

echo "FROM gcr.io/google_containers/etcd:2.2.1\n${common_labels}" \
  | docker build --tag="temp/etcd" -

docker build \
  --tag="${image_prefix}etcd-${kubernetes_release}" \
  --file="./etcd.dockerfile" ./

echo "
FROM centos:7
ENV KUBERNETES_ANYWHERE_TOOLBOX_IMAGE=${image_prefix}toolbox-${kubernetes_release}
${common_labels}
" | docker build --tag="temp/toolbox" -

docker build \
  --tag="${image_prefix}toolbox-${kubernetes_release}" \
  --build-arg="KUBERNETES_RELEASE=${kubernetes_release}" \
  --build-arg="DOCKER_RELEASE=${toolbox_docker_release}" \
  --build-arg="COMPOSE_RELEASE=${toolbox_compose_release}" \
  --build-arg="JQ_RELEASE=${toolbox_jq_release}" \
  --build-arg="EASYRSA_RELEASE=${toolbox_easyrsa_release}" \
  --file="./toolbox.dockerfile" ./
