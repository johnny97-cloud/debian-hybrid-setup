#!/bin/bash

# setup-basic.sh - Basic Debian system setup (2025 best practices)
# Part of debian-hybrid-setup project
# Run as root (or with sudo) on a fresh Debian installation

set -euo pipefail

echo "========================================"
echo "  Debian Basic Setup - Hybrid Project   "
echo "========================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (or with sudo)"
   exit 1
fi

# Update package lists and upgrade system
echo "Updating package index and upgrading installed packages..."
apt update
apt upgrade -y
apt autoremove -y

# Install essential and commonly useful packages
echo "Installing basic tools and utilities..."
apt install -y \
    curl wget git vim nano \
    htop iotop iftop \
    unzip unrar-free p7zip-full \
    ca-certificates \
    sudo locales tzdata \
    bash-completion \
    man-db \
    fail2ban  # Basic brute-force protection

# Set timezone interactively (or default to UTC)
echo "Setting timezone..."
dpkg-reconfigure tzdata

# Set locale to en_US.UTF-8 (most common safe default)
echo "Configuring locale..."
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/default/locale

# Optional: Create a non-root sudo user (recommended for security)
read -p "Create a new sudo user? (y/N): " create_user
if [[ $create_user =~ ^[Yy]$ ]]; then
    read -p "Enter username: " username
    if id "$username" &>/dev/null; then
        echo "User $username already exists."
    else
        adduser --gecos "" "$username"
        usermod -aG sudo "$username"
        echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$username"
        chmod 0440 /etc/sudoers.d/"$username"
        echo "User $username created with sudo privileges."
    fi
fi

# Basic firewall setup (ufw - simple and effective)
echo "Setting up basic firewall (UFW)..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH  # Allows SSH (port 22) - adjust if you change port later
ufw --force enable
echo "UFW firewall enabled with SSH allowed."

# Optional: Run SSH server hardening
read -p "Configure secure SSH server now? (y/N): " setup_ssh_server
if [[ $setup_ssh_server =~ ^[Yy]$ ]]; then
    if [[ -f "./services/ssh/ssh_server-conf.sh" ]]; then
        echo "Running SSH server hardening..."
        bash ./services/ssh/ssh_server-conf.sh
    else
        echo "SSH server script not found in ./services/ssh/"
    fi
fi

# Optional: Switch to non-root user and setup SSH client
if [[ $create_user =~ ^[Yy]$ ]] && [[ -n "${username:-}" ]]; then
    read -p "Switch to user $username and configure SSH client? (y/N): " setup_client
    if [[ $setup_client =~ ^[Yy]$ ]]; then
        echo "Switching to $username to run client setup..."
        if [[ -f "./services/ssh/ssh_client-conf.sh" ]]; then
            su - "$username" -c "bash ./services/ssh/ssh_client-conf.sh"
        else
            echo "SSH client script not found."
        fi
    fi
fi

echo
echo "========================================"
echo "Basic Debian setup complete!"
echo "========================================"
echo
echo "Next steps:"
echo "  • Reboot if kernel was updated"
echo "  • Test SSH access with keys (not passwords)"
echo "  • Consider additional hardening (e.g., AppArmor, unattended-upgrades)"
echo "  • Install unattended-upgrades for auto security updates:"
echo "      apt install unattended-upgrades && dpkg-reconfigure unattended-upgrades"
echo
echo "Your system is now more secure and ready for further customization."
