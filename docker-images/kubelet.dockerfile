FROM temp/hyperkube

ADD weave-fix-nameserver.sh /fix-nameserver
ADD kubelet-anywhere.sh /kubelet-anywhere

ADD https://storage.googleapis.com/kubernetes-release/network-plugins/cni-09214926.tar.gz /tmp/cni.tgz
RUN mkdir -p /opt/cni && tar xzf /tmp/cni.tgz -C /opt/cni/ && rm -f /tmp/cni.tgz

CMD [ "/kubelet-anywhere" ]
