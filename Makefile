
SHELL=/bin/bash
.SHELLFLAGS="-O" "extglob" "-o" "errexit" "-o" "pipefail" "-o" "nounset" "-c"

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

default:
	$(MAKE) deploy

config:
	CONFIG_="." kconfig-conf Kconfig

menuconfig:
	CONFIG_="." kconfig-mconf Kconfig

.config: $(KCONFIG_FILES)
	$(MAKE) config

.config.json: .config
	util/config_to_json $< > $@

echo-config: .config.json
	cat $<

deploy-cluster destroy-cluster: .config.json
	$(MAKE) do WHAT=$@

# For maximum usefulness, use this target with "make -s" to silence any trace output, e.g.:
#   $ export KUBECONFIG=$(make -s kubeconfig-path)
kubeconfig-path: .config.json
	@$(eval KUBECONFIG_PATH := $(shell pwd)/phase1/$(shell jq -r '.phase1.cloud_provider' .config.json)/.tmp/kubeconfig.json)
	@if [ ! -e "$(KUBECONFIG_PATH)" ]; then \
		echo "Cannot find kubeconfig file. Have you started a cluster with \"make deploy\" yet?" > /dev/stderr; \
		exit 1; \
	fi
	@echo $(KUBECONFIG_PATH)

validate: .config.json
	KUBECONFIG="$$(pwd)/phase1/$$(jq -r '.phase1.cloud_provider' .config.json)/.tmp/kubeconfig.json" ./util/validate

addons: .config.json
	KUBECONFIG="$$(pwd)/phase1/$$(jq -r '.phase1.cloud_provider' .config.json)/.tmp/kubeconfig.json" ./phase3/do deploy

deploy: | deploy-cluster validate addons
destroy: | destroy-cluster

do:
	( cd "phase1/$$(jq -r '.phase1.cloud_provider' .config.json)"; ./do $(WHAT) )

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) .

docker-dev: docker-build
	${info Starting Kuberetes Anywhere deployment shell in a container}
	docker run -it --rm --env="PS1=[container]:\w> " --net=host --volume="`pwd`:/opt/kubernetes-anywhere" $(IMAGE_NAME):$(IMAGE_VERSION) /bin/bash

docker-push: docker-build
	docker push $(IMAGE_NAME):$(IMAGE_VERSION)

clean:
	rm -rf .tmp
	rm -rf phase3/.tmp
	rm -rf phase1/gce/.tmp
	rm -rf phase1/azure/.tmp

fmt:
	for f in $$(find . -name '*.jsonnet'); do jsonnet fmt -i -n 2 $${f}; done;
	# for f in $$(find . -name '*.json'); do jq -S '.' "$${f}" | ex -sc "wq!$${f}" /dev/stdin; done;
