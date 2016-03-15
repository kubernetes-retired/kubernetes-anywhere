#!/bin/bash -ex

source weave_password
export WEAVE_PASSWORD

known_peers=$(docker-machine ip $(seq -f 'kube-%g' 1 5) | xargs)

install_weave=" \
  sudo curl --silent --location http://git.io/weave --output /usr/local/bin/weave ; \
  sudo chmod +x /usr/local/bin/weave ; \
  env WEAVE_PASSWORD=${WEAVE_PASSWORD} weave launch ${known_peers}
"

docker-machine create -d vmwarefusion kube-local

docker-machine ssh kube-local "${install_weave}"

dkr="docker $(docker-machine config 'kube-local')"

$dkr pull weaveworks/kubernetes-anywhere:tools

docker $(docker-machine config 'kube-4') save kubernetes-anywhere:tools-secure-config | $dkr load
