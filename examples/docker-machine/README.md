```
git clone https://github.com/weaveworks/weave-kubernetes-anywhere
cd examples/docker-machine
```

Make sure you have Docker Toolbox v1.10 (or later) installed.

## Create the cluster

This is as simple as:
```
./create-cluster.sh
```

> **Please note** the default driver is current `virtualbox`, so if you wish to
> use a different driver you need to set `DOCKER_MACHINE_DRIVER` accordingly.
> Please see below for more information about drivers.


Once done, you need to login to either of `kube-[4-7]` with `docker-machine ssh`,
e.g. `docker-machine ssh kube-5` and run the following commands.

```
eval $(weave env)
docker run --interactive --tty --volumes-from=kube-toolbox-pki \
  weaveworks/kubernetes-anywhere:toolbox-v1.2
```

> **Please note** this example has TLS enabled, see `create-cluster.sh` for more details.

Inside this container you can check that there 3 nodes ready to take workload on board:
```
kubectl get nodes
```

And now you can deploy the guestbook app:
```
kubectl create -f guestbook-example-NodePort
```

You will need to note the port number allocated for the app and then you can hit it in
your browser via any of the node IPs (`docker-machine ip kube-5 kube-6 kube-7`).

## Supported Drivers

This code has been tested with VMWare Fusion and DigitalOcean drivers.

> VMWare vSphere and Microsoft Hyper-V drivers should probably work out of the box.
> Public cloud provider drivers vary a lot more and require additonal setup steps,
> e.g. Amazon EC2 driver needs VPC pre-configured and probably won't work with
> Kubernetes cloud provider for AWS, as that deppends on certainer tagging scheme on
> all of the resources... Anyhow, we do provide separate examples for EC2 and GCE.

### DigitalOcean

It should be suffiencent to
```
export DOCKER_MACHINE_DRIVER=digitalocean
export DIGITALOCEAN_ACCESS_TOKEN=<...>
```
and then run `./create-cluster.sh`.

### VMWare Fusion

If you have VMWare Fusion installed on your machine, you might care to
```
export DOCKER_MACHINE_DRIVER=vmwarefusion
```
prior to running `./create-cluster.sh`, as it's a bit quicker then VirtualBox.
