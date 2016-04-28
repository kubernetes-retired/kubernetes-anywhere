FROM temp/hyperkube
LABEL io.k8s/KubernetesAnywhere/role=apiserver

ENV ETCD_CLUSTER_SIZE="1"

ADD apiserver-anywhere.sh /apiserver-anywhere
CMD [ "/apiserver-anywhere" ]
