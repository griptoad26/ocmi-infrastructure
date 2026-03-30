#!/bin/bash
# OCMI Agent Setup Script - Comprehensive
# Run this on any machine to set up OCMI components

set -e

# Configuration
GATEWAY="http://100.80.211.39:8090"
FILE_SERVER="http://100.80.211.39:8888"
MATRIX_SERVER="http://192.168.50.174:8008"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  OCMI Agent Setup - Comprehensive${NC}"
echo -e "${GREEN}================================================${NC}"

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS="windows"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="unknown"
fi

echo -e "${YELLOW}Detected OS: $OS${NC}"

# Get machine name
if [ "$OS" == "windows" ]; then
    MACHINE_NAME=$(hostname)
else
    MACHINE_NAME=$(hostname)
fi

echo "Machine: $MACHINE_NAME"

# Function to check service
check_service() {
    local url=$1
    local name=$2
    if curl -s --max-time 5 "$url/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $name is not responding${NC}"
        return 1
    fi
}

echo ""
echo -e "${YELLOW}=== Step 1: Checking Services ===${NC}"
check_service "$GATEWAY" "Cluster Hub" || echo "Cluster Hub needs restart"
check_service "$FILE_SERVER" "File Server" || echo "File Server needs setup"

echo ""
echo -e "${YELLOW}=== Step 2: Setting Up OpenClaw ===${NC}"

if command -v openclaw &> /dev/null; then
    echo -e "${GREEN}✓ OpenClaw already installed${NC}"
    openclaw --version
else
    echo "Installing OpenClaw..."
    if [ "$OS" == "linux" ] || [ "$OS" == "macos" ]; then
        pip3 install openclaw 2>/dev/null || pip install openclaw
    elif [ "$OS" == "windows" ]; then
        pip install openclaw
    fi
fi

echo ""
echo -e "${YELLOW}=== Step 3: OpenClaw Configuration ===${NC}"

CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$CONFIG_DIR"

# Create main config
cat > "$CONFIG_DIR/openclaw.json" << 'EOFCONFIG'
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
      "enabled": true,
      "groupPolicy": "allowlist"
    }
  },
  "gateway": {
    "port": 18789
  }
}
EOFCONFIG

echo -e "${GREEN}✓ Config created at $CONFIG_DIR/openclaw.json${NC}"

echo ""
echo -e "${YELLOW}=== Step 4: Register with Cluster Hub ===${NC}"

# Register this node
REGISTER_URL="$GATEWAY/api/nodes/register"
curl -s -X POST "$REGISTER_URL" \
    -H "Content-Type: application/json" \
    -d "{\"hostname\":\"$MACHINE_NAME\",\"os\":\"$OS\",\"status\":\"online\"}" \
    > /dev/null 2>&1 && echo -e "${GREEN}✓ Registered with Cluster Hub${NC}" || echo "Registration failed (may already be registered)"

echo ""
echo -e "${YELLOW}=== Step 5: Start OpenClaw Gateway ===${NC}"

if [ "$OS" == "linux" ] || [ "$OS" == "macos" ]; then
    # Linux/macOS
    nohup openclaw gateway > "$CONFIG_DIR/gateway.log" 2>&1 &
    echo -e "${GREEN}✓ Gateway started on port 18789${NC}"
elif [ "$OS" == "windows" ]; then
    # Windows
    start /min python -m openclaw gateway
    echo -e "${GREEN}✓ Gateway started (check Task Manager)${NC}"
fi

sleep 2

echo ""
echo -e "${YELLOW}=== Step 6: OneDrive Sync Setup (Optional) ===${NC}"
echo "To sync ~/.openclaw to OneDrive:"
echo "  1. Install: sudo apt install onedrive"
echo "  2. Authorize: onedrive --authorize"
echo "  3. Sync: mkdir -p ~/OneDrive/OCMI/$MACHINE_NAME"
echo "  4. Configure: onedrive --sync ~/OneDrive/OCMI/$MACHINE_NAME"

echo ""
echo -e "${YELLOW}=== Step 7: Useful Commands ===${NC}"
echo "Check status: curl $GATEWAY/health"
echo "List nodes: curl $GATEWAY/api/nodes/list"
echo "Gateway: curl http://localhost:18789"
echo "Files: $FILE_SERVER"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Machine: $MACHINE_NAME"
echo "OS: $OS"
echo ""
echo "Next steps:"
echo "  1. Test Matrix connection in Element/FluffyChat"
echo "  2. Check Cluster Hub: curl $GATEWAY/health"
echo "  3. View files: $FILE_SERVER"
echo ""