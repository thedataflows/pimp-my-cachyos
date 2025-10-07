#!/bin/env bash
#MISE description="Faillock configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

patchProperty() {
  local FILE=$1
  local PROPERTY_KEY=$2
  local PROPERTY_VALUE=$3
  if ! grep -q "^$PROPERTY_KEY = $PROPERTY_VALUE" "$FILE"; then
    sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$FILE"
    sudo sed -i -E "s,^#?\s*($PROPERTY_KEY\s*=\s*).*,\1$PROPERTY_VALUE," "$FILE"
  fi
}

FILE=/etc/security/faillock.conf
patchProperty "$FILE" deny 10
patchProperty "$FILE" unlock_time 300
