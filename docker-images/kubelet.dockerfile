FROM temp/hyperkube

ADD weave-fix-nameserver.sh /fix-nameserver
ADD kubelet-anywhere.sh /kubelet-anywhere

#ADD https://storage.googleapis.com/kubernetes-anywhere/cni-v0.1.0-111-gd190448.tar.gz /tmp/cni.tgz
#RUN mkdir -p /opt/cni/bin && tar xzf /tmp/cni.tgz -C /opt/cni/ && rm -f /tmp/cni.tgz

ADD https://get.docker.com/builds/Linux/x86_64/docker-1.10.3 /usr/bin/docker
RUN chmod +x /usr/bin/docker

ADD kubelet-cni/bin /opt/cni/bin
ADD kubelet-cni/net.d /etc/cni/net.d

ENV WEAVE_VERSION=git-c09dfe6b5ad8
#ENV WEAVE_DEBUG=1
ENV DOCKER_HOST=unix:///docker.sock

CMD [ "/kubelet-anywhere" ]
