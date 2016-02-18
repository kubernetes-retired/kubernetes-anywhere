#!/bin/bash -x

set -o errexit
set -o pipefail
set -o nounset

for unit in $(ls /usr/share/systemd-units/*) ; do
  install --mode=0644 --owner=0 --group=0 $unit /host-systemd/
done
