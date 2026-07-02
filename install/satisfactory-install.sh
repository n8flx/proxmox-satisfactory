#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: n8flx
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://www.satisfactorygame.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  lib32gcc-s1 \
  lib32stdc++6
msg_ok "Installed Dependencies"

msg_info "Creating Satisfactory User"
useradd --system \
  --create-home \
  --home-dir /opt/satisfactory \
  --shell /usr/sbin/nologin \
  satisfactory
mkdir -p /opt/steamcmd /opt/satisfactory/server
chown -R satisfactory:satisfactory /opt/steamcmd /opt/satisfactory
msg_ok "Created Satisfactory User"

msg_info "Installing SteamCMD"
curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz |
  tar -xz -C /opt/steamcmd
chown -R satisfactory:satisfactory /opt/steamcmd
msg_ok "Installed SteamCMD"

msg_info "Installing Satisfactory Dedicated Server"
$STD runuser -u satisfactory -- /opt/steamcmd/steamcmd.sh \
  +force_install_dir /opt/satisfactory/server \
  +login anonymous \
  +app_update 1690800 validate \
  +quit
msg_ok "Installed Satisfactory Dedicated Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/satisfactory.service
[Unit]
Description=Satisfactory Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=satisfactory
Group=satisfactory
WorkingDirectory=/opt/satisfactory/server
Environment=HOME=/opt/satisfactory
Environment=LANG=C.UTF-8
ExecStart=/opt/satisfactory/server/FactoryServer.sh -log
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=120
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now satisfactory
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
