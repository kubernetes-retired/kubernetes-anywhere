#!/bin/sh -x

if [ $(docker inspect --format='{{.State.Status}}' kubelet-volumes) = 'exited' ]
then
  exit
else

  docker_root=/var/lib/docker
  kubelet_root=/var/lib/kubelet

  if [ -d /rootfs/etc ] && [ -f /rootfs/etc/os-release ]
  then
    case "$(eval `cat /rootfs/etc/os-release` ; echo $ID)" in
      boot2docker)
        docker_root=/mnt/sda1/var/lib/docker
        kubelet_root=/mnt/sda1/var/lib/kubelet
        [ -L /var/lib/kubelet ] || ln -s $kubelet_root /var/lib/kubelet
        break
        ;;
      *)
        break
        ;;
    esac
  fi

  docker run \
    --volume="/:/rootfs:ro" \
    --volume="/sys:/sys:ro" \
    --volume="/dev:/dev" \
    --volume="${docker_root}/:${docker_root}:rw" \
    --volume="${kubelet_root}/:/var/lib/kubelet:rw" \
    --volume="/var/run:/var/run:rw" \
    --volume="/var/run/weave/weave.sock:/weave.sock" \
    --name=kubelet-volumes \
    weaveworks/kubernetes-anywhere:tools /bin/true
fi
