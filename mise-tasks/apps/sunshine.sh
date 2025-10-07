#!/bin/env bash
#MISE description="Configure sunshine"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type sunshine &>/dev/null || exit 0

BIN=$(readlink -e "$(which sunshine)")
set -x
sudo setcap cap_sys_admin+p "$BIN"
