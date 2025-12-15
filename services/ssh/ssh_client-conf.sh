#!/bin/bash

# Modern SSH Client Configuration Script
# For Debian/Ubuntu systems (2025 best practices)
# Generates secure keys and sets up a sensible ~/.ssh/config

set -euo pipefail

echo "Setting up modern SSH client configuration..."

# Install openssh-client if missing
if ! dpkg -l | grep -q openssh-client; then
    echo "Installing openssh-client..."
    sudo apt update
    sudo apt install -y openssh-client
fi

# Create .ssh directory with correct permissions
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Ask for email/comment for the key
read -p "Enter your email or name for key comment (e.g., user@example.com): " comment
comment=${comment:-$(whoami)@$(hostname)}

# Preferred: Generate Ed25519 key (modern default)
KEY_TYPE="ed25519"
KEY_FILE="$SSH_DIR/id_ed25519"

if ssh-keygen -t ed25519 -C "$comment" -f "$KEY_FILE" -N "" >/dev/null 2>&1; then
    echo "Generated Ed25519 key pair at $KEY_FILE"
else
    # Fallback to RSA-4096 if Ed25519 not supported (very old systems)
    echo "Ed25519 not supported, falling back to RSA-4096..."
    KEY_TYPE="rsa"
    KEY_FILE="$SSH_DIR/id_rsa"
    ssh-keygen -t rsa -b 4096 -C "$comment" -f "$KEY_FILE" -N "" >/dev/null
    echo "Generated RSA-4096 key pair at $KEY_FILE"
fi

# Set correct permissions on keys
chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE.pub"

# Create or update ~/.ssh/config with secure defaults
CONFIG_FILE="$SSH_DIR/config"

cat << EOF > "$CONFIG_FILE"
# Global SSH client configuration - secure defaults

Host *
    # Prefer modern key types
    PubkeyAcceptedKeyTypes +ssh-ed25519,sk-ssh-ed25519@openssh.com,rsa-sha2-512,rsa-sha2-256

    # Strong key exchange, ciphers, and MACs
    KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com

    # Security options
    StrictHostKeyChecking ask          # Ask on first connect, then remember
    PasswordAuthentication no          # Don't fall back to password if key fails
    ChallengeResponseAuthentication no
    GSSAPIAuthentication no            # Disable if not needed (faster)
    IdentitiesOnly yes                 # Only use explicitly specified keys

    # Convenience
    ServerAliveInterval 60             # Keep connections alive
    ServerAliveCountMax 3
    ForwardAgent no                    # Enable per-host if needed
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 4h

# Example host entries (uncomment and customize as needed)
# Host github.com
#     HostName github.com
#     User git
#     IdentityFile ~/.ssh/id_ed25519
#     Port 22

# Host myserver
#     HostName 192.168.1.100
#     User myuser
#     Port 22
EOF

# Create sockets directory for multiplexing
mkdir -p "$SSH_DIR/sockets"
chmod 700 "$SSH_DIR/sockets"

chmod 600 "$CONFIG_FILE"

echo ""
echo "SSH client setup complete!"
echo "Public key (copy this to servers or GitHub/GitLab):"
echo "----------------------------------------------------"
cat "$KEY_FILE.pub"
echo "----------------------------------------------------"
echo ""
echo "Tips:"
echo "  • Add your public key to servers: ssh-copy-id user@host"
echo "  • Or manually append to remote ~/.ssh/authorized_keys"
echo "  • Customize ~/.ssh/config for specific hosts as needed"
echo "  • For GitHub: Go to Settings > SSH keys and paste the public key above"
