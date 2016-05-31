# Example: Google Compute Engine

Setting up a cluster in Google Compute Engine (GCE) might seem trivial at first, however
if youtry to understand how it works exactly, if not that easy to read. This example is
aimed to demonstrate how to deploy Kubernetes in GCE through a smallest number of steps.

Being part of Kubernetes Anywhere project, this example will utilise Wevae Net as management
and apps network and all-Dockerized cluster components, thereby making it more portable
and much easier to setup and operate.

You will need to dowload the code first:
```
git clone https://github.com/weaveworks/weave-kubernetes-anywhere
cd phase1/google-compute-engine
```

Make sure you have default project and zone setup, you can run `gcloud init` to do this.

## Create the cluster

This is as simple as:
```
./create-cluster.sh
```

Once done, you can either go to the console or use your terminal. You need to login to
_any_ of the instances and run the following commands.

First, you might like to check all nodes are on Weave Net. You can use `sudo weave status`
for this and see if there 7 peers. You can also run `weave status dns` to see all the DNS
records there are, the output should have `etcd1`, `etcd2`, `etcd3`, `kube-apiserver`,
`kube-controller-manager` and `kube-scheduler` along with some records for each of the
instances, which were created via [`weave expose -h $(hostname).weave.local`][weave_expose].

[weave_expose]: https://github.com/weaveworks/weave-kubernetes-anywhere/blob/1b6b29fc17d11a66007b572b5ee1d57677515c26/examples/google-compute-engine/provision.sh#L43

Next you will need to fire-up the toolbox container like this:
```
$ sudo -s
# eval $(weave env)
# docker run -ti weaveworks/kubernetes-anywhere:toolbox-v1.2
```

Inside this container you can check that there 3 nodes ready to take workload on board:
```
kubectl get nodes
```

First, deploy cluster addons:
```
kubectl create -f addons-no-pki.yaml
```

And now you can deploy the guestbook app:
```
kubectl create -f guestbook-example-LoadBalancer
```

Run `kubectl get services --watch` and grab the external IP once it's shown.

## Visibility, Monitoring and Control with Weave Scope

You can find Weave Scope UI on port 4040 on any of the instances.
