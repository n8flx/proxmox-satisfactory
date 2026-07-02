#!/usr/bin/env bash
set -euo pipefail
# lxc-backup.sh - simple wrapper to backup an LXC using vzdump
# Usage: lxc-backup.sh <VMID> [--storage STORAGE] [--dumpdir DIR]

VMID=${1:-}
if [ -z "$VMID" ]; then
  echo "Usage: $0 <VMID> [--storage STORAGE] [--dumpdir DIR]" >&2
  exit 2
fi

STORAGE=local
DUMPDIR=/var/lib/vz/dump

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --storage) STORAGE=${2:-local}; shift 2;;
    --dumpdir) DUMPDIR=${2:-/var/lib/vz/dump}; shift 2;;
    *) shift;;
  esac
done

mkdir -p "$DUMPDIR"

echo "Running vzdump for CT $VMID -> storage=$STORAGE, dumpdir=$DUMPDIR"
vzdump "$VMID" --mode suspend --compress lzo --storage "$STORAGE" --dumpdir "$DUMPDIR"

echo "Backup finished."
