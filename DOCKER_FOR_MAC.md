# Running Kubernetes on Docker for Mac

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
      sh -c 'setup-kubelet-volumes && compose -p kube up -d'
```

Now you can use toolbox, try use toolbox to interact with the cluster:
```
> docker run --net=weave --dns=172.17.0.1 weaveworks/kubernetes-anywhere:toolbox-v1.2 kubectl get nodes
NAME      STATUS    AGE
docker    Ready     5m
```

You also might like to checkout [`weave-osx-ctl`](https://github.com/pidster/weave-osx-ctl/).
