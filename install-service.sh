#!/bin/bash

# Install Hyperliquid Node as systemd service

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo"
    exit 1
fi

if [ ! -f /home/$SUDO_USER/hl-visor ]; then
    echo "Error: hl-visor not found. Please run ./setup.sh first"
    exit 1
fi

echo "Installing Hyperliquid node as systemd service..."

# Create systemd service file
cat > /etc/systemd/system/hyperliquid-node.service << EOF
[Unit]
Description=Hyperliquid Node
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=10
User=$SUDO_USER
WorkingDirectory=/home/$SUDO_USER
ExecStart=/home/$SUDO_USER/hl-visor run-non-validator --write-trades --write-fills --serve-info
StandardOutput=append:/home/$SUDO_USER/hl/logs/node.log
StandardError=append:/home/$SUDO_USER/hl/logs/node.error.log

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
mkdir -p /home/$SUDO_USER/hl/logs
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/hl

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable hyperliquid-node.service

echo ""
echo "✓ Service installed successfully!"
echo ""
echo "Commands:"
echo "  Start:   sudo systemctl start hyperliquid-node"
echo "  Stop:    sudo systemctl stop hyperliquid-node"
echo "  Status:  sudo systemctl status hyperliquid-node"
echo "  Logs:    sudo journalctl -u hyperliquid-node -f"
echo ""
echo "To start the node now, run:"
echo "  sudo systemctl start hyperliquid-node"