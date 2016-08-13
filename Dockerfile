FROM ubuntu

# Install basics
RUN apt-get update && apt-get -y upgrade \
    && apt-get install -y git curl vim jq libssl-dev openssl zip make sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
ENV TERRAFORM_VERSION 0.7.0-rc1
RUN curl -sSL --fail \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    -o /tmp/tf.zip \
    && unzip -d /usr/local/bin /tmp/tf.zip \
    && rm /tmp/tf.zip

# Azure - Required dependencies 
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y nodejs npm && \
    rm -rf /var/lib/apt/lists/*
RUN npm install -g azure-cli

# Install Jsonnet
# ENV JSONNET_GIT_TAG v0.8.8
#     (too old - std.manifestJson is missing)
ENV JSONNET_GIT_TAG master
RUN cd /tmp \
    && git clone https://github.com/google/jsonnet \
    && cd jsonnet \
    && git checkout ${JSONNET_GIT_TAG} \
    && make \
    && cp jsonnet /usr/bin/jsonnet

ENV KUBECTL_VERSION "v1.3.0"
RUN curl -sSL --fail \
    "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        >/usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

WORKDIR /root/kubernetes-anywhere

ADD . /root/kubernetes-anywhere/

CMD make
