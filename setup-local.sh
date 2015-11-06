#!/bin/sh

#(cd ./docker-images; ./build.sh)

./weave launch-router
./weave launch-proxy --rewrite-inspect
./weave expose -h $HOSTNAME.weave.local

docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools compose -p kube up -d

echo '# Once all services are ready run'

echo '> eval $(./weave env)'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f /skydns-addon'

echo '# now wait SkyDNS this to get deployed and deploy the Guesbook app with'

echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f /guestbook-example'

echo '# if you wanna deploy something else, you can just pass a URL to your manifest like this'

echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f https://example.com/guestbook.yaml'
