FROM temp/hyperkube

ADD weave-fix-nameserver.sh /fix-nameserver
ADD kubelet-anywhere.sh /kubelet-anywhere

ADD https://storage.googleapis.com/kubernetes-release/network-plugins/cni-09214926.tar.gz /tmp/cni.tgz
ADD https://raw.githubusercontent.com/weaveworks/weave/issues/1992-cni-plugin/weave /usr/bin/weave
ADD https://get.docker.com/builds/Linux/x86_64/docker-1.10.3 /usr/bin/docker

RUN mkdir -p /opt/cni/bin && tar xzf /tmp/cni.tgz -C /opt/cni/ && rm -f /tmp/cni.tgz && chmod +x /usr/bin/weave && ln -s /usr/bin/weave /opt/cni/bin/weave-net && ln -s /usr/bin/weave /opt/cni/bin/weave-ipam && mkdir -p /etc/cni/net.d && echo '{ "name": "weave", "type": "weave-net" }' > /etc/cni/net.d/10-weave.conf && chmod +x /usr/bin/docker

ENV WEAVE_VERSION=git-f18f10bac090

CMD [ "/kubelet-anywhere" ]
