# Weaving Kubernetes Anywhere

Weave lets you run Kubernetes clusters anywhere without configuration chnages.

Having deployed Kubernetes over Weave Net, you can rely 100% on cloud portability, thanks to Weave being an L2 network.

Additionally, thanks to Weave Run and how it (handles IP address allocation as well as DNS)[http://weave.works/talks/crdt/slides.html#1] without reaquiring a persistant store, you can deploy etcd over Weave as well.

So you can simply ocnfigure all of the cluster components to have fixed DNS names, all you should care about is how these services are distributed accross your compute instance, e.g. what is the size of etcd cluster and whether it is on a dedcicated machine with the right type of storage attached.

You no longer have to care about the IP address of the API server or any of those things.
