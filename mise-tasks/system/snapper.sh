#!/bin/env bash
#MISE description="Snapper configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type snapper &> /dev/null || $PARU snapper
type delta &>/dev/null || $PARU git-delta

set -x
# shellcheck disable=SC2086
sudo $CP ${MISE_PROJECT_ROOT:-.}/copy/etc/snapper /etc/
sudo systemctl restart snapperd
{ set +x; } 2>/dev/null

for SVC in snapper-timeline snapper-cleanup snapper-boot; do
  set -x
  sudo systemctl enable --now ${SVC}.timer
  { set +x; } 2>/dev/null
done
