#!/bin/env bash
#MISE description="Configure gamescope"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type gamescope &>/dev/null || exit 0

BIN=$(readlink -e "$(which gamescope)")
set -x
sudo setcap 'cap_sys_nice=eip' "$BIN"
