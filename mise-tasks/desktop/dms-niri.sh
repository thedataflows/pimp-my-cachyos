#!/bin/env bash
#MISE description="Setup Niri with DankMaterialShell (DMS) integration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

echo "Setting up Niri with DankMaterialShell..."

mise run files:ln symlink/~/.config/systemd/user
systemctl --user daemon-reload

# Enable DMS service (but don't start it - it will start with Niri)
echo "Enabling DMS systemd service..."
systemctl --user enable dms
systemctl --user add-wants niri.service dms.service

echo "Disabling XWayland Satellite service, it will be started as needed by niri..."
systemctl --user disable xwayland-satellite || true

echo "Niri + DMS setup complete!"
