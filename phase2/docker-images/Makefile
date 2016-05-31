.PHONY: lint build test push

lint:
	@shellcheck -x -s bash \
	  ./build \
	  ./push \
	  ./push-only-latest-tag \
	  ./build-and-push \
	  ./test-single-node \
	  ./toolbox-configure.sh \
	  ./toolbox/scripts/* \
	  ./apiserver-anywhere.sh \
	  ./controller-manager-anywhere.sh \
	  ./kubelet-anywhere.sh \
	  ./proxy-anywhere.sh \
	  ./scheduler-anywhere.sh \
	  ./kubelet-cni/bin/weave-net \
	  ./kubelet-cni/bin/weave-ipam
	@shellcheck -x -s sh \
	  ./etcd-anywhere.sh \
	  ./weave-fix-nameserver.sh
build:
	./$@ $(KUBERNETES_RELEASE)

test:
	./test-local-docker

push:
	./$@ $(KUBERNETES_RELEASE)
