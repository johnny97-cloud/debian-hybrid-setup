#!/bin/bash
set -euo pipefail

# Modern Apache2 setup for Debian 13 (Trixie) - 2025 best practices
# Installs Apache, enables basic security, sets up example virtual host
# Optional: PHP 8.4 + PHP-FPM with mpm_event for performance

echo "=== Modern Apache2 Setup for Debian 13 ==="

# Update system first (recommended)
apt update && apt upgrade -y

# Install Apache2
apt install -y apache2 apache2-utils

# Enable useful modules
a2enmod rewrite headers ssl  # Common essentials (ssl for future HTTPS)

# Switch to mpm_event + PHP-FPM for better performance (default prefork is slower)
a2dismod mpm_prefork || true
a2enmod mpm_event || true

# Ask about PHP
read -p "Install PHP 8.4 support with PHP-FPM? (y/N): " install_php
if [[ "$install_php" =~ ^[Yy]$ ]]; then
    apt install -y php8.4 php8.4-fpm libapache2-mod-fcgid
    a2enmod proxy_fcgi setenvif
    a2enconf php8.4-fpm
    echo "PHP 8.4 + FPM installed and configured with Apache."
fi

# Hide Apache version & OS info (security best practice)
SEC_CONF="/etc/apache2/conf-available/security.conf"
cp "$SEC_CONF" "${SEC_CONF}.bak" 2>/dev/null || true
sed -i 's/^ServerTokens .*/ServerTokens Prod/' "$SEC_CONF"
sed -i 's/^ServerSignature .*/ServerSignature Off/' "$SEC_CONF"
echo "Server version hidden (ServerTokens Prod + ServerSignature Off)"

# Disable default virtual host
a2dissite 000-default.conf || true

# Create example virtual host directory
EXAMPLE_DIR="/var/www/example.lan"
mkdir -p "$EXAMPLE_DIR/public_html" "$EXAMPLE_DIR/logs"

# Simple index page
echo "<html><body><h1>Welcome to example.lan!</h1><p>Apache is working on Debian 13.</p></body></html>" > "$EXAMPLE_DIR/public_html/index.html"
chown -R www-data:www-data "$EXAMPLE_DIR"

# Create virtual host config
VHOST_CONF="/etc/apache2/sites-available/example.lan.conf"
cat > "$VHOST_CONF" <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@example.lan
    ServerName example.lan
    ServerAlias www.example.lan

    DocumentRoot $EXAMPLE_DIR/public_html

    <Directory $EXAMPLE_DIR/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $EXAMPLE_DIR/logs/error.log
    CustomLog $EXAMPLE_DIR/logs/access.log combined
</VirtualHost>
EOF

# Enable the site
a2ensite example.lan.conf

# Test config & restart
apachectl configtest && systemctl restart apache2

echo "=== Apache setup complete! ==="
echo "Test at: http://localhost or http://example.lan (add to /etc/hosts if needed)"
echo "For real domains: copy example.lan.conf, edit ServerName/DocumentRoot, then a2ensite and restart Apache."
echo "For HTTPS: install certbot and run 'certbot --apache' later."
