FROM temp/etcd

ENV ETCD_CLUSTER_SIZE="1"

ADD etcd-anywhere.sh /etcd-anywhere
CMD [ "/etcd-anywhere" ]
