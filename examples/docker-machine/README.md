```
git clone https://github.com/weaveworks/weave-kubernetes-anywhere
cd examples/docker-machine
```

Make sure you have Docker Toolbox v1.10 (or later) installed.

## Create the cluster

This is as simple as:
```
./create-cluster.sh
```

Once done, you need to login to _any_ of the instances with `docker-machine ssh`,
e.g. `docker-machine ssh kube-5` and run the following commands.

```
eval $(weave env)
docker run --name=kube-tools-secure-config kubernetes-anywhere:tools-secure-config
docker run --interactive --tty --volumes-from=kube-tools-secure-config \
  weaveworks/kubernetes-anywhere:tools bash -l
```

> **Please note** this example has TLS enabled, see `create-cluster.sh` for more details.

Inside this container you can check that there 3 nodes ready to take workload on board:
```
kubectl get nodes
```

And now you can deploy the guestbook app:
```
kubectl create -f guestbook-example-NodePort
```

You will need to note the port number allocated for the app and then you can hit it in
your browser via any of the node IPs (`docker-machine ip kube-5 kube-6 kube-7`).
