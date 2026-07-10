#!/bin/env bash
#MISE description="Run all tasks in the proper order"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

## Software installation
mise run packages

## Configure: apps
mise run ai
mise run aliases
mise run android
mise run atuin
mise run backup
mise run baloo
mise run bat
mise run betterbird
mise run bookokrat
mise run boot
mise run btop
mise run cloud
mise run code
mise run containers
mise run crypto
mise run dank-material-shell
mise run desktop
mise run development
mise run dolphin
mise run easyeffects
mise run fastfetch
mise run files
mise run fonts
mise run fzf
mise run gaming
mise run ghostty
mise run git
mise run glow
mise run gnupg
mise run graphics
mise run grsync
mise run gtk
mise run htop
mise run icons
mise run internet
mise run iommu-viewer
mise run kde-desktop
mise run keepassxc
mise run kew
mise run kitty
mise run kopia
mise run lazygit
mise run looking-glass
mise run mangohud
mise run mc
mise run menus
mise run micro
mise run mise
mise run mpv
mise run multimedia
mise run network
mise run niri
mise run nvtop
mise run nwg-look
mise run oh-my-posh
mise run okular
mise run opencode
mise run openrgb
mise run pacseek
mise run panel-colorizer
mise run plasma-systemmonitor
mise run productivity
mise run remote
mise run rsync
mise run rustdesk
mise run security
mise run sesh
mise run signal
mise run spectacle
mise run strawberry
mise run swaylock
mise run syncthingtray
mise run system
mise run system-dbus
mise run system-htop
mise run system-keyd
mise run system-libvirt
mise run system-modprobe
mise run system-modules
mise run system-nsswitch
mise run system-nvidia
mise run system-pipewire
mise run system-plasma
mise run system-samba
mise run system-snapper
mise run system-sysctl
mise run system-tmux
mise run system-udev
mise run systemd
mise run television
mise run text
mise run thorium
mise run tmux
mise run viddy
mise run vlc
mise run wallpaper
mise run xdg-desktop-portal
mise run xsettingsd
mise run yazi
mise run zed
mise run zellij
mise run zsh

## Configure: network
mise run network:firewall
mise run network:sshd

## Configure: system
mise run system:limine
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

## Configure: desktop
mise run kde-icon-theme
mise run root-gtk

## Configure: Alternative Desktop Environments (optional)
mise run dms-niri

## Cleanup
mise run user:cleanup

