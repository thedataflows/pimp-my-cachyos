#!/bin/env bash
#MISE description="Cleanup user files"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

for F in fish kate; do
  for P in ~/.config/$F ~/.local/share/$F; do
    [[ -e "$P" ]] || continue
    set -x
    rm --verbose --force --recursive "$P"
    { set +x; } 2>/dev/null
  done
done
