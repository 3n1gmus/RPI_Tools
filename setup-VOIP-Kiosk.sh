#!/bin/bash

# 1. Update and install dependencies
echo "Installing dependencies..."
sudo apt update && sudo apt install -y chromium-browser x11-xserver-utils wget libfuse2 xdg-utils

# 2. Download and Setup Keet (The "Smart" way)
echo "Downloading Keet..."
mkdir -p ~/Apps
wget -O ~/Apps/keet-linux.tar.gz https://static.keet.io/downloads/latest/Keet-arm64.tar.gz
cd ~/Apps && tar -xvf keet-linux.tar.gz

# Find whatever was extracted (Keet or Keet.AppImage) and standardize it
mv ~/Apps/Keet* ~/Apps/keet.bin
chmod +x ~/Apps/keet.bin

# Symlink to a standard location
sudo ln -sf ~/Apps/keet.bin /usr/local/bin/keet

# 3. Register the Protocol Handler
echo "Registering keet:// protocol..."
mkdir -p ~/.local/share/applications
cat <<EOF > ~/.local/share/applications/keet.desktop
[Desktop Entry]
Name=Keet
Exec=/usr/local/bin/keet --appimage-extract-and-run %u
Type=Application
Terminal=false
MimeType=x-scheme-handler/keet;
EOF

xdg-mime default keet.desktop x-scheme-handler/keet

# 4. Create the Final Dashboard
echo "Creating Dashboard..."
cat <<EOF > /home/$USER/kiosk_home.html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { background: #000; color: #fff; font-family: sans-serif; text-align: center; padding-top: 10vh; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; max-width: 600px; margin: auto; }
        .btn { padding: 40px; border-radius: 15px; text-decoration: none; color: white; font-weight: bold; border: 2px solid #333; font-size: 1.2rem; }
        .keet { background: #fff; color: #000; grid-column: span 2; border-color: #00ff88; }
        .zoom { background: #2D8CFF; }
        .meet { background: #00832D; }
    </style>
</head>
<body>
    <h1>CONFERENCE HUB</h1>
    <div class="grid">
        <a href="keet://open" class="btn keet">LAUNCH KEET P2P</a>
        <a href="https://zoom.us/join" class="btn zoom">Zoom</a>
        <a href="https://meet.google.com" class="btn meet">Google Meet</a>
    </div>
</body>
</html>
EOF

# 5. Set up Kiosk Autostart
echo "Setting up Autostart..."
mkdir -p ~/.config/lxsession/LXDE-pi/
cat <<EOF > ~/.config/lxsession/LXDE-pi/autostart
@xset s off
@xset -dpms
@xset s noblank
@chromium-browser --kiosk --noerrdialogs --disable-infobars /home/$USER/kiosk_home.html
EOF

echo "All set! Reboot to start your kiosk."