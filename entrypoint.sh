#! /bin/bash
set -o errexit
set -o pipefail
set -o nounset

# use a flag to switch between job and interactive modes.
# use a flag to switch between deploy/destroy
# Use IS_JOB=t and DELETE_CLUSTER
#
#If IS_JOB
#	if DELETE_CLUSTER
#		Download files from cloud storage
#		call make destroy
#		if ok, blow files away from cloud storage
#	else
#		Skip the interactive quiz. Generate .config file from ENV vars
#		call make deploy
#		save files needed for destroy in cloud storage.
#		echo vars to stdout needed by job


IS_JOB=${IS_JOB:-}
DELETE_CLUSTER=${DELETE_CLUSTER:-}
if [ -n "$IS_JOB" ];
then

	CLOUD_PROVIDER=${CLOUD_PROVIDER?Error \$CLOUD_PROVIDER is not defined.}

	if [ -n "$DELETE_CLUSTER" ];
	then
		./phase1/${CLOUD_PROVIDER}/cloud_storage.py --download

		FORCE_DESTROY=y make destroy

		./phase1/${CLOUD_PROVIDER}/cloud_storage.py --clean

	else
		./util/env_to_config.py

		make deploy

		echo KUBECONFIG_JSON=`cat phase1/${CLOUD_PROVIDER}/.tmp/kubeconfig.json | jq -c '.'| base64 | tr -d '\n'`

		./phase1/${CLOUD_PROVIDER}/cloud_storage.py --upload

	fi

else

	exec make $@

fi
