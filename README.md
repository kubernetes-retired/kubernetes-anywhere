# Weaving Kubernetes Anywhere

Weave lets you run Kubernetes clusters anywhere without configuration changes. It is by far the easiest way to get started on a single machine, and later scale-out to any infrastructure seemlestly.

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
# kubectl create -f /skydns-addon/
# kubectl get pods,rc,services --all-namespaces
# kubectl get pods --all-namespaces --watch

# kubectl create -f /guestbook-example/
# kubectl get pods --watch
```

## Amazon EC2 Container Service

### Setup ECS cluster
```
cd examples/aws-ecs/
./create-cluster.sh
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
./delete-cluster.sh
```

# Using TLS

Thanks to WeaveDNS we can create a certificate for fixed `kube-apiserver.weave.local` domain name.

One way to distribute the certificates and configuration files for all the components is via containers.

If one assumes that their registry is a secure place, TLS configuration be done very transparently.

First run [a helper script](https://github.com/weaveworks/weave-kubernetes-anywhere/blob/master/docker-images/setup-secure-cluster-conf-volumes.sh) shipped in the `weaveworks/kubernetes-anywhere:tools`:

```
docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools setup-secure-cluster-conf-volumes
```

which results in a number of containers tagged `kubernetes-anywhere:<component>-secure-config`, e.g.

```
REPOSITORY               TAG                       IMAGE ID        CREATED         VIRTUAL SIZE
kubernetes-anywhere      tools-secure-config       a93be2f313fd    9 minutes ago   4.796 MB
kubernetes-anywhere      proxy-secure-config       4120c5fce546    9 minutes ago   4.796 MB
kubernetes-anywhere      kubelet-secure-config     df9a758b5473    9 minutes ago   4.796 MB
kubernetes-anywhere      apiserver-secure-config   2ae2ce355f5c    9 minutes ago   4.802 MB
```

Next, you can push these to the registry and use the volumes these images export like this

## API Server
```
docker run --name=kube-apiserver-secure-config kubernetes-anywhere:apiserver-secure-config
docker run -d --name=kube-apiserver --volumes-from=kube-apiserver-secure-config weaveworks/kubernetes-anywhere:apiserver
```

## Kubelet
```
docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools setup-kubelet-volumes
docker run --name=kubelet-secure-config kubernetes-anywhere:kubelet-secure-config
docker run -d --name=kubelet  --privileged=true --net=host --pid=host --volumes-from=kubelet-volumes --volumes-from=kubelet-secure-config weaveworks/kubernetes-anywhere:kubelet
```

## Proxy
```
docker run --name=kube-proxy-secure-config kubernetes-anywhere:proxy-secure-config
docker run -d --name=kube-proxy  --privileged=true --net=host --pid=host --volumes-from=kube-proxy-secure-config weaveworks/kubernetes-anywhere:proxy
```

## Tools
```
docker run --name=kube-tools-secure-config kubernetes-anywhere:tools-secure-config
docker run --interactive --tty --volumes-from=kube-tools-secure-config weaveworks/kubernetes-anywhere:tools bash -l
```

