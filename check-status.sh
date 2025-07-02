#!/bin/bash

# Check Hyperliquid Node Status

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the environment file if it exists
if [ -f "$SCRIPT_DIR/.hyperliquid_env" ]; then
    source "$SCRIPT_DIR/.hyperliquid_env"
else
    # Fallback to home directory if env file doesn't exist
    HYPERLIQUID_HOME="$HOME"
fi

echo "Hyperliquid Node Status Check"
echo "============================="
echo "Installation path: $HYPERLIQUID_HOME"
echo ""

# Check if running as service
if systemctl is-active --quiet hyperliquid-node; then
    echo "✓ Node is running as service"
    echo ""
    echo "Service status:"
    systemctl status hyperliquid-node --no-pager | head -n 10
else
    # Check if running manually
    if pgrep -f "hl-visor" > /dev/null; then
        echo "✓ Node is running (manual mode)"
        echo "  PID: $(pgrep -f hl-visor)"
    else
        echo "✗ Node is not running"
        echo ""
        echo "To start the node:"
        echo "  ./start-node.sh"
        echo "Or as a service:"
        echo "  sudo systemctl start hyperliquid-node"
        exit 1
    fi
fi

echo ""
echo "Network connections:"
ss -tuln | grep -E "4001|4002" || echo "No connections on ports 4001/4002"

echo ""
echo "Disk usage:"
du -sh "$HYPERLIQUID_HOME/hl/data" 2>/dev/null || echo "No data directory found"

echo ""
echo "Recent logs:"
if [ -f "$HYPERLIQUID_HOME/hl/logs/node.log" ]; then
    tail -n 20 "$HYPERLIQUID_HOME/hl/logs/node.log"
else
    # Try to get logs from running process
    if systemctl is-active --quiet hyperliquid-node; then
        journalctl -u hyperliquid-node -n 20 --no-pager
    else
        echo "No log files found"
    fi
fi