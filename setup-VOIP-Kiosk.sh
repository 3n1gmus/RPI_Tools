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
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

UPGRADE_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
if [ -f "$UPGRADE_CONF" ]; then
    echo "--> Configuring 3:00 AM maintenance window for updates requiring reboots..."
    sed -i '/Unattended-Upgrade::Automatic-Reboot /d' "$UPGRADE_CONF"
    sed -i '/Unattended-Upgrade::Automatic-Reboot-WithUsers/d' "$UPGRADE_CONF"
    sed -i '/Unattended-Upgrade::Automatic-Reboot-Time/d' "$UPGRADE_CONF"
    
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

systemctl daemon-reload
systemctl enable cpu-performance.service
systemctl start cpu-performance.service

# 6. Configure Kanshi Display Profile (Forced Mirroring + 1680x1050 Upper Cap)
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)

echo "--> Setting up Kanshi display profile for mirroring and resolution constraints..."
mkdir -p "$USER_HOME/.config/kanshi"

cat << 'EOF' > "$USER_HOME/.config/kanshi/config"
profile {
    output HDMI-A-1 mode <= 1680x1050 position 0,0
    output HDMI-A-2 mode <= 1680x1050 position 0,0
}
EOF

# Set local folder permissions for the real user
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config"

# Create global system default folder so ANY future users inherit this rule
echo "--> Copying Kanshi configuration to system defaults (/etc/xdg/kanshi/config)..."
mkdir -p /etc/xdg/kanshi
cp "$USER_HOME/.config/kanshi/config" /etc/xdg/kanshi/config

# 7. Configure Desktop XDG Autostart & Wrapper Script
AUTOSTART_DIR="$USER_HOME/.config/autostart"
echo "--> Configuring Desktop XDG autostart for user: $REAL_USER..."
mkdir -p "$AUTOSTART_DIR"

# A. Create the background launcher helper script to wipe crash markers safely
echo "--> Generating background kiosk browser launcher script..."
cat << 'EOF' > /usr/local/bin/kiosk-browser.sh
#!/bin/bash
PREFS_FILE="$HOME/.config/chromium/Default/Preferences"
LOCAL_STATE="$HOME/.config/chromium/Local State"

if [ -f "$PREFS_FILE" ]; then
    sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/g' "$PREFS_FILE"
    sed -i 's/"exited_cleanly":false/"exited_cleanly":true/g' "$PREFS_FILE"
fi

if [ -f "$LOCAL_STATE" ]; then
    sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/g' "$LOCAL_STATE"
    sed -i 's/"exited_cleanly":false/"exited_cleanly":true/g' "$LOCAL_STATE"
fi

sleep 3
/usr/bin/chromium --start-maximized --password-store=basic --autoplay-policy=no-user-gesture-required --use-fake-ui-for-media-stream
EOF

chmod +x /usr/local/bin/kiosk-browser.sh

# B. Create a clean, standard-compliant Chromium launcher shortcut pointing to our script
cat << 'EOF' > "$AUTOSTART_DIR/kiosk.desktop"
[Desktop Entry]
Type=Application
Name=Chromium Kiosk
Comment=Launch Chromium cleanly on startup via wrapper script
Exec=/usr/local/bin/kiosk-browser.sh
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

# C. Create the Unclutter mouse-hiding launcher
cat << 'EOF' > "$AUTOSTART_DIR/hide-mouse.desktop"
[Desktop Entry]
Type=Application
Name=Hide Mouse Cursor
Comment=Hide the mouse pointer automatically during kiosk execution
Exec=unclutter -idle 3 -root
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

# Ensure the real user owns the autostart shortcuts completely
chown -R "$REAL_USER":"$REAL_USER" "$AUTOSTART_DIR"

echo "================================================="
echo " Setup Complete! "
echo " Kiosk initialization has shifted to XDG Autostart."
echo "================================================="
echo "Rebooting in 5 seconds... Press Ctrl+C to abort."
sleep 5
reboot