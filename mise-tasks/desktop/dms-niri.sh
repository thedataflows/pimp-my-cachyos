#!/bin/env bash
#MISE description="Setup Niri with DankMaterialShell (DMS) integration"

set -Eeuo pipefail
trap 'echo "[ERROR] on line $LINENO: \"${BASH_COMMAND}\" exited with status $?"' ERR

echo "Setting up Niri with DankMaterialShell..."

mise run files:ln

# Bind DMS to niri service so it only runs under Niri
# (won't start in Plasma or other sessions)
if systemctl --user list-unit-files | grep -q "niri.service"; then
    echo "Binding DMS to niri.service..."
    systemctl --user add-wants niri.service dms || true
fi

# Enable DMS service (but don't start it - it will start with Niri)
echo "Enabling DMS systemd service..."
systemctl --user enable dms || true

echo "Disabling XWayland Satellite service, it will be started as needed by niri..."
systemctl --user disable xwayland-satellite || true

echo "Niri + DMS setup complete!"
