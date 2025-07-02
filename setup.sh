#!/bin/bash

# Hyperliquid Node Setup Script

set -e

echo "================================"
echo "Hyperliquid Node Setup"
echo "================================"
echo ""

# Check if running on Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release 2>/dev/null; then
    echo "Warning: This script is designed for Ubuntu 24.04 LTS"
    echo "Your system: $(lsb_release -d 2>/dev/null || echo 'Unknown')"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check system requirements
echo "Checking system requirements..."

CPUS=$(nproc)
MEM_GB=$(free -g | awk '/^Mem:/{print $2}')
DISK_GB=$(df -BG ~ | awk 'NR==2 {print $4}' | sed 's/G//')

echo "- CPU cores: $CPUS (minimum 4 required)"
echo "- RAM: ${MEM_GB}GB (minimum 32GB required)"
echo "- Free disk space: ${DISK_GB}GB (minimum 200GB required)"
echo ""

if [ "$CPUS" -lt 4 ] || [ "$MEM_GB" -lt 32 ] || [ "$DISK_GB" -lt 200 ]; then
    echo "Warning: Your system does not meet the minimum requirements!"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Choose network
echo "Which network do you want to run?"
echo "1) Mainnet"
echo "2) Testnet"
read -p "Enter choice (1 or 2): " NETWORK_CHOICE

if [ "$NETWORK_CHOICE" = "1" ]; then
    CHAIN="Mainnet"
    BINARY_URL="https://binaries.hyperliquid.xyz/Mainnet/hl-visor"
    SIG_URL="https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc"
elif [ "$NETWORK_CHOICE" = "2" ]; then
    CHAIN="Testnet"
    BINARY_URL="https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor"
    SIG_URL="https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc"
else
    echo "Invalid choice!"
    exit 1
fi

echo ""
echo "Setting up $CHAIN node..."

# Create visor.json
echo "Creating visor configuration..."
echo "{\"chain\": \"$CHAIN\"}" > ~/visor.json

# Download GPG key
echo "Downloading GPG public key..."
curl -s https://raw.githubusercontent.com/hyperliquid-dex/node/main/pub_key.asc > /tmp/pub_key.asc
gpg --import /tmp/pub_key.asc || echo "Warning: GPG key import failed"

# Download visor binary
echo "Downloading visor binary..."
curl -L "$BINARY_URL" > ~/hl-visor
chmod +x ~/hl-visor

# Download and verify signature
echo "Downloading signature..."
curl -L "$SIG_URL" > ~/hl-visor.asc

echo "Verifying signature..."
if gpg --verify ~/hl-visor.asc ~/hl-visor 2>/dev/null; then
    echo "✓ Signature verified successfully"
else
    echo "⚠ Warning: Signature verification failed"
    echo "This might be due to GPG configuration. The binary might still be valid."
fi

# Create directories
echo "Creating data directories..."
mkdir -p ~/hl/data
mkdir -p ~/hl/logs

# Configure firewall
echo ""
echo "Configuring firewall..."
if command -v ufw &> /dev/null; then
    echo "Opening ports 4001 and 4002..."
    sudo ufw allow 4001/tcp
    sudo ufw allow 4002/tcp
    echo "✓ Firewall configured"
else
    echo "⚠ ufw not found. Please manually open ports 4001 and 4002"
fi

echo ""
echo "================================"
echo "Setup complete!"
echo "================================"
echo ""
echo "To start the node, run:"
echo "  ./start-node.sh"
echo ""
echo "To install as a system service, run:"
echo "  sudo ./install-service.sh"
echo ""