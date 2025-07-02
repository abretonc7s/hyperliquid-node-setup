#!/bin/bash

# Start Hyperliquid Node

set -e

if [ ! -f ~/hl-visor ]; then
    echo "Error: hl-visor not found. Please run ./setup.sh first"
    exit 1
fi

if [ ! -f ~/visor.json ]; then
    echo "Error: visor.json not found. Please run ./setup.sh first"
    exit 1
fi

CHAIN=$(cat ~/visor.json | grep -o '"chain"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
echo "Starting Hyperliquid $CHAIN node..."
echo "Press Ctrl+C to stop"
echo ""

# Run with recommended flags
~/hl-visor run-non-validator --write-trades --write-fills --serve-info