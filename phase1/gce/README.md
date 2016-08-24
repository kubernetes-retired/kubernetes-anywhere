# Getting started on Google Cloud

Prerequisites:
* A GCP project which can be created [here](https://cloud.google.com/)
* An authorized gcloud which can be downloaded [here](https://cloud.google.com/sdk/)
* docker-engine which can be downloaded [here](https://docs.docker.com/engine/installation/)

Clone the kubernetes-anywhere repository.

```console
$ git clone https://github.com/kubernetes/kubernetes-anywhere.git
$ cd kubernetes-anywhere
```

Setup a GCP service account for kubernetes-anywhere to use to deploy your cluster. First export the name of your project.

```console
$ export PROJECT_ID="<replace with the name of your project>"
```

then run:

```console
$ export SERVICE_ACCOUNT="kubernetes-anywhere@${PROJECT_ID}.iam.gserviceaccount.com"
$ gcloud iam service-accounts create kubernetes-anywhere \
    --display-name kubernetes-anywhere
$ gcloud iam service-accounts keys create phase1/gce/account.json \
    --iam-account "${SERVICE_ACCOUNT}"
$ gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${SERVICE_ACCOUNT}" --role roles/editor
```

Now hop into your deployment shell with all the tools you need to deploy a kubernetes-anywhere cluster. Run:

```console
$ make docker-dev
```

Once in your dev shell run:

```console
$ make deploy
```

and fill complete the config wizard to deploy a kubernetes-anywhere cluster. Eventually, you will see a set of nodes when you run:

```console
$ kubectl --kubeconfig phase1/gce/kubeconfig.json get nodes
```

It may take a couple minutes for the Kubernetes API to start responding to requests. Once all the nodes in your cluster is ready, you can deploy cluster addons by running:

```console
$ ./phase3/do gen
$ kubectl --kubeconfig phase1/gce/kubeconfig.json apply -f ./phase3/.tmp/
```

After you've had a great experience with Kubernetes, run:

```console
$ make destroy
```

to tear down your cluster.
