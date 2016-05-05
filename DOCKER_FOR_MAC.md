# Running Kubernetes on Docker for Mac

> **Q:** What's good about this approach?
>
> **A:** You can actually extend the cluster pretty easily, i.e. start single node on your laptop, add colleague's laptop as another node or even relocate your cluster to the cloud :)


## Boostrap

First, setup Weave Net:
```
sudo curl --silent --location git.io/weave --output /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave
weave launch
weave expose -h docker.weave.local
```

Next, bootstrap single-node local cluster with one command:
```
docker run --rm \
  --volume="/:/rootfs" \
  --volume="/var/run/weave/weave.sock:/docker.sock" \
    weaveworks/kubernetes-anywhere:toolbox-v1.2 \
      sh -c 'setup-single-node && compose -p kube up -d'
```

## Setup `kubectl`

Install `kubectl` command via Homebrew:
```
brew install kubectl
```

If you have installed it by some other means earlier, you should check if the version you have is at least v1.2.0,
otherwise some features may not work as expected.

If you have installed Google Cloud SDK (`gcloud`), you will have `kubectl`, just make sure to run `gcloud components update`.

To configure `kubectl` to use your newly created Docker for Mac cluster, you can run the following command:
```
mkdir -p ~/.kube
docker run --rm --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 print-apiproxy-config > ~/.kube/config
```

To confirm it worked, run `kubectl get nodes` and you should see one node called `docker` on the list, i.e.:

```
> kubectl get nodes
NAME      STATUS    AGE
docker    Ready     5m
```

If you already have `~/.kube/config` file and would like to keep it, you can simply create one in your current working
directory by redirecting standard output, i.e.:
```
docker run --rm --volumes-from=kube-toolbox-pki weaveworks/kubernetes-anywhere:toolbox-v1.2 print-apiproxy-config > ./local-cluster
```
To use that file you will need to pass `--kubeconfig=<path>` flag like this:
```
kubectl --kubeconfig=./local-cluster get nodes
```

If you don't wish to install anything, you can use provided toolbox container like this:
```
docker run --rm \
  --net=weave --dns=172.17.0.1 \
  --volumes-from=kube-toolbox-pki \
  weaveworks/kubernetes-anywhere:toolbox-v1.2 \
    kubectl [flags] [command]
```

## Create Cluster Addons

The cluster is empty right now. Most example apps reply on SkyDNS addon being present. You can setup all neccessary
addons (currently only SkyDNS) with one command:
```
kubectl create -f https://git.io/vw5Uc
```

## Deploy the Pixel Monsterz App

> **Q:** What's this app?
>
> **A:** [The Pixel Monsterz App](https://github.com/ThePixelMonsterzApp) is a fairly simple one and uses cool frameworks,
> Python/Flask and Node.js/Restify, as well as Redis. You might have seen an earlier version of this app, if you have read
> Adrian Mouat’s book “Using Docker”. This app was adapted from MonsterID, which generates unique avatars for signed up users
> (as seen on Github).

```
kubectl create -f https://raw.github.com/ThePixelMonsterzApp/infra/master/kubernetes-app.yaml
```

You can run `kubectl get pods --watch` to see pods being created. Once all pods are created, you should see output
similar to this:

```
> kubectl get pods
NAME                 READY     STATUS    RESTARTS   AGE
hello-d53og          1/1       Running   0          1m
hello-wis7n          1/1       Running   0          1m
monsterz-den-hu0af   1/1       Running   0          1m
monsterz-den-q4sp6   1/1       Running   0          1m
monsterz-den-t1wxe   1/1       Running   0          1m
redis-94stx          1/1       Running   0          1m
```

Now, you can load the app in your browser using proxied URL:
```
http://localhost:8001/api/v1/proxy/namespaces/default/services/hello:app/
```

If you reload the page a few times, you will see counter being incremented and different mosnters will show each time. The
monster shown at the very top belongs to a pod that serves it (`hello-*`), the other monster is pseudo-random. You can get a great variety of monsters by creating more
pods, i.e. scaling the replication controller.

```
kubectl scale rc hello --replicas=12
```

## Additional notes and TODOs

- [ ] How to expand the cluster?
- [ ] <strike>Explain how to use [`weave-osx-ctl`](https://github.com/pidster/weave-osx-ctl/)...</strike> _(broken as of beta9, thanks Apple)_

