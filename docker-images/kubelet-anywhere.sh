#!/bin/sh -x

/fix-nameserver

if [ -d /rootfs/etc ] && [ -f /rootfs/etc/os-release ]
then
  case "$(eval `cat /rootfs/etc/os-release` ; echo $ID)" in
    boot2docker)
      if [ -d /rootfs/mnt/sda1/var/lib/docker ]
      then
        mkdir -p /var/lib
        ln -s /rootfs/mnt/sda1/var/lib/docker /var/lib/docker
      fi
      break
      ;;
    *)
      if [ -d /rootfs/var/lib/docker ]
      then
        mkdir -p /var/lib
        ln -s /rootfs/var/lib/docker /var/lib/docker
      fi
      break
      ;;
  esac
fi

/hyperkube kubelet \
  --docker-endpoint=unix:/weave.sock \
  --port=10250 \
  --api-servers=http://kube-apiserver.weave.local:8080 \
  --cluster-dns=10.16.0.3 \
  --cluster-domain=kube.local \
  --containerized=true \
  --logtostderr=true
