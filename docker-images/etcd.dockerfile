FROM gcr.io/google_containers/etcd:2.2.1
LABEL works.weave.role=system

ENV ETCD_CLUSTER_SIZE="1"

ADD etcd-anywhere.sh /etcd-anywhere
CMD [ "/etcd-anywhere" ]
