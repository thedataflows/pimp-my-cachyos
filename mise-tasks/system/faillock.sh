#!/bin/env bash
#MISE description="Faillock configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

FILE=/etc/security/faillock.conf
MAX_TRIES=10
UNLOCK_TIME=300

if ! grep -q '^deny = '$MAX_TRIES "$FILE"; then
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$FILE"
  set -x
  sudo sed -i -E "s,^#?\s*(deny\s*=\s*).*,\1$MAX_TRIES," "$FILE"
  { set +x; } 2>/dev/null
fi
if ! grep -q '^unlock_time = '$UNLOCK_TIME "$FILE"; then
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$FILE"
  set -x
  sudo sed -i -E "s,^#?\s*(unlock_time\s*=\s*).*,\1$UNLOCK_TIME," "$FILE"
  { set +x; } 2>/dev/null
fi
