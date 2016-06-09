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

FROM temp/hyperkube
LABEL io.k8s/KubernetesAnywhere/role=kubelet

ADD weave-fix-nameserver.sh /fix-nameserver
ADD kubelet-anywhere.sh /kubelet-anywhere

#ADD https://storage.googleapis.com/kubernetes-anywhere/cni-v0.1.0-111-gd190448.tar.gz /tmp/cni.tgz
#RUN mkdir -p /opt/cni/bin && tar xzf /tmp/cni.tgz -C /opt/cni/ && rm -f /tmp/cni.tgz

ADD https://get.docker.com/builds/Linux/x86_64/docker-1.10.3 /usr/bin/docker
RUN chmod +x /usr/bin/docker

ADD kubelet-cni/bin /opt/cni/bin
ADD kubelet-cni/net.d /etc/cni/net.d

ENV USE_CNI="yes"
ENV DOCKER_HOST="unix:///docker.sock"
ENV WEAVE_VERSION=1.5.2 WEAVE_VERSION_DEFAULT=1.5.2

CMD [ "/kubelet-anywhere" ]
