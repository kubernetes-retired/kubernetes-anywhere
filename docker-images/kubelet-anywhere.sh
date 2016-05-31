#!/bin/bash -x

# Copyright 2015-2016 Weaveworks Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

/fix-nameserver

## This already done from `setup-kubelet-volumes`, but it has to be done on restart also
## it's somewhat odd that Docker doesn't fail to start it though, like it does initially.
## This is best to be handled by `setup-kubelet-volumes` in systemd
nsenter --mount=/proc/1/ns/mnt -- mount --make-rshared /

config="/srv/kubernetes/kubelet/kubeconfig"
master="kube-apiserver.weave.local"

args=(
  --cluster-dns="10.16.0.3"
  --cluster-domain="cluster.local"
  --cloud-provider="${CLOUD_PROVIDER}"
  --allow-privileged="true"
  --logtostderr="true"
)

if [ -f $config ]
then
  args+=(
    --kubeconfig="${config}"
    --api-servers="https://${master}:6443"
  )
else
  args+=( --api-servers="http://${master}:8080" )
fi

if [ "${CLOUD_PROVIDER}" = "aws" ]
then ## TODO: check if not needed with v1.2.0 is out (see kubernetes/kubernetes#11543)
  args+=(
    --hostname-override="${AWS_LOCAL_HOSTNAME}"
  )
fi

case "${KUBERNETES_RELEASE}" in
  v1.1.*)
    args+=(
      --docker-endpoint="unix:/docker.sock"
      --resolv-conf="/dev/null"
    )
    ;;
  v1.2.*)
    args+=( --docker-endpoint="unix:///docker.sock" )
    if [ "${USE_CNI}" = "yes" ]
    then
      args+=(
        --network-plugin="cni"
        --network-plugin-dir="/etc/cni/net.d"
      )
    else
      args+=( --resolv-conf="/dev/null" )
    fi
    ;;
esac

exec /hyperkube kubelet "${args[@]}"
