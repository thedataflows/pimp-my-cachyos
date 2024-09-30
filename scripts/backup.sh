#!/bin/env bash

## Backup a file in-place with its md5sum as suffix
## If the input is a directory, it will be copied recursively and current date-time will be appended to the directory name

set -u -e -o pipefail

trap 'echo [ERROR] $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <file|directory>"
  exit 1
fi

if [[ ! -e "$1" ]]; then
  echo "[WARNING] File or directory not found: $1. No backup for now!"
  exit 0
fi

## Is a directory
if [[ -d "$1" ]]; then
  NEW=$(basename "$1")-$(date +%Y%m%d%H%M%S)
  if ! test -d "${1}.$NEW"; then
    set -x
    cp --verbose --recursive "$1" "${1}.$NEW"
    { set +x; } 2>/dev/null
  fi
  exit 0
fi

## Is a file
SUM=$(md5sum "$1" | cut -d' ' -f1)
test -f "${1}.$SUM" && exit 0
set -x
cp --verbose "$1" "${1}.$SUM"
{ set +x; } 2>/dev/null
