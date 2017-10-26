# Getting started on OpenStack

Prerequisites:
* docker which can be downloaded [here](https://docs.docker.com/engine/installation/)
* working OpenStack deployment with: Keystone v3, Nova and Neutron (with LBaaS v2)

Clone the kubernetes-anywhere repository.

```console
$ git clone https://github.com/kubernetes/kubernetes-anywhere.git
$ cd kubernetes-anywhere
```

Create an SSH key pair in the kubernetes-anywhere directory. Run:

```console
$ ssh-keygen -t rsa -f id_rsa
```

During configuration step, when asked for SSH key pair, set to /opt/kubernetes-anywhere/id_rsa.

Hop into deployment shell which includes all the tools you need to deploy a kubernetes-anywhere cluster. Run:

```console
$ make docker-dev
```

then run:

```console
$ make config
```

You will then be prompted for configuration values necessary to deploy a cluster. Fill complete the config wizard. Alternatively you can also run `make menuconfig`

then run:

```console
$ make deploy
```

which will deploy a kubernetes-anywhere cluster. Eventually, you will see a set of nodes when you run:

```console
$ kubectl --kubeconfig $(make -s kubeconfig-path) get nodes
```

It may take a couple minutes for the Kubernetes API to start responding to requests.

After you've had a great experience with Kubernetes, run:

```console
$ make destroy
```

to tear down your cluster.
