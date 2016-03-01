FROM centos:7
LABEL works.weave.role=system

ENV DOCKER_HOST=unix:///docker.sock

ENV WD=/etc/resources

ENV KUBE_RELEASE=v1.1.8

RUN yum --assumeyes --quiet install openssl python-setuptools git-core

RUN easy_install awscli

RUN curl --silent --location \
  https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
  --output /usr/bin/jq \
  && chmod +x /usr/bin/jq ;

RUN curl --silent --location \
  https://get.docker.com/builds/Linux/x86_64/docker-1.10.2 \
  --output /usr/bin/docker \
  && chmod +x /usr/bin/docker ;

RUN curl --silent --location \
  https://storage.googleapis.com/kubernetes-release/release/$KUBE_RELEASE/bin/linux/amd64/kubectl \
  --output /usr/bin/kubectl \
  && chmod +x /usr/bin/kubectl ;

RUN curl --silent --location \
  https://github.com/OpenVPN/easy-rsa/releases/download/3.0.1/EasyRSA-3.0.1.tgz \
  | tar xz -C /opt \
  && mv /opt/EasyRSA-3.0.1 /opt/EasyRSA

RUN kubectl config set-cluster default-cluster --server=http://kube-apiserver.weave.local:8080 ; \
   kubectl config set-context default-system --cluster=default-cluster ; \
   kubectl config use-context default-system ;

RUN mkdir $WD ; cd $WD ; \
  resources="{redis-master-controller,redis-master-service,redis-slave-controller,redis-slave-service,frontend-controller,frontend-service}.yaml" ; \
  curl --silent --location \
    "https://raw.github.com/kubernetes/kubernetes/${KUBE_RELEASE}/examples/guestbook/${resources}" \
    --remote-name ; \
  mkdir guestbook-example-LoadBalancer ; \
  cp *.yaml guestbook-example-LoadBalancer ; \
  sed 's/# \(type: LoadBalancer\)/\1/' \
    -i guestbook-example-LoadBalancer/frontend-service.yaml ; \
  mkdir guestbook-example-NodePort ; \
  cp *.yaml guestbook-example-NodePort ; \
  sed 's/# \(type:\) LoadBalancer/\1 NodePort/' \
    -i guestbook-example-NodePort/frontend-service.yaml ; \
  rm -f *.yaml ;

ADD kube-system-namespace.yaml $WD/kube-system-namespace.yaml
ADD skydns-addon $WD/skydns-addon
RUN cp -a $WD/skydns-addon $WD/skydns-addon-secure ; \
  sed 's|\(- -kube_master_url=http://kube-apiserver.weave.local:8080\)$|# \1|' -i $WD/skydns-addon-secure/controller.yaml

RUN curl --silent --location \
  https://github.com/docker/compose/releases/download/1.6.2/docker-compose-Linux-x86_64 \
  --output /usr/bin/compose \
  && chmod +x /usr/bin/compose ;

ADD docker-compose.yml $WD/

ADD setup-kubelet-volumes.sh /usr/bin/setup-kubelet-volumes
ADD setup-secure-cluster-config-volumes.sh /usr/bin/setup-secure-cluster-config-volumes
ADD make-ecr-secure-config-images.sh /usr/bin/make-ecr-secure-config-images
ADD find-ecr-secure-config-images.sh /usr/bin/find-ecr-secure-config-images

ADD find-weave-peers-by-ec2-tag.sh /usr/bin/find-weave-peers-by-ec2-tag
ADD describe-ec2-node.sh /usr/bin/describe-ec2-node
ADD install-simple-systemd-units.sh /usr/bin/install-simple-systemd-units
ADD install-secure-systemd-units.sh /usr/bin/install-secure-systemd-units

ADD systemd-units-common /usr/share/kubernetes-anywhere-systemd-units-common/
ADD systemd-units-simple /usr/share/kubernetes-anywhere-systemd-units-simple/
ADD systemd-units-secure /usr/share/kubernetes-anywhere-systemd-units-secure/

WORKDIR $WD
