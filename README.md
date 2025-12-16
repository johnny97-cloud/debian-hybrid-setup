![Debian Logo](assets/logo.png "Debian logo") Debian Server                                                                                                         
===============================

# Debian Server Setup Guide (Debian 12/13)

**A complete, modern guide and script collection for setting up a secure Debian server from scratch – 2025 edition**

This repository provides **step-by-step documentation** and **safe, tested Bash scripts** to turn a fresh Debian 12 (Bookworm) or Debian 13 (Trixie) installation into a secure, production-ready server with common services (Apache, PHP, MariaDB, Bind9, Samba, NFS, etc.).

Whether you're setting up a home lab, VPS, or small business server, this project helps you do it quickly and securely.

### Purpose of This Repo

- Teach and automate best-practice Debian server configuration in 2025
- Provide **reliable, idempotent scripts** for common tasks (hardening, service installation)
- Offer a **clear, beginner-friendly guide** (GUIDE.md) explaining every step and why it matters
- Combine automation with learning – run scripts for speed or follow manually for understanding
- Modern replacement for outdated server setup repos (many are 8+ years old)

### Features

- Full written guide from fresh install to advanced services
- Simple Bash scripts organized by service
- Security-first approach (SSH hardening, UFW firewall, Fail2Ban, auto-updates)
- Easy one-command testing via Podman (for developers)
- Supports both Debian 12 and 13
- Future-ready: will add Ansible playbooks later

### How to Use This Repo

#### Option 1: Quick Start (Recommended for most users)

After installing Debian (minimal + OpenSSH server enabled):

```bash
# Log in as root or your initial user with sudo
sudo apt update && sudo apt install -y git curl

# Clone the repo
git clone https://github.com/idhirandar/debian-server-guide.git
cd debian-server-guide

# Run the basic setup first (highly recommended)
sudo bash setup-basic.sh
