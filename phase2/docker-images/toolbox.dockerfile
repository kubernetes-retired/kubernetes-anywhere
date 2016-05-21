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

FROM temp/toolbox
LABEL io.k8s/KubernetesAnywhere/role=toolbox
ARG KUBERNETES_RELEASE
ARG DOCKER_RELEASE
ARG COMPOSE_RELEASE
ARG AWSCLI_RELEASE
ARG JQ_RELEASE
ARG EASYRSA_RELEASE
ENV DOCKER_HOST="unix:///docker.sock"
ENV USE_CNI="yes"
ENV FORCE_USERSPACE_PROXY="no"
ENV FORCE_LOCAL_APISERVER="no"
ENV APIPROXY_PORT="8001"
ENV APISERVER_LOCAL_PORT="8080"
ENV APISERVER_LOCAL_BIND="127.0.0.1"
ENV WEAVE_VERSION=1.5.2
ENV SHELL="/bin/bash"
ADD toolbox /etc/toolbox
ADD toolbox-configure.sh /tmp/toolbox-configure.sh
RUN /tmp/toolbox-configure.sh
WORKDIR /etc/toolbox/resources
CMD [ "/bin/bash", "-l" ]
