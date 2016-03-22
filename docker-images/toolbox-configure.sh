#!/bin/bash -ex

set -o errexit
set -o nounset
set -o pipefail

## install all the tools we need

ln -s /etc/toolbox/scripts/* /usr/bin/

yum --assumeyes --quiet install openssl python-setuptools git-core

easy_install awscli

curl="curl --silent --location"

$curl "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/amd64/kubectl" \
  --output /usr/bin/kubectl

$curl "https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_RELEASE}" \
  --output /usr/bin/docker

$curl "https://github.com/docker/compose/releases/download/${COMPOSE_RELEASE}/docker-compose-Linux-x86_64" \
  --output /usr/bin/compose \

$curl "https://github.com/stedolan/jq/releases/download/jq-${JQ_RELEASE}/jq-linux64" \
  --output /usr/bin/jq

chmod +x /usr/bin/kubectl /usr/bin/docker /usr/bin/compose /usr/bin/jq

$curl "https://github.com/OpenVPN/easy-rsa/releases/download/${EASYRSA_RELEASE}/EasyRSA-${EASYRSA_RELEASE}.tgz" \
  | tar xz -C /opt

mv "/opt/EasyRSA-${EASYRSA_RELEASE}" "/opt/EasyRSA"

## create default kubeconfig

kubectl config set-cluster default-cluster --server=http://kube-apiserver.weave.local:8080
kubectl config set-context default-system --cluster=default-cluster
kubectl config use-context default-system

## the rest of configuration concerns resource files

cd /etc/toolbox/resources

## fetch released copy of guestbook example released

resources="{redis-master-controller,redis-master-service,redis-slave-controller,redis-slave-service,frontend-controller,frontend-service}.yaml"

$curl "https://raw.github.com/kubernetes/kubernetes/${KUBERNETES_RELEASE}/examples/guestbook/${resources}" \
    --remote-name

## create two setparate copies for each of the service types

mkdir guestbook-example-LoadBalancer
cp redis-*.yaml frontend-*.yaml guestbook-example-LoadBalancer
sed 's|# \(type: LoadBalancer\)|\1|' \
  -i guestbook-example-LoadBalancer/frontend-service.yaml

mkdir guestbook-example-NodePort
cp redis-*.yaml frontend-*.yaml guestbook-example-NodePort
sed 's|# \(type:\) LoadBalancer|\1 NodePort|' \
  -i guestbook-example-NodePort/frontend-service.yaml

## remove files we have downloaded originally

rm -f redis-*.yaml frontend-*.yaml

## create a modified copy of skydns addon and remove master url arg

cp -a skydns-addon skydns-addon-secure
sed 's|\(- -kube_master_url=http://kube-apiserver.weave.local:8080\)$|# \1|' \
  -i skydns-addon-secure/controller.yaml
cp -a skydns-addon-v1.2 skydns-addon-secure-v1.2
sed 's|\(- --kube_master_url=http://kube-apiserver.weave.local:8080\)$|# \1|' \
  -i skydns-addon-secure-v1.2/controller.yaml
