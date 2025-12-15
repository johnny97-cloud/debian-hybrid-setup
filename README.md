![Debian Logo](assets/logo.png "Debian logo") Debian Server                                                                                                         
===============================

# A collection of modern, secure scripts for setting up a fresh Debian system (servers, containers, or VMs). 

## Features
- `setup-basic.sh`: Updates system, installs essentials, sets locale/timezone, optional sudo user.
- `services/ssh/ssh_server-conf.sh`: Hardens OpenSSH server (key-only, no root login).
- `services/ssh/ssh_client-conf.sh`: Generates secure Ed25519 keys and sensible client config.

---
Supported services (so far):
- Samba (file sharing)
- NFS (network file system)
- Apache (web server)
- MariaDB
- VSFTPD
- SSH (hardened)
- Backups
- User management
- Basic firewall & quota

## Quick Start

```bash
# Clone the repo
git clone https://github.com/idhirandar/debian-hybrid-setup.git
cd debian-hybrid-setup

