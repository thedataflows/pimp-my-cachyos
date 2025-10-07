#!/bin/env bash
#MISE description="Samba configuration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

type fd &> /dev/null || $PARU fd
type yq &> /dev/null || $PARU go-yq
type hostname &> /dev/null || $PARU inetutils
type samba &> /dev/null || $PARU samba
type avahi-daemon &> /dev/null || $PARU avahi

set -x
sudo systemctl enable --now avahi-daemon

# shellcheck disable=SC2086
sudo $CP ${MISE_TASK_DIR:-.}/copy/etc/samba/smb.conf /etc/samba/
{ set +x; } 2>/dev/null

SMB_DEFAULT_GROUP=${SMB_DEFAULT_GROUP:-smb}
## Create the group if it doesn't exist
sudo getent group "$SMB_DEFAULT_GROUP" &>/dev/null || \
  { set -x; sudo groupadd "$SMB_DEFAULT_GROUP"; { set +x; } 2>/dev/null; }

## Add current user to the samba group
[[ " $(id -Gn) " =~ $SMB_DEFAULT_GROUP ]] || \
  { set -x; sudo usermod -aG "$SMB_DEFAULT_GROUP" "$USER"; { set +x; } 2>/dev/null; }

## Add current user to samba
sudo pdbedit -L 2>/dev/null | grep -qP "^$USER:" || \
  { set -x; sudo smbpasswd -a "$USER"; { set +x; } 2>/dev/null; }

## Share via samba the local mounts
SMB_CONF_DIR="/etc/samba/smb.conf.d"
sudo test -d "$SMB_CONF_DIR" || \
  { set -x; sudo mkdir -p "$SMB_CONF_DIR"; { set +x; } 2>/dev/null; }
MOUNTS=$(cat "${MISE_PROJECT_ROOT:-.}/mountpoints/mounts.$(hostname).yaml") || exit 0
for NAME in $(yq 'with_entries(select(.value.share != false)) | keys[]' <<< "$MOUNTS"); do
  DEST=$(yq -r ".${NAME}.destination" - <<< "$MOUNTS")
  FILE="$SMB_CONF_DIR/${NAME}.conf"
  ## Backup existing
  sudo "${MISE_PROJECT_ROOT:-.}/mise-tasks/backup.sh" "$FILE"
  ## Write new
  cat <<! | sudo tee "$FILE" >/dev/null
[$NAME]
comment = $NAME
path = $DEST
valid users = @$SMB_DEFAULT_GROUP
public = no
writable = yes
!
  ## Include the config in the main smb.conf
  sudo grep -qP "^include\s*=\s*$FILE" "/etc/samba/smb.conf" || \
    { set -x; sudo tee -a "/etc/samba/smb.conf" <<< "include = $FILE" >/dev/null; { set +x; } 2>/dev/null; }
done

## Enable and restart samba service
set -x
sudo systemctl is-enabled smb &>/dev/null || \
  sudo systemctl enable smb
sudo systemctl is-active smb &>/dev/null || \
  sudo systemctl restart smb
{ set +x; } 2>/dev/null
