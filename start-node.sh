#!/bin/bash

# Start Hyperliquid Node

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the environment file if it exists
if [ -f "$SCRIPT_DIR/.hyperliquid_env" ]; then
    source "$SCRIPT_DIR/.hyperliquid_env"
else
    # Fallback to home directory if env file doesn't exist
    HYPERLIQUID_HOME="$HOME"
fi

if [ ! -f "$HYPERLIQUID_HOME/hl-visor" ]; then
    echo "Error: hl-visor not found at $HYPERLIQUID_HOME. Please run ./setup.sh first"
    exit 1
fi

if [ ! -f "$HYPERLIQUID_HOME/visor.json" ]; then
    echo "Error: visor.json not found at $HYPERLIQUID_HOME. Please run ./setup.sh first"
    exit 1
fi

CHAIN=$(cat "$HYPERLIQUID_HOME/visor.json" | grep -o '"chain"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
echo "Starting Hyperliquid $CHAIN node..."
echo "Installation path: $HYPERLIQUID_HOME"
echo "Press Ctrl+C to stop"
echo ""

# Run with recommended flags
"$HYPERLIQUID_HOME/hl-visor" run-non-validator --write-trades --write-fills --serve-info