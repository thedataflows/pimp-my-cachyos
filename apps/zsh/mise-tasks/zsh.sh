#!/bin/env bash
#MISE description="Install and configure zsh"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

_APP_DIR="${MISE_TASK_DIR}/.."

if [[ -s "$_APP_DIR/packages.yaml" && "${PIMP_ALL_PACKAGES_DONE:-0}" != "1" ]]; then
  mise run packages "$_APP_DIR/packages.yaml"
fi

if [[ -d "$_APP_DIR/config" ]]; then
  mise -E user dotfiles apply
fi

if [[ -d "$_APP_DIR/system-config" ]]; then
  sudo mise -E system dotfiles apply
fi
