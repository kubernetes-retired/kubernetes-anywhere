# Kubernetes on Azure Deployment

## Overview

This will deploy a Kubernetes cluster into Azure.

## Preparation

Required software:
  * `docker` for executing the `kubernetes-anywhere` deployment
  * `kubectl` for talking to the cluster after deployment

Required information:
  * Azure Subscription ID (The ID of the Subscription that this cluster will be deployed to)
  * Azure Tenant ID (The ID of the AAD Tenant to which the Azure Service Principal belongs)
  * Azure Service Principal Client ID (The Client ID (or Application Identifier URL) of your Service Principal)
  * Azure Service Principal Client Secret (The Client Secret (or Password) of your Service Principal)

If you need help creating an Azure Service Principal, [Hashicorp has some documentation](https://www.packer.io/docs/builders/azure-setup.html).

NOTE: Currently, this service principal is used both for driving the deployment in Terraform as well as powering the cloudprovider in the cluster. This means that you
either need to grant the Service Principal `Contributor` level access to the entire subscription, or you need to make the Resource Group ahead of time and grant
the Service Principal access to just that specific Resource Group.

## Execution

### Deploy the Cluster to Azure

  ```shell
  curl https://raw.githubusercontent.com/kubernetes/kubernetes-anywhere/master/kickstart.sh | bash
  ```

  **NOTE**: For now, the name chosen for `phase1.cluster_name` needs to be globally unique.

  **NOTE**: To properly boot a cluster in Azure, you MUST set these values in the wizard:

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

  **NOTE**: If you want the cluster to have functioning Service clusterIPs, ensure that you make the following choices.
  (It's highly recommended that you choose to deploy `kube-proxy` and in fact all of the cluster addons.
  If this is confusing, just leave it on the defaults.)

  ```
  * phase3.run_addons = true
  * phase3.kube_proxy = true
  ```

  Give it a minute or so for the system addon containers to boot up.

  Congratulations, you have a Kubernetes cluster!

  Let's copy your `kubeconfig.json` file somewhere for safe-keeping. Note, this will overwrite any existing config
  file at `~/.kube/config`. If you already have clusters configured, you can choose how to handle this new
  cluster's `kubeconfig.json` file.

  ```shell
  mkdir ~/.kube/config
  cp ./.tmp/kubeconfig.json ~/.kube/config
  ```

### Deploy Something to the Cluster

  Your cluster is ready to use!

  If you want to prove to yourself that it works, you can try:

  * (Note, if you stored `kubeconfig.json` in a location other than `$HOME/.kube/config` you need to set `KUBECONFIG`):
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
