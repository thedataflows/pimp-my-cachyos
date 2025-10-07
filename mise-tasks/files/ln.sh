#!/bin/env bash
#MISE description="Link from the source directory. Children are used as base directories. ~ is the current user home directory."

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

DIR=$(readlink -f "${MISE_PROJECT_ROOT:-.}/symlink")

type fd &>/dev/null || $PARU fd
type delta &>/dev/null || $PARU git-delta

[[ -d "$DIR" ]] || return
for D in $(fd --type dir --max-depth 1 --hidden --format '{/}' . "$DIR"); do
  fd --type file --hidden . "$DIR/$D" | while IFS= read -r F; do
    DEST=${F#"$DIR"/}
    SUDO=sudo
    if [[ "$D" == "~" ]]; then
      DEST=$HOME/${F#"$DIR"/"$D"/}
      SUDO=
    fi
    $SUDO test -d "${DEST%/*}" || $SUDO mkdir -pv "${DEST%/*}"
    SRC=$(readlink -f "$F")
    $SUDO test -L "$DEST" || \
      $SUDO ln --verbose --symbolic "$SRC" "$DEST" || \
        { RET=$?; set -x; delta "$SRC" "$DEST" || { set +x; } 2>/dev/null; exit $RET; }
    ## Fix symlink
    $SUDO readlink -e "$DEST" >/dev/null || \
      $SUDO ln --verbose --symbolic --force "$SRC" "$DEST"
  done
done
