#FROM alpine
FROM mhart/alpine-node:6.4.0

RUN apk add --update bash
ADD ./util/docker-build.sh /opt/
RUN /opt/docker-build.sh

WORKDIR /opt/kubernetes-anywhere
ADD . /opt/kubernetes-anywhere/
CMD make
