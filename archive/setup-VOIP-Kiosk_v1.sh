#!/bin/bash

# 1. Update and install dependencies
echo "Updating system and installing Chromium..."
apt update && apt upgrade -y
apt install -y chromium-browser x11-xserver-utils sed

# 2. Create the HTML Dashboard
echo "Creating the Kiosk Dashboard..."
cat <<EOF > /home/$USER/kiosk_home.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Meeting Kiosk</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f0f0f; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; overflow: hidden; }
        h1 { margin-bottom: 40px; color: #00ff88; font-weight: 300; letter-spacing: 2px; }
        .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 25px; }
        .btn { width: 220px; padding: 35px; text-align: center; border-radius: 12px; text-decoration: none; color: white; font-weight: bold; font-size: 1.4rem; transition: all 0.2s ease; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 4px 15px rgba(0,0,0,0.3); }
        .btn:hover { transform: translateY(-5px); filter: brightness(1.2); box-shadow: 0 8px 25px rgba(0,0,0,0.5); }
        .zoom { background: #2D8CFF; }
        .meet { background: #00832D; }
        .teams { background: #4B53BC; }
        .jitsi { background: #ff4000; }
        .url-box { margin-top: 40px; display: flex; gap: 10px; }
        input { padding: 15px; border-radius: 8px; border: none; width: 300px; font-size: 1rem; }
        .go-btn { padding: 15px 25px; background: #00ff88; color: black; border-radius: 8px; font-weight: bold; cursor: pointer; border: none; }
    </style>
</head>
<body>
    <h1>CONFERENCE HUB</h1>
    <div class="grid">
        <a href="https://zoom.us/join" class="btn zoom">Zoom</a>
        <a href="https://meet.google.com" class="btn meet">Google Meet</a>
        <a href="https://teams.microsoft.com/_#/scheduling-grid" class="btn teams">MS Teams</a>
        <a href="https://meet.jit.si/" class="btn jitsi">Jitsi Meet</a>
    </div>
    <div class="url-box">
        <input type="text" id="meetingUrl" placeholder="Paste Meeting Link Here...">
        <button class="go-btn" onclick="window.location.href=document.getElementById('meetingUrl').value">JOIN</button>
    </div>
</body>
</html>
EOF

chown $USER:$USER /home/$USER/kiosk_home.html

# 3. Configure Autostart (Global LXDE-pi)
echo "Configuring Autostart and disabling screen sleep..."
mkdir -p /home/$USER/.config/lxsession/LXDE-pi/
AUTOSTART_FILE="/home/$USER/.config/lxsession/LXDE-pi/autostart"

cat <<EOF > $AUTOSTART_FILE
@xset s off
@xset -dpms
@xset s noblank
@chromium-browser --kiosk --noerrdialogs --disable-infobars --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" /home/$USER/kiosk_home.html
EOF

chown $USER:$USER $AUTOSTART_FILE

# 4. Adjust GPU Memory (requires reboot)
echo "Increasing GPU Memory to 256MB..."
if grep -q "gpu_mem" /boot/config.txt; then
    sed -i 's/gpu_mem=.*/gpu_mem=256/' /boot/config.txt
else
    echo "gpu_mem=256" >> /boot/config.txt
fi

echo "-------------------------------------------------------"
echo "Setup Complete! Your Pi will boot into the Kiosk after reboot."
echo "Note: If using Pi 5, ensure your cooling fan is connected."
echo "REBOOTING IN 10 SECONDS... Press Ctrl+C to cancel."
echo "-------------------------------------------------------"
sleep 10
reboot