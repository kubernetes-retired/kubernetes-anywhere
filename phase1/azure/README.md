# Getting Started on Azure

## Overview

This will deploy a Kubernetes cluster into Azure.

## Preparation

Required software:
  * `docker` for executing the `kubernetes-anywhere` deployment
  * `make` for entering the deployment environment
  * `kubectl` for working with the cluster after deployment

Required information:
  * Azure Subscription ID (The ID of the Subscription that this cluster will be deployed to)


## Deployment

#### Clone the `kubernetes-anywhere` tool:

```shell
git clone https://github.com/kubernetes/kubernetes-anywhere
cd kubernetes-anywhere
```

#### Enter the `kubernetes-anywhere` deployment environment:

```shell
make docker-dev
```

#### Start the deployment wizard:

```shell
make deploy
```

**Notes**:
* The name chosen for `phase1.cluster_name` needs to be globally unique. (See ["Cluster Naming Restrictions"](#cluster-naming-restrictions) below for full details)

* To properly boot a cluster in Azure, you MUST set these values in the wizard:

  ```
  * phase1.azure.subscription_id = "[azure_subscription_id]"
  ```

  You may skip these fields, and the deployment will offer to fill them in for you:

  ```
  * phase1.azure.tenant_id
  * phase1.azure.client_id
  * phase1.azure.client_secret
  ```

* If you see this error output, please wait a minute and re-execute `make deploy`. This is a known issue due to some Azure AD interactions.

  ```
  Error refreshing state: 1 error(s) occurred:

  * Credentials for acessing the Azure Resource Manager API are likely to be incorrect, or
    the service principal does not have permission to use the Azure Service Management
    API.
  ```

## Congratulations!

You have a Kubernetes cluster!

Let's copy your `kubeconfig.json` file somewhere for safe-keeping.
*(Note, this will overwrite any existing config file at `~/.kube/config`.)*
You'll need to do this outside of the `kubernetes-anywhere` deployment environment so that it is usable later.

```shell
mkdir -p ~/.kube
cp ./phase1/azure/.tmp/kubeconfig.json ~/.kube/config
```


#### Deploy Something to the Cluster

  Your cluster is ready to use!

  If you want to prove to yourself that it works, you can try:

  * (Note, if you stored `kubeconfig.json` in a location other than `$HOME/.kube/config` you need to set `KUBECONFIG` appropriately):
  ```shell
  export KUBECONFIG=$HOME/.kube/config
  ```

  1. Start an `nginx` deployment:
  ```shell
  kubectl run nginx --image=nginx --replicas=3
  ```

  2. Expose the `nginx` deployment via a Service (Type=LoadBalancer):
  ```shell
  kubectl expose deployment nginx --name=nginx --type=LoadBalancer --port=80
  ```

  3. Wait a couple minutes for the Azure Load Balancer to be provisioned, then:
  ```shell
  kubectl get service nginx
  ```

  4. Once the Azure Load Balancer has finished provisioning, you will see the external IP address where `nginx` is now
  accessible. If you see `<pending>` then you need to wait a few more minutes.

Enjoy your Kubernetes cluster on Azure!

## Troubleshooting

### Validation Fails (Zero nodes are healthy)
If no nodes are available, there was likely a provisioning failure on the master (either in Azure or in the `ignition` provisioning container).
The following steps will help in troubleshooting:

1. SSH to the master.
2. Use the following commands to upload relevant logs:
  * `sudo journalctl -u kubelet 2>&1 | nc termbin.com 9999`
  * `sudo cat /var/log/cloud-init-output.log | nc termbin.com 9999`
3. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.

### Validation Fails (One or more nodes are missing/unhealthy)

1. Use `kubectl get nodes` to identify the missing nodes.
2. Use Azure Portal or `azure-xplat-cli` to find the node and the node's private IPv4 address.
3. SSH to the master, then to the missing node
4. Use the following commands to upload relevant logs:
  * `sudo journalctl -u kubelet 2>&1 | nc termbin.com 9999`
  * `sudo cat /var/log/cloud-init-output.log | nc termbin.com 9999`
5. Attach the logs to [a new Issue](https://github.com/kubernetes/kubernetes-anywhere/issues/new) in this repository.

## Notes

### Cluster Naming Restrictions
The `cluster_name` is used as a prefix for all created resources and is used as the storage account name (dashes are automatically removed). The following restrictions apply to storage account names, and thus must be respected when choosing a `cluster_name`:
  * Must be unique across Azure
  * Must contain at least 3 characters
  * Must contain no more than 24 characters
  * Must only use alphanumeric characters and underscores (same as domain name requirements)
  * Must start with a letter

### Between Deployments
At times, it can be helpful to run `make clean`. Note that this will remove the Terraform state files, requiring you to manually remove the cluster. Fortunately this is easy in Azure, and just requires you to remove the resource group created by the deployment.

### Service Principal Permission Scope
Currently, this service principal is used both for driving the deployment in Terraform as well as powering the cloudprovider in the cluster. This means that you
either need to grant the Service Principal `Contributor` level access to the entire subscription, or you need to make the Resource Group ahead of time and grant
the Service Principal access to just that specific Resource Group.

### Service Principal Creation
The deployment process will offer to create a service principal for you if you choose to
omit the relevant fields. If you would like to create the service principal and specify the
credentials manually, you may do so. You'll want to make sure your Azure CLI is configured for
the same subscription as you're planning to deploy into.

```shell
wget https://raw.githubusercontent.com/kubernetes/kubernetes-anywhere/master/phase1/azure/create-azure-service-principal.sh -O ./create-azure-service-principal.sh
chmod +x ./create-azure-service-principal.sh
./create-azure-service-principal.sh \
	--subscription-id=<your subscription id> \
	--name=<whatever name you want> \
	--app-url=<the client_id> \
	--secret=<the client_secret> \
	--output-format=text
```
