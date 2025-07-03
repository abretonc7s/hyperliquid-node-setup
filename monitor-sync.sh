#!/bin/bash

# Monitor Hyperliquid Node Sync Status

# Get the installation path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.hyperliquid_env" ]; then
    source "$SCRIPT_DIR/.hyperliquid_env"
else
    HYPERLIQUID_HOME="$HOME"
fi

echo "Hyperliquid Node Sync Monitor"
echo "============================="
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to check sync status
check_sync() {
    # Try port 3001 (info endpoint when --serve-info is used)
    if response=$(timeout 2 curl -s http://localhost:3001/info 2>/dev/null); then
        if [ -n "$response" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Info endpoint available:"
            echo "$response" | jq -r '. | "  Block Height: \(.current_block // "N/A")\n  Is Synced: \(.is_synced // "N/A")\n  Network: \(.network // "N/A")"' 2>/dev/null || echo "  Raw: $response"
            return 0
        fi
    fi
    
    # If info endpoint not available, check logs for sync progress
    local latest_log=$(tail -5 "$HYPERLIQUID_HOME/hl/logs/node.log" 2>/dev/null | grep "reading bytes" | tail -1)
    if [ -n "$latest_log" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Downloading initial state:"
        echo "  $latest_log" | sed 's/.*reading bytes for abci_stream recv greeting: /  Progress: /'
        echo "  Info endpoint will be available after initial download completes"
    else
        # Check if node is syncing blocks
        local block_log=$(tail -20 "$HYPERLIQUID_HOME/hl/logs/node.log" 2>/dev/null | grep "applied block" | tail -1)
        if [ -n "$block_log" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Syncing blocks:"
            echo "  $block_log"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Node starting up..."
        fi
    fi
    return 1
}

# Function to check disk usage
check_disk_usage() {
    local data_dir="$HYPERLIQUID_HOME/hl/data"
    if [ -d "$data_dir" ]; then
        local size=$(du -sh "$data_dir" 2>/dev/null | cut -f1)
        local size_bytes=$(du -sb "$data_dir" 2>/dev/null | cut -f1)
        echo "  Data Size: $size"
        
        # Calculate growth rate if we have a previous size
        if [ -n "$PREV_SIZE_BYTES" ] && [ "$PREV_SIZE_BYTES" -gt 0 ]; then
            local growth=$((size_bytes - PREV_SIZE_BYTES))
            if [ "$growth" -gt 0 ]; then
                local growth_mb=$((growth / 1024 / 1024))
                echo "  Growth: +${growth_mb}MB since last check"
            fi
        fi
        PREV_SIZE_BYTES=$size_bytes
    else
        echo "  Data directory not found"
    fi
    
    # Also show available disk space
    local available=$(df -h "$HYPERLIQUID_HOME" | awk 'NR==2 {print $4}')
    echo "  Available Space: $available"
}

# Check if node is running
if ! pgrep -f "hl-visor" > /dev/null && ! systemctl is-active --quiet hyperliquid-node; then
    echo "Error: Hyperliquid node is not running"
    echo "Start it with: ./start-node.sh or sudo systemctl start hyperliquid-node"
    exit 1
fi

# Initialize previous size
PREV_SIZE_BYTES=0

# Monitor loop
while true; do
    check_sync
    check_disk_usage
    echo "---"
    sleep 10
done 