# Weaving Kubernetes Anywhere

Weave lets you run Kubernetes clusters anywhere without configuration changes.

Having deployed Kubernetes over Weave Net, you can rely 100% on cloud portability, thanks to Weave being an L2 network.

Additionally, thanks to Weave Run and how it [handles IP address allocation as well as DNS](http://weave.works/talks/crdt/slides.html#1) without requiring a persistant store, you can deploy etcd over Weave as well.

Now you can simply configure all of the cluster components to have fixed DNS names, all you should care about is how these services are distributed accross your compute instances, e.g. what is the size of etcd cluster and whether it is on a dedcicated machines with the right type of storage attached.

You no longer have to care about the IP address of the API server or any of those things.

# Try it!

## Local Docker host

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
docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools \
  compose -p kube up -d
```

View DNS records for Kubernetes cluster components
```
$ weave status dns
```

### Deploy the Kubernetes app

```
$ docker run -ti weaveworks/kubernetes-anywhere:tools bash -l

# kubectl get nodes
# kubectl create -f /skydns-addon/
# kubectl get pods,rc,services --all-namespaces
# kubectl get pods --all-namespaces --watch

# kubectl create -f /guestbook-example/
# kubectl get pods --watch
```

## Amazon EC2 Container Service

### Setup ECS cluster
```
./create-ecs-cluser.sh
./ecs-deploy-services.sh
./ecs-docker-ps.sh
```

### Login to an instance

```
> ssh_cloud -i weave-ecs-demo-key.pem ec2-user@XXX.compute-1.amazonaws.com
```

Setup Weave environment:
```
$ eval $(weave env)
```
View DNS records for Kubernetes cluster components
```
$ weave status dns
```

### Deploy the Kubernetes app

```
$ docker run -ti weaveworks/kubernetes-anywhere:tools bash -l

# kubectl get nodes
# kubectl create -f /skydns-addon/
# kubectl get pods,rc,services --all-namespaces
# kubectl scale --namespace=kube-system --replicas=3 rc kube-dns-v8
# kubectl get pods --all-namespaces --watch

# kubectl create -f /guestbook-example/
# kubectl get pods --watch
```

If you want to deploy something else, you can just pass a URL to your manifest like this:

```
# kubectl create -f https://example.com/guestbook.yaml
```

### Tear-down the ECS cluster

```
./ecs-remove-services.sh
./delete-ecs-cluster.sh
```
