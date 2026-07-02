# Proxmox Helper: Satisfactory LXC

Kurz: Dieses Hilfs-Skript erstellt eine Debian-LXC auf einem Proxmox VE Host,
installiert SteamCMD und den Satisfactory Dedicated Server, richtet einen
`systemd`-Service sowie einen täglichen Update-Timer ein.

Datei: `scripts/create_satisfactory_lxc.sh`

Kurzanleitung:

- Klone oder kopiere das Git-Repository auf den Proxmox-Host und wechsle in das Repo-Verzeichnis:

```bash
cd /pfad/zum/proxmox-satisfactory
```

- Führe das Skript als `root` aus:

```bash
bash scripts/create_satisfactory_lxc.sh 101 satisfactory local-lvm vmbr0 dhcp
```

- Alternativ mit absolutem Repo-Pfad:

```bash
bash /pfad/zum/proxmox-satisfactory/scripts/create_satisfactory_lxc.sh 101 satisfactory local-lvm vmbr0 dhcp
```

- Oder direkt als Bootstrap-Download:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/n8flx/proxmox-satisfactory/main/bootstrap.sh) 101 satisfactory local-lvm vmbr0 dhcp
```

- Für statische IP:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/n8flx/proxmox-satisfactory/main/bootstrap.sh) 101 satisfactory local-lvm vmbr0 192.168.1.50/24
```

- Standard-Netz: `vmbr0` (DHCP) wenn kein IP-Argument angegeben wird.
- Standard-Speicher: `local-lvm`. Ändere den dritten Parameter, wenn du anderes Storage nutzen willst.
- Prüfe `STEAM_APPID` in der Skript-Datei, falls die Installation fehlschlägt.

Nach der Ausführung:

- Service prüfen: `pct exec <VMID> -- systemctl status satisfactory`
- Logs: `pct exec <VMID> -- journalctl -u satisfactory -f`

Hinweis:

- Das Skript versucht, ein aktuelles Debian-Template (Debian 12 bevorzugt) per `pveam` herunterzuladen.
- Die Installation läuft im Container als Benutzer `satisfactory`.
- Unprivilegierte Container können Einschränkungen haben; das Skript erstellt ein privilegiertes LXC (`--unprivileged 0`).
