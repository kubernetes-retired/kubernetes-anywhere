# Getting Started on vSphere

  - [Prerequisites](#prerequisites)
  - [Deployment](#deployment)
  - [Destroy](#destroy)
  - [Issues](#issues)

## Prerequisites
  * `docker-engine` for executing the `kubernetes-anywhere` deployment which can be downloaded [here](https://docs.docker.com/engine/installation/)
  * `make` for entering the deployment environment 

## Deployment

**Notes**:
The deployment is tested with kubernetes v1.4.0 and v1.4.4.

### Upload Template to vSphere:
You **must** upload template to vCenter before deploying kubernetes. 

#### Upload using vSphere Client.
1. Login to vSphere Client.
2. Right-Click on ESX host on which you want to deploy template.
3. Select Deploy OVF template.
4. Copy and paste URL for [OVA](https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/KubernetesAnywhereTemplatePhotonOS.ova)
5. Follow next steps according to instructions mentioned in wizard.

You can also upload ova using [govc](https://github.com/vmware/govmomi/tree/master/govc). 

```shell
git clone https://github.com/kubernetes/kubernetes-anywhere
cd kubernetes-anywhere
```

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

**Notes**
If you want to launch another cluster while keeping existing one then clone the kubernetes-anywhere and follow the steps above.

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
