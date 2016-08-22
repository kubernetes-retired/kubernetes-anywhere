#!/bin/bash

# Copyright 2015 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Run e2e tests using environment variables exported in e2e.sh.

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace


# Have cmd/e2e run by goe2e.sh generate JUnit report in ${WORKSPACE}/junit*.xml
ARTIFACTS=${WORKSPACE}/_artifacts
mkdir -p ${ARTIFACTS}

# E2E runner stages
STAGE_PRE="PRE-SETUP"
STAGE_SETUP="SETUP"
STAGE_CLEANUP="CLEANUP"
STAGE_KUBEMARK="KUBEMARK"

: ${KUBE_GCS_RELEASE_BUCKET:="kubernetes-release"}
: ${KUBE_GCS_DEV_RELEASE_BUCKET:="kubernetes-release-dev"}

# Use a published version like "ci/latest" (default), "release/latest",
# "release/latest-1", or "release/stable"
function fetch_published_version_tars() {
  local -r published_version="${1}"
  IFS='/' read -a varr <<< "${published_version}"
  path="${varr[0]}"
  if [[ "${path}" == "release" ]]; then
    local -r bucket="${KUBE_GCS_RELEASE_BUCKET}"
  else
    local -r bucket="${KUBE_GCS_DEV_RELEASE_BUCKET}"
  fi
  build_version=$(gsutil cat "gs://${bucket}/${published_version}.txt")
  echo "Using published version $bucket/$build_version (from ${published_version})"
  fetch_tars_from_gcs "gs://${bucket}/${path}" "${build_version}"
  unpack_binaries
  # Set CLUSTER_API_VERSION for GKE CI
  export CLUSTER_API_VERSION=$(echo ${build_version} | cut -c 2-)
}

function clean_binaries() {
  echo "Cleaning up binaries."
  rm -rf kubernetes*
}

function fetch_tars_from_gcs() {
  local -r gspath="${1}"
  local -r build_version="${2}"
  echo "Pulling binaries from GCS; using server version ${gspath}/${build_version}."
  gsutil -mq cp "${gspath}/${build_version}/kubernetes.tar.gz" "${gspath}/${build_version}/kubernetes-test.tar.gz" .
}

function unpack_binaries() {
  md5sum kubernetes*.tar.gz
  tar -xzf kubernetes.tar.gz
  tar -xzf kubernetes-test.tar.gz
}

clean_binaries
fetch_published_version_tars "${JENKINS_PUBLISHED_VERSION:-ci/latest}"

e2e_go_args=( \
  -v \
  --dump="${ARTIFACTS}" \
  --test \
  --test_args="${GINKGO_TEST_ARGS}" \
)

e2e_go="$(dirname "${0}")/e2e.go"
if [[ ! -f "${e2e_go}" ]]; then
  echo "TODO(fejta): stop using head version of e2e.go"
  e2e_go="./hack/e2e.go"
fi

pwd
find ${WORKSPACE}
make docker-build
gsutil cp gs://public-mikedanese-k8s/k8s-anywhere.config.json .config.json
docker run --net=host -v `pwd`:/opt/kubernetes-anywhere kubernetes-anywhere:v0.0.1 make do WHAT=deploy-cluster
docker run --net=host -v `pwd`:/opt/kubernetes-anywhere kubernetes-anywhere:v0.0.1 make do WHAT=validate
docker run --net=host -v `pwd`:/opt/kubernetes-anywhere kubernetes-anywhere:v0.0.1 make do WHAT=destroy-cluster

cd kubernetes/
go run "${e2e_go}" ${E2E_OPT:-} "${e2e_go_args[@]}"
