#!/bin/env bash
#MISE description="Run all tasks in the proper order"
#MISE interactive=true

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

_RUN_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/pimp-my-cachyos"
_RUN_STATE_FILE="$_RUN_STATE_DIR/all-run.state"

_run_state_get() {
  [[ -f "$_RUN_STATE_FILE" ]] || return 0
  local key=$1
  grep -E "^${key}=" "$_RUN_STATE_FILE" | tail -n1 | cut -d= -f2-
}

_run_state_set() {
  mkdir -p "$_RUN_STATE_DIR"
  local key=$1 value=$2
  if [[ -f "$_RUN_STATE_FILE" ]]; then
    grep -vE "^${key}=" "$_RUN_STATE_FILE" > "${_RUN_STATE_FILE}.tmp" || true
  fi
  printf '%s=%s\n' "$key" "$value" >> "${_RUN_STATE_FILE}.tmp"
  mv "${_RUN_STATE_FILE}.tmp" "$_RUN_STATE_FILE"
}

_run_state_clear() {
  rm -f "$_RUN_STATE_FILE"
}

_run_or_resume() {
  local task=$1
  if [[ "${_SKIP_DONE:-1}" == "1" ]]; then
    if [[ "$task" == "$(_run_state_get LAST_SUCCESSFUL_TASK)" ]]; then
      echo ">> Resuming after $task"
      _SKIP_DONE=0
    else
      echo ">> Skipping already completed: $task"
    fi
    return 0
  fi
  echo ">> Running $task"
  mise run "$task"
  _run_state_set LAST_SUCCESSFUL_TASK "$task"
}

if [[ "${PIMP_ALL_FRESH:-0}" == "1" ]]; then
  _run_state_clear
fi

_SKIP_DONE=1
if [[ -z "$(_run_state_get LAST_SUCCESSFUL_TASK)" ]]; then
  _SKIP_DONE=0
fi

## Software installation
_run_or_resume packages

## Configure: apps
_run_or_resume ai
_run_or_resume aliases
_run_or_resume android
_run_or_resume atuin
_run_or_resume backup
_run_or_resume baloo
_run_or_resume bat
_run_or_resume betterbird
_run_or_resume bookokrat
_run_or_resume boot
_run_or_resume btop
_run_or_resume cloud
_run_or_resume code
_run_or_resume containers
_run_or_resume crypto
_run_or_resume dank-material-shell
_run_or_resume desktop
_run_or_resume development
_run_or_resume dolphin
_run_or_resume easyeffects
_run_or_resume fastfetch
_run_or_resume files
_run_or_resume fonts
_run_or_resume fzf
_run_or_resume gaming
_run_or_resume ghostty
_run_or_resume git
_run_or_resume glow
_run_or_resume gnupg
_run_or_resume graphics
_run_or_resume grsync
_run_or_resume gtk
_run_or_resume htop
_run_or_resume icons
_run_or_resume internet
_run_or_resume iommu-viewer
_run_or_resume kde-desktop
_run_or_resume keepassxc
_run_or_resume kew
_run_or_resume kitty
_run_or_resume kopia
_run_or_resume lazygit
_run_or_resume looking-glass
_run_or_resume mangohud
_run_or_resume mc
_run_or_resume menus
_run_or_resume micro
_run_or_resume mise
_run_or_resume moonlight
_run_or_resume mpv
_run_or_resume multimedia
_run_or_resume network
_run_or_resume niri
_run_or_resume nvtop
_run_or_resume nwg-look
_run_or_resume oh-my-posh
_run_or_resume okular
_run_or_resume opencode
_run_or_resume openrgb
_run_or_resume pacseek
_run_or_resume panel-colorizer
_run_or_resume plasma-systemmonitor
_run_or_resume productivity
_run_or_resume remote
_run_or_resume rsync
_run_or_resume rustdesk
_run_or_resume security
_run_or_resume sesh
_run_or_resume signal
_run_or_resume spectacle
_run_or_resume strawberry
_run_or_resume swaylock
_run_or_resume syncthingtray
_run_or_resume system
_run_or_resume system-dbus
_run_or_resume system-htop
_run_or_resume system-keyd
_run_or_resume system-libvirt
_run_or_resume system-modprobe
_run_or_resume system-modules
_run_or_resume system-nsswitch
_run_or_resume system-nvidia
_run_or_resume system-pipewire
_run_or_resume system-plasma
_run_or_resume system-samba
_run_or_resume system-snapper
_run_or_resume system-sysctl
_run_or_resume system-tmux
_run_or_resume system-udev
_run_or_resume systemd
_run_or_resume television
_run_or_resume text
_run_or_resume thorium
_run_or_resume tmux
_run_or_resume viddy
_run_or_resume vlc
_run_or_resume wallpaper
_run_or_resume xdg-desktop-portal
_run_or_resume xsettingsd
_run_or_resume yazi
_run_or_resume zed
_run_or_resume zellij
_run_or_resume zsh

## Configure: network
_run_or_resume network:firewall
_run_or_resume network:sshd

## Configure: system
_run_or_resume system:limine
_run_or_resume system:snapper
_run_or_resume system:services
_run_or_resume system:video-drivers
_run_or_resume system:faillock
_run_or_resume system:locale
_run_or_resume system:mountpoints
_run_or_resume system:smb
_run_or_resume system:edk2-ovmf-downgrade
_run_or_resume system:virtualization

## Configure: user
_run_or_resume user:shell

## Configure: desktop
_run_or_resume kde-icon-theme
_run_or_resume root-gtk

## Configure: Alternative Desktop Environments (optional)
_run_or_resume dms-niri

## Cleanup
_run_or_resume user:cleanup

# Clear run state on successful completion
_run_state_clear

