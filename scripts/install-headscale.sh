#!/bin/bash
# Headscale Installation Script for Linux Machines
# Run this on each Linux machine to connect to Headscale VPN

set -e

# Configuration
HEADSCALE_URL="http://192.168.50.174:8099"
AUTH_KEY=""  # Get this from Pi-Serve: headscale preauthkeys create

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Installing Headscale...${NC}"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l) ARCH_NAME="armv7" ;;
    *) echo -e "${RED}Unknown architecture: $ARCH${NC}"; exit 1 ;;
esac

echo "Architecture: $ARCH_NAME"

# Get latest version
VERSION=$(curl -sL "https://github.com/juanfont/headscale/releases/latest" | grep -oP 'v\K[0-9.]+' | head -1)
echo "Latest version: $VERSION"

# Download Headscale
echo "Downloading Headscale..."
curl -sL "https://github.com/juanfont/headscale/releases/download/v${VERSION}/headscale_${VERSION}_linux_${ARCH_NAME}" -o /tmp/headscale
chmod +x /tmp/headscale

# Install
echo "Installing Headscale..."
sudo mv /tmp/headscale /usr/local/bin/headscale
sudo setcap cap_net_bind_service=+ep /usr/local/bin/headscale

# Create config directory
mkdir -p ~/.config/headscale

# Ask for auth key if not provided
if [ -z "$AUTH_KEY" ]; then
    echo -e "${YELLOW}Enter auth key from Pi-Serve (or press Enter to generate new):${NC}"
    read AUTH_KEY
fi

# Get machine name for node name
NODE_NAME=$(hostname)

# Create basic config
cat > ~/.config/headscale/config.yaml << EOF
server_url: ${HEADSCALE_URL}
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 9090
grpc_listen_addr: 0.0.0.0:50443
base_domain: ocmi.local
disable_check_updates: true
db_type: sqlite3
db_path: /var/lib/headscale/db.sqlite
log:
  format: text
  level: info
EOF

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/headscale.service > /dev/null << 'EOF'
[Unit]
Description=Headscale
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/headscale serve
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable headscale

# Try to get auth key if not provided
if [ -z "$AUTH_KEY" ]; then
    echo -e "${YELLOW}To connect to Headscale, run on Pi-Serve:${NC}"
    echo "  headscale preauthkeys create -n $NODE_NAME --reusable -e 1y"
    echo ""
    echo "Then run: headscale tailscale up --auth-key YOUR_KEY"
else
    echo "Connecting to Headscale..."
    headscale tailscale up --login-server $HEADSCALE_URL --auth-key $AUTH_KEY
fi

echo -e "${GREEN}✅ Headscale installed!${NC}"
echo ""
echo "Commands:"
echo "  sudo systemctl start headscale   # Start service"
echo "  sudo systemctl status headscale  # Check status"
echo "  headscale nodes list           # See connected nodes"