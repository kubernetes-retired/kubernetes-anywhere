FROM temp/hyperkube

ENV ETCD_CLUSTER_SIZE="1"

ADD apiserver-anywhere.sh /apiserver-anywhere
CMD [ "/apiserver-anywhere" ]
