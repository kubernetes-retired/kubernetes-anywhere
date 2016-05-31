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

applet="proxy"
config="/srv/kubernetes/kube-${applet}/kubeconfig"
master="kube-apiserver.weave.local"

args=(
  --logtostderr="true"
)

if [ -f $config ]
then
  args+=( --kubeconfig="${config}" )
else
  args+=( --master="http://${master}:8080" )
fi

if ! [ "${USE_CNI}" = "yes" ] || [ "${FORCE_USERSPACE_PROXY}" = "yes" ]
then
  args+=( --proxy-mode="userspace" )
fi

exec /hyperkube ${applet} "${args[@]}"
