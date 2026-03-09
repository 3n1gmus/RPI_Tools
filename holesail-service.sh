#!/bin/bash

# 1. Cleanup
echo "Cleaning up old service..."
sudo systemctl stop holesail.service 2>/dev/null
sudo systemctl disable holesail.service 2>/dev/null
sudo rm -f /etc/systemd/system/holesail.service
sudo systemctl daemon-reload

# 2. Configuration
echo "--- Holesail SSH Setup (52-char Key Fix) ---"
Z32_SAFE="ybndrfszgctmqpkhxwjica34567"

read -p "Enter Secret Key (Leave blank to auto-generate 52-char key): " USER_KEY

if [ -z "$USER_KEY" ]; then
    # GENERATING 52 CHARACTERS FOR A 32-BYTE DECODE
    HOLESAIL_KEY=$(LC_ALL=C tr -dc "$Z32_SAFE" < /dev/urandom | head -c 52)
    echo "Generated Key: $HOLESAIL_KEY"
else
    # Check length if manual
    if [ ${#USER_KEY} -ne 52 ]; then
        echo "ERROR: Manual key must be exactly 52 characters long for z32 compatibility."
        exit 1
    fi
    HOLESAIL_KEY=$USER_KEY
fi

read -p "Enter SSH Port (default 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

# 3. Create service
sudo bash -c "cat > /etc/systemd/system/holesail.service" <<EOF
[Unit]
Description=Holesail SSH Tunnel
After=network.target

[Service]
ExecStart=/usr/local/bin/holesail --live $SSH_PORT --key $HOLESAIL_KEY
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

# 4. Start
sudo systemctl daemon-reload
sudo systemctl enable holesail.service
sudo systemctl start holesail.service

echo "-----------------------------------------------"
echo "NEW 52-CHARACTER KEY: $HOLESAIL_KEY"
echo "-----------------------------------------------"
echo "On your client, run: holesail $HOLESAIL_KEY --port 2222"
echo "Check logs for Client Key Specifics: sudo journalctl -u holesail.service --no-pager"
