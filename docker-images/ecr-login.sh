#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

doc=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document)
export AWS_DEFAULT_REGION=$(printf "${doc}" | jq -r .region)

exec $(aws ecr get-login)
