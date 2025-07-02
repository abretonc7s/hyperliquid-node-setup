#!/bin/bash

# Monitor Hyperliquid Node Sync Status

echo "Hyperliquid Node Sync Monitor"
echo "============================="
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to check sync status
check_sync() {
    # Try port 3001 first, then 4001
    for port in 3001 4001; do
        if response=$(curl -s http://localhost:$port/info 2>/dev/null); then
            if [ -n "$response" ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Info from port $port:"
                echo "$response" | jq -r '. | "  Block Height: \(.current_block // "N/A")\n  Is Synced: \(.is_synced // "N/A")\n  Network: \(.network // "N/A")"' 2>/dev/null || echo "  Raw: $response"
                return 0
            fi
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Info endpoint not yet available"
    return 1
}

# Check if node is running
if ! pgrep -f "hl-visor" > /dev/null && ! systemctl is-active --quiet hyperliquid-node; then
    echo "Error: Hyperliquid node is not running"
    echo "Start it with: ./start-node.sh or sudo systemctl start hyperliquid-node"
    exit 1
fi

# Monitor loop
while true; do
    check_sync
    echo "---"
    sleep 10
done 