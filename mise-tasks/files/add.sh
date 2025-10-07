#!/bin/env bash
#MISE description="Add an existing target file/directory to the repository and create a symlink to it instead"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type fd &>/dev/null || $PARU fd
type delta &>/dev/null || $PARU git-delta

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <file_or_directory>"
  echo "  Add existing file(s) to the repository and replace with symlinks"
  exit 1
fi

TARGET="$1"

# Validate target exists
if [[ ! -e "$TARGET" ]]; then
  echo "[ERROR] Target does not exist: $TARGET"
  exit 1
fi

SYMLINK_DIR=$(readlink -f "${MISE_PROJECT_ROOT:-.}/symlink")
[[ -d "$SYMLINK_DIR" ]] || mkdir -p "$SYMLINK_DIR"

# Build list of files to process
declare -a FILES
if [[ -d "$TARGET" ]]; then
  mapfile -t FILES < <(fd --type file --hidden . "$TARGET")
else
  FILES=("$TARGET")
fi

# Process each file
for FILE in "${FILES[@]}"; do
  FILE=$(readlink -f "$FILE")

  # Determine base directory, relative path, and sudo requirement
  SUDO=sudo
  if [[ "$FILE" == "$HOME"/* ]]; then
    # File is in user home
    BASE_DIR="$SYMLINK_DIR/~"
    RELATIVE_PATH="${FILE#"$HOME"/}"
    SUDO=
  else
    # System file
    BASE_DIR="$SYMLINK_DIR"
    RELATIVE_PATH="$FILE"
  fi

  REPO_FILE="$BASE_DIR/$RELATIVE_PATH"

  # Skip if already in repository
  if [[ "$FILE" == "$SYMLINK_DIR"/* ]]; then
    echo "[SKIP] Already in repository: $FILE"
    delta "$FILE" "$REPO_FILE" || true
    continue
  fi

  # Create parent directory in repository
  mkdir -p "${REPO_FILE%/*}"

  # Move file to repository
  set -x
  $SUDO mv -v "$FILE" "$REPO_FILE"
  { set +x; } 2>/dev/null

  # Create symlink at original location
  "${MISE_TASK_DIR:-.}/ln.sh" "$REPO_FILE"
done
