#!/bin/env bash
#MISE description="Grub configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

patchFile() {
  local FILE=$1
  local PROPERTY_KEY=$2
  local PROPERTY_VALUE=$3
  if ! grep -q "^$PROPERTY_KEY=\"$PROPERTY_VALUE\"" "$FILE"; then
    sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$FILE"
    sudo sed -i -E "s,^#?\s*($PROPERTY_KEY\s*=).*,\1\"$PROPERTY_VALUE\"," "$FILE"
  fi
}

if paru -Q grub-btrfs &>/dev/null; then
  patchFile /etc/default/grub-btrfs/config GRUB_BTRFS_LIMIT 15
fi

GRUB_CONF=/etc/default/grub
patchFile $GRUB_CONF GRUB_DISABLE_OS_PROBER false
patchFile $GRUB_CONF GRUB_GFXMODE "1920x1080x32,auto"
patchFile $GRUB_CONF GRUB_THEME /usr/share/grub/themes/catppuccin-mocha/theme.txt
patchFile $GRUB_CONF GRUB_TIMEOUT 2

# shellcheck disable=SC2076
if [[ " cri-pc " =~ "$(hostname)" ]]; then
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$GRUB_CONF"
  ## Enable iommu
  VENDOR=intel
  [[ $(lscpu | grep '^Vendor ID:' | awk '{print $3}') == "AuthenticAMD" ]] && VENDOR=amd
  if [[ ! " $(grep -oP '(?<=^GRUB_CMDLINE_LINUX_DEFAULT=")[^"]+' $GRUB_CONF) " =~ "${VENDOR}_iommu=on" ]]; then
    set -x
    sudo sed -i -E "s,^#*(GRUB_CMDLINE_LINUX_DEFAULT.+[^\"']+),\1 ${VENDOR}_iommu=on," $GRUB_CONF
    { set +x; } 2>/dev/null
  fi
  if [[ "$VENDOR" = 'amd' && ! " $(grep -oP '(?<=^GRUB_CMDLINE_LINUX_DEFAULT=")[^"]+' $GRUB_CONF) " =~ "iommu=pt" ]]; then
    set -x
    sudo sed -i -E "s,^#*(GRUB_CMDLINE_LINUX_DEFAULT.+[^\"']+),\1 iommu=pt," $GRUB_CONF
    { set +x; } 2>/dev/null
  fi
fi

type lscpu &>/dev/null || $PARU util-linux
## Regenerate GRUB config
set -x
sudo grub-mkconfig -o /boot/grub/grub.cfg
