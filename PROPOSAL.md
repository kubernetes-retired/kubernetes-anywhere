# Kubernetes Anywhere Original Design Proposal

This is the original design proposal for Kubernetes Anywhere, which is kept here for posterity but may not be completely up to date.

*{concise,reliable,cross-platform} turnup of Kubernetes clusters*

### Goals and Motivation

Learning how to deploy Kubernetes is hard because the default deployment automation [`cluster/kube-up.sh`](https://github.com/kubernetes/kubernetes/blob/master/cluster/kube-up.sh) is opaque. We can do better, and by doing better we enable users to run Kubernetes in more places.

This implementation will be considered successful if it:
  * is portable across many deployment targets (e.g. at least GCE/AWS/Azure)
  * allows for an easy and reliable first experience with running multinode Kubernetes in the cloud
  * is transparent and can be used as a reference when creating deployments to new targets

### Deployment:

The input of the deployment will be a cluster configuration object, specified as JSON object. It serves the purpose of the current [`config-*.sh`](https://github.com/kubernetes/kubernetes/blob/master/cluster/gce/config-default.sh) files do for `kube-up.sh`.

The deployment consists of two phases, provisioning and bootstrap:

  1. **Provisioning** consists of creating the physical or virtual resources that the cluster will run on (ips, instances, persistent disks). Provisioning will be implemented per cloud provider. There will be an implementation of GCE/AWS/Azure provisiong that utilizes [Terraform](https://www.terraform.io/). This phase takes the cluster configuration object as input.
  2. **Bootstrapping** consists of on host installation and configuration. This process will install Docker and a single init unit for the kubelet which will run in a Docker container and will place configuration files for master component static pods. The input to bootstrap will be the cluster configuration object along with the ip address of the master and a tarball of cryptographic assets that are output by phase 1. This step will be implemented by running [Ansible](http://docs.ansible.com/) in a Docker container that bootstraps the host over a chroot and will ideally be implemented once for all deployment targets (with sufficient configuration parameters).

Phase 1 should be sufficiently decoupled from phase 2 such that phase 2 could be used with minimal modification on deployment targets that don't have a phase 1 implemented for them (e.g. baremetal).

At the end of these two phases:
  * The master will be running a kubelet in a Docker container and (apiserver, controller-manager, scheduler, etcd and addon-manager) in static pods.
  * The nodes will be running a kubelet in a Docker container that is registered securely to the apiserver using tls client key auth.

Deployment of fluentd, kube-proxy will happen with DaemonSets after this process through the addon manager. Deployment of heapster, kube-dns, all other addons will happen after this process through the addon manager.

There should be a reasonably portable default networking configuration. For this default: node connectivity will be configured during provisioning and pod connectivity will be configured during bootstrapping. Pod connectivity will (likely) use flannel and the kubelet cni network plugin. The pod networking configuration should be sufficiently decoupled from the rest of the bootstrapping configuration so that it can be swapped with minimal modification for other pod networking implementations.

### Transparency

What does transparency mean in this context? Transparency means that with little effort a person unfamiliar with Kubernetes deployment can quickly understand deployment by referencing the deployment automation.

Why is transparency important? There is a massive set of deployment targets. It is unfeasible to try to implement a solution that works well for all targets. By creating a transparent deployment, we enable users to easily port Kubernetes to the environments that matter to them.

How do we make this transparent? We can do this by using well documented and popular **declarative** configuration tools like Terraform and Ansible. The configuration should be as **concise** as possible. The configuration should be **minimal** and offload as much management as possible to Kubernetes objects (static pods, deployments, daemonsets, configmaps). We should also disallow excessive conditional branching and cyclomatic complexity in configuration parmeterization.

Taking kube-up as a conterexample (it's the antithesis of transparency): to understand the provisioning phase, a new user must trace through thousands of lines of imperative bash code. To understand the bootstrapping phase, a new user must read terribly complex salt configuration (look how many if branches are in this config [file](https://github.com/kubernetes/kubernetes/blob/master/cluster/saltbase/salt/docker/init.sls)!).

The initial implementation should value transparency over production worthiness.
