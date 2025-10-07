#!/bin/env bash
#MISE description="Configure current user shell"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

sudo usermod --shell /bin/zsh "$(id -un)"
