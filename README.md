# Hyperliquid Node Setup

Simple setup scripts for running a Hyperliquid node on Ubuntu 24.04.

## Prerequisites

- Ubuntu 24.04 LTS
- Minimum 4 CPU cores
- 32 GB RAM
- 200 GB available disk space
- Ports 4001 and 4002 open to the internet

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/abretonc7s/hyperliquid-node-setup.git
cd hyperliquid-node-setup
```

2. Run the setup script:
```bash
./setup.sh
```

3. Choose your network (Mainnet or Testnet) when prompted.

4. Start the node:
```bash
./start-node.sh
```

## Manual Setup

If you prefer to set up manually:

1. Create the visor configuration:
```bash
echo '{"chain": "Mainnet"}' > ~/visor.json
# Or for testnet:
# echo '{"chain": "Testnet"}' > ~/visor.json
```

2. Download and run the visor:
```bash
# For Mainnet
curl https://binaries.hyperliquid.xyz/Mainnet/hl-visor > ~/hl-visor

# For Testnet
# curl https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor > ~/hl-visor

chmod +x ~/hl-visor
~/hl-visor run-non-validator
```

## Systemd Service

To run the node as a system service:

```bash
sudo ./install-service.sh
```

This will:
- Install the node as a systemd service
- Enable automatic startup on boot
- Allow you to manage the node with systemctl commands

## Management Commands

After installing as a service:

- Start: `sudo systemctl start hyperliquid-node`
- Stop: `sudo systemctl stop hyperliquid-node`
- Status: `sudo systemctl status hyperliquid-node`
- Logs: `sudo journalctl -u hyperliquid-node -f`

## Data Location

The node stores data in `~/hl/data/`. This directory will grow to ~100GB per day due to logs.

## Monitoring

To monitor your node:

1. Check if it's syncing:
```bash
./check-status.sh
```

2. View logs:
```bash
tail -f ~/hl/logs/node.log
```

## Troubleshooting

### Node keeps restarting
- Ensure ports 4001-4002 are open in your firewall
- Check you have enough disk space
- Verify you're running Ubuntu 24.04

### Cannot connect to peers
- Check your firewall settings
- Ensure your server has a public IP
- Verify ports are forwarded if behind NAT

## Security Notes

- The node does not require any private keys
- It runs as a non-validator (read-only) node
- Keep your system updated with security patches

## Additional Options

The node supports various flags:

- `--write-trades`: Write trade data (enabled by default)
- `--write-fills`: Write fill data (enabled by default)
- `--serve-info`: Serve info API on port 3001
- `--serve-eth-rpc`: Serve Ethereum-compatible RPC

## Support

For issues specific to this setup, please open an issue on GitHub.
For Hyperliquid node support, visit the official documentation.