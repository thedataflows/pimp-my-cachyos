#!/bin/env bash
#MISE description="Configure atuin for bash"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type atuin &> /dev/null || $PARU atuin

ATUIN_SCRIPT_PATH=/usr/local/libexec/atuin
sudo test -d "$ATUIN_SCRIPT_PATH" || sudo mkdir -p "$ATUIN_SCRIPT_PATH"
sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$ATUIN_SCRIPT_PATH/bash-preexec.sh"
sudo curl -sSL https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o "$ATUIN_SCRIPT_PATH/bash-preexec.sh"
if ! grep -q 'bash-preexec\.sh' /etc/bash.bashrc; then
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" /etc/bash.bashrc
  echo "[[ -f $ATUIN_SCRIPT_PATH/bash-preexec.sh ]] && source $ATUIN_SCRIPT_PATH/bash-preexec.sh" | sudo tee -a /etc/bash.bashrc
fi
if ! grep -q 'atuin init' /etc/bash.bashrc; then
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" /etc/bash.bashrc
  # shellcheck disable=SC2016
  printf "%s\n\n" 'eval "$(atuin init bash)"' | sudo tee -a /etc/bash.bashrc
fi
