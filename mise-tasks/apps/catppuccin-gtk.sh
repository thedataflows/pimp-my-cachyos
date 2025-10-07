#!/bin/env bash
#MISE description="Configure catppuccin-gtk theme"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

paru -Q catppuccin-gtk-theme-mocha &>/dev/null || \
  paru -Sy --noconfirm aur/catppuccin-gtk-theme-mocha

THEME=lavender
for D in gtk-3.0 gtk-4.0; do
  GTK_DIR="$HOME/.config/$D"
  [[ -d "$GTK_DIR" ]] || \
    mkdir -p "$GTK_DIR"
  for F in thumbnail.png gtk.css gtk-dark.css assets; do
    SRC="/usr/share/themes/catppuccin-mocha-$THEME-standard+default/$D/$F"
    DST="$GTK_DIR/$F"
    test -L "$DST" -a -e "$DST"  || \
      ln --verbose --symbolic --force "$SRC" "$GTK_DIR/" || \
        { RET=$?; delta "$SRC" "$DST"; exit $RET; }
  done
done
