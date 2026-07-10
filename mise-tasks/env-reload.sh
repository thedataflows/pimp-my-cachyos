#!/bin/env bash
#MISE description="Reload current user environment variables and update dbus activation environment"
#MISE interactive=true

set -a
for f in ~/.config/environment.d/*.conf; do
  #shellcheck disable=SC1090
  source "$f"
done
set +a

set -x
systemctl --user import-environment
dbus-update-activation-environment --all
type niri &>/dev/null && niri msg action load-config-file || true
