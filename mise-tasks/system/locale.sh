#!/bin/env bash
#MISE description="Locale configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

echo "LANG=en_US.UTF-8" | sudo tee /etc/default/locale > /dev/null
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null
sudo locale-gen en_US.UTF-8
