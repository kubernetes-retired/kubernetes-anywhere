# Running Kubernetes Anywhere

This project uses Weave to dramatically simplify Kubernetes deployment - anywhere. It is by far the easiest way to get started on a single machine, and later scale-out to any infrastructure seamlessly. We use Weave Net as a cluster management network. This enables complete portability, and for example allows one to move or clone the entire cluster. Even TLS setup is fully transparent.

Additionally, thanks to how [Weave Net handles IP address allocation as well as DNS](https://www.youtube.com/watch?v=117gWVShcGU) without requiring a persistant store, you can deploy etcd over Weave Net as well. The etcd cluster can thereby benefit from simple service discovery WeaveDNS provides and therefor facilitate node replacement without config changes.

Now you can simply configure all of the cluster components to have fixed DNS names, all you should care about is how these services are distributed accross your compute instances, e.g. what is the size of etcd cluster and whether it is on a dedcicated machines with the right type of storage attached.

You no longer have to care about the IP address of the API server or any of those things.

# Try it!

All you need is one or more Docker hosts.

## Get started using a single Docker host

### Launch Weave

```
sudo curl --location --silent git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
weave launch-router
weave launch-proxy --rewrite-inspect
weave expose -h $(hostname).weave.local
eval $(weave env)
```

### Deploy Kubernetes services

```
$ docker run -ti -v /:/rootfs -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools bash -l
# setup-kubelet-volumes
# compose -p kube up -d
# exit
```

View DNS records for Kubernetes cluster components

```
$ weave status dns
```

### Deploy the Kubernetes app

```
$ docker run -ti weaveworks/kubernetes-anywhere:tools bash -l

# kubectl get nodes
# kubectl create -f skydns-addon
# kubectl get pods,rc,services --all-namespaces
# kubectl get pods --all-namespaces --watch

# kubectl create -f guestbook-example-NodePort
# kubectl get pods --watch
```

## A multi-node cluter

For a more realisitic setup, let's say you'd like to have a cluster of 5 servers like this:

  - 3 dedicated etcd hosts (`$KUBE_ETCD_1`, `$KUBE_ETCD_2`, `$KUBE_ETCD_3`)
  - 1 host running all master components (`$KUBE_MASTER_0`)
  - 2 worker nodes (`$KUBE_WORKER_1`, `$KUBE_WORKER_2`)

As you will soon see, if you were to modify the cluster topology, it won't requite any configuration changes at all. You simply run containers on different hosts and only need to think about how many hosts are there and not what's running where exactly. You can potentially use any provisioning automation tools (Ansible, Terraform, Fleet or Swarm), but it's pretty simple to describe with automation aside.

Given a recent version of Docker is running on each of the hosts you have setup, let's install & launch Weave Net first.

```Shell
sudo curl --location --silent git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
```

Next, given `/usr/local/bin/` is in your shell's `$PATH`, you need to launch the Weave Net router.

> **Please note** that you will need to have Weave Net ports open on those hosts, which are the _control port (TCP 6783)_ and _data ports (UDP 6783/6784)_.

If you already know all hostnames/IPs of the servers in your cluster, you can run the following to launch Weave Net router on each of those servers:

```Shell
weave launch-router \
  $KUBE_ETCD_1 $KUBE_ETCD_2 $KUBE_ETCD_3 \
  $KUBE_MASTER_0 \
  $KUBE_WORKER_1 $KUBE_WORKER_2
```

If you only know some of the peer hostnames/IPs, you can launch Weave Net router like this:

```Shell
weave launch-router --init-peer-count 6 $KUBE_ETCD_1 $KUBE_MASTER_0 $KUBE_WORKER_1
```

or even

```Shell
weave launch-router --init-peer-count 6 $KUBE_MASTER_0
```

Otherwise, you could also run `weave connect` later, just make sure to pass `--init-peer-count` with a number of servers you are expecing to have in your cluster.

Next, you need to launch Weave proxy for the Docker API. It's crictical to pass `--rewrite-inspect` flag for Kubernetes integration to function properly.

```Shell
weave launch-proxy --rewrite-inspect
```

And finally, you need to expose the host on Weave Net and set a DNS record for it like so:

```Shell
weave expose -h "$(hostname).weave.local"
```

Before launching any containers you will also need to point Docker client to Weave proxy socket by setting `$DOCKER_HOST` like with the following command:
```Shell
eval $(weave env)
```

The above can be wrapped in a simple provisioning script which you will find below.

### Launch etcd cluster

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

### Launch master components

On `$KUBE_MASTER_0`, run:

```Shell
docker run -d -e ETCD_CLUSTER_SIZE=3 --name=kube-apiserver weaveworks/kubernetes-anywhere:apiserver
docker run -d --name=kube-controller-manager weaveworks/kubernetes-anywhere:controller-manager
docker run -d --name=kube-scheduler weaveworks/kubernetes-anywhere:scheduler
```

### Launch workers

On `$KUBE_WORKER_1` & `$KUBE_WORKER_2`, start kubelet and proxy like this:

```
docker run \
      --volume="/:/rootfs" \
      --volume="/var/run/weave/weave.sock:/weave.sock" \
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

### Provisioning is done, let's launch an app!

There is a tools container you can run on any of the hosts in the cluster that has `kubectl` preconfigured to use `kube-apiserver.weave.local`.

Here is how you can use this tools container.

Start it in interactive mode:

```
$ docker run -ti weaveworks/kubernetes-anywhere:tools
```

Check there is an expected number of worker nodes in the cluster:

```
# kubectl get nodes
```

Deploy SkyDNS addon and, if you like, scale it from default single replica to 3:

```
# kubectl create -f skydns-addon
# kubectl scale --namespace=kube-system --replicas=3 rc kube-dns-v10
```

Deploy Guestbook example app and wait for pods become ready

```
# kubectl create -f guestbook-example-NodePort
# kubectl get pods --watch
```

If you want to deploy something else, you can just pass a URL to your manifest like this:

```
# kubectl create -f https://example.com/app-controller.yaml
# kubectl create -f https://example.com/app-service.yaml
```

> Please note that that you can add a management node to run tools container, which may be part of your CI/CD setup or even just a VM on your laptop, given it can Weave Net ports on your cluster.

## Using TLS

> **Please note** that this currently requires Docker version 1.10, for the mount propagation feature.

Thanks to WeaveDNS we can create a certificate for fixed `kube-apiserver.weave.local` domain name.

One way to distribute the certificates and configuration files for all the components is via containers.

If one assumes that their registry is a secure place, TLS configuration can be done very transparently.

First run [a helper script](https://github.com/weaveworks/weave-kubernetes-anywhere/blob/master/docker-images/setup-secure-cluster-config-volumes.sh) shipped in the `weaveworks/kubernetes-anywhere:tools`:

```
docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools setup-secure-cluster-config-volumes
```

which results in a number of containers tagged `kubernetes-anywhere:<component>-secure-config`, e.g.

```
REPOSITORY               TAG                       IMAGE ID        CREATED         VIRTUAL SIZE
kubernetes-anywhere                  tools-secure-config                9f29f12d2462        9 minutes ago       4.796 MB
kubernetes-anywhere                  scheduler-secure-config            7a6b45807c48        9 minutes ago       4.796 MB
kubernetes-anywhere                  controller-manager-secure-config   cb0dd7c10ba7        9 minutes ago       4.797 MB
kubernetes-anywhere                  kubelet-secure-config              f80fcff78a37        9 minutes ago       4.796 MB
kubernetes-anywhere                  proxy-secure-config                073305ee4bef        9 minutes ago       4.796 MB
kubernetes-anywhere                  apiserver-secure-config            3b7f44eb2fc2        9 minutes ago       4.802 MB
```

Next, you can push these to the registry and use the volumes these images export like this

### API Server
```
docker run --name=kube-apiserver-secure-config kubernetes-anywhere:apiserver-secure-config
docker run -d --name=kube-apiserver --volumes-from=kube-apiserver-secure-config weaveworks/kubernetes-anywhere:apiserver
```

> **Don't forget** to pass `-e ETCD_CLUSTER_SIZE=<N>` as intended.

### Kubelet
```
docker run -v /:/rootfs -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools setup-kubelet-volumes
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

Setting up SkyDNS requires a different version of the manisfest, which had been provided in tools container, please use it like this:
```
# kubectl create -f kube-system-namespace.yaml
namespace "kube-system" created
# kubectl create -f skydns-addon-secure
replicationcontroller "kube-dns-v10" created
service "kube-dns" created
```

## Further Examples

The goal of this project is to illustrate how Kubernetes clusters can be deployed in different environments, and there
are a few complete examples provided in order to accomplish this.

  - [**Amazon EC2 (with Terraform, using Ubuntu)**][aws-ec2-terraform]
  - [**Google Compute Engine (with `glcoud` CLI, using Debian)**][google-compute-engine]
  - [**Docker Machine (with TLS)**][docker-machine]

These examples are design to be easy to adopt and thereby are kept simple. Cluster component images published in
`weaveworks/kubernetes-anywhere` are kept up-to-date, however there may be a good reason for the user to rebuild
these images and publish in their own registry, please see [`docker-images`][docker-images] directory for scripts
and `Dockerfile`s used to build the images.

[aws-ec2-terraform]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/aws-ec2-terraform
[google-compute-engine]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/google-compute-engine
[docker-machine]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/docker-machine
[docker-images]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/docker-images
