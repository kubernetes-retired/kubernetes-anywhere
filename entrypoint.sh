#! /bin/bash
set -o errexit
set -o pipefail
set -o nounset

# Flag to kick off automated deploy
IS_JOB=${IS_JOB:-}
if [ -n "$IS_JOB" ];
then
	# automated mode

	CLOUD_PROVIDER=${CLOUD_PROVIDER?Error \$CLOUD_PROVIDER is not defined.}

	if [ -d "/crush" ];
	then
		# Since some needed files are in directories and docker can't mount individaul files, we
		# will copy anything found in /crush to /opt/kubernetes-anywhere
		# This only matters in docker. Kubernetes can mount files in directories.
		# This is also useful if you wish to overwrite certain files without having to create a new image
		cp -vR /crush/* /opt/kubernetes-anywhere/
	fi

	# check for both. It's easy to mess these up.
	DELETE_CLUSTER=${DELETE_CLUSTER:-}
	DESTROY_CLUSTER=${DESTROY_CLUSTER:-}
	if [ -n "$DESTROY_CLUSTER" ] || [ -n "$DELETE_CLUSTER" ];
	then
		# Destroy cluster. We fetch the configs first.
		./util/config-store.sh --download

		FORCE_DESTROY=y make destroy
		# The configs are destroyed with the cluster so no config cleanup is needed

	else
		# Deploy cluster. We build configs from env first.
		./util/env_to_config.py

		make deploy

		# Echo the contents of the kubeconfig.json file to STDOUT. This can be parsed by the job.
		echo KUBECONFIG_JSON=`cat phase1/${CLOUD_PROVIDER}/.tmp/kubeconfig.json | jq -c '.'| base64 | tr -d '\n'`

		# Store the configs in the cluster
		./util/config-store.sh --upload
	fi

else
	# interactive mode
	exec make $@
fi
