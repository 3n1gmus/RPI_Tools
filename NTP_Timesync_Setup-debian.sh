#!/bin/bash

# --- CONFIGURATION ---
# Add your local NTP server address here.
# Example: LOCAL_NTP="192.168.1.50"
LOCAL_NTP="hylia.synthrealm.net"
FALLBACK_SERVERS="0.north-america.pool.ntp.org 1.north-america.pool.ntp.org 2.north-america.pool.ntp.org 3.north-america.pool.ntp.org"
CONF_FILE="/etc/systemd/timesyncd.conf"
# ---------------------

echo "NTP Setup Script"

# Cache sudo credentials at the start
echo "Please enter your password to authorize the setup:"
sudo -v

# Keep-alive loop to maintain sudo privileges
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 1. Backup the current config if it exists
if [ -f "$CONF_FILE" ]; then
    BACKUP_NAME="${CONF_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up current config to: $BACKUP_NAME"
    sudo cp "$CONF_FILE" "$BACKUP_NAME"
fi

# 2. Update package lists and install service
echo "Updating package lists..."
sudo apt update -y

echo "Installing systemd-timesyncd..."
sudo apt install -y systemd-timesyncd

# 3. Configure NTP servers
echo "Configuring NTP settings..."

# Set the Fallback servers
sudo sed -i "s|^#\?FallbackNTP=.*|FallbackNTP=$FALLBACK_SERVERS|" "$CONF_FILE"

if [ -n "$LOCAL_NTP" ] && [ "$LOCAL_NTP" != "your.local.ntp.server" ]; then
    echo "Setting primary NTP server to: $LOCAL_NTP"
    sudo sed -i "s|^#\?NTP=.*|NTP=$LOCAL_NTP|" "$CONF_FILE"
else
    echo "No local server specified, using North American pools as primary."
    sudo sed -i "s|^#\?NTP=.*|NTP=0.north-america.pool.ntp.org|" "$CONF_FILE"
fi

# 4. Enable and start the service
echo "Restarting service..."
sudo systemctl restart systemd-timesyncd
sudo systemctl enable systemd-timesyncd

# Ensure NTP synchronization is active
sudo timedatectl set-ntp true

echo "--------------------------------------"
echo "Setup Complete!"
echo "Primary:   ${LOCAL_NTP:-0.north-america.pool.ntp.org}"
echo "Fallbacks: $FALLBACK_SERVERS"
echo "Backup:    $BACKUP_NAME"
echo "--------------------------------------"
timedatectl status
