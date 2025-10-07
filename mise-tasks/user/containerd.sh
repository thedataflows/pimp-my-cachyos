#!/bin/env bash
#MISE description="Install and configure containerd and nerdctl for the current user"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

## Disabled for now
[[ "${1:-}" == "--force" ]] || exit 0

type buildkitd &>/dev/null || $PARU buildkit
type rootlesskit &>/dev/null || $PARU rootlesskit
type nerdctl &>/dev/null || $PARU nerdctl
type newuidmap &>/dev/null || $PARU shadow
type /opt/cni/bin/bridge &>/dev/null || $PARU cni-plugins
type slirp4netns &>/dev/null || $PARU slirp4netns

set -x
sudo test -r "/usr/local/bin/docker" || \
  sudo ln -s /usr/bin/nerdctl /usr/local/bin/docker
{ set +x; } 2>/dev/null

## Setup rootless containerd
sudo systemctl daemon-reload
for srv in containerd buildkit; do
  set -x
  sudo systemctl disable $srv
  sudo systemctl stop $srv || true
  { set +x; } 2>/dev/null
done

## Install
set -x
containerd-rootless-setuptool.sh install
containerd-rootless-setuptool.sh install-buildkit
