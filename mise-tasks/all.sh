#!/bin/env bash
#MISE description="Run all tasks in the proper order"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

## Software installation
mise run packages:add
mise run packages:remove

## Configure: files
mise run files:cp
mise run files:ln

## Configure: network
mise run network:firewall
mise run network:sshd

## Configure: system
mise run system:grub
mise run system:snapper
mise run system:services
mise run system:video-drivers
mise run system:faillock
mise run system:locale
mise run system:mountpoints
mise run system:smb
mise run system:edk2-ovmf-downgrade
mise run system:virtualization

## Configure: user
mise run user:shell
# mise run user:containerd

## Configure: apps
mise run apps:atuin
mise run apps:bat
mise run apps:yazi
mise run apps:gamescope
mise run apps:sunshine
mise run apps:catppuccin-gtk

## Configure: desktop
mise run desktop:kde-icon-theme
mise run desktop:baloo
mise run desktop:root-gtk

## Configure: Alternative Desktop Environments (optional)
mise run desktop:dms-niri

## Cleanup
mise run user:cleanup
