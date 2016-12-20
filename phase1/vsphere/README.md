# Getting Started on vSphere

  - [Prerequisites](#prerequisites)
  - [Deployment](#deployment)
  - [Destroy](#destroy)
  - [Issues](#issues)
  - [Troubleshooting](#troubleshooting)

## Prerequisites
  * `docker-engine` for executing the `kubernetes-anywhere` deployment which can be downloaded [here](https://docs.docker.com/engine/installation/).
  * `make` for entering the deployment environment. 

## Deployment

**Note**:

The recommended version is v1.4.7

The deployment is tested with kubernetes v1.4.0, v1.4.4 and v1.4.7

vSphere Cloud Provider is tested on v1.4.7


### Upload Template to vSphere:
You **must** upload the template OS ova to vCenter before deploying kubernetes.

#### Upload using vSphere Client.
1. Login to vSphere Client.
2. Right-Click on ESX host on which you want to deploy template.
3. Select ```Deploy OVF template```.
4. Copy and paste URL for [OVA](https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/KubernetesAnywhereTemplatePhotonOS.ova).
5. Check the name of the VM created, this will be used to deploy kubernetes later. (Should default to KubernetesAnywhereTemplatePhotonOS)
6. Follow next steps according to instructions mentioned in wizard. Select the resource pool in which the kubernetes cluster is to be created.

You can also upload ova using [govc](https://github.com/vmware/govmomi/tree/master/govc). 

**Note**:

This OVA is based on Photon OS(v1.0) with virtual hardware v11. 

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

* Set the resource pool to be same as the one selected during import of OVA above.

* To properly boot a cluster in vSphere, you MUST set these values in the wizard:

  ```
  * phase2.installer_container = "docker.io/ashivani/k8s-ignition:v4"
  ```

* To change configuration, run: ``` make config .config```

* The deployment is configured to use DHCP. 

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

## Known Issues
  
1. ```make destroy``` is [flaky.](https://github.com/kubernetes/kubernetes-anywhere/issues/285)
2. [Photon OS template needs to be in the same cluster as kubernetes VMs.] (https://github.com/kubernetes/kubernetes-anywhere/issues/300)
3. [Only a single kubernetes cluster can exist in a resource pool.] (https://github.com/kubernetes/kubernetes-anywhere/issues/296)

## Troubleshooting

### Validation Fails (Zero nodes are healthy)
If no nodes are available, there was likely a provisioning failure on the master (either in vSphere or in the `ignition` provisioning container).
The following steps will help in troubleshooting:

1. SSH to the master.
2. Use the following command to upload relevant logs:
  * `journalctl -u kubelet`
3. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.

### Validation Fails (One or more nodes are missing/unhealthy)

1. Use `kubectl get nodes` to identify the missing nodes.
2. Use vSphere Client or `govc` to find the node and the node's IP address.
3. SSH to the master, then to the missing node
4. Use the following command to upload relevant logs:
   * `journalctl -u kubelet`
5. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.

### Validation Fails (Dashboard or other kubernetes services are not working)
This was be mostly likely flannel failure.

1. Use `kubectl describe pod dashboard-pod-name` to identify the node on which dashboard pod is scheduled.
2. Use vSphere Client or `govc` to find the node and the node's IP address.
3. SSH to the node.
4. Use the following command on node to upload relevant logs:
   * `journalctl -u flannelc`
5. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.
