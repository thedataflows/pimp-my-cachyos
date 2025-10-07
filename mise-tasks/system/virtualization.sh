#!/bin/env bash
#MISE description="Virtualization configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

paru -Q virt-manager &>/dev/null || $PARU virt-manager
paru -Q qemu-desktop &>/dev/null || $PARU qemu-desktop

echo ">> Enabling and starting services"
for SVC in libvirtd virtqemud virtnetworkd virtstoraged virtnodedevd; do
  set -x
  sudo systemctl enable --now $SVC
  { set +x; } 2>/dev/null
done

USER=$(id -un)
for GRP in libvirt libvirt-qemu; do
  if [[ ! " $(id -Gn) " =~ $GRP ]]; then
    echo ">> Adding user $USER to $GRP group"
    set -x
    sudo usermod -aG $GRP "$USER"
    { set +x; } 2>/dev/null
  fi
done

NET_INFO=$(sudo virsh net-info default)
if ! grep -qP '^Autostart:\s+yes' <<< "$NET_INFO"; then
  set -x
  sudo virsh net-autostart default
  { set +x; } 2>/dev/null
fi
if ! grep -qP '^Active:\s+yes' <<< "$NET_INFO"; then
  set -x
  sudo virsh net-start default
  { set +x; } 2>/dev/null
fi
