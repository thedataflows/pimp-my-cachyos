#!/bin/env bash
#MISE description="Stop and disable baloo file indexer"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type balooctl6 &>/dev/null || exit 0

balooctl6 disable || true
balooctl6 purge || true
