# Running Kubernetes Anywhere

> ## TL;DR
>
> Make Kubernetes cluster super easy to set up with Weave Net. Pick your tools and your cloud,
> without the need to set it all up entirely from scratch. Deploy Weave Net first, then `docker run` cluster
> components, including etcd. Several fully-automated provisioning examples
> [are provided](#enough-said--go-try-it).

Kubernetes Anywhere uses Weave Net to dramatically simplify Kubernetes deployment — anywhere.
It is by far the easiest way to get started on a single machine and to subsequently scale-out
to any infrastructure. By using Weave Net as a cluster management/bootstrap network,
portability is ensured, and entire clusters can be move or cloned without you having to reconfigure
anything. Design the cluseter once, and deploy it anywhere. Provisioning of security certificates
is also fully transparent, and in-place cluster upgrades are easy, since everything is containerized.

Each of the cluster components gets a fixed DNS names, e.g. `kube-apiserver.weave.local`,
`etcd1.weave.local` ...etc. Having this enables you to focus on higher level problems, i.e. make
cluster bootstrap the responsibility of the network and put less weight on already complex provisioning
and management tools.

Because Weave Net manages its state without [the use of an external store][bryans-talk], you
can also deploy etcd with the help of Weave Net. An etcd cluster also benefits from the service
discovery that WeaveDNS provides, making etcd management easier.


[bryans-talk]: https://www.youtube.com/watch?v=117gWVShcGU

# What is it made of?

We are currently shipping discrete containers (no self-hosting). You will find up-to-date images on Docker
Hub under [`weaveworks/kubernetes-anywhere`][docker-hub]. You may wish to rebuild these containers yourself, if
you like, and you can consult [`build-and-push`][build-and-publish] script if you really would like to do so.

These images are based on upstream `gcr.io/google_containers/hyperkube` and incorporate thin shell scripts that
pass correct arguments to each of the components. You may wish to explore [`docker-images`][docker-images]
directory, if you wish to know what goes in exactly.

Images are tagged with component name and version. If you pull `weaveworks/kubernetes-anywhere:apiserver-v1.2`,
you will get the latest build of `v1.2.x`, so upgrading your cluster to patch releases is very easy.
However, if you don't like this, there are tags for patch releases also. We may update any of the versioned
images without changing the version of Kubernetes base image, but you can use Docker's new content hashes,
if you feel uncertain/paranoid.

## Feature Summary

  - **Fully-containerized cluster deployment**
  - **Tested and up-to-date images on Docker Hub**
  - **Provision and manage certificate as data containers**
  - **Upgrade the cluster components without re-provisioning**
  - **Easy to adopt in any environment**

![Travis CI](https://img.shields.io/travis/weaveworks/kubernetes-anywhere.svg?style=flat-square)

[docker-hub]: https://hub.docker.com/r/weaveworks/kubernetes-anywhere/tags/
[docker-images]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/docker-images
[build-and-publish]: https://github.com/weaveworks/weave-kubernetes-anywhere/blob/master/build-and-push

# Enough said — Go, try it!

All you need is one or more Docker hosts.

## Single Node Example (Using Docker Compose)

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
$ docker run --rm -ti -v /:/rootfs -v /var/run/weave/weave.sock:/docker.sock weaveworks/kubernetes-anywhere:toolbox
# setup-kubelet-volumes
# compose -p kube pull
# compose -p kube up -d
# exit
```

> **If you are seeing the following error**
> ```
> ERROR: Cannot start container 86fbeefafb7bce30dd3b6dfbe5bd9c7c1d15ccb4cc02140ba01e3fc8b78def29: Path /var/lib/kubelet is mounted on / but it is not a shared mount.
> ```
> You will need to modify `docker.service` systemd unit and commend out `MountFlags=slave` (, then restart the unit.
> One way to do this is vy running the following commands:
> ```
> sudo sed 's/\(MountFlags=slave\)/# \1/' -i /etc/systemd/system/docker.service
> sudo systemctl daemon-reload
> sudo systemctl restart docker
>```

View DNS records for Kubernetes cluster components

```
$ weave status dns
```

### Deploying the Guestbook App

```
$ docker run --rm -ti weaveworks/kubernetes-anywhere:toolbox

# kubectl get nodes
# kubectl create -f skydns-addon
# kubectl get pods,rc,services --all-namespaces
# kubectl get pods --all-namespaces --watch

# kubectl create -f guestbook-example-NodePort
# kubectl get pods --watch
```

## Full-blown Cluster Example (Using Terraform in EC2)

Instantiate the module like this:

```HCL
module "kubernetes-anywhere-aws-ec2" {
    source         = "github.com/weaveworks/weave-kubernetes-anywhere/examples/aws-ec2-terraform"
    aws_access_key = "${var.aws_access_key}"
    aws_secret_key = "${var.aws_secret_key}"
    aws_region     = "us-east-1" # currently the only supported region as it uses ECR

    cluster                = "weave1"
    cluster_config_flavour = "secure" # or simple, if you don't need TLS

    # You can also set instance types with node_instance_type/master_instance_type/etcd_instance_type
    # For SSH access, you will need to create a key named kubernetes-anywhere or set ec2_key_name
}
```

Now, run Terraform:
```
terraform get
terraform apply # it may error, simply re-run if it did
```

This will create a cluster of 7 EC2 instances in a VPC. This cluster will have 3 etcd nodes,
one master and 3 workers.  All resources will be tagged `KubernetesCluster=weave1`.
The module code can be found in [`examples/aws-ec2-terraform`][aws-ec2-terraform].

Once instances are up, you can login to any of the 3 worker nodes or the master and run
`kubernetes-anywhere-toolbox`, and run `kubectl` from there. You can also use `curl` or `git`, or
install anything else with `yum`. If you login with agent forwarding enabled (`ssh -A`), toolbox
will pick it up, so you can clone your private repo!

Besides all the usual things, such as VPC and ASG, this example features an EC2 Container Registry
for storing [PKI container images](#containerized-provisioning-of-certificates--way-easier-then-ever).

## Launching a Multi-node Cluster (A General How-To)

For a more realistic setup, for example, deploying a cluster of 5 servers in a configuration similar to:

  - 3 dedicated etcd hosts (`$KUBE_ETCD_1`, `$KUBE_ETCD_2`, `$KUBE_ETCD_3`)
  - 1 host running all master components (`$KUBE_MASTER_0`)
  - 2 worker nodes (`$KUBE_WORKER_1`, `$KUBE_WORKER_2`)

As you will see, if you were to modify the cluster topology, no configuration changes are required. You can run these component
containers on different hosts, and then turn your attention to the number of hosts there are and where your containers are running.

You could also run Kubernetes Anywhere using whatever provisioning automation tools you prefer (Ansible, Terraform, Fleet or Swarm).

Provided that you have a recent version of Docker running (1.10 or later) on each of the hosts, you will install and launch Weave Net first:

```Shell
sudo curl --location --silent git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
```

Next, you will need to launch the Weave Net router.

> **Please note** Weave Net ports must be open on the hosts to which you are deploying. These are the _control port (TCP 6783)_ and _data ports (UDP 6783/6784)_.

If you know the hostnames or the IPs of all the servers in your cluster, you can run the following to launch Weave Net router on to each of the servers:

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

>> **Important** For the Kubernetes integration to function properly, it is critical that you pass the `--rewrite-inspect` flag when launching the Weave Docker API Proxy.

Finally, expose the overlay network to the host and add a DNS record for it in `weave.local` zone:

```Shell
weave expose -h "$(hostname).weave.local"
```

Before launching any containers you must first point the Docker client to the Weave proxy socket by setting `$DOCKER_HOST` environment variable:
```Shell
eval $(weave env)
```

The above can be wrapped in a convenient provisioning script. You can find examples of provisioning scripts for different cloud providers described in [Further Examples](#further-examples).

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

On `$KUBE_WORKER_1` & `$KUBE_WORKER_2`, start the kubelet and the proxy:

```
docker run \
      --volume="/:/rootfs" \
      --volume="/var/run/docker.sock:/docker.sock" \
      weaveworks/kubernetes-anywhere:toolbox \
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

There is a toolbox container you can run on any of the hosts in the cluster, inside the toolbox you will find `kubectl` preconfigured to use `kube-apiserver.weave.local`.

Start the toolbox container in interactive mode:

```
$ docker run -ti weaveworks/kubernetes-anywhere:toolbox
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

> **Please Note** You can also run the toolbox container via a remote management node, without accessing the machines directly. This can be a part of your CI/CD setup or even just a VM on your laptop, provided it can reach Weave Net ports on your cluster.

## Containerized Provisioning of Certificates — way easier then ever!

Kubernetes Anywhere uses containerized Public Key Infrastructure (PKI) to enable configuration for the cluster
components. Thanks to WeaveDNS we can create a certificate for the fixed `kube-apiserver.weave.local` domain name.

One way to distribute the certificates and configuration files for all the components is via containers.

If one assumes that their registry is a secure place, TLS configuration can be done transparently.

First run [a helper script](https://github.com/weaveworks/weave-kubernetes-anywhere/blob/master/docker-images/toolbox/scripts/create-pki-containers) bundled in `weaveworks/kubernetes-anywhere:toolbox`:

```
docker run -v /var/run/docker.sock:/docker.sock weaveworks/kubernetes-anywhere:toolbox create-pki-containers
```

which results in a number of containers tagged `kubernetes-anywhere:<component>-pki`, for example:

```
REPOSITORY               TAG                      IMAGE ID        CREATED         VIRTUAL SIZE
kubernetes-anywhere      toolbox-pki              9f29f12d2462    9 minutes ago   4.796 MB
kubernetes-anywhere      scheduler-pki            7a6b45807c48    9 minutes ago   4.796 MB
kubernetes-anywhere      controller-manager-pki   cb0dd7c10ba7    9 minutes ago   4.797 MB
kubernetes-anywhere      kubelet-pki              f80fcff78a37    9 minutes ago   4.796 MB
kubernetes-anywhere      proxy-pki                073305ee4bef    9 minutes ago   4.796 MB
kubernetes-anywhere      apiserver-pki            3b7f44eb2fc2    9 minutes ago   4.802 MB
```

Next, push these images to the Docker Hub or a private registry and use the volumes these images export.

### API Server
```
docker run --name=kube-apiserver-pki kubernetes-anywhere:apiserver-pki
docker run -d --name=kube-apiserver --volumes-from=kube-apiserver-pki weaveworks/kubernetes-anywhere:apiserver
```

> **Don't forget** to pass `-e ETCD_CLUSTER_SIZE=<N>` as intended.

### Kubelet
```
docker run -v /:/rootfs -v /var/run/docker.sock:/docker.sock weaveworks/kubernetes-anywhere:toolbox setup-kubelet-volumes
docker run --name=kubelet-pki kubernetes-anywhere:kubelet-pki
docker run -d --name=kubelet  --privileged=true --net=host --pid=host --volumes-from=kubelet-volumes --volumes-from=kubelet-pki weaveworks/kubernetes-anywhere:kubelet
```
### Proxy
```
docker run --name=kube-proxy-pki kubernetes-anywhere:proxy-pki
docker run -d --name=kube-proxy  --privileged=true --net=host --pid=host --volumes-from=kube-proxy-pki weaveworks/kubernetes-anywhere:proxy
```
### Controller Manager
```
docker run --name=kube-controller-manager-pki kubernetes-anywhere:controller-manager-pki
docker run -d --name=kube-controller-manager --volumes-from=kube-controller-manager-pki weaveworks/kubernetes-anywhere:controller-manager
```
### Scheduler
```
docker run --name=kube-scheduler-pki kubernetes-anywhere:scheduler-pki
docker run -d --name=kube-scheduler --volumes-from=kube-scheduler-pki weaveworks/kubernetes-anywhere:scheduler
```
### Toolbox
```
docker run --name=kube-toolbox-pki kubernetes-anywhere:toolbox-pki
docker run --interactive --tty --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox
```

Setting up SkyDNS requires a different version of the manifest, which is provided in toolbox container. You can use it like this:

```
# kubectl create -f kube-system-namespace.yaml
namespace "kube-system" created
# kubectl create -f skydns-addon-secure
replicationcontroller "kube-dns-v10" created
service "kube-dns" created
```

## Further Examples

The goal of this project is to illustrate how Kubernetes clusters can be deployed into different environments.
There are several examples provided in order to accomplish this.

  - [**Amazon EC2 (with Terraform, using Ubuntu, TLS enabled)**][aws-ec2-terraform]
  - [**Google Compute Engine (with `glcoud` CLI, using Debian)**][google-compute-engine]
  - [**Docker Machine (with TLS)**][docker-machine]

These examples are designed to be easy to adopt and therefore are kept simple. Your production requirements may vary,
catering for all would make these examples too complex.

[aws-ec2-terraform]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/aws-ec2-terraform
[google-compute-engine]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/google-compute-engine
[docker-machine]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/examples/docker-machine
[docker-images]: https://github.com/weaveworks/weave-kubernetes-anywhere/tree/master/docker-images
[docker-hub]: https://hub.docker.com/r/weaveworks/kubernetes-anywhere/tags/

