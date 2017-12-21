# Getting Started on vSphere

  - [Prerequisites](#prerequisites)
  - [Deployment](#deployment)
  - [Destroy](#destroy)
  - [Known issues](#known-issues)
  - [Troubleshooting](#troubleshooting)

## Prerequisites
  * If Kubernetes Cluster is deployed on vSphere Cluster, then make sure time is in sync on all esx hosts in the cluster otherwise deployment may fail due to certificate expiry check.
  * `docker-engine` for executing the `kubernetes-anywhere` deployment which can be downloaded [here](https://docs.docker.com/engine/installation/).
  * Kubernetes Anywhere is tested on vSphere deployments with vCenter, single node vSphere without vCenter is not supported.
  * Deployment requires DHCP server in the VM network.
  * vCenter user with following minimal set of privileges.
      ```
      Datastore > Allocate space
      Datastore > Low level file Operations
      Folder > Create Folder
      Folder > Delete Folder
      Network > Assign network
      Resource > Assign virtual machine to resource pool
      Virtual machine > Configuration > Add new disk
      Virtual Machine > Configuration > Add existing disk
      Virtual Machine > Configuration > Add or remove device
      Virtual Machine > Configuration > Change CPU count
      Virtual Machine > Configuration > Change resource
      Virtual Machine > Configuration > Memory
      Virtual Machine > Configuration > Modify device settings
      Virtual Machine > Configuration > Remove disk
      Virtual Machine > Configuration > Rename
      Virtual Machine > Configuration > Settings
      Virtual machine > Configuration > Advanced
      Virtual Machine > Interaction > Power off
      Virtual Machine > Interaction > Power on
      Virtual Machine > Inventory > Create from existing
      Virtual Machine > Inventory > Create new
      Virtual Machine > Inventory > Remove
      Virtual Machine > Provisioning > Clone virtual machine
      Virtual Machine > Provisioning > Customize
      Virtual Machine > Provisioning > Read customization specifications
      vApp > Import
      Profile-driven storage -> Profile-driven storage view
      ```
**Note: vSphere Cloud Provider doesn't need these many privileges. These privileges are required for deployment of Kubernetes Cluster using Kubernetes-Anywhere. Please refer [vSphere Cloud Provider Guide](https://kubernetes.io/docs/getting-started-guides/vsphere/) for minimal set of privileges required for vSphere Cloud Provider.**

## Deployment

**Note**:

* Kubernetes recommended version is v1.6.5
* The deployment is tested with kubernetes v1.6.5, v1.5.7
* vSphere Cloud Provider is tested on v1.6.5, v1.5.7

### Upload VM image to be used to vSphere:

Upload the template OS OVA to vCenter before deploying kubernetes. All kubernetes nodes will be clones of this VM.

#### Upload using vSphere Client.

1. Login to vSphere Client.
2. Right-Click on ESX host on which you want to deploy template.
3. Select ```Deploy OVF template```.
4. Copy and paste URL for [OVA For vSphere 6.0 and above](https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/KubernetesAnywhereTemplatePhotonOS.ova) (*Updated on March 1 2017*).
[OVA For vSphere 5.5 with Virtual Machine Hardware Version 10](https://storage.googleapis.com/kubernetes-anywhere-for-vsphere-cna-storage/KubernetesAnywhereTemplatePhotonOSESX5.5.ova)
5. **Check the name of the VM created**, this will be used to deploy kubernetes later. (Should default to KubernetesAnywhereTemplatePhotonOS.ova)

You can also upload ova using [govc](https://github.com/vmware/govmomi/tree/master/govc).
This OVA is based on Photon OS(v1.0) with virtual hardware v11.

**NOTE: DO NOT POWER ON THE IMPORTED VM.**

If you do power it on, future clones of this VM will end up [getting the same IP as the imported VM](https://github.com/vmware/photon/wiki/Frequently-Asked-Questions#q-why-do-all-of-my-cloned-photon-os-instances-have-the-same-ip-address-when-using-dhcp). To work around this run the following command before powering the VM off and using it to clone the kubernetes nodes.
```
echo -n > /etc/machine-id
```

### Launch deployment environment

#### Pull `cnastorage/kubernetes-anywhere:latest` docker image:

```shell
docker pull cnastorage/kubernetes-anywhere
```

#### Run docker container using `cnastorage/kubernetes-anywhere:latest` image to launch deployment environment:

```shell
docker run -it -v /tmp:/tmp --rm --env="PS1=[container]:\w> " --net=host cnastorage/kubernetes-anywhere:latest /bin/bash
```
**Note:** Here in the above command we are mounting local /tmp directory, so that after the deployment is finished successfully, we can copy kubeconfig.json file on local system from the deployment container.

### Start the deployment wizard:

#### Sample config

Lets take a look at vSphere environment before starting deployment wizard.


![k8s-vsphere-deployment-01](https://user-images.githubusercontent.com/22985595/29735888-5b4117be-89b1-11e7-8590-214dc738a6a1.png)

Here you see Datacenter ```cna-storage```, has ```cluster-vsan-1``` with one resource pool - ```dev-resource-pool```.

Following steps will deploy 4 nodes Kubernetes Cluster on the ```dev-resource-pool``` using the template file deployed on the cluster.

Let's start the deployment wizard. on the container prompt execute ```make config``` from ```/opt/kubernetes-anywhere``` directory

```shell
[container]:/opt/kubernetes-anywhere> make config
```

and complete the config wizard to create configuration for the kubernetes cluster.
**You can get help for any config option by entering '?'.**

* Select the number of nodes. Master + Number of nodes will be deployed.
```
number of nodes (phase1.num_nodes) [4] (NEW) 4
```

* Set the cluster name. A folder with the cluster name will be created to place all the VMs.
```
cluster name (phase1.cluster_name) [kubernetes] (NEW) kubernetes
```

* phase1.ssh_user - This field is not used for vSphere Deployment. Leave it blank and hit enter.
```
SSH user to login to OS for provisioning (phase1.ssh_user) [] (NEW)
```

* Select the provider, in this case it would be vsphere.
```
cloud provider: gce, azure or vsphere (phase1.cloud_provider) [vsphere] (NEW) vsphere
```

* Set the vCenter URL (Just the IP or domain name, without https://)
```
  vCenter URL Ex: 10.192.10.30 or myvcenter.io (phase1.vSphere.url) [] (NEW) 10.160.0.77
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
  Does host use self-signed cert (phase1.vSphere.insecure) [Y/n/?] (NEW) Y
```

* Set the datacenter in vCenter to use. Specify the same datacenter to which the OVA was imported to.
```
  Datacenter (phase1.vSphere.datacenter) [datacenter] (NEW) cna-storage
```

* Set the datastore to be use. This will be used for placing the VMs and volumes created via storage classes/dynamic provisioning.
```
  Datastore (phase1.vSphere.datastore) [datastore] (NEW) vsanDatastore
```

* Specify where to deploy Kubernetes Cluster on Host or on Cluster.
```
   Deploy Kubernetes Cluster on 'host' or 'cluster' (phase1.vSphere.placement) [cluster] (NEW) cluster
```

*  If Host is selected, Specify host IP or FQDN. If Cluster is selected, Specify cluster name
```
    vsphere cluster name. Please make sure that all the hosts in the cluster are time-synchronized otherwise some of the nodes can remain in pending state for ever due to expired certificate (phase1.vSphere.cluster) [] (NEW) cluster-vsan-1
```

*  Specify yes if Kubernetes Cluster needs to be deployed on the resource pool located in selected host or cluster
```
    Do you want to use the existing resource pool created on the host or cluster? [yes, no] (phase1.vSphere.useresourcepool) [no] (NEW) yes
```

*  Specify name of the resource pool.
```
  Name of the Resource Pool. If Resource pool is enclosed within another Resource pool, specify pool hierarchy as ParentResourcePool/ChildResourcePool (phase1.vSphere.resourcepool) (NEW) dev-resource-pool
```

* Specify the folder name or folder path where Kubernetes Node VMs should placed in the VC Inventory. Folder path will be created if not present.
```
  VM Folder name or Path (e.g kubernetes, VMFolder1/dev-cluster, VMFolder1/Test Group1/test-cluster). Folder path will be created if not present (phase1.vSphere.vmfolderpath) [kubernetes] (NEW) kubernetes
```

* Number of vCPUs for each VM. Master and all nodes will have the number of vCPUs configured below.
```
  Number of vCPUs for each VM (phase1.vSphere.vcpu) [1] (NEW) 4
```

* Memory for each VM. Master and all nodes will have the RAM configured below.
```
  Memory for each VM (phase1.vSphere.memory) [2048] (NEW) 4096
```

* Network for each VM. Master and all nodes will have the Network configured below.
```
  Network for each VM (phase1.vSphere.network) [VM Network] (NEW)
```

* Name of the template VM to use to create clone VMs for master and all nodes. The name here should be the same as the name that is reported by vCenter.
```
  Name of the template VM imported from OVA. If Template file is not available at the destination location specify vm path (phase1.vSphere.template) [KubernetesAnywhereTemplatePhotonOS.ova] (NEW) /PA-DC/vm/KubernetesAnywhereTemplatePhotonOS
```

* Configure the POD network using flannel
```
  Flannel Network (phase1.vSphere.flannel_net) [172.1.0.0/16] (NEW)
```

* Ignition image to be used for phase 2.
For Kubernetes release 1.6 and above use `docker.io/cnastorage/k8s-ignition:v2`. For older releasees use `docker.io/cnastorage/k8s-ignition:v1`

```
*
* Phase 2: Node Bootstrapping
*
```
* Set the release of Kubernetes to be used. The release should be the exact string used to tag a release.
```
kubernetes version (phase2.kubernetes_version) [v1.6.5] (NEW)
```

* Set bootstrap provider to ignition
```
bootstrap provider (phase2.provider) [ignition] (NEW) ignition
```

* Set the installer container
```
installer container (phase2.installer_container) [docker.io/cnastorage/k8s-ignition:v2] (NEW) docker.io/cnastorage/k8s-ignition:v2
```

* Registry to be used by Kubernetes
```
docker registry (phase2.docker_registry) [gcr.io/google-containers] (NEW)
```

* Select the addons. Defaults to yes. **Make sure to choose 'N' for weave-net addon.**
```
*
* Phase 3: Deploying Addons.
*
Run the addon manager? (phase3.run_addons) [Y/n/?] (NEW)
  Run kube-proxy? (phase3.kube_proxy) [Y/n/?] (NEW)
  Run the dashboard? (phase3.dashboard) [Y/n/?] (NEW)
  Run heapster? (phase3.heapster) [Y/n/?] (NEW)
  Run kube-dns? (phase3.kube_dns) [Y/n/?] (NEW)
  Run weave-net? (phase3.weave_net) [N/y/?] (NEW) N

#
# configuration written to .config
#
```
Start the deployment using .config file


```
[container]:/opt/kubernetes-anywhere> make deploy
util/config_to_json /opt/kubernetes-anywhere/.config > /opt/kubernetes-anywhere/.config.json
make do WHAT=deploy-cluster
make[1]: Entering directory '/opt/kubernetes-anywhere'
.
.
.
KUBECONFIG="$(pwd)/phase1/vsphere/kubernetes/kubeconfig.json" ./util/validate
Validation: Expected 5 (workers + master) healthy nodes; found 0. (10s elapsed)
Validation: Expected 5 (workers + master) healthy nodes; found 2. (20s elapsed)
Validation: Expected 5 (workers + master) healthy nodes; found 5. (30s elapsed)
Validation: Success!
.
.
+ kubectl apply -f kubernetes/.tmp
deployment "kubernetes-dashboard" created
service "kubernetes-dashboard" created
deployment "heapster-v1.2.0" created
service "heapster" created
replicationcontroller "kube-dns-v19" created
service "kube-dns" created
daemonset "kube-proxy" created
```


**Notes**:

* if OVA file is not located in the resource pool, where you want to deploy Kubernetes Cluster, please specify full VM Path.
* You can build your own ```phase2.installer_container``` using Dockerfile [here](https://github.com/kubernetes/kubernetes-anywhere/blob/master/phase2/ignition/Dockerfile).
* To change configuration, run: ``` make config .config```. Run ```make clean``` before ```make deploy```

### Congratulations!

You have a Kubernetes cluster!

Lets take a look at where node VM's are located on the vCenter.

Node VMs are placed in the ```dev-resource-pool``` under the VM Folder ```kubernetes```.  ```kubernetes``` is the name of the cluster we specified in the configuration wizard.

![k8s-vsphere-deployment-02](https://user-images.githubusercontent.com/22985595/29735890-5e941cea-89b1-11e7-864f-67a8e3343d8c.png)

![k8s-vsphere-deployment-03](https://user-images.githubusercontent.com/22985595/29735891-6076f744-89b1-11e7-86ac-7e873025b4a1.png)

To deploy another kubernetes cluster while keeping the existing one, run `make config` and specify different kubernetes cluster name (phase1.cluster_name) and resource pool name and follow steps mentioned above.

#### Next Steps:

First set KUBECONFIG to access cluster using kubectl:

```shell
export KUBECONFIG="/opt/kubernetes-anywhere/phase1/vsphere/kubernetes/kubeconfig.json"
```
Note: In the path `/opt/kubernetes-anywhere/phase1/vsphere/kubernetes` kubernetes is the name of the cluster that we have specifed in the config file. If you have specified different name make sure to specify the appropriate path.

We have mounted /tmp directory in the deployment container. If you want to save the config on your local machine just copy this file to the /tmp directory in the container.

You will get cluster information when you run:
```shell
kubectl cluster-info
```

To access the dashboard after successful installation of kubernetes cluster. There are 2 options.

* Run ```kubectl proxy``` outside the container created from ```cnastorage/kubernetes-anywhere:latest```

Note: Make sure to download the kubectl version that matches with deployed kubernetes cluster
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.6.5/bin/linux/amd64/kubectl
chmod u+x kubectl
mkdir ~/.kube/
cd  ~/.kube/
vi config // copy content of $(make -s kubeconfig-path) and paste in this file.
export KUBECONFIG=~/.kube/config
./kubectl proxy
Starting to serve on 127.0.0.1:8001
```

Open the http://127.0.0.1:8001/ui in a browser

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
2. [Only a single kubernetes cluster can exist in a resource pool.](https://github.com/kubernetes/kubernetes-anywhere/issues/296)

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
2. Use the following command to get relevant logs:
   * `journalctl -u kubelet`
3. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.

### Validation Fails (One or more nodes are missing/unhealthy)

1. Use `kubectl get nodes` to identify the missing nodes.
2. Use vSphere Client or `govc` to find the node and the node's IP address.
3. SSH to the master, then to the missing node
4. Use the following command to get relevant logs:
   * `journalctl -u kubelet`
5. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.

### Validation Fails (Dashboard or other kubernetes services are not working)
This was be mostly likely flannel failure.

1. Use `kubectl describe pod dashboard-pod-name` to identify the node on which dashboard pod is scheduled.
2. Use vSphere Client or `govc` to find the node and the node's IP address.
3. SSH to the node.
4. Use the following command on node to get relevant logs:
   * `journalctl -u flannelc`
5. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.
