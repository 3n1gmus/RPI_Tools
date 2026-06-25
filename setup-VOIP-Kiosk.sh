#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "================================================="
echo " Starting Raspberry Pi 4 Video Kiosk Setup Script"
echo "================================================="

# 1. Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (e.g., sudo ./setup_kiosk.sh)"
  exit 1
fi

# 2. Update System and Install Prerequisites
echo "--> Updating package lists and upgrading system..."
apt update && apt full-upgrade -y

echo "--> Installing unclutter (to hide mouse cursor)..."
apt install unclutter -y

echo "--> Installing automatic update tools..."
apt install unattended-upgrades apt-listchanges -y

# 3. Configure Automatic Updates (Unattended-Upgrades)
echo "--> Configuring unattended-upgrades..."
# Force enable the automatic upgrades system cleanly via configuration seeds
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

UPGRADE_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
if [ -f "$UPGRADE_CONF" ]; then
    echo "--> Configuring 3:00 AM maintenance window for updates requiring reboots..."
    
    # Clean up any existing matching entries to avoid duplicates
    sed -i '/Unattended-Upgrade::Automatic-Reboot /d' "$UPGRADE_CONF"
    sed -i '/Unattended-Upgrade::Automatic-Reboot-WithUsers/d' "$UPGRADE_CONF"
    sed -i '/Unattended-Upgrade::Automatic-Reboot-Time/d' "$UPGRADE_CONF"
    
    # Append kiosk-optimized reboot parameters before the final closing brace block
    cat << 'EOF' >> "$UPGRADE_CONF"

// Kiosk Specific Automation Added via Setup Script
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF
fi

# 4. Optimize GPU Memory (Setting to 128MB)
CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="/boot/config.txt"
fi

echo "--> Optimizing GPU Memory to 128MB in $CONFIG_FILE..."
sed -i '/^gpu_mem=/d' "$CONFIG_FILE"
echo "gpu_mem=128" >> "$CONFIG_FILE"

# 5. Force CPU to Performance Mode via native systemd
echo "--> Creating systemd service for CPU performance governor..."
cat << 'EOF' > /etc/systemd/system/cpu-performance.service
[Unit]
Description=Force CPU Scaling Governor to Performance Mode
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload and engage the new service
systemctl daemon-reload
systemctl enable cpu-performance.service
systemctl start cpu-performance.service

# 6. Configure Labwc Environment Autostart (Run as the normal user)
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)
AUTOSTART_DIR="$USER_HOME/.config/labwc"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

echo "--> Configuring Labwc kiosk autostart for user: $REAL_USER..."
mkdir -p "$AUTOSTART_DIR"

if [ -f "$AUTOSTART_FILE" ]; then
    mv "$AUTOSTART_FILE" "${AUTOSTART_FILE}.bak"
fi

cat << 'EOF' > "$AUTOSTART_FILE"
# ==========================================
# Kiosk Autostart Profile
# ==========================================

# 1. Hide mouse cursor after 3 seconds of inactivity
unclutter -idle 3 -root &

# 2. Launch Chromium in dedicated Kiosk Mode
# Change the URL below to your dashboard, Jitsi instance, or Google Meet URL
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --no-first-run \
  --start-maximized \
  --autoplay-policy=no-user-gesture-required \
  --use-fake-ui-for-media-stream \
  https://meet.google.com &
EOF

chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config"

echo "================================================="
echo " Setup Complete! "
echo " Your Pi will automatically apply security updates "
echo " and restart at 3:00 AM only if a reboot is needed."
echo "================================================="
echo "Rebooting in 5 seconds... Press Ctrl+C to abort."
sleep 5
reboot