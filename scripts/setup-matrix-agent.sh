#!/bin/bash
# Matrix Agent Setup Script for OpenClaw
# Run this on each machine to connect to Matrix

MACHINE_NAME=$(hostname)
CONFIG_URL="http://100.64.0.1:8889/matrix-configs/${MACHINE_NAME}.json"

echo "Setting up Matrix agent for: $MACHINE_NAME"
echo "Downloading from: $CONFIG_URL"

# Create config directory
mkdir -p ~/.openclaw/memory

# Download config
curl -s "$CONFIG_URL" -o ~/.openclaw/memory/matrix_config.json

if [ -f ~/.openclaw/memory/matrix_config.json ]; then
    echo "✅ Config downloaded successfully!"
    echo "Contents:"
    cat ~/.openclaw/memory/matrix_config.json
    echo ""
    echo "Next steps:"
    echo "1. Install matrix-nio: pip install matrix-nio"
    echo "2. Create Matrix client script in ~/.openclaw/memory/matrix_client.py"
    echo "3. Add to your OpenClaw to use Matrix for communication"
else
    echo "❌ Config download failed!"
    echo "Make sure machine name matches: $(hostname)"
fi
