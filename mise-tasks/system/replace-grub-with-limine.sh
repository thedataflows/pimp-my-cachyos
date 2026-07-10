#!/bin/env bash
#MISE description="Replace GRUB with Limine bootloader (destructive, one-time migration)"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

echo "=================================================="
echo "WARNING: This replaces GRUB with Limine."
echo "Ensure you have a recovery option before proceeding."
echo "=================================================="
echo ""

## Run package management via mise (boot.yaml drives both removal and installation)
set -x
mise run packages "${MISE_PROJECT_ROOT:-.}/apps/boot/packages.yaml"
{ set +x; } 2>/dev/null

## Configure Limine bootloader
mise run system:limine

echo ""
echo "=================================================="
echo "GRUB → Limine migration complete."
echo "Reboot to verify Limine boots correctly."
echo "If Limine fails, boot a live ISO and reinstall GRUB."
echo "=================================================="
