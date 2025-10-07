#!/bin/env bash
#MISE description="Downgrade OVMF firmware to a version compatible with Looking Glass"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

VERSION=202208-3

echo ">> Downgrade EFI OVMF firmware that works with Looking Glass kvmfr module"
set -x
paru -Q edk2-ovmf=${VERSION} &>/dev/null || \
  paru -U --noconfirm --needed https://archive.archlinux.org/packages/e/edk2-ovmf/edk2-ovmf-${VERSION}-any.pkg.tar.zst
sudo sed -i -E 's,^#?\s*(IgnorePkg\s*=\s*).*,\1 edk2-ovmf,' /etc/pacman.conf
