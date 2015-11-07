### Setup
```
./create-ecs-cluser.sh
./ecs-deploy-services.sh

```

### Kubernetes
```
> ssh_cloud -i weave-ecs-demo-key.pem ec2-user@XXX.compute-1.amazonaws.com

$ eval `weave env`

$ docker run weaveworks/kubernetes-anywhere:tools kubectl get nodes

$ weave status dns
$ docker run -ti weaveworks/kubernetes-anywhere:tools  sh -l

# kubectl get nodes
# kubectl create -f /skydns-addon/
# kubectl get pods,rc,services --all-namespaces
# kubectl scale --namespace=kube-system --replicas=3 rc kube-dns-v8
# kubectl get pods --all-namespaces --watch

# kubectl get create -f /guestbook-example
# kubectl get pods --watch

... ## test it localy first, then forward the port to access it in the browser
```


### Cleanup

```
./ecs-remove-services.sh
./delete-ecs-cluster.sh
```
