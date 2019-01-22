#FROM alpine
FROM mhart/alpine-node:6.4.0

RUN apk add --update bash
ADD ./util/docker-build.sh /opt/
RUN /opt/docker-build.sh
ADD ./util/setup-terraform-jsonnet-kubectl.sh /opt/
RUN /opt/setup-terraform-jsonnet-kubectl.sh

WORKDIR /opt/kubernetes-anywhere
ADD . /opt/kubernetes-anywhere/
CMD make
