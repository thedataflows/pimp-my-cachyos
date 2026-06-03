#!/bin/env bash
#MISE description="Limine configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

## Ensure /etc/default/limine exists
LIMINE_DEFAULT=/etc/default/limine
[[ -f "$LIMINE_DEFAULT" ]] || sudo touch "$LIMINE_DEFAULT"

## Host-specific IOMMU parameters (preserved from grub.sh)
# shellcheck disable=SC2076
if [[ " cri-pc " =~ "$(hostname)" ]]; then
  VENDOR=intel
  [[ $(lscpu | grep '^Vendor ID:' | awk '{print $3}') == "AuthenticAMD" ]] && VENDOR=amd

  ## Append IOMMU parameters if not already present
  if ! grep -q "${VENDOR}_iommu=on" "$LIMINE_DEFAULT"; then
    sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$LIMINE_DEFAULT"
    echo "KERNEL_CMDLINE[default]+=\"${VENDOR}_iommu=on\"" | sudo tee -a "$LIMINE_DEFAULT" >/dev/null
  fi

  if [[ "$VENDOR" = 'amd' ]] && ! grep -q "iommu=pt" "$LIMINE_DEFAULT"; then
    sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$LIMINE_DEFAULT"
    echo "KERNEL_CMDLINE[default]+=\"iommu=pt\"" | sudo tee -a "$LIMINE_DEFAULT" >/dev/null
  fi
fi

type lscpu &>/dev/null || $PARU util-linux

## Detect ESP path and persist it so limine-install never fails
if ! grep -q '^ESP_PATH=' "$LIMINE_DEFAULT"; then
  ESP_PATH=$(bootctl --print-esp-path 2>/dev/null || true)
  if [[ -z "$ESP_PATH" ]]; then
    # bootctl failed; fall back to findmnt on common ESP mount points
    for CANDIDATE in /boot/efi /efi /boot; do
      if findmnt -n -o FSTYPE "$CANDIDATE" 2>/dev/null | grep -qiE 'vfat|fat32'; then
        ESP_PATH=$CANDIDATE
        break
      fi
    done
  fi
  if [[ -n "$ESP_PATH" ]]; then
    sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$LIMINE_DEFAULT"
    echo "ESP_PATH=${ESP_PATH}" | sudo tee -a "$LIMINE_DEFAULT" >/dev/null
  else
    echo "[ERROR] Cannot detect ESP path. Set ESP_PATH manually in ${LIMINE_DEFAULT}."
    exit 1
  fi
fi
## Install Limine to ESP
set -x
sudo limine-install
{ set +x; } 2>/dev/null

## Install post-hook to persist Catppuccin Mocha theme and //Snapshots marker
HOOK_DIR=/etc/boot/hooks/post.d
sudo mkdir -p "$HOOK_DIR"
sudo tee "${HOOK_DIR}/91-catppuccin-mocha-theme" >/dev/null <<'EOF'
#!/bin/bash
set -e

ESP_PATH=$(bootctl --print-esp-path 2>/dev/null || echo "/boot")
LIMINE_CONF="${ESP_PATH}/limine.conf"

[[ -f "$LIMINE_CONF" ]] || exit 0

# Inject Catppuccin Mocha theme if not present
if ! grep -q "^term_palette:" "$LIMINE_CONF"; then
  sed -i '1i\
term_palette: 1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4\
term_palette_bright: 585b70;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4\
term_background: 1e1e2e\
term_foreground: cdd6f4\
term_background_bright: 585b70\
term_foreground_bright: cdd6f4\
interface_branding:\
' "$LIMINE_CONF"
fi

# Ensure //Snapshots marker exists for limine-snapper-sync
if ! grep -q "//Snapshots" "$LIMINE_CONF"; then
  echo "//Snapshots" >> "$LIMINE_CONF"
fi
EOF
sudo chmod +x "${HOOK_DIR}/91-catppuccin-mocha-theme"

## Update Limine entries and regenerate initramfs (triggers post-hook)
set -x
sudo limine-mkinitcpio
{ set +x; } 2>/dev/null

## Determine ESP path and directly apply theme/snapshots (idempotent fallback)
ESP_PATH=$(bootctl --print-esp-path 2>/dev/null || echo "/boot")
LIMINE_CONF="${ESP_PATH}/limine.conf"

if [[ -f "$LIMINE_CONF" ]]; then
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$LIMINE_CONF"

  ## Prepend Catppuccin Mocha theme if not already present
  if ! grep -q "^term_palette:" "$LIMINE_CONF"; then
    sudo sed -i '1i\
term_palette: 1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4\
term_palette_bright: 585b70;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4\
term_background: 1e1e2e\
term_foreground: cdd6f4\
term_background_bright: 585b70\
term_foreground_bright: cdd6f4\
interface_branding:\
' "$LIMINE_CONF"
  fi

  ## Ensure //Snapshots keyword exists for limine-snapper-sync
  if ! grep -q "//Snapshots" "$LIMINE_CONF"; then
    echo "//Snapshots" | sudo tee -a "$LIMINE_CONF" >/dev/null
  fi
fi

## Enable and start limine-snapper-sync service
if systemctl list-unit-files limine-snapper-sync.service &>/dev/null; then
  set -x
  sudo systemctl enable --now limine-snapper-sync.service
  { set +x; } 2>/dev/null

  ## Run initial sync
  set -x
  sudo limine-snapper-sync
  { set +x; } 2>/dev/null
fi
