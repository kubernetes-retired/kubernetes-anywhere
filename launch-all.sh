./weave launch-router
./weave launch-proxy --rewrite-inspect
./weave expose -h $HOSTNAME.weave.local

docker run -v /var/run/weave/weave.sock:/weave.sock weaveworks/kubernetes-anywhere:tools compose up -d
echo 'Once all services are ready run'
echo '> docker run weaveworks/kubernetes-anywhere:tools kubectl create -f /skydns-addon'
echo 'then wait SkyDNS this to get deployed and deploy the Guesbook app with'
echo '> ...'
