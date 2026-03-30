#!/bin/bash
# OCMI Agent Setup Script - WSL / Linux
# Run this on Ubuntu/WSL/Linux machines

set -e

# Configuration
GATEWAY="http://100.80.211.39:8090"
FILE_SERVER="http://100.80.211.39:8888"
MATRIX_SERVER="http://192.168.50.174:8008"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== OCMI Agent Setup - WSL/Linux ===${NC}"

# Get hostname
MACHINE_NAME=$(hostname)
echo "Machine: $MACHINE_NAME"

# Check if WSL
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    echo "Detected: WSL"
    IS_WSL=true
else
    IS_WSL=false
fi

# Check services
echo ""
echo -e "${YELLOW}=== Checking Services ===${NC}"
curl -s --max-time 3 "$GATEWAY/health" > /dev/null 2>&1 && echo "✓ Cluster Hub OK" || echo "⚠ Cluster Hub not responding"
curl -s --max-time 3 "$FILE_SERVER/" > /dev/null 2>&1 && echo "✓ File Server OK" || echo "⚠ File Server not responding"

# Install dependencies
echo ""
echo -e "${YELLOW}=== Installing Dependencies ===${NC}"

# Update
sudo apt update -y

# Install Python if needed
if ! command -v python3 &> /dev/null; then
    sudo apt install -y python3 python3-pip
fi

# Install OpenClaw
if ! command -v openclaw &> /dev/null; then
    pip3 install openclaw 2>/dev/null || pip install openclaw
fi

# Install git
if ! command -v git &> /dev/null; then
    sudo apt install -y git
fi

# Create config directory
mkdir -p ~/.openclaw

# Create config
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "channels": {
    "matrix": {
      "enabled": true,
      "homeserver": "http://192.168.50.174:8008",
      "allowPrivateNetwork": true,
      "dm": { "policy": "open" },
      "groupPolicy": "open",
      "autoJoin": "always"
    },
    "discord": {
      "enabled": true
    }
  },
  "gateway": {
    "port": 18789
  }
}
EOF

echo "✓ Config created at ~/.openclaw/openclaw.json"

# Register with Cluster Hub
echo ""
echo -e "${YELLOW}=== Registering with Cluster Hub ===${NC}"
curl -s -X POST "$GATEWAY/api/nodes/register" \
    -H "Content-Type: application/json" \
    -d "{\"hostname\":\"$MACHINE_NAME\",\"os\":\"$IS_WSL\",\"status\":\"online\"}" \
    > /dev/null 2>&1 && echo "✓ Registered" || echo "⚠ Already registered or failed"

# Start gateway
echo ""
echo -e "${YELLOW}=== Starting Gateway ===${NC}"
nohup openclaw gateway > ~/.openclaw/gateway.log 2>&1 &
sleep 2

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Machine: $MACHINE_NAME (WSL: $IS_WSL)"
echo "Gateway: http://localhost:18789"
echo "Files: $FILE_SERVER"
echo "Cluster: $GATEWAY"
echo ""
echo "Next: Test Matrix connection at http://192.168.50.174:8008"