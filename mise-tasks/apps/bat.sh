#!/bin/env bash
#MISE description="Configure bat"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

bat cache --build
