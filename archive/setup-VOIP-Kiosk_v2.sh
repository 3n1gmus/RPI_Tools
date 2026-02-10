#!/bin/bash

# 1. Update and install core dependencies
echo "Updating system..."
sudo apt update && sudo apt install -y chromium-browser x11-xserver-utils wget libfuse2

# 2. Download and Setup Keet (Portable Binary)
echo "Downloading Keet..."
mkdir -p ~/Apps
# Note: This URL points to the latest Linux ARM64 version
wget -O ~/Apps/keet-linux.tar.gz https://static.keet.io/downloads/latest/Keet-arm64.tar.gz
cd ~/Apps && tar -xvf keet-linux.tar.gz
chmod +x ~/Apps/Keet
# Create a symlink for easy calling
sudo ln -sf ~/Apps/Keet /usr/local/bin/keet

# 3. Create the HTML Dashboard with Keet Integration
echo "Creating the Kiosk Dashboard..."
cat <<EOF > /home/$USER/kiosk_home.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Meeting Kiosk</title>
    <style>
        body { font-family: sans-serif; background: #0b0b0b; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
        .btn { width: 180px; padding: 30px; text-align: center; border-radius: 12px; text-decoration: none; color: white; font-weight: bold; border: 1px solid rgba(255,255,255,0.1); }
        .zoom { background: #2D8CFF; }
        .meet { background: #00832D; }
        .keet { background: #ffffff; color: black; border: 2px solid #00ff88; }
        .jitsi { background: #ff4000; }
        .clock { margin-top: 30px; font-size: 1.5rem; color: #555; }
    </style>
</head>
<body>
    <h1 style="color: #00ff88;">COMMUNICATION HUB</h1>
    <div class="grid">
        <a href="https://zoom.us/join" class="btn zoom">Zoom</a>
        <a href="https://meet.google.com" class="btn meet">Google Meet</a>
        <a href="https://meet.jit.si/" class="btn jitsi">Jitsi Meet</a>
    </div>
    <div style="margin-top:20px;">
        <button onclick="window.close();" class="btn keet">Launch Keet P2P</button>
    </div>
    <div class="clock" id="time"></div>
    <script>
        setInterval(() => { document.getElementById('time').innerText = new Date().toLocaleTimeString(); }, 1000);
    </script>
</body>
</html>
EOF

# 4. Finalizing Autostart
echo "Configuring Autostart..."
mkdir -p /home/$USER/.config/lxsession/LXDE-pi/
cat <<EOF > /home/$USER/.config/lxsession/LXDE-pi/autostart
@xset s off
@xset -dpms
@xset s noblank
@chromium-browser --kiosk --noerrdialogs --disable-infobars /home/$USER/kiosk_home.html
EOF

echo "Done! Run 'keet' in the terminal to test, or reboot to see the kiosk."