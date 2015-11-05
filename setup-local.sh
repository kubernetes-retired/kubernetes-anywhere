#!/bin/bash

#(cd ./docker-images; ./build.sh)

./weave launch-router
./weave launch-proxy --rewrite-inspect
./weave expose -h $HOSTNAME.weave.local

docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools compose up -d

echo 'Once all services are ready run'

echo '> eval $(./weave env)'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f /skydns-addon'

echo 'then wait SkyDNS this to get deployed and deploy the Guesbook app with'

echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://raw.github.com/kubernetes/kubernetes/v1.0.7/examples/guestbook/redis-master-controller.yaml'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://raw.github.com/kubernetes/kubernetes/v1.0.7/examples/guestbook/redis-master-service.yaml'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://raw.github.com/kubernetes/kubernetes/v1.0.7/examples/guestbook/redis-slave-controller.yaml'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://raw.github.com/kubernetes/kubernetes/v1.0.7/examples/guestbook/redis-slave-service.yaml'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://raw.github.com/kubernetes/kubernetes/v1.0.7/examples/guestbook/frontend-controller.yaml'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://raw.github.com/kubernetes/kubernetes/v1.0.7/examples/guestbook/frontend-service.yaml'
