
SHELL=/bin/bash
.SHELLFLAGS=-O extglob -o errexit -o pipefail -o nounset -c

.PHONY: config echo-config

IMAGE_NAME?=kubernetes-anywhere
IMAGE_VERSION?=v0.0.1

# sorry windows and non amd64
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	OS = linux
endif
ifeq ($(UNAME_S),Darwin)
	OS = darwin
endif

CONF_TOOL_VERSION = 4.6
KCONFIG_FILES = $(shell find . -name 'Kconfig')

CONFIG_FILE ?= .config
CONFIG_FILE_ABS := $(abspath $(lastword $(CONFIG_FILE)))
export CONFIG_JSON_FILE := $(CONFIG_FILE_ABS).json
CLOUD_PROVIDER = $(shell jq -r '.phase1.cloud_provider' $(CONFIG_JSON_FILE) 2>/dev/null)
BOOTSTRAP_PROVIDER = $(shell jq -r '.phase2.provider' $(CONFIG_JSON_FILE) 2>/dev/null)
CLUSTER_NAME = $(shell jq -r '.phase1.cluster_name' $(CONFIG_JSON_FILE) 2>/dev/null)
CLUSTER_DIR=clusters/$(CLUSTER_NAME)

default:
	$(MAKE) deploy

config:
	CONFIG_="." kconfig-conf Kconfig

menuconfig:
	CONFIG_="." kconfig-mconf Kconfig

$(CONFIG_FILE_ABS): $(KCONFIG_FILES)
	$(MAKE) config

$(CONFIG_JSON_FILE): $(CONFIG_FILE_ABS)
	util/config_to_json $< > $@

echo-config: $(CONFIG_JSON_FILE)
	cat $<

deploy-cluster destroy-cluster: $(CONFIG_JSON_FILE)
	$(MAKE) do WHAT=$@

upgrade-master: $(CONFIG_JSON_FILE)
	( cd "phase2/$(BOOTSTRAP_PROVIDER)"; ./do $@ )

# For maximum usefulness, use this target with "make -s" to silence any trace output, e.g.:
#   $ export KUBECONFIG=$(make -s kubeconfig-path)
kubeconfig-path: $(CONFIG_JSON_FILE)
	@$(eval KUBECONFIG_PATH := $(shell pwd)/phase1/$(CLOUD_PROVIDER)/$(CLUSTER_DIR)/kubeconfig.json)
	@if [ ! -e "$(KUBECONFIG_PATH)" ]; then \
		echo "Cannot find kubeconfig file. Have you started a cluster with \"make deploy\" yet?" > /dev/stderr; \
		exit 1; \
	fi
	@echo $(KUBECONFIG_PATH)

validate-cluster-up: $(CONFIG_JSON_FILE)
	KUBECONFIG="$$(pwd)/phase1/$(CLOUD_PROVIDER)/$(CLUSTER_DIR)/kubeconfig.json" ./util/validate

validate-node-ready: $(CONFIG_JSON_FILE)
	KUBECONFIG="$$(pwd)/phase1/$(CLOUD_PROVIDER)/$(CLUSTER_DIR)/kubeconfig.json" NODE_READINESS_CHECK=y ./util/validate

addons: $(CONFIG_JSON_FILE)
	KUBECONFIG="$$(pwd)/phase1/$(CLOUD_PROVIDER)/$(CLUSTER_DIR)/kubeconfig.json" ./phase3/do deploy

deploy: | deploy-cluster  validate-cluster-up  addons  validate-node-ready
destroy: | destroy-cluster

do:
	( cd "phase1/$(CLOUD_PROVIDER)"; ./do $(WHAT) )

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) .

docker-dev: docker-build
	$(info Starting Kuberetes Anywhere deployment shell in a container)
	docker run -it --rm --env="PS1=[container]:\w> " --net=host --volume="`pwd`:/opt/kubernetes-anywhere" $(IMAGE_NAME):$(IMAGE_VERSION) /bin/bash

docker-push: docker-build
	docker push $(IMAGE_NAME):$(IMAGE_VERSION)

clean:
	rm -rf phase1/*/clusters/*
	rm -rf phase3/clusters/*

fmt:
	for f in $$(find . -name '*.jsonnet'); do jsonnet fmt -i -n 2 $$(f); done;
	# for f in $$(find . -name '*.json'); do jq -S '.' "$$(f)" | ex -sc "wq!$$(f)" /dev/stdin; done;
