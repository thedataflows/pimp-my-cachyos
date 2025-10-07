#!/bin/env bash
#MISE description="Configure system firewall"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

HOSTS=("cri-pc")

type ufw &>/dev/null || $PARU ufw

for HOST in "${HOSTS[@]}"; do
  if [[ "$HOST" != $(hostname) ]]; then
    continue
  fi
  set -x
  sudo ufw disable
  { set +x; } 2>/dev/null
done
