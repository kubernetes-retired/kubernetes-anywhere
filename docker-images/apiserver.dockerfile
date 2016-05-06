FROM temp/hyperkube
LABEL io.k8s/KubernetesAnywhere/role=apiserver

ENV ETCD_CLUSTER_SIZE="1"
ENV APISERVER_LOCAL_PORT="8080"
ENV FORCE_LOCAL_APISERVER="no"

ADD apiserver-anywhere.sh /apiserver-anywhere
CMD [ "/apiserver-anywhere" ]
