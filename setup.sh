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

# Determine default installation path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# Get the real path in case of symlinks
REAL_PATH="$(readlink -f "$SCRIPT_DIR")"
if [[ "$REAL_PATH" == /volumes/* ]]; then
    # If running from /volumes, use the current directory
    DEFAULT_PATH="$REAL_PATH"
else
    # Otherwise use home directory
    DEFAULT_PATH="$HOME"
fi

# Ask for installation path
echo ""
echo "Where would you like to install Hyperliquid?"
echo "Default: $DEFAULT_PATH"
echo "You can specify a custom path (e.g., /volumes/hyperliquid)"
read -p "Installation path [press Enter for default]: " INSTALL_PATH

# Set default if empty
if [ -z "$INSTALL_PATH" ]; then
    INSTALL_PATH="$DEFAULT_PATH"
fi

# Expand tilde if present
INSTALL_PATH="${INSTALL_PATH/#\~/$HOME}"

# Check disk space at the installation path
DISK_GB=$(df -BG "$INSTALL_PATH" | awk 'NR==2 {print $4}' | sed 's/G//')

echo ""
echo "Installation path: $INSTALL_PATH"
echo "- CPU cores: $CPUS (minimum 4 required)"
echo "- RAM: ${MEM_GB}GB (minimum 32GB required)"
echo "- Free disk space at $INSTALL_PATH: ${DISK_GB}GB (minimum 200GB required)"
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
echo "{\"chain\": \"$CHAIN\"}" > "$INSTALL_PATH/visor.json"

# Download GPG key
echo "Downloading GPG public key..."
curl -s https://raw.githubusercontent.com/hyperliquid-dex/node/main/pub_key.asc > /tmp/pub_key.asc
gpg --import /tmp/pub_key.asc || echo "Warning: GPG key import failed"

# Download visor binary
echo "Downloading visor binary..."
curl -L "$BINARY_URL" > "$INSTALL_PATH/hl-visor"
chmod +x "$INSTALL_PATH/hl-visor"

# Download and verify signature
echo "Downloading signature..."
curl -L "$SIG_URL" > "$INSTALL_PATH/hl-visor.asc"

echo "Verifying signature..."
if gpg --verify "$INSTALL_PATH/hl-visor.asc" "$INSTALL_PATH/hl-visor" 2>/dev/null; then
    echo "✓ Signature verified successfully"
else
    echo "⚠ Warning: Signature verification failed"
    echo "This might be due to GPG configuration. The binary might still be valid."
fi

# Create directories
echo "Creating data directories..."
mkdir -p "$INSTALL_PATH/hl/data"
mkdir -p "$INSTALL_PATH/hl/logs"

# If installing outside of home directory, create symlink for compatibility
if [ "$INSTALL_PATH" != "$HOME" ] && [ ! -e "$HOME/hl" ]; then
    echo "Creating symlink for data directory compatibility..."
    ln -s "$INSTALL_PATH/hl" "$HOME/hl"
fi

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

# Save installation path for other scripts
echo "HYPERLIQUID_HOME=\"$INSTALL_PATH\"" > "$INSTALL_PATH/.hyperliquid_env"

echo ""
echo "================================"
echo "Setup complete!"
echo "================================"
echo ""
echo "Installation path: $INSTALL_PATH"
echo ""
echo "To start the node, run:"
echo "  cd $INSTALL_PATH && ./start-node.sh"
echo ""
echo "To install as a system service, run:"
echo "  cd $INSTALL_PATH && sudo ./install-service.sh"
echo ""