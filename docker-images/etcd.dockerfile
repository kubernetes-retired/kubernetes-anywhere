FROM temp/etcd
LABEL io.k8s/KubernetesAnywhere/role=etc

ENV ETCD_CLUSTER_SIZE="1"

ADD etcd-anywhere.sh /etcd-anywhere
CMD [ "/etcd-anywhere" ]
