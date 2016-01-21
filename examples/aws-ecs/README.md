## Kubernetes on Amazon EC2 Container Service (ECS)

Running Kubernetes on ECS might seeem odd at first, however it provides the user with a very simple way of ensuring that master components are running all the time, without requiring additional layers of monitoring infrastructure. If either `kube-scheduler` or `kube-controller-manager` go down, ECS will make sure they get restarted and the user doesn't have to care about this and avoid running extra moving parts, i.e. the so-called [`podmaster` and another etcd cluster it brings with it](http://kubernetes.io/v1.1/docs/proposals/high-availability.html). ALthough, the `podmaster` is to be depricated with v1.2, you still need to make sure that certain number of spare cluster component instances are running. Also, do bear in mind that ECS is completely free, you would only pay of EC2 usage.

## Try it out!

### Setup ECS cluster
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

## Some important notes about limitations etc

Please do note that this is an experiment part of the Kubernetes Anywhere project, it needs some more testing before this notice can be removed.

Currently ECS doesn't support `--pid=host` and `--pid=host` (aws/amazon-ecs-agent#185), and the default scheduler doesn't provides a sane way to launch a task on each instance, thereby the `kubelet` and `kube-proxy` are launched directly on all intances.

The `ecs-cli` binary (compiled for OS X) has been checked-in, as at the time the master branch had the certain features that had not been released, you might want to try latest version... The `ecs-cli` is used for it's `docker-compose.yml` compatibility, however this should probably be all done via CloudFormation (see #10).
