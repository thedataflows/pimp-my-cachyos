#!/bin/env bash

set -u -e -o pipefail

trap 'echo [ERROR] $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

if ! pacman-key --list-keys &>/dev/null; then
  echo "[ERROR] pacman keys not initialized. Is this an already installed CachyOS?"
  exit 1
fi

type mise &>/dev/null || pacman -Sy --noconfirm --needed mise

cd "${0%/*}"
mise "$@"
