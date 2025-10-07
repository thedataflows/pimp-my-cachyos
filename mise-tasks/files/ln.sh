#!/bin/env bash
#MISE description="Link from the source directory. Children are used as base directories. ~ is the current user home directory."

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

DIR=$(readlink -f "${MISE_PROJECT_ROOT:-.}/symlink")

type fd &>/dev/null || $PARU fd
type delta &>/dev/null || $PARU git-delta

[[ -d "$DIR" ]] || return

# Process specific input or all files
declare -a FILES_TO_PROCESS
if [[ $# -eq 1 ]]; then
  INPUT="$1"

  # Validate input exists
  if [[ ! -e "$INPUT" ]]; then
    echo "[ERROR] Input does not exist: $INPUT"
    exit 1
  fi

  # Build file list from input
  if [[ -d "$INPUT" ]]; then
    mapfile -t FILES_TO_PROCESS < <(fd --type file --hidden . "$INPUT")
  else
    FILES_TO_PROCESS=("$INPUT")
  fi
else
  # No input - process all files in symlink directory
  mapfile -t FILES_TO_PROCESS < <(fd --type file --hidden . "$DIR")
fi

# Create symlinks for each file
for F in "${FILES_TO_PROCESS[@]}"; do
  F=$(readlink -f "$F")

  # Determine base directory from file path
  if [[ "$F" == "$DIR/~/"* ]]; then
    D="~"
    DEST=$HOME/${F#"$DIR"/"$D"/}
    SUDO=
  elif [[ "$F" == "$DIR/"* ]]; then
    D=$(echo "$F" | sed -E "s|^$DIR/([^/]+)/.*|\1|")
    DEST=${F#"$DIR"/}
    SUDO=sudo
  else
    echo "[SKIP] File not in symlink directory: $F"
    continue
  fi

  $SUDO test -d "${DEST%/*}" || $SUDO mkdir -pv "${DEST%/*}"
  SRC=$(readlink -f "$F")
  if ! $SUDO test -L "$DEST"; then
    $SUDO ln --verbose --symbolic "$SRC" "$DEST" || \
      { RET=$?; set -x; delta "$SRC" "$DEST" || { set +x; } 2>/dev/null; exit $RET; }
  fi
  ## Fix symlink
  $SUDO readlink -e "$DEST" >/dev/null || \
    $SUDO ln --verbose --symbolic --force "$SRC" "$DEST"
done
