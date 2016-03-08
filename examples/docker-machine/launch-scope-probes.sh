#!/bin/bash -ex
[ $# -eq 1 ] || ( echo "$0 <WEAVE_SCOPE_SERVICE_TOKEN>" ; exit 1 )
## Launch Scope probe in head nodes to monitor master and etcd (`kube-{1,2,3,4}`)
for m in 'kube-1' 'kube-2' 'kube-3' 'kube-4' ; do
  docker $(docker-machine config ${m}) run --detach \
    --name="weavescope" \
    --privileged="true" --net="host" --pid="host" \
    --volume="/var/run/docker.sock:/var/run/docker.sock" \
      weaveworks/scope:0.13.1 \
        --no-app --probe.docker="true" --probe.docker.bridge="docker0" \
        --service-token="${1}"
done
## And Scope addon
curl --silent --location https://gist.github.com/errordeveloper/3f13301adb276e26bfee/raw/scope-ds.yaml \
  | sed "s/%%WEAVE_SCOPE_SERVICE_TOKEN%%/${1}/" \
  | docker-machine ssh 'kube-4' docker --host="unix:///var/run/weave/weave.sock" run \
      --volumes-from="kube-tools-secure-config" \
      --interactive \
        weaveworks/kubernetes-anywhere:tools \
          kubectl create --validate="false" -f -
