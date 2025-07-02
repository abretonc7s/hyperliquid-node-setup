#!/bin/bash

# Uninstall Hyperliquid Node

echo "Hyperliquid Node Uninstaller"
echo "============================"
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
rm -f ~/hl-visor ~/hl-visor.asc ~/visor.json

# Ask about data
if [ -d ~/hl ]; then
    echo ""
    echo "Node data directory found: ~/hl"
    read -p "Remove all node data? This cannot be undone! (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing data..."
        rm -rf ~/hl
    else
        echo "Data preserved in ~/hl"
    fi
fi

echo ""
echo "✓ Uninstall complete"