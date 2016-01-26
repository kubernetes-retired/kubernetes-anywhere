FROM gcr.io/google_containers/hyperkube:v1.1.4
LABEL works.weave.role=system

ENV ETCD_CLUSTER_SIZE="1"

ADD apiserver-anywhere.sh /apiserver-anywhere
CMD [ "/apiserver-anywhere" ]
