# Example: Google Compute Engine

Although deploying Kubernetes to Google Compute Engine (GCE) may appear simple on the surface, if you or organization have specific requirements, and you need to modify the basic deployment, it can be quite difficult and complex to comprehend. 

However, with Kubernetes Anywhere, customizing a Kubernetes cluster deployment is significantly simplified, and enables you to deploy clusters to GCE in just a few steps.

Kubernetes Anywhere makes use of the underlying technology in Weave Net and uses it as both a management and a container network to deploy Dockerized cluster components. The result is a portable and simple way to configure and manage clusters onto any cloud provider.

###Before You Begin

You will need to download the code:

```
git clone https://github.com/weaveworks/weave-kubernetes-anywhere
cd examples/google-compute-engine
```
Create an account with Google Cloud Engine and then specify a default project and zone.

>>Note: If you didn't set up a default project and  you can run `gcloud init` to authenticate your profile with Google Cloud SDK from the command line before running `create-cluster.sh`.

## Create the Cluster

This is as simple as running:

```
./create-cluster.sh
```

Once the script has finished, log on to any of the instances on GCE and run the following commands.

Check that all of the nodes are attached to Weave Net using:

```
sudo weave status
```

There should be 7 peers with 42 connections.

Next, ensure that entries have been added to `weavedns` by running:

 ```
 weave status dns`
 ```

The `weave status dns` should return `etcd1`, `etcd2`, `etcd3`, `kube-apiserver`, `kube-controller-manager` and `kube-scheduler` as well as additional records for each of the instances.

The instances for the cluster were created using: [`weave expose -h $(hostname).weave.local`][weave_expose]

[weave_expose]: https://github.com/weaveworks/weave-kubernetes-anywhere/blob/1b6b29fc17d11a66007b572b5ee1d57677515c26/examples/google-compute-engine/provision.sh#L43

With the cluster deployed and running, you are ready to launch the tools container in interactive mode:

```
$ sudo -s
# eval $(weave env)
# docker run -ti weaveworks/kubernetes-anywhere:tools
```

Ensure that there are three nodes ready to accept the workload:

```
kubectl get nodes
```

Then, create the SkyDNS addon:

```
kubectl create -f skydns-addon
```

And now you can deploy the guestbook app:

```
kubectl create -f guestbook-example-LoadBalancer
```

Run `kubectl get services --watch` and make a note of the external IP for the sample guestbook app. You can use this IP to launch the app into a browser.

## Visibility, Monitoring and Control with Weave Scope

With everything up and running, visualize your Kubernetes setup using Weave Scope. Launch any of the instance IP's using port 4040 into the browser.


###Further Reading

 * [Kubernetes Anywhere](https://github.com/weaveworks/weave-kubernetes-anywhere/README.md)


