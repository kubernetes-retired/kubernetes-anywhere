#! /bin/bash
set -o errexit
set -o pipefail
set -o nounset

# If CLOUD_PROVIDER is set in env, we run from env vars.
CLOUD_PROVIDER=${CLOUD_PROVIDER:-}
FORCE_DESTROY=${FORCE_DESTROY:-}
if [ -n "$CLOUD_PROVIDER" ];
then
	./util/env_to_config.py

	if [ -n "$FORCE_DESTROY" ];
	then
		# This will expect kubeconfig.json to exist
		make destroy
	else
		make deploy
		# Echo KUBECONFIG_JSON and KUBEADM_TOKEN to stdout so job can parse them.
		tmp_dir="phase1/${CLOUD_PROVIDER}/.tmp"
		echo KUBECONFIG_JSON=`cat ${tmp_dir}/kubeconfig.json | jq -c '.'| base64 | tr -d '\n'`
		echo KUBEADM_TOKEN=`awk '{gsub("\"",""); print $3}' ${tmp_dir}/terraform.tfvars | base64 | tr -d '\n'`
	fi

else
	exec make $@
fi
