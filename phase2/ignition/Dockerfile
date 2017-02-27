FROM alpine

RUN apk --update add openssl ca-certificates

RUN wget https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/ignition \
  -O /bin/ignition \
  && chmod +x /bin/ignition

RUN wget https://storage.googleapis.com/public-mikedanese-k8s/k8s/jsonnet \
  -O /bin/jsonnet \
  && chmod +x /bin/jsonnet

ADD do_role /bin/do_role
ADD vanilla /opt/kubernetes-anywhere

CMD /bin/do_role
