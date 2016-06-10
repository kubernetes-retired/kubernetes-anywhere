# a big docker file meant for depolying min-turnup
FROM ubuntu

RUN apt-get update
RUN apt-get install -y curl vim jq libssl-dev openssl zip make sudo

RUN curl -sSL --fail -o /usr/local/bin/jsonnet \
  "https://storage.googleapis.com/kube-deploy/jsonnet/adf169b1e4a4ba170f58b47111ed88552fae42c8"
RUN chmod +x /usr/local/bin/jsonnet

RUN curl -sSL --fail \
  "https://releases.hashicorp.com/terraform/0.6.16/terraform_0.6.16_linux_amd64.zip" \
  -o /tmp/tf.zip \
  && unzip -d /usr/local/bin /tmp/tf.zip \
  && rm /tmp/tf.zip

WORKDIR /root/min-turnup

CMD bash
