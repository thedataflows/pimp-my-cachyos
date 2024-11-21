# shellcheck disable=SC2148
## Environment
export PATH=~/go/bin:${KREW_ROOT:-$HOME/.krew}/bin:$PATH
#export GSETTINGS_SCHEMA_DIR=/usr/share/glib-2.0/schemas
export SKIM_DEFAULT_COMMAND="fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."
export WEBKIT_DISABLE_DMABUF_RENDERER=1
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"
export SSH_ASKPASS="/usr/bin/ksshaskpass"
export EDITOR="micro"

virblk() {
  lsblk |awk 'NR==1{print $0" DEVICE-ID(S)"}NR>1{dev=$1;printf $0" ";system("find /dev/disk/by-id -lname \"*"dev"\" -printf \" %p\"");print "";}'|grep -vP 'part|lvm'
}

## Set up environment.d
## https://wiki.gnome.org/Initiatives/Wayland/SessionStart
# _ED_PATH=~/.config/environment.d
# [[ -d "$_ED_PATH" ]] || mkdir -p "$_ED_PATH"
# grep -qP '^SSH_AUTH_SOCK=.+' "$_ED_PATH/profile.conf" || \
#   echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >> "$_ED_PATH/profile.conf"

## https://mise.jdx.dev/ide-integration.html#ide-integration
eval "$(mise activate ${SHELL##*/} --shims)"

## Set up other profiles
for p in x z; do
  [[ -L ~/.${p}profile || -e ~/.${p}profile ]] || ln -vs ~/.profile ~/.${p}profile
done
