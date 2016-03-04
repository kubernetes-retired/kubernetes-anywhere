#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

for unit in $(ls /usr/share/kubernetes-anywhere-systemd-units-common/*) ; do
  install --mode=0644 --owner=0 --group=0 $unit /host-systemd/
done
for unit in $(ls /usr/share/kubernetes-anywhere-systemd-units-simple/*) ; do
  install --mode=0644 --owner=0 --group=0 $unit /host-systemd/
done
