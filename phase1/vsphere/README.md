# Getting Started on vSphere

  - [Prerequisites](#prerequisites)
  - [Deployment](#deployment)
  - [Destroy](#destroy)
  - [Issues](#issues)
  - [Troubleshooting](#troubleshooting)

## Prerequisites
  * `docker-engine` for executing the `kubernetes-anywhere` deployment which can be downloaded [here](https://docs.docker.com/engine/installation/).
  * `make` for entering the deployment environment.
  * Kubernetes Anywhere is tested on vSphere deployments with vCenter, single node vSphere without vCenter is not supported.

## Deployment

**Note**:

The recommended version is v1.4.7

The deployment is tested with kubernetes v1.4.0, v1.4.4 and v1.4.7

vSphere Cloud Provider is tested on v1.4.7

### Upload VM image to be used to vSphere:

Upload the template OS OVA to vCenter before deploying kubernetes. All kubernetes nodes will be clones of this VM.

#### Upload using vSphere Client.

1. Login to vSphere Client.
2. Right-Click on ESX host on which you want to deploy template.
3. Select ```Deploy OVF template```.
4. Copy and paste URL for [OVA](https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/KubernetesAnywhereTemplatePhotonOS.ova).
5. **Check the name of the VM created**, this will be used to deploy kubernetes later. (Should default to KubernetesAnywhereTemplatePhotonOS.ova)
6. Follow next steps according to instructions mentioned in wizard. Select the resource pool in which the kubernetes cluster is to be created. **The Resource Pool selected** will need to be entered in the wizard when deploying kubernetes during ```make deploy``` or ```make config```

You can also upload ova using [govc](https://github.com/vmware/govmomi/tree/master/govc). 

This OVA is based on Photon OS(v1.0) with virtual hardware v11. 

### Clone `kubernetes-anywhere`:

```shell
git clone https://github.com/kubernetes/kubernetes-anywhere
cd kubernetes-anywhere
```

### Enter the `kubernetes-anywhere` deployment environment:

```shell
make docker-dev # Building docker image for first time can take few minutes.
```

### Start the deployment wizard:

```shell
make deploy
```

and fill complete the config wizard to deploy a kubernetes-anywhere cluster.

### Sample config

* Select the number of nodes. Master + Number of nodes will be deployed.
```
number of nodes (phase1.num_nodes) [4] (NEW) 8
```

* Set the cluster name. A folder with the cluster name will be created to place all the VMs.
```
cluster name (phase1.cluster_name) [kubernetes] (NEW) k8s-test-cluster-1
```

* Select the provider, in this case it would be vsphere.
```
cloud provider: gce, azure or vsphere (phase1.cloud_provider) [gce] (NEW) vsphere
```

* Set the vCenter URL (Just the IP or domain name, without https://)
```
  vCenter URL Ex: 10.192.10.30 or myvcenter.io (phase1.vSphere.url) [] (NEW) 10.192.72.70
```

* Set the port for vCenter communication. Unless vCenter is setup with a different port select the default port.
```
  vCenter port (phase1.vSphere.port) [443] (NEW) 
```

* Enter the user name for vCenter. All vCenter operations will be performed using these user credentials
```
  vCenter username (phase1.vSphere.username) [] (NEW) administrator@myvcenter.io
```

* Enter the password for vCenter.
```
  vCenter password (phase1.vSphere.password) [] (NEW) MyPassword#3
```

* Set the type of certificate used by vCenter. Set to true for self signed certificates
```
  Does host use self-signed cert (phase1.vSphere.insecure) [true] (NEW) 
```

* Set the datacenter in vCenter to use. Specify the same datacenter to which the OVA was imported to.
```
  Datacenter (phase1.vSphere.datacenter) [datacenter] (NEW) PA-DC
```

* Set the datastore to be use. This will be used for placing the VMs and volumes created via storage classes/dynamic provisioning.
```
  Datastore (phase1.vSphere.datastore) [datastore] (NEW) vsanDatastore
```

* Specify a valid Cluster, Host or Resource Pool in which to deploy Kubernetes VMs. This should the same as the one selected when importing the template OVA. Example: Cluster: vsan-cluster, Host: 10.192.72.70 or Resource Pool: /vcqaDC/host/10.192.72.70/Resources or /vcqaDC/host/vsan-cluster/Resources
```
  Resource pool/cluster (same as destination for OVA import). (phase1.vSphere.resourcepool) [] (NEW) vsan-cluster
```

* Number of vCPUs for each VM. Master and all nodes will have the number of vCPUs configured below.
```
  Number of vCPUs for each VM (phase1.vSphere.vcpu) [1] (NEW) 4
```

* Memory for each VM. Master and all nodes will have the RAM configured below.
```
  Memory for each VM (phase1.vSphere.memory) [2048] (NEW) 8192 
```

* Name of the template VM to use to create clone VMs for master and all nodes. The name here should be the same as the name that is reported by vCenter.
```
  Name of the VM created after import of OVA (phase1.vSphere.template) [KubernetesAnywhereTemplatePhotonOS.ova] (NEW) KubernetesAnywhereTemplate
```

* Configure the POD network using flannel
```
  Flannel Network (phase1.vSphere.flannel_net) [172.1.0.0/16] (NEW) 
```

* Ignition image to be used for phase 2. **Do not use the default value for vSphere.**

```
*
* Phase 2: Node Bootstrapping
*
installer container (phase2.installer_container) [docker.io/colemickens/k8s-ignition:latest] (NEW) docker.io/ashivani/k8s-ignition:v4
```

* Registry to be used by Kubernetes
```
docker registry (phase2.docker_registry) [gcr.io/google-containers] (NEW) 
```

* Set the release of Kubernetes to be used. The release should be the exact string used to tag a release.
```
kubernetes version (phase2.kubernetes_version) [v1.4.7] (NEW) v1.4.7
```

* Set bootstrap provider to ignition
```
bootstrap provider (phase2.provider) [ignition] (NEW) ignition
```

* Select the addons. Defaults to yes.
```
*
* Phase 3: Deploying Addons. 
*
Run the addon manager? (phase3.run_addons) [Y/n/?] (NEW) 
  Run kube-proxy? (phase3.kube_proxy) [Y/n/?] (NEW) 
  Run the dashboard? (phase3.dashboard) [Y/n/?] (NEW) 
  Run heapster? (phase3.heapster) [Y/n/?] (NEW) 
  Run kube-dns? (phase3.kube_dns) [Y/n/?] (NEW) 
```

**Notes**:

* Set the resource pool to be same as the one selected during import of OVA above.

* To properly boot a cluster in vSphere, you MUST set these values in the wizard:

  ```
  * phase2.installer_container = "docker.io/ashivani/k8s-ignition:v4"
  ```

* To change configuration, run: ``` make config .config```. Run ```make clean``` before ```make deploy```

* The deployment is configured to use DHCP. 

### Congratulations!

You have a Kubernetes cluster!

**Notes**
If you want to launch another cluster while keeping existing one then clone the kubernetes-anywhere and follow the steps above.

#### Next Steps:

First set KUBECONFIG to access cluster using kubectl:

```shell
export KUBECONFIG=phase1/vsphere/.tmp/kubeconfig.json
```

You will get cluster information when you run:
```shell
kubectl cluster-info
```

To access the dashboard after successful instllation of kubernetes cluster. There are 2 options.

* Run ```kubectl proxy``` outside the container spawned by ```make docker-dev```
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.4.7/bin/linux/amd64/kubectl
chmod u+x kubectl
export KUBECONFIG=phase1/vsphere/.tmp/kubeconfig.json
./kubectl proxy
Starting to serve on 127.0.0.1:8001
# Open the https://127.0.0.1:8001/ui in a browser
``` 

* Access the dashboard from the node it is running on via NodePort mapping
```
# Get NodePort mapping
kubectl describe service kubernetes-dashboard --namespace=kube-system| grep -i NodePort
Type:                   NodePort
NodePort:               <unset> 31402/TCP
```
```
# Get node it is running on
kubectl get pods --namespace=kube-system| grep -i dashboard
  kubernetes-dashboard-1763797262-fzla9   1/1       Running   0          13m

kubectl describe pod kubernetes-dashboard-1763797262-fzla9 --namespace=kube-system| grep Node
  Node:           node1/10.20.104.220
```
```
# Select the public IP for the node via or use govc or vCenter UI
kubectl describe node node1| grep Address
# Open the <IP Addr>:<NodePort> in a browser
``` 

## Destroy

After you've had a great experience with Kubernetes, run:
```console
$ make destroy
```
to tear down your cluster.

If make destroy fails due to a [known issue](https://github.com/kubernetes/kubernetes-anywhere/issues/285), the VMs can be deleted from vCenter.

## Known Issues
  
1. ```make destroy``` is [flaky.](https://github.com/kubernetes/kubernetes-anywhere/issues/285)
2. [Photon OS template needs to be in the same cluster as kubernetes VMs.] (https://github.com/kubernetes/kubernetes-anywhere/issues/300)
3. [Only a single kubernetes cluster can exist in a resource pool.] (https://github.com/kubernetes/kubernetes-anywhere/issues/296)

## Troubleshooting
### Logging into the VMs
The default password is [not yet configurable](https://github.com/kubernetes/kubernetes-anywhere/issues/294), the default login is
```
user: root
password: kubernetes
```
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
