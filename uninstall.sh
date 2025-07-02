#!/bin/bash

# Uninstall Hyperliquid Node

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the environment file if it exists
if [ -f "$SCRIPT_DIR/.hyperliquid_env" ]; then
    source "$SCRIPT_DIR/.hyperliquid_env"
else
    # Fallback to home directory if env file doesn't exist
    HYPERLIQUID_HOME="$HOME"
fi

echo "Hyperliquid Node Uninstaller"
echo "============================"
echo ""
echo "Installation path: $HYPERLIQUID_HOME"
echo ""
echo "This will remove:"
echo "- The systemd service (if installed)"
echo "- The visor binary and configuration"
echo "- Optionally: all node data"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Stop and remove service
if systemctl is-active --quiet hyperliquid-node; then
    echo "Stopping service..."
    sudo systemctl stop hyperliquid-node
fi

if [ -f /etc/systemd/system/hyperliquid-node.service ]; then
    echo "Removing service..."
    sudo systemctl disable hyperliquid-node
    sudo rm /etc/systemd/system/hyperliquid-node.service
    sudo systemctl daemon-reload
fi

# Stop manual process
if pgrep -f "hl-visor" > /dev/null; then
    echo "Stopping node process..."
    pkill -f "hl-visor"
fi

# Remove binaries and config
echo "Removing binaries and configuration..."
rm -f "$HYPERLIQUID_HOME/hl-visor" "$HYPERLIQUID_HOME/hl-visor.asc" "$HYPERLIQUID_HOME/visor.json"

# Ask about data
if [ -d "$HYPERLIQUID_HOME/hl" ]; then
    echo ""
    echo "Node data directory found: $HYPERLIQUID_HOME/hl"
    read -p "Remove all node data? This cannot be undone! (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing data..."
        rm -rf "$HYPERLIQUID_HOME/hl"
    else
        echo "Data preserved in $HYPERLIQUID_HOME/hl"
    fi
fi

# Remove environment file
if [ -f "$HYPERLIQUID_HOME/.hyperliquid_env" ]; then
    rm -f "$HYPERLIQUID_HOME/.hyperliquid_env"
fi

# Remove symlink if it exists
if [ -L "$HOME/hl" ] && [ "$(readlink -f "$HOME/hl")" = "$HYPERLIQUID_HOME/hl" ]; then
    echo "Removing data directory symlink..."
    rm -f "$HOME/hl"
fi

echo ""
echo "✓ Uninstall complete"