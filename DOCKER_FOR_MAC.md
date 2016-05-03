# Running Kubernetes on Docker for Mac

> **Q:** What's good about this approach?
>
> **A:** You can actually extend the cluster pretty easily, i.e. start single node on your laptop, add colleague's laptop as another node or even relocate your cluster to the cloud :)

First, setup Weave Net:
```
sudo curl --silent --location git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
weave launch
weave expose -h docker.weave.local
```

Next, bootstrap single-node local cluster with one command:
```
docker run \
  --volume="/:/rootfs" \
  --volume="/var/run/weave/weave.sock:/docker.sock" \
    weaveworks/kubernetes-anywhere:toolbox-v1.2 \
      sh -c 'setup-single-node && compose -p kube up -d'
```

Now you can use toolbox to interact with the cluster:
```
> docker run --net=weave --dns=172.17.0.1 --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 kubectl get nodes
weaveworks/kubernetes-anywhere:toolbox-v1.2
NAME      STATUS    AGE
docker    Ready     5m
```

## Start System Services

```
> docker run --net=weave --dns=172.17.0.1 --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 kubectl create -f kube-system-namespace.yaml
namespace "kube-system" created
> docker run --net=weave --dns=172.17.0.1 --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 kubectl create -f skydns-addon-secure-v1.2
replicationcontroller "kube-dns-v11" created
service "kube-dns" created
```

## Deploy the Guesbook App

```
> docker run --net=weave --dns=172.17.0.1 --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 kubectl create -f guestbook-example-NodePort
deployment "frontend" created
You have exposed your service on an external port on all nodes in your
cluster.  If you want to expose this service to the external internet, you may
need to set up firewall rules for the service port(s) (tcp:30512) to serve traffic.

See http://releases.k8s.io/release-1.2/docs/user-guide/services-firewalls.md for more details.
service "frontend" created
deployment "redis-master" created
service "redis-master" created
deployment "redis-slave" created
service "redis-slave" created
```

## Using `kubectl`

You can use toolbox container as show below, however in some cases it may be more convenient to use `kubectl` that you
hav installed on your Mac. You can install it via Homebrew (`brew install kubectl`), or via Google Cloud SDK.

To configure `kubectl`, you can run the following command:
```
docker run --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 print-apiproxy-config
```

You can redirect the output to a file, which you can pass with `--kubeconfig` flag:
```
docker run --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 print-apiproxy-config > ./local-cluster
kubectl --kubeconfig=./local-cluster get nodes
```

Otherwise, if you prefer, you can simply setup default configuration in `~/.kube/config`:
```
mkdir -p ~/.kube
docker run --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 print-apiproxy-config > ~/.kube/config
kubectl get nodes
```

## Additional notes and TODOs

- [ ] How to expand the cluster?
- [ ] <strike>Explain how to use [`weave-osx-ctl`](https://github.com/pidster/weave-osx-ctl/)...</strike> _(broken as of beta9, thanks Apple)_

