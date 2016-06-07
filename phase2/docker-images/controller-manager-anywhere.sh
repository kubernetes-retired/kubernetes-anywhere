#!/bin/bash -x

# Copyright 2016 The Kubernetes Authors All rights reserved.
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

applet="controller-manager"
config="/srv/kubernetes/kube-${applet}"
master="kube-apiserver.weave.local"

weave_ip=$(hostname -i)

args=(
  --address="${weave_ip}"
  --cloud-provider="${CLOUD_PROVIDER}"
  --logtostderr="true"
)

if [ -d $config ]
then
  args+=(
    --kubeconfig="${config}/kubeconfig"
    --service-account-private-key-file="${config}/kube-apiserver.key"
    --root-ca-file="${config}/kube-ca.crt"
  )
else
  args+=( --master="http://${master}:8080" )
fi

exec /hyperkube ${applet} "${args[@]}"
