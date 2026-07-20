# Satisfactory Dedicated Server – Proxmox VE Helper Script

This repository contains a Community Scripts-compatible helper for deploying
the official Satisfactory Dedicated Server in a Debian 13 LXC on Proxmox VE.
It installs the server with SteamCMD, creates a systemd service, exposes live
logs on the LXC console and provides an integrated update action.

## Install

To create a Satisfactory LXC, run the following command in the Proxmox VE
Shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/n8flx/proxmox-satisfactory/main/bootstrap.sh)" -- auto satisfactory local-lvm vmbr0 dhcp
```

The command downloads and executes the standalone installer from this
repository. It:

- selects the next available container ID;
- creates a Debian 13 LXC named `satisfactory`, falling back to Debian 12 if
  the Trixie template is unavailable;
- uses `local-lvm` for its 20 GiB root disk and `vmbr0` with DHCP;
- optionally sets a root password for console login;
- installs SteamCMD and Satisfactory Dedicated Server App ID `1690800`;
- runs SteamCMD and the game server as the dedicated unprivileged `steam` user;
- creates and starts the `satisfactory.service`;
- enables the update timer and writes logs to both journald and the LXC
  console.

Review the downloaded script before execution when required by your security
policy. The storage, bridge and IP parameters can be changed at the end of the
command.

If the helper is accepted and published by Community Scripts, its official
installation command will be:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/satisfactory.sh)"
```

That future URL does not work until the contribution has been accepted and
deployed to `community-scripts/ProxmoxVE`.

## Community Scripts submission files

The files follow the current
[Proxmox VE Community Scripts contribution structure](https://community-scripts.org/docs/contribution/readme):

| File | Purpose |
| --- | --- |
| `ct/satisfactory.sh` | Proxmox host entry point, container defaults and update action |
| `install/satisfactory-install.sh` | Installation performed inside the LXC |
| `json/satisfactory.json` | Website metadata required by the current ProxmoxVED PR template |

New scripts must first be submitted to the
[ProxmoxVED development repository](https://github.com/community-scripts/ProxmoxVED).
They should not be submitted directly to the production `ProxmoxVE`
repository. Although the website guide describes a separate metadata
workflow, the current ProxmoxVED repository template and automated validator
still require the matching top-level JSON file.

The clean submission branch must contain only:

```text
ct/satisfactory.sh
install/satisfactory-install.sh
json/satisfactory.json
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
request. It also has no public GitHub repository with 600 or more stars and
is distributed through SteamCMD instead of official release tarballs; the
automated ProxmoxVED validator therefore closes the submission for unmet
application requirements.

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

The service launches `FactoryServer.sh` as the dedicated `steam` account. Do
not start the game server manually as `root`.

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
`scripts/create_satisfactory_lxc.sh`. The files in `ct/`, `install/` and
`json/` are the versions prepared for a Community Scripts contribution.

## License

[MIT](LICENSE)
