#!/bin/env bash
#MISE description="Manage packages defined in yaml lists"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type paru &> /dev/null || sudo pacman -Sy --noconfirm paru
type yq &> /dev/null || $PARU go-yq
type fd &> /dev/null || $PARU fd

_HOSTNAME=$(hostname)

if [[ $# -eq 0 ]]; then
  mapfile -t _PACKAGE_FILES < <(fd --type file '\.ya?ml' "${MISE_PROJECT_ROOT:-.}/apps")
else
  _PACKAGE_FILES=("$@")
fi

## Add packages
for F in "${_PACKAGE_FILES[@]}"; do
  [[ -r "$F" ]] || continue
  _PACKAGES=$(yq --no-colors --no-doc ".[] | select(.state!=\"absent\" and .state!=\"removed\") | select(.hosts == null or (.hosts | contains([\"$_HOSTNAME\"]))) | .name" "$F" 2>/dev/null || true)
  [[ -n "$_PACKAGES" ]] || continue
  echo ""
  echo ">> add: $F"
  set -x
  #shellcheck disable=SC2086
  $PARU $_PACKAGES
  { set +x; } 2>/dev/null
done

## Remove packages marked absent/removed
for F in "${_PACKAGE_FILES[@]}"; do
  [[ -r "$F" ]] || continue
  _PACKAGES=$(yq --no-colors --no-doc ".[] | select(.state==\"absent\" or .state==\"removed\") | select(.hosts == null or (.hosts | contains([\"$_HOSTNAME\"]))) | .name" "$F" 2>/dev/null || true)
  [[ -n "$_PACKAGES" ]] || continue
  #shellcheck disable=SC2086
  _PACKAGES=$(paru -Q $_PACKAGES 2>/dev/null | cut -f1 -d' ' || true)
  [[ -n "$_PACKAGES" ]] || continue
  echo ""
  echo ">> remove: $F"
  set -x
  #shellcheck disable=SC2086
  paru --remove --recursive --noconfirm $_PACKAGES
  { set +x; } 2>/dev/null
done
