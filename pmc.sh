#!/bin/env bash

set -u -e -o pipefail

trap 'echo [ERROR] $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

if ! pacman-key --list-keys &>/dev/null; then
  echo "[ERROR] pacman keys not initialized. Is this an already installed CachyOS?"
  exit 1
fi

type go-task &>/dev/null || pacman -Sy --noconfirm --needed go-task

cd "${0%/*}"
go-task "$@"
