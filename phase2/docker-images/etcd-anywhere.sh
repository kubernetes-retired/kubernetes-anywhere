#!/bin/sh -x

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

ETCD_INITIAL_CLUSTER=$(seq -s , 1 "${ETCD_CLUSTER_SIZE}" | sed 's|\([1-9]*\)|etcd\1=http://etcd\1:2380|g')

export ETCD_INITIAL_CLUSTER

n="$(hostname -s)" c="http://${n}:2379" p="http://${n}:2380"

exec etcd --name="${n}" \
  --listen-peer-urls="${p}" \
  --initial-advertise-peer-urls="${p}" \
  --listen-client-urls="${c}" \
  --advertise-client-urls="${c}"
