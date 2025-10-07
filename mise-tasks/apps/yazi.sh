#!/bin/env bash
#MISE description="Configure yazi"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type yazi &> /dev/null || $PARU yazi

ya pack --upgrade
