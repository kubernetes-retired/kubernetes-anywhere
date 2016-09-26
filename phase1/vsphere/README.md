# Getting Started on vSphere

  - [Prerequisites](#prerequisites)
  - [Deployment](#deployment)
  - [Destroy](#destroy)
  - [Issues](#issues)

## Prerequisites
  * `docker-engine` for executing the `kubernetes-anywhere` deployment which can be downloaded [here](https://docs.docker.com/engine/installation/)
  * `make` for entering the deployment environment
  *  OVA which can be found [here](https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/KubernetesAnywhereTemplatePhotonOS.ova) 

## Deployment

**Notes**:
The deployment is tested with kubernetes v1.4.0 and 1.4.4.

### Clone the `kubernetes-anywhere` tool:

```shell
git clone https://github.com/kubernetes/kubernetes-anywhere
cd kubernetes-anywhere
```

### Enter the `kubernetes-anywhere` deployment environment:

```shell
make docker-dev
```

### Start the deployment wizard:

```shell
make deploy
```
and fill complete the config wizard to deploy a kubernetes-anywhere cluster.

**Notes**:

* To properly boot a cluster in vSphere, you MUST set these values in the wizard:

  ```
  * phase2.installer_container = "docker.io/ashivani/k8s-ignition:v3"
  ```

### Congratulations!

You have a Kubernetes cluster!

#### Get Cluster Info:

First set KUBECONFIG to access cluster using kubectl:
```shell
export KUBECONFIG=phase1/vsphere/.tmp/kubeconfig.json
```
You will get cluster information when you run:
```shell
kubectl cluster-info
```

## Destroy

After you've had a great experience with Kubernetes, run:
```console
$ make destroy
```
to tear down your cluster.

## Issues
  - make destroy is flaky.
  - kubelet doesn't restart when node restarts.
