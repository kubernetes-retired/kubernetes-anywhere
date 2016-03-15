export DOCKER_MACHINE_DRIVER=digitalocean DIGITALOCEAN_ACCESS_TOKEN=99aed22b412c7fcbe1af97e9ee096a9359eba3788cac565ff6045f7aeda973ad DIGITALOCEAN_SIZE=16GB

./create-cluster.sh

./remote-weave.sh 
