#!/bin/env bash
#MISE description="SSHD server setup"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type sshd &>/dev/null || $PARU openssh
sudo systemctl enable sshd
sudo systemctl restart sshd
