#!/bin/bash -x

if [[ $(docker inspect --format='{{.State.Status}}' kubelet-volumes) = 'exited' ]]
then
  exit
else

  def_docker_root="/var/lib/docker"
  def_kubelet_root="/var/lib/kubelet"

  if [ -d /rootfs/etc ] && [ -f /rootfs/etc/os-release ]
  then
    case "$(eval `cat /rootfs/etc/os-release` ; echo $ID)" in
      boot2docker)
        docker_root="/mnt/sda1/${def_docker_root}"
        kubelet_root="/mnt/sda1/${def_kubelet_root}"
        mkdir -p "/rootfs/${kubelet_root}"
        ln -sf "${kubelet_root}" "/rootfs/var/lib/kubelet"
        docker_root_vol=" \
          --volume=\"${docker_root}:${docker_root}:rw\" \
          --volume=\"${def_docker_root}:${def_docker_root}:rw\" \
        "
        kubelet_root_vol=" \
          --volume=\"${kubelet_root}:${def_kubelet_root}:rw,rshared\" \
        "
        ;;
      *)
        docker_root_vol="\
          --volume=\"${def_docker_root}/:${def_docker_root}:rw\" \
        "
        kubelet_root_vol=" \
          --volume=\"${def_kubelet_root}:${def_kubelet_root}:rw,rshared\" \
        "
        ;;
    esac
  fi

  docker run \
    --pid="host" \
    --privileged="true" \
    weaveworks/kubernetes-anywhere:tools nsenter --mount=/proc/1/ns/mnt -- mount --make-rshared /

  docker run \
    --volume="/:/rootfs:ro" \
    --volume="/sys:/sys:ro" \
    --volume="/dev:/dev" \
    --volume="/var/run:/var/run:rw" \
    ${kubelet_root_vol} \
    ${docker_root_vol} \
    --volume="/var/run/weave/weave.sock:/weave.sock" \
    --name="kubelet-volumes" \
    weaveworks/kubernetes-anywhere:tools true
fi
