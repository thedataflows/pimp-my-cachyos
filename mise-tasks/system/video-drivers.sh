#!/bin/env bash
#MISE description="Video drivers installation"
#MISE interactive=true

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

# Detect vendor from lspci description (everything after the first ':')
detect_vendor() {
    local desc="$1"
    case "$desc" in
        [Nn][Vv][Ii][Dd][Ii][Aa]*|[Nn][Vv][Ii][Dd][Ii][Aa]*) echo "nvidia" ;;
        *[Aa][Mm][Dd]/[Aa][Tt][Ii]*|*[Aa][Dd][Vv][Aa][Nn][Cc][Ee][Dd]*[Mm][Ii][Cc][Rr][Oo]*[Dd][Ee][Vv][Ii][Cc][Ee][Ss]*) echo "amd" ;;
        [Ii][Nn][Tt][Ee][Ll]*) echo "intel" ;;
        *) echo "unknown" ;;
    esac
}

mapfile -t _LINES < <(lspci | grep -iE 'vga|display|3d')

declare -A _SEEN
declare -a _TO_INSTALL

for LINE in "${_LINES[@]}"; do
    PCI_ID="${LINE%% *}"
    DESC="${LINE#*: }"
    DESC="${DESC# }"

    # Skip if device is reserved for VFIO passthrough
    if is_vfio_bound "0000:${PCI_ID}"; then
        echo "[INFO] ${DESC} at ${PCI_ID} is bound to VFIO, skipping driver installation"
        continue
    fi

    VENDOR=$(detect_vendor "$DESC")
    [[ "$VENDOR" == "unknown" ]] && { echo "[WARN] Unrecognised vendor for ${DESC} at ${PCI_ID}, skipping"; continue; }

    # Deduplicate: only install once per vendor
    [[ -n "${_SEEN[$VENDOR]:-}" ]] && continue
    _SEEN[$VENDOR]=1

    echo "[INFO] ${VENDOR^^} GPU detected at ${PCI_ID}: ${DESC}"
    _TO_INSTALL+=("$VENDOR")
done

for VENDOR in "${_TO_INSTALL[@]}"; do
    case "$VENDOR" in
        nvidia)
            ADDITIONAL=aur/nvidia-patch
            V1=$(paru -Si "$ADDITIONAL" | grep ^Version | cut -d: -f2 | head -1 || true)
            V2=$(paru -Si nvidia-utils | grep ^Version | cut -d: -f2 | head -1 || true)
            [[ "${V1:-}" == "${V2:-}" ]] || ADDITIONAL=
            set -x
            #shellcheck disable=SC2086
            $PARU $ADDITIONAL opencl-nvidia lib32-nvidia-utils lib32-opencl-nvidia libva-nvidia-driver cuda nvidia-container-toolkit linux-cachyos-nvidia-open
            { set +x; } 2>/dev/null
            ;;
        amd)
            set -x
            $PARU mesa lib32-mesa opencl-mesa rocm-opencl-runtime rocm-smi-lib lib32-opencl-mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu amdgpu_top radeontop
            { set +x; } 2>/dev/null
            ;;
        intel)
            set -x
            $PARU mesa lib32-mesa vulkan-intel lib32-vulkan-intel
            { set +x; } 2>/dev/null
            ;;
    esac
done
