#!/bin/sh -x

docker_root=/var/lib/docker/

if [ -d /rootfs/etc ] && [ -f /rootfs/etc/os-release ]
then
  case "$(eval `cat /rootfs/etc/os-release` ; echo $ID)" in
    boot2docker)
      docker_root=/mnt/sda1/var/lib/docker/
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
  --volume="${docker_root}:/var/lib/docker:rw" \
  --volume="/var/lib/kubelet/:/var/lib/kubelet:rw" \
  --volume="/var/run:/var/run:rw" \
  --volume="/var/run/weave/weave.sock:/weave.sock" \
  --name=kubelet-volumes \
  weaveworks/kubernetes-anywhere:tools /bin/true
