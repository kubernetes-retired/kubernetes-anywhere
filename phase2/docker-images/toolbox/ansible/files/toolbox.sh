#!/bin/bash
source /etc/kubernetes-anywhere/base.env
source /etc/kubernetes-anywhere/local.env
source /etc/kubernetes-anywhere/pki-images.env

export HOME=/root

toolbox="${KUBERNETES_ANYWHERE_TOOLBOX_IMAGE:-"weaveworks/kubernetes-anywhere:toolbox"}"
(sudo docker pull "${toolbox}" >&2)

(sudo docker pull "${KUBERNETES_ANYWHERE_TOOLBOX_PKI_IMAGE}" >&2)

## TODO: find a way to avoid garbage
pki="$(sudo docker run --detach "${KUBERNETES_ANYWHERE_TOOLBOX_PKI_IMAGE}")"

args=(
  "--volume=/var/run/weave/weave.sock:/docker.sock"
  "--volumes-from=${pki}"
)

if tty > /dev/null 2>&1 ; then
  args+=(
    "--tty"
    "--interactive"
  )
fi

if [ -n "${SSH_AUTH_SOCK}" ] ; then
  args+=(
    "--volume=${SSH_AUTH_SOCK}:/agent.sock"
    "--env=SSH_AUTH_SOCK=/agent.sock"
  )
fi

exec sudo docker --host="unix:///var/run/weave/weave.sock" run "${args[@]}" "${toolbox}" "$@"
