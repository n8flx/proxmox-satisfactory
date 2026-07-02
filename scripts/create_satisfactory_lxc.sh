#!/usr/bin/env bash
set -euo pipefail

# create_satisfactory_lxc.sh
# Automatisiert Erstellung einer Debian LXC auf Proxmox, installiert SteamCMD
# und den Satisfactory Dedicated Server, legt einen systemd-Service und
# Update-Timer an.

# Defaults
DEFAULT_CORES=4
DEFAULT_MEMORY=8192
DEFAULT_DISK=20
DEFAULT_STORAGE="local-lvm"
STEAM_APPID="1690800"

usage() {
  cat <<EOF
Usage: $0 [VMID|auto] [CT_NAME] [STORAGE] [BRIDGE] [IP]
  VMID     : optional numeric CT ID (z.B. 101). If omitted or set to auto, the next free ID is used.
  CT_NAME  : hostname / container name (z.B. satisfactory)
  STORAGE  : Proxmox storage name for rootfs (default: $DEFAULT_STORAGE)
  BRIDGE   : bridge interface (default: vmbr0)
  IP       : DHCP or static address (z.B. 192.168.1.50/24)

Example:
  $0 auto satisfactory local-lvm vmbr0 dhcp
  $0 satisfactory local-lvm vmbr0 dhcp
  $0 101 satisfactory local-lvm vmbr0 dhcp

The script must be executed on the Proxmox host as root.
EOF
  exit 1
}

VMID=""
if [ "${1:-}" = "auto" ]; then
  shift
elif [[ "${1:-}" =~ ^[0-9]+$ ]]; then
  VMID=$1
  shift
fi

CT_NAME=${1:-satisfactory}
STORAGE=${2:-$DEFAULT_STORAGE}
NET_BRIDGE=${3:-vmbr0}
CT_IP=${4:-dhcp} # e.g. 192.168.1.50/24 or 'dhcp'

if [ -z "$VMID" ]; then
  if command -v pvesh >/dev/null 2>&1; then
    VMID=$(pvesh get /cluster/nextid)
  else
    VMID=$(pct list | tail -n +2 | awk '{print $1}' | sort -n | awk 'BEGIN{next=100} {while($1>next){print next; exit} if($1==next){next++}} END{print next}')
  fi
fi

if ! [[ "$VMID" =~ ^[0-9]+$ ]]; then
  echo "VMID must be numeric." >&2
  exit 2
fi

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root on the Proxmox host." >&2
  exit 3
fi

ROOT_PASSWORD=""
if [ -c /dev/tty ]; then
  while true; do
    printf "Root password for the container (leave empty to disable password login): " >/dev/tty
    if ! IFS= read -r -s ROOT_PASSWORD </dev/tty; then
      ROOT_PASSWORD=""
      echo >/dev/tty
      break
    fi
    echo >/dev/tty

    if [ -z "$ROOT_PASSWORD" ]; then
      break
    fi

    printf "Confirm root password: " >/dev/tty
    if ! IFS= read -r -s ROOT_PASSWORD_CONFIRM </dev/tty; then
      ROOT_PASSWORD=""
      echo >/dev/tty
      break
    fi
    echo >/dev/tty

    if [ "$ROOT_PASSWORD" = "$ROOT_PASSWORD_CONFIRM" ]; then
      break
    fi

    echo "Passwords do not match. Please try again." >/dev/tty
  done
fi

echo "Creating LXC $VMID with hostname $CT_NAME on storage $STORAGE"

# Choose a Debian template (prefer Debian 13 "Trixie", then Debian 12).
echo "Updating template index..."
pveam update >/dev/null
AVAILABLE_TEMPLATES=$(pveam available | tr -s '[:space:]' '\n' | grep -E '^debian-[0-9]+-standard' || true)
TEMPLATE=$(printf '%s\n' "$AVAILABLE_TEMPLATES" | grep '^debian-13-standard' | head -n 1 || true)
if [ -z "$TEMPLATE" ]; then
  TEMPLATE=$(printf '%s\n' "$AVAILABLE_TEMPLATES" | grep '^debian-12-standard' | head -n 1 || true)
fi
if [ -z "$TEMPLATE" ]; then
  # fallback: take first Debian template if output format is different
  TEMPLATE=$(printf '%s\n' "$AVAILABLE_TEMPLATES" | head -n 1)
fi

if [ -z "$TEMPLATE" ]; then
  echo "Kein passendes Debian-Template gefunden. Bitte Templates im Proxmox Host prüfen." >&2
  exit 4
fi

echo "Using template: $TEMPLATE"
echo "Downloading template to local storage (if needed)..."
pveam download local "$TEMPLATE"

echo "Creating container..."

