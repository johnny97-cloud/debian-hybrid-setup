#!/bin/bash

# Modern Secure OpenSSH Server Configuration Script
# Suitable for Debian 12+ (Bookworm) and later — tested in 2025
# Run as root (or with sudo)

set -euo pipefail  # Better error handling

echo "Starting secure OpenSSH configuration..."

# Install openssh-server if not already installed
if ! dpkg -l | grep -q openssh-server; then
    echo "Installing openssh-server..."
    apt update
    apt install -y openssh-server
fi

# Backup the original config with timestamp
CONFIG="/etc/ssh/sshd_config"
BACKUP="${CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG" "$BACKUP"
echo "Backed up original config to $BACKUP"

# Helper function to set or update a config line
set_config() {
    local key="$1"
    local value="$2"
    local file="$3"

    if grep -q "^#*$key " "$file"; then
        sed -i "s/^#*$key .*/$key $value/" "$file"
    else
        echo "$key $value" >> "$file"
    fi
}

# Apply targeted secure settings

# Disable root login
set_config "PermitRootLogin" "no" "$CONFIG"

# Disable password authentication (force key-based only)
set_config "PasswordAuthentication" "no" "$CONFIG"

# Ensure public key authentication is enabled
set_config "PubkeyAuthentication" "yes" "$CONFIG"

# Reduce login grace time (disconnect if no auth in 60 seconds)
set_config "LoginGraceTime" "60" "$CONFIG"

# Limit authentication attempts
set_config "MaxAuthTries" "3" "$CONFIG"

# Disconnect idle sessions after 5 minutes
set_config "ClientAliveInterval" "300" "$CONFIG"
set_config "ClientAliveCountMax" "0" "$CONFIG"

# Explicitly disable empty passwords (default, but good to be clear)
set_config "PermitEmptyPasswords" "no" "$CONFIG"

# Optional: Add a login banner (legal notice)
BANNER_DIR="/etc/ssh-banner"
BANNER_FILE="$BANNER_DIR/banner"

if [ ! -f "$BANNER_FILE" ]; then
    mkdir -p "$BANNER_DIR"
    cat << 'EOF' > "$BANNER_FILE"
********************************************************************************
*                     UNAUTHORIZED ACCESS PROHIBITED                           *
*                                                                              *
* This system is for the use of authorized users only. All activity may be     *
* monitored and recorded. Individuals using this system without authority or   *
* in excess of their authority are subject to having all their activities      *
* logged and prosecuted to the fullest extent of the law.                      *
*                                                                              *
* Disconnect IMMEDIATELY if you are not an authorized user.                    *
********************************************************************************
EOF
    echo "Created SSH banner at $BANNER_FILE"
fi

# Enable banner if not already set
set_config "Banner" "/etc/ssh-banner/banner" "$CONFIG"

# Optional: Stronger crypto (uncomment if you want to enforce modern algorithms only)
# These are often already default, but you can force them:
# echo "" >> "$CONFIG"
# echo "# Enforce strong modern cryptography" >> "$CONFIG"
# echo "KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512" >> "$CONFIG"
# echo "HostKeyAlgorithms ssh-ed25519,rsa-sha2-512" >> "$CONFIG"
# echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com" >> "$CONFIG"
# echo "MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com" >> "$CONFIG"

# Test the configuration syntax
echo "Testing SSH configuration syntax..."
if ! sshd -t; then
    echo "ERROR: Invalid SSH configuration! Reverting to backup..."
    cp "$BACKUP" "$CONFIG"
    exit 1
fi

# Restart SSH service
echo "Restarting SSH service..."
systemctl restart ssh

echo "OpenSSH has been securely configured!"
echo ""
echo "Recommendations:"
echo "  • Use strong SSH keys (prefer ed25519: ssh-keygen -t ed25519)"
echo "  • Consider installing fail2ban for brute-force protection"
echo "  • Restrict access via firewall (ufw/iptables) to trusted IPs only"
echo "  • For internet-facing servers: use a VPN or bastion host instead of direct SSH exposure"
