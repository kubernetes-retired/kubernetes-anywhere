#!/bin/sh -x

git_repo="https://github.com/weaveworks/weave-kubernetes-anywhere"
git_rev=$(git rev-parse @)

kubernetes_release=${1:-"v1.1.8"}

image_prefix=${2:-"weaveworks/kubernetes-anywhere:"}

echo "
FROM gcr.io/google_containers/hyperkube:${kubernetes_release}
LABEL io.k8s.release=${kubernetes_release}
LABEL works.weave.role=system
LABEL com.git-scm.repo=${git_repo}
LABEL com.git-scm.rev=${git_rev}
ENV KUBERNETES_RELEASE=${kubernetes_release}
" | docker build --tag temp/hyperkube -

for i in kubelet proxy apiserver controller-manager scheduler ; do
  docker build \
    --tag="${image_prefix}${i}-${kubernetes_release}" \
    --file="./${i}.dockerfile" ./
done

echo "
FROM gcr.io/google_containers/etcd:2.2.1
LABEL io.k8s.release=${kubernetes_release}
LABEL works.weave.role=system
LABEL com.git-scm.repo=${git_repo}
LABEL com.git-scm.rev=${git_rev}
" | docker build --tag temp/etcd -

docker build \
  --tag="${image_prefix}etcd-${kubernetes_release}" \
  --file="./etcd.dockerfile" ./

echo "
FROM centos:7
LABEL io.k8s.release=${kubernetes_release}
LABEL works.weave.role=system
LABEL com.git-scm.repo=${git_repo}
LABEL com.git-scm.rev=${git_rev}
" | docker build --tag temp/tools -

docker build \
  --tag="${image_prefix}tools-${kubernetes_release}" \
  --build-arg="kubernetes_release=${kubernetes_release}" \
  --file="./tools.dockerfile" ./
