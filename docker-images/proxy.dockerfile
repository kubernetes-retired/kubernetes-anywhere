FROM temp/hyperkube
LABEL io.k8s/KubernetesAnywhere/role=proxy

ADD weave-fix-nameserver.sh /fix-nameserver
ADD proxy-anywhere.sh /proxy-anywhere

ENV USE_CNI=yes

CMD [ "/proxy-anywhere" ]
