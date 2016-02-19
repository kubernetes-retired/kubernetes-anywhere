# Example: Google Compute Engine

Although Google Compute Engine (GCE) may appear simple on the surface, configuring clusters is not a trivial task. With Kubernetes Anywhere, this learning curve is significantly shortened, enabling you to deploy clusters in GCE in just a few steps.

Kubernetes Anywhere makes use of the underlying technology in Weave Net and uses it as both a management and an apps network to deploy Dockerized cluster components. The result is a portable and simple way to configure and manage clusters onto any cloud provider.

###Before You Begin

You will need to download the code:

```
git clone https://github.com/weaveworks/weave-kubernetes-anywhere
cd examples/google-compute-engine
```
Create an account with Google Cloud Engine and specify a default project and zone.

>>Note: If you didn't set up a default project and  you can run `gcloud init` to authenticate your profile with Google Cloud SDK from the command line before running `create-cluster.sh`.

## Create the Cluster

This is as simple as running:

```
./create-cluster.sh
```

Once the script is finished, log on to any of the instances on GCE and run the following commands.

First, check that all of the nodes are attached to `Weave Net`:

```
sudo weave status
```

There should be 7 peers with 42 connections.

Next check the status of the `weavedns` entries by running:

 ```
 weave status dns`
 ```

Ensure that all DNS records have been captured. The output should have `etcd1`, `etcd2`, `etcd3`, `kube-apiserver`, `kube-controller-manager` and `kube-scheduler` as well as additional records for each of the instances.

The instances were created using the `Weave Net` command, [`weave expose -h $(hostname).weave.local`][weave_expose]

[weave_expose]: https://github.com/weaveworks/weave-kubernetes-anywhere/blob/1b6b29fc17d11a66007b572b5ee1d57677515c26/examples/google-compute-engine/provision.sh#L43

With the cluster deployed and running, you are now ready to launch the tools container in interactive mode:

```
$ sudo -s
# eval $(weave env)
# docker run -ti weaveworks/kubernetes-anywhere:tools
```

Ensure that 3 nodes are ready to accept the workload:

```
kubectl get nodes
```

Create the SkyDNS addon:

```
kubectl create -f skydns-addon
```

And now you are ready to deploy the guestbook app:

```
kubectl create -f guestbook-example-LoadBalancer
```

Run `kubectl get services --watch` and make a note of the external IP for the sample guestbook app. You can use this IP to launch the app into a browser.

## Visibility, Monitoring and Control with Weave Scope

With everything up and running, visualize your Kubernetes setup using Weave Scope. Launch any of the instance IP's using port 4040 into the browser.

###Further Reading

 * [Kubernetes Anywhere](https://github.com/weaveworks/weave-kubernetes-anywhere/README.md)


