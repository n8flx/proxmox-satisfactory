# Proxmox Helper: Satisfactory LXC

Kurz: Dieses Hilfs-Skript erstellt eine Debian-LXC auf einem Proxmox VE Host,
installiert SteamCMD und den Satisfactory Dedicated Server, richtet einen
`systemd`-Service sowie einen täglichen Update-Timer ein.

Datei: `scripts/create_satisfactory_lxc.sh`

Kurzanleitung:

- Auf Proxmox-Host als `root` ausführen:

```bash
bash scripts/create_satisfactory_lxc.sh 101 satisfactory local-lvm
```

- Der Script fragt interaktiv nach fehlenden Parametern.
- Standard-Netz: `vmbr0` (DHCP). Passe `--net0` in der Skript-Datei an, falls notwendig.
- Standard-Speicher: `local-lvm`. Ändere den dritten Parameter, wenn du anderes Storage nutzen willst.
- Prüfe `STEAM_APPID` in der Skript-Datei, falls die Installation fehlschlägt.

Nach der Ausführung:

- Service prüfen: `pct exec <VMID> -- systemctl status satisfactory`
- Logs: `pct exec <VMID> -- journalctl -u satisfactory -f`

Hinweis:

- Das Skript versucht, ein aktuelles Debian-Template (Debian 12 bevorzugt) per `pveam` herunterzuladen.
- Die Installation läuft im Container als Benutzer `satisfactory`.
- Unprivilegierte Container können Einschränkungen haben; das Skript erstellt ein privilegiertes LXC (`--unprivileged 0`).
