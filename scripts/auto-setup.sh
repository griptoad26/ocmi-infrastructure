#!/bin/bash
# OCMI Agent Auto-Setup from GitHub
# Run this on any machine to connect to Headscale

set -e

echo "=== OCMI Agent Auto-Setup ==="

# Pull commands from GitHub
echo "1. Pulling commands from GitHub..."
curl -sL https://raw.githubusercontent.com/griptoad26/moving-molty/main/Headscale-Commands.txt -o /tmp/headscale-commands.txt

# Show the commands
echo ""
echo "2. Commands downloaded:"
cat /tmp/headscale-commands.txt

echo ""
echo "3. Extracting auth key..."
AUTH_KEY=$(grep "Auth Key:" /tmp/headscale-commands.txt | head -1 | awk '{print $3}')
SERVER_URL=$(grep "Server:" /tmp/headscale-commands.txt | head -1 | awk '{print $2}')

echo "Auth Key: $AUTH_KEY"
echo "Server: $SERVER_URL"

echo ""
echo "4. Connecting to Headscale..."

# Detect OS and run appropriate command
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "Windows detected..."
    powershell -Command "tailscale down; Start-Sleep -Seconds 2; tailscale up --login-server $SERVER_URL --auth-key $AUTH_KEY --accept-routes"
else
    # Linux/WSL
    echo "Linux/WSL detected..."
    tailscale down
    sleep 2
    tailscale up --login-server=$SERVER_URL --auth-key=$AUTH_KEY --accept-routes
fi

echo ""
echo "5. Verifying connection..."
sleep 5
tailscale status | head -5

echo ""
echo "=== Setup Complete ==="
