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
ss -tuln | grep -E "4001|4002|3001" || echo "No connections on expected ports"

echo ""
echo "Disk usage:"
if [ -d "$HYPERLIQUID_HOME/hl/data" ]; then
    echo "  Data directory: $(du -sh "$HYPERLIQUID_HOME/hl/data" 2>/dev/null | cut -f1)"
    echo "  Total hl directory: $(du -sh "$HYPERLIQUID_HOME/hl" 2>/dev/null | cut -f1)"
    echo "  Available space: $(df -h "$HYPERLIQUID_HOME" | awk 'NR==2 {print $4}')"
    
    # Show breakdown if data exists
    if [ -d "$HYPERLIQUID_HOME/hl/data" ]; then
        echo ""
        echo "  Breakdown:"
        du -sh "$HYPERLIQUID_HOME/hl/data"/* 2>/dev/null | sort -hr | head -5 | sed 's/^/    /'
    fi
else
    echo "  No data directory found"
fi

# Check if info endpoint is available
echo ""
echo "Node info endpoint:"
if curl -s http://localhost:3001/info > /dev/null 2>&1; then
    echo "✓ Info endpoint available at http://localhost:3001/info"
    curl -s http://localhost:3001/info | jq . 2>/dev/null || curl -s http://localhost:3001/info
elif curl -s http://localhost:4001/info > /dev/null 2>&1; then
    echo "✓ Info endpoint available at http://localhost:4001/info"
    curl -s http://localhost:4001/info | jq . 2>/dev/null || curl -s http://localhost:4001/info
else
    echo "✗ Info endpoint not yet available (node may still be starting)"
fi

echo ""
echo "Recent logs:"
if [ -f "$HYPERLIQUID_HOME/hl/logs/node.log" ]; then
    echo "From node.log:"
    tail -n 20 "$HYPERLIQUID_HOME/hl/logs/node.log"
else
    # Try to get logs from running process
    if systemctl is-active --quiet hyperliquid-node; then
        echo "From systemd journal:"
        journalctl -u hyperliquid-node -n 20 --no-pager
    else
        echo "No log files found"
    fi
fi

# Look for sync status in logs
echo ""
echo "Sync status (from logs):"
if [ -f "$HYPERLIQUID_HOME/hl/logs/node.log" ]; then
    grep -i "height\|sync\|block" "$HYPERLIQUID_HOME/hl/logs/node.log" | tail -5 || echo "No sync information found in logs yet"
fi