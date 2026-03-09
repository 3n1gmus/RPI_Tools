#!/bin/bash

# Update package list
echo "Updating package list..."
sudo apt update -y

# Install OpenSSH server
echo "Installing OpenSSH server..."
sudo apt install -y openssh-server

# Enable and start the SSH service
echo "Enabling and starting SSH service..."
sudo systemctl enable ssh
sudo systemctl start ssh

# Check the status of the SSH service
echo "Checking SSH service status..."
sudo systemctl status ssh

echo "--------------------------------------"
echo "SSH setup complete!"
echo "You can now connect to this device via SSH."
