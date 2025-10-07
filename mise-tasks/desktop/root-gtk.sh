#!/bin/env bash
#MISE description="Root gtk settings linked to user's"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

for L in .config/gtk-3.0 .config/gtk-4.0 .config/Trolltech.conf; do
  sudo test -L /root/$L || \
    sudo ln -s "$HOME/$L" /root/$L
done
