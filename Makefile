
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
	$(MAKE) config

.tmp/conf .tmp/mconf:
	mkdir -p $(dir $@)
	curl -sSL --fail -o "$@" "https://storage.googleapis.com/public-mikedanese-k8s/kconfig/$(CONF_TOOL_VERSION)/$(OS)/$(shell basename $@)"
	chmod +x "$@"

config: .tmp/conf
	CONFIG_="" .tmp/conf Kconfig

menuconfig: .tmp/mconf
	CONFIG_="" .tmp/mconf Kconfig

.config: .tmp/conf $(KCONFIG_FILES)
	$(MAKE) config

.config.json: .config
	util/config_to_json $< > $@

echo-config: .config.json
	cat $<

deploy destroy: .config.json
	$(MAKE) do WHAT=$@

do:
	( cd "phase1/$$(jq -r '.phase1.cloud_provider' .config.json)"; ./do $(WHAT) )

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) .

docker-run: docker-build
	docker run -it --net=host $(IMAGE_NAME):$(IMAGE_VERSION) /bin/bash

docker-dev: docker-build
	docker run -it --net=host -v `pwd`:/root/kubernetes-anywhere $(IMAGE_NAME):$(IMAGE_VERSION) /bin/bash


clean:
	rm -rf .tmp
	rm -rf phase3/.tmp
	rm -rf phase1/gce/.tmp
	rm -rf phase1/azure/.tmp

fmt:
	for f in $$(find . -name '*.jsonnet'); do jsonnet fmt -i -n 2 $${f}; done;
	# for f in $$(find . -name '*.json'); do jq -S '.' "$${f}" | ex -sc "wq!$${f}" /dev/stdin; done;