# build network option
if [ "$CT_IP" = "dhcp" ] || [ -z "$CT_IP" ]; then
  NET_OPT="--net0 name=eth0,bridge=$NET_BRIDGE,ip=dhcp"
else
  NET_OPT="--net0 name=eth0,bridge=$NET_BRIDGE,ip=$CT_IP"
fi

pct create "$VMID" local:vztmpl/$TEMPLATE \
  --hostname "$CT_NAME" \
  --cores $DEFAULT_CORES \
  --memory $DEFAULT_MEMORY \
  $NET_OPT \
  --rootfs "$STORAGE:$DEFAULT_DISK" \
  --features nesting=1 \
  --unprivileged 0

echo "Starting container..."
pct start "$VMID"

echo "Waiting for container to finish initialization..."
sleep 5

if [ -n "$ROOT_PASSWORD" ]; then
  echo "Setting container root password..."
  printf 'root:%s\n' "$ROOT_PASSWORD" | pct exec "$VMID" -- chpasswd
fi
unset ROOT_PASSWORD ROOT_PASSWORD_CONFIRM

run_in_ct() {
  pct exec "$VMID" -- bash -lc "$1"
}

echo "Updating apt and installing prerequisites inside container..."
run_in_ct "apt-get update && apt-get install -y --no-install-recommends wget ca-certificates curl gnupg locales sudo tar bzip2 xz-utils unzip lib32gcc-s1 lib32stdc++6 && locale-gen en_US.UTF-8"

echo "Creating dedicated user 'satisfactory'..."
run_in_ct "id -u satisfactory >/dev/null 2>&1 || (useradd -m -s /bin/bash satisfactory && mkdir -p /home/satisfactory/steamcmd && chown -R satisfactory:satisfactory /home/satisfactory)"

echo "Installing SteamCMD into /home/satisfactory/steamcmd..."
run_in_ct "su -s /bin/bash -l satisfactory -c 'cd ~/steamcmd && wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf -'"

echo "Installing Satisfactory Dedicated Server (app $STEAM_APPID)..."
run_in_ct "su -s /bin/bash -l satisfactory -c '~/steamcmd/steamcmd.sh +force_install_dir ~/satisfactory-dedicated +login anonymous +app_update $STEAM_APPID validate +quit'"

echo "Creating start script and systemd service inside container..."
run_in_ct "cat > /home/satisfactory/start_satisfactory.sh <<'EOF'
#!/usr/bin/env bash
cd /home/satisfactory/satisfactory-dedicated || exit 1
if [ -x ./FactoryServer.sh ]; then
  exec ./FactoryServer.sh -log
elif [ -x ./FactoryGame/Binaries/Linux/SatisfactoryServer-Linux-Shipping ]; then
  exec ./FactoryGame/Binaries/Linux/SatisfactoryServer-Linux-Shipping -log
else
  echo 'Server binary not found in expected locations.' >&2
  exit 2
fi
EOF
chmod +x /home/satisfactory/start_satisfactory.sh
chown satisfactory:satisfactory /home/satisfactory/start_satisfactory.sh"

run_in_ct "cat > /etc/systemd/system/satisfactory.service <<'EOF'
[Unit]
Description=Satisfactory Dedicated Server
After=network.target

[Service]
Type=simple
User=satisfactory
Group=satisfactory
WorkingDirectory=/home/satisfactory
ExecStart=/home/satisfactory/start_satisfactory.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

echo "Creating update script and systemd timer (daily)..."
run_in_ct "cat > /usr/local/bin/update_satisfactory.sh <<'EOF'
#!/usr/bin/env bash
set -e
su -s /bin/bash -l satisfactory -c '~/steamcmd/steamcmd.sh +force_install_dir ~/satisfactory-dedicated +login anonymous +app_update $STEAM_APPID +quit'
systemctl --no-block restart satisfactory.service || true
EOF
chmod +x /usr/local/bin/update_satisfactory.sh"

run_in_ct "cat > /etc/systemd/system/satisfactory-update.service <<'EOF'
[Unit]
Description=Update Satisfactory Dedicated Server via SteamCMD

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update_satisfactory.sh
EOF
"

run_in_ct "cat > /etc/systemd/system/satisfactory-update.timer <<'EOF'
[Unit]
Description=Daily timer to run Satisfactory update

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
"

echo "Enabling and starting service and timer inside container..."
run_in_ct "systemctl daemon-reload && systemctl enable --now satisfactory.service && systemctl enable --now satisfactory-update.timer || true"

echo "Done. Container $VMID should be running the Satisfactory Dedicated Server service (check with: pct exec $VMID -- systemctl status satisfactory)."

echo "Notes:"
echo " - The script assumes a bridged network on 'vmbr0' with DHCP. Adjust network options in the script if needed."
echo " - Verify the Steam appid if installation fails."

exit 0
