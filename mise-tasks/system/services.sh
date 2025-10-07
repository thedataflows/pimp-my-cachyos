#!/bin/env bash
#MISE description="Enable/disable various system services"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

## ## https://wiki.cachyos.org/configuration/dual_gpu/#kde-plasma
for S in power-profiles-daemon keyd switcheroo-control; do
  set -x
  sudo systemctl enable --now $S
  { set +x; } 2>/dev/null
done

## https://wiki.cachyos.org/configuration/sched-ext/#disable-ananicy-cpp
for S in ananicy-cpp plocate-updatedb.timer plocate-updatedb.service rustdesk; do
  set -x
  sudo systemctl disable --now $S || echo "[WARN] Failed"
  { set +x; } 2>/dev/null
done
