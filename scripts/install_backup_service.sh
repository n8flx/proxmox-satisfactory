#!/usr/bin/env bash
#set -euo pipefail

# install_backup_service.sh
# Kopiert die Beispiel-Backup-Skripte in /usr/local/bin und die systemd-Units
# nach /etc/systemd/system, lädt systemd neu und aktiviert den Timer für einen
# gegebenen CT-VMID.

set -euo pipefail

VMID=${1:-}

if [ "$EUID" -ne 0 ]; then
  echo "Dieses Installationsskript muss als root auf dem Proxmox-Host ausgeführt werden." >&2
  exit 1
fi

if [ -z "$VMID" ]; then
  echo "Usage: $0 <VMID-to-enable-timer-for>" >&2
  exit 2
fi

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Using repo source: $SRC_DIR"

# Copy create script and backup script
mkdir -p /usr/local/bin
cp -v "$SRC_DIR/scripts/create_satisfactory_lxc.sh" /usr/local/bin/create_satisfactory_lxc.sh
chmod 755 /usr/local/bin/create_satisfactory_lxc.sh
cp -v "$SRC_DIR/examples/lxc-backup.sh" /usr/local/bin/lxc-backup.sh
chmod 755 /usr/local/bin/lxc-backup.sh

# Copy systemd unit templates
cp -v "$SRC_DIR/examples/lxc-backup@.service" /etc/systemd/system/lxc-backup@.service
cp -v "$SRC_DIR/examples/lxc-backup@.timer" /etc/systemd/system/lxc-backup@.timer

# Reload systemd
systemctl daemon-reload

# Enable and start timer for the VMID
systemctl enable --now lxc-backup@${VMID}.timer

echo "Installed create and backup scripts, and enabled lxc-backup@${VMID}.timer"

exit 0
