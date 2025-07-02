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

The setup script will:
- Ask for your preferred installation path (defaults to current directory if in `/volumes/*`, otherwise `$HOME`)
- Download and verify the Hyperliquid visor binary
- Create necessary directories
- Configure firewall rules

3. Choose your network (Mainnet or Testnet) when prompted.

4. Start the node:
```bash
./start-node.sh
```

## Installation Path

The setup script supports custom installation paths. This is useful if:
- Your home directory has limited space
- You want to use a dedicated volume for blockchain data

When prompted for the installation path, you can:
- Press Enter to use the default
- Specify a custom path like `/volumes/hyperliquid`

**Note**: Hyperliquid binaries are hardcoded to use `~/hl` for data storage. If you install outside your home directory, the setup script will automatically create a symlink from `~/hl` to your chosen installation path.

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

The node stores data in:
- `~/hl/data/` (always, due to hardcoded paths in Hyperliquid binaries)
- If installed outside home directory, this will be a symlink to `<install_path>/hl/`

The data directory will grow to ~100GB per day due to logs.

## Monitoring

To monitor your node:

1. Check overall node status:
```bash
./check-status.sh
```

2. Check if the node is synced:
```bash
# Once the node starts serving the info endpoint (may take a few minutes)
curl http://localhost:3001/info | jq .

# The response will show:
# - current_block: The block height your node has synced to
# - is_synced: Whether your node is fully synced with the network
```

3. View real-time logs:
```bash
# If running manually
tail -f ~/hl/logs/node.log

# If running as service
sudo journalctl -u hyperliquid-node -f

# To see only sync-related messages
grep -i "height\|sync\|block" ~/hl/logs/node.log | tail -20
```

4. Monitor disk usage:
```bash
du -sh ~/hl/data/
```

### Understanding Sync Status

The node needs to sync historical data before it's fully operational. This process can take:
- **Initial sync**: Several hours to days depending on network conditions
- **The node is synced when**: The `is_synced` field in the info endpoint returns `true`
- **During sync**: The `current_block` will gradually increase until it catches up with the network

### Monitoring Endpoints

- **Info endpoint**: `http://localhost:3001/info` - General node information and sync status
- **Health check**: Node listens on ports 4001-4002 for peer connections

## Uninstalling

To remove the node:

```bash
./uninstall.sh
```

This will:
- Stop and remove the systemd service (if installed)
- Remove the visor binary and configuration
- Optionally remove all node data
- Clean up any symlinks created during installation

## Troubleshooting

### Node keeps restarting
- Ensure ports 4001-4002 are open in your firewall
- Check you have enough disk space
- Verify you're running Ubuntu 24.04

### Cannot connect to peers
- Check your firewall settings
- Ensure your server has a public IP
- Verify ports are forwarded if behind NAT

### Disk space issues
- If installed in home directory, ensure you have 200GB+ free
- Consider reinstalling to a volume with more space using the custom installation path

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