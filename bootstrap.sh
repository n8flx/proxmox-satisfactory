#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh
# Lädt das Create-Script direkt aus dem GitHub-Repo und führt es aus.

REPO_RAW_URL="https://raw.githubusercontent.com/n8flx/proxmox-satisfactory/main/scripts/create_satisfactory_lxc.sh"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_RAW_URL" | bash -s -- "$@"
elif command -v wget >/dev/null 2>&1; then
  wget -qO- "$REPO_RAW_URL" | bash -s -- "$@"
else
  echo "Dieses System braucht curl oder wget, um das Bootstrap-Skript herunterzuladen." >&2
  exit 1
fi
