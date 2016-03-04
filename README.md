# Running Kubernetes Anywhere

Kubernetes Anywhere uses Weave Net to dramatically simplify Kubernetes deployment --anywhere. It is by far the easiest way to get started on a single machine and to subsequently scale-out to any infrastructure. By implementing Weave Net as a cluster management network, complete portability is ensured, allowing you to move or clone an entire cluster. Even setting up Transport Layer Security (TLS) is fully transparent.

Because [Weave Net handles IP allocation and DNS] (https://www.youtube.com/watch?v=117gWVShcGU) without the use of a persistent store, you can also deploy etcd with the help of Weave Net. An etcd cluster also benefits from the service discovery that WeaveDNS provides, and it simplifies node replacement by not requiring any configuration changes.

Once deployed, you can configure all of the cluster components to have fixed DNS names. This enables you to focus on how your services are distributed among your compute instances, for example: the size of the etcd cluster and whether it is on a dedicated machine with the correct type of storage attached.  Also by using Weave Net you will no longer have to allocate an IP address to the API server or to any other nodes.


# Try it!

All you need is one or more Docker hosts.


## Using Terraform in EC2

```HCL
module "kubernetes-anywhere-aws-ec2" {
    source         = "github.com/weaveworks/weave-kubernetes-anywhere/examples/aws-ec2-terraform"
    aws_access_key = "${var.aws_access_key}"
    aws_secret_key = "${var.aws_secret_key}"
    aws_region     = "us-east-1" # currently the only supported region as it uses ECR

    cluster                = "devx"
    cluster_config_flavour = "secure" # or simple, if you don't need TLS
    
    # You can also set instance types with node_instance_type/master_instance_type/etcd_instance_type
    # For SSH access, you will need to create a key named kubernetes-anywhere or set ec2_key_name
}
```

## Getting Started on a Single Docker Host

### Launching Weave

```
sudo curl --location --silent git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
weave launch-router
weave launch-proxy --rewrite-inspect
weave expose -h $(hostname).weave.local
eval $(weave env)
```

### Deploying the Kubernetes Services

```
$ docker run -ti -v /:/rootfs -v /var/run/weave/weave.sock:/docker.sock weaveworks/kubernetes-anywhere:tools bash -l
# setup-kubelet-volumes
# compose -p kube up -d
# exit
```

View DNS records for Kubernetes cluster components

```
$ weave status dns
```

### Deploying the Kubernetes App

```
$ docker run -ti weaveworks/kubernetes-anywhere:tools bash -l

# kubectl get nodes
# kubectl create -f skydns-addon
# kubectl get pods,rc,services --all-namespaces
# kubectl get pods --all-namespaces --watch

# kubectl create -f guestbook-example-NodePort
# kubectl get pods --watch
```

## Launching a Multi-node Cluster

For a more realisitic setup, for example, deploying a cluster of 5 servers in a configuration similar to:

  - 3 dedicated etcd hosts (`$KUBE_ETCD_1`, `$KUBE_ETCD_2`, `$KUBE_ETCD_3`)
  - 1 host running all master components (`$KUBE_MASTER_0`)
  - 2 worker nodes (`$KUBE_WORKER_1`, `$KUBE_WORKER_2`)

As you will see, if you were to modify the cluster topology, no configuration changes are required. You can run containers on different hosts and then turn your attention to the number of hosts there are and where your containers are running. 

You could also run Kubernetes Anywhere using whatever provisioning automation tools you prefer (Ansible, Terraform, Fleet or Swarm).

Provided that you have a recent version of Docker is running on each of the hosts, you will install and launch Weave Net first:

```Shell
sudo curl --location --silent git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
```

Next, provided that  `/usr/local/bin/` is in your shell's `$PATH`, you will need to launch the Weave Net router.

> **Please note** Weave Net ports must be open on the hosts to which you are deploying.  These are the _control port (TCP 6783)_ and _data ports (UDP 6783/6784)_.

If you know the hostnames or the IPs of the servers in your cluster, you can run the following to launch Weave Net router on to each of the servers:

```Shell
weave launch-router \
  $KUBE_ETCD_1 $KUBE_ETCD_2 $KUBE_ETCD_3 \
  $KUBE_MASTER_0 \
  $KUBE_WORKER_1 $KUBE_WORKER_2
```

If only some of the peer hostnames/IPs are known, launch the Weave Net router as follows:

```Shell
weave launch-router --init-peer-count 6 $KUBE_ETCD_1 $KUBE_MASTER_0 $KUBE_WORKER_1
```

or:

```Shell
weave launch-router --init-peer-count 6 $KUBE_MASTER_0
```

The number of servers in your cluster are passed to `weave launch` using `--init-peer-count`. At a later time, run `weave connect` to dynamically add the servers to your cluster.

In order to communicate with the Docker daemon and use standard Docker commands, launch Weave Docker API Proxy. 

```Shell
weave launch-proxy --rewrite-inspect
```

>>**Important** For the Kubernetes integration to function properly, it is crictical that you pass the `--rewrite-inspect` flag when launching the Weave Docker API Proxy.


Finally, expose the host network and then add a DNS record for it:

```Shell
weave expose -h "$(hostname).weave.local"
```

Before launching any containers you must first point the Docker client to the Weave proxy socket by setting `$DOCKER_HOST` environment variable:

```Shell
eval $(weave env)
```

The above can be wrapped in a convenient provisioning script. You can find examples of provisioning scripts for differnt cloud providers described in [Further Examples](#further-examples). 

### Launch the etcd Cluster

On `$KUBE_ETCD_1`, run:

```Shell
docker run -d -e ETCD_CLUSTER_SIZE=3 --name=etcd1 weaveworks/kubernetes-anywhere:etcd
```

On `$KUBE_ETCD_2`:

```Shell
docker run -d -e ETCD_CLUSTER_SIZE=3 --name=etcd2 weaveworks/kubernetes-anywhere:etcd
```

On `$KUBE_ETCD_3`:

```Shell
docker run -d -e ETCD_CLUSTER_SIZE=3 --name=etcd3 weaveworks/kubernetes-anywhere:etcd
```

### Launching the Master Components

On `$KUBE_MASTER_0`, run:

```Shell
docker run -d -e ETCD_CLUSTER_SIZE=3 --name=kube-apiserver weaveworks/kubernetes-anywhere:apiserver
docker run -d --name=kube-controller-manager weaveworks/kubernetes-anywhere:controller-manager
docker run -d --name=kube-scheduler weaveworks/kubernetes-anywhere:scheduler
```

### Launching the Workers

On `$KUBE_WORKER_1` & `$KUBE_WORKER_2`, start the kubelet and the kube proxy:

```
docker run \
      --volume="/:/rootfs" \
      --volume="/var/run/docker.sock:/docker.sock" \
      weaveworks/kubernetes-anywhere:tools \
      setup-kubelet-volumes
docker run -d \
      --name=kubelet \
      --privileged=true --net=host --pid=host \
      --volumes-from=kubelet-volumes \
      weaveworks/kubernetes-anywhere:kubelet
docker run -d \
      --name=kube-proxy \
      --privileged=true --net=host --pid=host \
      weaveworks/kubernetes-anywhere:proxy
```

### Provisioning is complete, let's launch an app!

There is a tools container you can run on any of the hosts in the cluster, which has `kubectl` preconfigured to use `kube-apiserver.weave.local`.

Start the tools container in interactive mode:

```
$ docker run -ti weaveworks/kubernetes-anywhere:tools
```

Check that there is the correct number of worker nodes in the cluster:

```
# kubectl get nodes
```

Deploy the SkyDNS addon and, if you like, scale it from default single replica to 3:

```
# kubectl create -f skydns-addon
# kubectl scale --namespace=kube-system --replicas=3 rc kube-dns-v10
```

Deploy Guestbook example app and wait until the pods are ready:

```
# kubectl create -f guestbook-example-NodePort
# kubectl get pods --watch
```

If you want to deploy another app, pass a URL to your manifest as follows:

```
# kubectl create -f https://example.com/app-controller.yaml
# kubectl create -f https://example.com/app-service.yaml
```

>> **Note:** You can also run the tools container by adding a management node. This can be a part of your CI/CD setup or even just a VM on your laptop, provided it can reach Weave Net ports on your cluster.

## Using TLS

> **Please note** that this currently requires Docker version 1.10, for the mount propagation feature.

Thanks to WeaveDNS we can create a certificate for a fixed `kube-apiserver.weave.local` domain name.

One way to distribute the certificates and configuration files for all the components is via containers.

If one assumes that their registry is a secure place, TLS configuration can be done transparently.

First run [a helper script](https://github.com/weaveworks/weave-kubernetes-anywhere/blob/master/docker-images/setup-secure-cluster-config-volumes.sh) bundled in `weaveworks/kubernetes-anywhere:tools`:

```
docker run -v /var/run/docker.sock:/docker.sock weaveworks/kubernetes-anywhere:tools setup-secure-cluster-config-volumes
```

which results in a number of containers tagged `kubernetes-anywhere:<component>-secure-config`, for example:

```
REPOSITORY               TAG                       IMAGE ID        CREATED         VIRTUAL SIZE
kubernetes-anywhere                  tools-secure-config                9f29f12d2462        9 minutes ago       4.796 MB
kubernetes-anywhere                  scheduler-secure-config            7a6b45807c48        9 minutes ago       4.796 MB
kubernetes-anywhere                  controller-manager-secure-config   cb0dd7c10ba7        9 minutes ago       4.797 MB
kubernetes-anywhere                  kubelet-secure-config              f80fcff78a37        9 minutes ago       4.796 MB
kubernetes-anywhere                  proxy-secure-config                073305ee4bef        9 minutes ago       4.796 MB
kubernetes-anywhere                  apiserver-secure-config            3b7f44eb2fc2        9 minutes ago       4.802 MB
```

Next, push these to images to the dockerhub registry and use the volumes these images export. 

### API Server
```
docker run --name=kube-apiserver-secure-config kubernetes-anywhere:apiserver-secure-config
docker run -d --name=kube-apiserver --volumes-from=kube-apiserver-secure-config weaveworks/kubernetes-anywhere:apiserver
```

> **Don't forget** to pass `-e ETCD_CLUSTER_SIZE=<N>` as intended.

### Kubelet
```
docker run -v /:/rootfs -v /var/run/docker.sock:/docker.sock weaveworks/kubernetes-anywhere:tools setup-kubelet-volumes
docker run --name=kubelet-secure-config kubernetes-anywhere:kubelet-secure-config
docker run -d --name=kubelet  --privileged=true --net=host --pid=host --volumes-from=kubelet-volumes --volumes-from=kubelet-secure-config weaveworks/kubernetes-anywhere:kubelet
```
### Proxy
```
docker run --name=kube-proxy-secure-config kubernetes-anywhere:proxy-secure-config
docker run -d --name=kube-proxy  --privileged=true --net=host --pid=host --volumes-from=kube-proxy-secure-config weaveworks/kubernetes-anywhere:proxy
```
### Controller Manager
```
docker run --name=kube-controller-manager-secure-config kubernetes-anywhere:controller-manager-secure-config
docker run -d --name=kube-controller-manager --volumes-from=kube-controller-manager-secure-config weaveworks/kubernetes-anywhere:controller-manager
```
### Scheduler
```
docker run --name=kube-scheduler-secure-config kubernetes-anywhere:scheduler-secure-config
docker run -d --name=kube-scheduler --volumes-from=kube-scheduler-secure-config weaveworks/kubernetes-anywhere:scheduler
```
### Tools
```
docker run --name=kube-tools-secure-config kubernetes-anywhere:tools-secure-config
docker run --interactive --tty --volumes-from=kube-tools-secure-config weaveworks/kubernetes-anywhere:tools bash -l
```

Setting up SkyDNS requires a different version of the manifest, which is provided in the tools container. You can use it like this:

```
# kubectl create -f kube-system-namespace.yaml
namespace "kube-system" created
# kubectl create -f skydns-addon-secure
replicationcontroller "kube-dns-v10" created
service "kube-dns" created
```

## Further Examples

The goal of this project is to illustrate how Kubernetes clusters can be deployed into different environments. There are several complete examples provided for you:

  - [**Amazon EC2 (with Terraform, using Ubuntu)**][aws-ec2-terraform]
  - [**Google Compute Engine (with `glcoud` CLI, using Debian)**][google-compute-engine]
  - [**Docker Machine (with TLS)**][docker-machine]

These examples are designed to be easy to adopt and therefor are kept simple. Cluster component images published in
[`weaveworks/kubernetes-anywhere`][docker-hub] are kept up-to-date, however there may be a good reason for the you to rebuild
these images and publish them to your own registry, please see [`docker-images`][docker-images] directory for the scripts
and the `Dockerfile`s used to build these images.

[aws-ec2-terraform]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/aws-ec2-terraform
[google-compute-engine]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/google-compute-engine
[docker-machine]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/docker-machine
[docker-images]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/docker-images
[docker-hub]: https://hub.docker.com/r/weaveworks/kubernetes-anywhere/tags/
