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
ENV SHELL="/bin/bash"
ADD toolbox /etc/toolbox
ADD toolbox-configure.sh /tmp/toolbox-configure.sh
RUN /tmp/toolbox-configure.sh
WORKDIR /etc/toolbox/resources
CMD [ "/bin/bash", "-l" ]
