Kubernetes runs well in containers on most Linux distributions that support Docker v1.10 (or above), however there are a few small bugs in some of the default installations.

### Official Docker Engine Packages and systemd

> _See [docker/docker#19625][] for details_

If you install Docker through the official package repository on a systemd-enabled distribution, you will need ensure that `docker.service` unit has `MountFlags=shared` instead of default `MountFlags=slave`.

This is simple to fix with a drop-in unit:

```
sudo mkdir -p /etc/systemd/system/docker.service.d/
cat << EOF | sudo tee /etc/systemd/system/docker.service.d/clear_mount_propagtion_flags.conf
[Service]
MountFlags=shared
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker.service
```

### Debian 8 and cgroups

> _See [kubernetes/kubernetes#23816][] for details_

If you are using Debian 8 (Jessie), you will need to check if memory cgroup is enabled, fixing it requires a reboot.

  - Open `/etc/default/grub` in your favourite text editor
  - Add `cgroup_enable=memory swapaccount=1` to `GRUB_CMDLINE_LINUX`
  - Run `sudo update-grub2` followed by `sudo reboot`

[docker/docker#19625]: https://github.com/docker/docker/issues/19625#issuecomment-202168866
[kubernetes/kubernetes#23816]: https://github.com/Kubernetes/kubernetes/issues/23816
