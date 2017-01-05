# Deploying a Kubernetes Development Cluster

This describes the steps to use kubernetes-anywhere to deploy a custom build of
kubernetes in GCE on a Linux that has the apt package manager.

- gcp-project-id = the Google Cloud Platform project id where you want your dev
  cluster to run.
- gcs-bucket-name = GCS bucket you will create to hold some artifacts needed
  during the node installation process.

## Setup Steps

1. Create a GCS bucket to hold your builds and make it public so that during the
   installation process, when kubeadm runs on the GCE instances, it will be able
   to access the bucket and download the debian packages that will be there.

    ```sh
    gsutil mb gs://<gcs-bucket-name>
    gsutil defacl ch -u AllUsers:R gs://<gcs-bucket-name>
    ```

2. Modify the GCS path in `kubernetes-anywhere/phase1/gce/configure-vm-kubeadm.sh`
   to be your personal GCS bucket created in the previous step.

    ```diff
    -KUBEADM_VERSION=$(get_metadata "k8s-kubeadm-version")
    +KUBEADM_VERSION="gs://<gcs-bucket-name>/build/debs"
    ```

3. Right after that line, add a line setting the repo prefix.

    ```diff
    +export KUBE_REPO_PREFIX="gcr.io/<gcp-project-id>"
    ```

4. Further down in the same file, tell kubeadm to install your develpment build
   instead of the default behavior, which is to install the most recent version.

    ```diff
       "master")
    -    kubeadm init --discovery "token://${TOKEN}@" --skip-preflight-checks --api-advertise-addresses "$(get_metadata "k8s-advertise-addresses")"
    +    kubeadm init --discovery "token://${TOKEN}@" --skip-preflight-checks --api-advertise-addresses "$(get_metadata "k8s-advertise-addresses")" --use-kubernetes-version v1.6.0-alpha
    ```

5. There are some additional images used during the kubernetes install that are
   not built as part of kubernetes. Tag recent versions of these images with the
   same version as your build. kubeadm will attempt to download these images and
   install them, and it will use the version specified above.

   Replace gcp-project-id with your project id.


    ```sh
    gcloud docker -a

    docker pull gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm
    docker tag gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm gcr.io/<gcp-project-id>/etcd-amd64:3.0.14-kubeadm
    docker push gcr.io/<gcp-project-id>/etcd-amd64:3.0.14-kubeadm

    docker pull gcr.io/google-containers/pause-amd64:3.0
    docker tag gcr.io/google-containers/pause-amd64:3.0 gcr.io/<gcp-project-id>/pause-amd64:3.0
    docker push gcr.io/<gcp-project-id>/pause-amd64:3.0

    docker pull gcr.io/google-containers/kube-discovery-amd64:1.0
    docker tag gcr.io/google-containers/kube-discovery-amd64:1.0 gcr.io/<gcp-project-id>/kube-discovery-amd64:1.0
    docker push gcr.io/<gcp-project-id>/kube-discovery-amd64:1.0
    ```

6. Create a shell script like this in your kubernetes directory, called
   `upload.sh`. There is an improvement for this step in flight.

    ```sh
    #!/bin/bash

    set -o xtrace
    set -o nounset
    set -o pipefail
    set -o errexit

    declare -r KUBE_VERSION="v1.6.0-alpha"

    if [[ -z ${KUBE_REPO_PREFIX:-} ]]; then
      echo "You must define \$KUBE_REPO_PREFIX. Something like:"
      echo
      echo "export KUBE_REPO_PREFIX=gcr.io/<gcp_project_name>"
      echo
      exit 1
    fi

    build_and_push() {
      local component="$1"
      bazel run "//build:${component}"
      docker tag "gcr.io/google-containers/build:${component}" "${KUBE_REPO_PREFIX}/${component}-amd64:${KUBE_VERSION}"
      docker push "${KUBE_REPO_PREFIX}/${component}-amd64:${KUBE_VERSION}"
    }

    components=("${@}")

    for component in "${components[@]}"; do
      build_and_push "${component}"
    done
    ```

7. Upload a custom build to a GCS bucket.

    ```sh
    cd kubernetes
    gcloud docker -a
    bash upload.sh kube-apiserver kube-controller-manager kube-proxy kube-scheduler
    ```

8. Create a cluster

    ```sh
    go run hack/e2e.go -kubernetes-anywhere-cluster=k-a -kubernetes-anywhere-path ../kubernetes-anywhere -kubernetes-anywhere-phase2-provider=kubeadm -deployment kubernetes-anywhere -v -up
    ```

9. When you are done you can destroy the cluster.

    ```sh
    go run hack/e2e.go -kubernetes-anywhere-cluster=k-a -kubernetes-anywhere-path ../kubernetes-anywhere -kubernetes-anywhere-phase2-provider=kubeadm -deployment kubernetes-anywhere -v -down
    ```

## Refreshing the Images in an Existing Cluster

1. Upload new image(s) to GCR. You can specify one or more images as paramaters
   to the `upload.sh` script, depending on what you are making changes to. In
   this example, only kube-apiserver is specified.

    ```sh
    cd kubernetes
    gcloud docker -a
    bash upload.sh kube-apiserver
    ```

2. Use the new image in the cluster by removing the old image on the master,
   then removing the container and allowing it to be automatically restarted.
   During the restart, the image will not be found locally, so the new image
   will be downloaded from GCR.

    ```sh
    sudo docker rmi -f gcr.io/google_containers/kube-apiserver-amd64:v1.5.1
    sudo docker rm -f `sudo docker ps --filter name=kube-apiserver -q`
    sudo docker ps --filter name=kube-apiserver
    ```

