#!/bin/env bash
#MISE description="Set the same icon theme for all users (current user and root)"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

paru -Q qogir-icon-theme &> /dev/null || $PARU qogir-icon-theme

CMD="kwriteconfig6 --file kdeglobals --group Icons --key Theme Qogir-Dark"
for U in $USER root; do
  set -x
  # shellcheck disable=SC2086
  sudo -u $U $CMD
  { set +x; } 2>/dev/null
done
