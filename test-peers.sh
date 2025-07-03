#!/bin/bash

echo "Testing connectivity to Hyperliquid seed peers..."
echo "=============================================="

# Test a few seed peers
peers=(
    "148.113.176.170:4001"  # NodeOps
    "20.188.6.225:4001"     # ASXN
    "180.189.55.18:4001"    # B-Harvest
    "52.68.71.160:4001"     # Infinite Field (Tokyo)
    "47.74.39.46:4001"      # HypurrCorea
)

for peer in "${peers[@]}"; do
    ip="${peer%:*}"
    port="${peer#*:}"
    echo ""
    echo "Testing $peer..."
    
    # Test basic connectivity
    if timeout 3 nc -zv $ip $port 2>&1 | grep -q "succeeded\|connected"; then
        echo "✓ Connection successful"
    else
        echo "✗ Connection failed"
    fi
    
    # Test ping (might not work for all)
    ping -c 1 -W 2 $ip > /dev/null 2>&1 && echo "✓ Ping successful" || echo "✗ Ping failed"
done

echo ""
echo "Checking outbound connectivity..."
curl -s https://api.ipify.org > /dev/null 2>&1 && echo "✓ Internet connection OK" || echo "✗ No internet connection" 