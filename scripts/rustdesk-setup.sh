#!/bin/bash
# RustDesk Setup Script for OCMI Agents
# Connects to pi-serve RustDesk server via Headscale

set -e

echo "=== RustDesk Setup for OCMI ==="

# Determine OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo "Windows detected - please use GUI settings"
    echo "Set ID Server to: http://100.64.0.7"
    exit 0
fi

# Get machine name
MACHINE_NAME=$(hostname)

# Configure RustDesk server (pi-serve)
echo "Configuring RustDesk to use pi-serve (100.64.0.7)..."

# Create config
echo "relay=100.64.0.7" | sudo tee /etc/rustdesk/server.conf > /dev/null
echo "api=100.64.0.7" | sudo tee -a /etc/rustdesk/server.conf > /dev/null
echo "key=cgK7fIZU0WyYucoBqqAvbvDlE6yHefuS0K7O+QtlQ+A=" | sudo tee -a /etc/rustdesk/server.conf > /dev/null

echo "Config written to /etc/rustdesk/server.conf:"

if command -v systemctl &> /dev/null; then
    echo "Restarting RustDesk service..."
    sudo systemctl restart rustdesk
    sleep 2
    echo "Service status:"
    sudo systemctl is-active rustdesk || echo "Service may need manual start"
else
    echo "No systemctl - you may need to restart RustDesk manually"
fi

echo ""
echo "=== Setup Complete ==="
echo "RustDesk server: 100.64.0.7 (pi-serve)"
echo "Machine: $MACHINE_NAME"