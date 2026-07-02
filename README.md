# Satisfactory Dedicated Server – Proxmox VE Helper Script

This repository contains a Community Scripts-compatible helper for deploying
the official Satisfactory Dedicated Server in a Debian 13 LXC on Proxmox VE.
It installs the server with SteamCMD, creates a systemd service, exposes live
logs on the LXC console and provides an integrated update action.

## Community Scripts submission files

The files follow the current
[Proxmox VE Community Scripts contribution structure](https://community-scripts.org/docs/contribution/readme):

| File | Purpose |
| --- | --- |
| `ct/satisfactory.sh` | Proxmox host entry point, container defaults and update action |
| `install/satisfactory-install.sh` | Installation performed inside the LXC |

New scripts must first be submitted to the
[ProxmoxVED development repository](https://github.com/community-scripts/ProxmoxVED).
They should not be submitted directly to the production `ProxmoxVE`
repository. Website metadata is submitted through the separate site/backend
workflow and must not be added to the script PR.

The clean submission branch must contain only:

```text
ct/satisfactory.sh
install/satisfactory-install.sh
```

The contribution must be tested from a personal ProxmoxVED fork using the
official `docs/contribution/setup-fork.sh --full` workflow. Static checks in
this repository do not replace Default, Advanced and update testing on a real
Proxmox VE host.

## Publication limitation

The current Community Scripts contribution guide states that new
closed-source applications are not accepted. Satisfactory and its dedicated
server are proprietary Steam content, so acceptance requires an explicit
exception from the Community Scripts maintainers before opening a pull
request.

## Defaults

| Setting | Value |
| --- | --- |
| OS | Debian 13 (Trixie) |
| CPU | 4 cores |
| RAM | 8192 MiB |
| Disk | 20 GiB |
| Container | Unprivileged |
| Game/API port | 7777 TCP and UDP |
| Reliable messaging | 8888 TCP |

Advanced setup in the Community Scripts installer can override the container
resources, storage and networking.

## Operation

The service is managed with:

```bash
systemctl status satisfactory
systemctl restart satisfactory
journalctl -u satisfactory -f
```

The game also rotates its own logs below:

```text
/opt/satisfactory/server/FactoryGame/Saved/Logs
```

Use the Community Scripts update action to back up the server data, validate
and update App ID `1690800`, restore the data and restart the server.

Add the container address in Satisfactory's **Server Manager** using port
`7777`, then claim and configure the server there.

## Legacy standalone installer

The earlier standalone implementation remains available under
`scripts/create_satisfactory_lxc.sh`. The files in `ct/` and `install/` are
the versions prepared for a Community Scripts contribution.

## License

[MIT](LICENSE)
