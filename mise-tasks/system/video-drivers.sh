#!/bin/env bash
#MISE description="Video drivers installation"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type lspci &>/dev/null || $PARU pciutils
type nvtop &>/dev/null || $PARU nvtop

# Check if PCI device is bound to VFIO
is_vfio_bound() {
    local pci_id="$1"
    local driver_path="/sys/bus/pci/devices/${pci_id}/driver"

    if [[ -L "$driver_path" ]]; then
        local driver_name
        driver_name="$(readlink "$driver_path")"
        driver_name="${driver_name##*/}"
        [[ "$driver_name" == "vfio-pci" ]] && return 0
    fi
    return 1
}

## Crude detection
PREV=
lspci | grep VGA | while IFS= read -r LINE; do
  PCI_ID=$(echo "$LINE" | awk '{print $1}')
  VGA=$(echo "$LINE" | awk '{print $5}')
  VGA_LONG=$(echo "$LINE" | awk '{print $5,$6,$7}')

  # Skip if device is reserved for VFIO passthrough
  if is_vfio_bound "0000:${PCI_ID}"; then
      echo "[INFO] ${VGA_LONG} VGA at ${PCI_ID} is bound to VFIO, skipping driver installation"
      continue
  fi

  [[ "$VGA" == "$PREV" ]] && continue
  PREV=$VGA
  echo "[INFO] $VGA_LONG VGA detected at $PCI_ID"

  case $VGA in
    NVIDIA)
      ADDITIONAL=aur/nvidia-patch
      V1=$(paru -Si $ADDITIONAL | grep ^Version | cut -d: -f2 | head -1)
      V2=$(paru -Si nvidia-utils | grep ^Version | cut -d: -f2 | head -1)
      [[ "$V1" == "$V2" ]] || ADDITIONAL=
      set -x
      $PARU $ADDITIONAL opencl-nvidia lib32-nvidia-utils lib32-opencl-nvidia libva-nvidia-driver cuda nvidia-container-toolkit linux-cachyos-nvidia-open
      { set +x; } 2>/dev/null
      ;;
    Advanced)
      set -x
      $PARU mesa lib32-mesa opencl-mesa rocm-opencl-runtime rocm-smi-lib lib32-opencl-mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu amdgpu_top radeontop
      { set +x; } 2>/dev/null
      ;;
    ## TODO Test
    Intel)
      set -x
      $PARU mesa lib32-mesa vulkan-intel lib32-vulkan-intel
      { set +x; } 2>/dev/null
      ;;
  esac
done
