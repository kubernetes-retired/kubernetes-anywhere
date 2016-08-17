# Getting Started on Azure

## Overview

This will deploy a Kubernetes cluster into Azure.

## Preparation

Required software:
  * `docker` for executing the `kubernetes-anywhere` deployment
  * `kubectl` for working with the cluster after deployment

Required information:
  * Azure Subscription ID (The ID of the Subscription that this cluster will be deployed to)
  * Azure Tenant ID (The ID of the AAD Tenant to which the Azure Service Principal belongs)
  * Azure Service Principal Client ID (The Client ID (or Application Identifier URL) of your Service Principal)
  * Azure Service Principal Client Secret (The Client Secret (or Password) of your Service Principal)

If you need help creating an Azure Service Principal, [Hashicorp has some documentation](https://www.packer.io/docs/builders/azure-setup.html).

NOTE: Currently, this service principal is used both for driving the deployment in Terraform as well as powering the cloudprovider in the cluster. This means that you
either need to grant the Service Principal `Contributor` level access to the entire subscription, or you need to make the Resource Group ahead of time and grant
the Service Principal access to just that specific Resource Group.

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
* For now, the name chosen for `phase1.cluster_name` needs to be globally unique.

* To properly boot a cluster in Azure, you MUST set these values in the wizard:

  ```
  * phase1.azure.tenant_id = "[azure_tenant_id]"
  * phase1.azure.subscription_id = "[azure_subscription_id]"
  * phase1.azure.client_id = "[azure_client_id]"
  * phase1.azure.client_secret = "[azure_client_secret]"
  ```

  ```
  * phase2.docker_registry = "gcr.io/google_containers"
  * phase2.kubernetes_version = "v1.4.0-alpha.2"
  * phase2.installer_container = "docker.io/colemickens/k8s-ignition:latest
  ```

* It is **highly** recommended that you leave the `phase3` options on the default settings.
  By default, all of the addons will be deployed.
  Most Kubernetes usages and examples will expect them.

## Congratulations!

You have a Kubernetes cluster!

Let's copy your `kubeconfig.json` file somewhere for safe-keeping.
*(Note, this will overwrite any existing config file at `~/.kube/config`.)*
You'll need to do this outside of the `kubernetes-anywhere` deployment environment so that it is usable later.

  ```shell
  mkdir ~/.kube/config
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
  kubectl expose deployment nginx --name=nginx --type=LoadBalancer
  ```

  3. Wait a couple minutes for the Azure Load Balancer to be provisioned, then:
  ```shell
  kubectl get service nginx
  ```

  4. Once the Azure Load Balancer has finished provisioning, you will see the external IP address where `nginx` is now
  accessible. If you see `<pending>` then you need to wait a few more minutes.

Enjoy your Kubernetes cluster on Azure!
