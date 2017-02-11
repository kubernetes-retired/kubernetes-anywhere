#! /bin/bash

# tar.gz the config files. Store them as a kubernetes secret in namespace kube-system

set -o errexit
set -o pipefail
set -o nounset

CLOUD_PROVIDER=${CLOUD_PROVIDER?ENV var CLOUD_PROVIDER is required}
KCTL="kubectl --kubeconfig=./phase1/${CLOUD_PROVIDER}/.tmp/kubeconfig.json --namespace=kube-system"

usage() {
  cat <<EOF >&2
$0: [--upload|--download]
EOF
exit 1
}

if [[ "$#" != 1 ]]; then
  usage
fi

upload() {
	echo 'packaging and uploading configs'

	find . \( -iname ".config*" -or -iname "terraform.tfstate*" -or -regex "\./phase1/.*/\.tmp" \) -print0 | \
		xargs -0 tar -zcvf configs.tar.gz

	${KCTL} create secret generic k8-anywhere-configs --from-file=gz=configs.tar.gz

	rm configs.tar.gz
}

download() {

	echo 'downloading and unpacking configs'
	${KCTL} get secret k8-anywhere-configs -o json | jq -r '.data.gz' | base64 -d > configs.tar.gz

	tar -zxvf configs.tar.gz

	rm configs.tar.gz
}

# This isn't used yet. Could be useful for testing or perhaps if someday terraform state is updated
clean() {
	echo 'removing configs from cluster'
	${KCTL} delete secret k8-anywhere-configs
}

case ${1} in
    --upload)
    upload
    ;;
    --download)
    download
    ;;
    --clean)
    clean
    ;;
    *)
    usage
    ;;
esac