# Kubernetes Anywhere

*{concise,reliable,cross-platform} turnup of Kubernetes clusters*

### Goals and Motivation

Learning how to deploy Kubernetes is hard because the default deployment automation [`cluster/kube-up.sh`](https://github.com/kubernetes/kubernetes/blob/master/cluster/kube-up.sh) is opaque. We can do better, and by doing better we enable users to run Kubernetes in more places.

This implementation will be considered successful if it:
  * is portable across many deployment targets (e.g. at least GCE/AWS/Azure)
  * allows for an easy and reliable first experience with running multinode Kubernetes in the cloud
  * is transparent (the opposite of opaque) and can be used as a reference when creating deployments to new targets

### Getting Started

If you want to deploy a cluster to kick the tires of Kubernetes, checkout one of the getting started guides for your preferred supported deployment target.

  * [Get started on Google Compute Engine](phase1/gce/README.md)
  * [Get started on Azure](phase1/azure/README.md)

### Diving Deeper

If you want to understand, read further about the design and implementation then dive into the code.

### Deployment Design:

The input of the deployment is a cluster configuration object, specified as JSON object. We use Kconfig to describe the structure of this object and add configuration parameters. You may notice that scattered around this repository, there are Kconfig files that define configuration parameters. Running `make config .config.json` executes the configuration wizard and produces a file in the root of the repository, `.config.json` which stores this config object.

The deployment consists of three phases (not including generating the config object), provisioning, bootstrap and addon deployment:

1. **Resource Provisioning**
2. **Node Bootstrap**
3. **Addon Deployment**

#### Phase 1: Resource Provisioning

Provisioning consists of creating the physical or virtual resources that the cluster will run on (ips, instances, persistent disks). Provisioning will be implemented per cloud provider. There will be an implementation of GCE/AWS/Azure provisioning that utilizes [Terraform](https://www.terraform.io/). This phase takes the cluster configuration object as input.

#### Phase 2: Node Bootstrap

Bootstrapping consists of on host installation and configuration. This process installs Docker and a single init unit for the kubelet running in a Docker container. On the master, it also places configuration files for master component [static pods](http://kubernetes.io/docs/admin/static-pods/) into the kubelet manifest directory, thus starting the control-plane.

The input to bootstrap phase is the cluster configuration object along with a small amount of other information (e.g. ip address of the master, cryptographic assets) that are output by phase 1. This step is currently implemented with a minimal [Ignition](https://coreos.com/ignition/docs/latest) configuration that runs in a Docker container that bootstraps the host over a chroot. This phase will ideally be implemented once for all deployment targets (with sufficient configuration parameters).

#### Phase 3: Deploying Cluster Addons

Addon deployment consists of deploying onto the Kubernetes cluster all the applications that make Kubernetes run. Examples of these apps are kube-dns, heapster monitoring, kube-proxy, a SDN node agent if they deployment calls for one. These applications are managed with kubctl apply and can be deployed and managed with a single command.

#### Tying it all together

Phase 1 should be sufficiently decoupled from phase 2 such that phase 2 could be used with minimal modification on deployment targets that don't have a phase 1 implemented for them (e.g. baremetal).

At the end of these two phases:
  * The master will be running a kubelet in a Docker container and (apiserver, controller-manager, scheduler, etcd and addon-manager) in static pods.
  * The nodes will be running a kubelet in a Docker container that is registered securely to the apiserver using TLS client key auth.

Deployment of fluentd, kube-proxy will happen with DaemonSets after this process through the addon manager. Deployment of heapster, kube-dns, all other addons will happen after this process through the addon manager.

There should be a reasonably portable default networking configuration. For this default: node connectivity will be configured during provisioning and pod connectivity will be configured during bootstrapping. Pod connectivity will (likely) use flannel and the kubelet cni network plugin. The pod networking configuration should be sufficiently decoupled from the rest of the bootstrapping configuration so that it can be swapped with minimal modification for other pod networking implementations.
