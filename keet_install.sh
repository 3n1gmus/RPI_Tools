#!/bin/bash

# Script to install Keet based on system architecture and required dependencies

# Installation directory
INSTALL_DIR="/usr/local/bin"

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    if [ -x "$(command -v apt)" ]; then
        sudo apt update
        sudo apt install -y libfuse2 libatomic1 libgtk-4-1 libwebkitgtk-6.0-4
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y fuse-libs libatomic libgtk-4-1 webkit2gtk3
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y fuse-libs libatomic libgtk-4-1 webkit2gtk3
    else
        echo "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
}

# Function to download and install Keet
install_keets() {
    local arch=$1
    local tar_file="Keet-${arch}.tar.gz"
    local app_image="Keet-*.AppImage"

    echo "Downloading $tar_file..."
    wget -q "https://static.keet.io/downloads/latest/$tar_file"

    echo "Extracting $tar_file..."
    tar -xzf "$tar_file"

    echo "Making AppImage executable..."
    chmod +x "$app_image"

    echo "Installing to $INSTALL_DIR..."
    mv "$app_image" "$INSTALL_DIR/keet-$arch.AppImage"
    echo "Keet installed to $INSTALL_DIR/keet-$arch.AppImage"
}

# Install dependencies
install_dependencies

# Check architecture
if [[ "$(uname -m)" == "x86_64" ]]; then
    echo "Detected x64 architecture."
    install_keets "x64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
    echo "Detected ARM64 architecture."
    install_keets "arm64"
else
    echo "Unsupported architecture: $(uname -m)"
    exit 1
fi

echo "Installation complete. You can run Keet from $INSTALL_DIR."
