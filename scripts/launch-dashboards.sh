#!/bin/bash
# OCMI Dashboard Launcher
# Opens all dashboards in organized browser windows

BASE_URL="http://localhost:8888"

DASHBOARDS=(
  "dashboard-index.html|Dashboard Hub"
  "thread-weave-lattice.html|Block Lattice"
  "agency-index.html|Agency Index"
  "agent-workspaces.html|Agent Workspaces"
)

echo "🚀 Launching OCMI Dashboards..."
echo ""

# Check if server is running
if ! curl -s -o /dev/null "$BASE_URL/"; then
  echo "❌ File server not running on port 8888"
  echo "   Starting server..."
  cd /home/x2/.openclaw/workspace
  nohup python3 -m http.server 8888 > /tmp/file-server.log 2>&1 &
  sleep 2
fi

echo "✅ Server running at $BASE_URL"
echo ""

# Open dashboards based on OS
if command -v xdg-open &> /dev/null; then
  # Linux
  for dash in "${DASHBOARDS[@]}"; do
    IFS='|' read -r file title <<< "$dash"
    echo "📊 Opening: $title"
    xdg-open "$BASE_URL/$file" &
  done
elif command -v open &> /dev/null; then
  # macOS
  for dash in "${DASHBOARDS[@]}"; do
    IFS='|' read -r file title <<< "$dash"
    echo "📊 Opening: $title"
    open "$BASE_URL/$file"
  done
elif command -v start &> /dev/null; then
  # Windows
  for dash in "${DASHBOARDS[@]}"; do
    IFS='|' read -r file title <<< "$dash"
    echo "📊 Opening: $title"
    start "$BASE_URL/$file"
  done
fi

echo ""
echo "🎉 All dashboards launched!"
echo ""
echo "Quick Links:"
echo "  Dashboard Hub:    $BASE_URL/dashboard-index.html"
echo "  Block Lattice:    $BASE_URL/thread-weave-lattice.html"
echo "  Agency Index:     $BASE_URL/agency-index.html"
echo "  Agent Workspaces: $BASE_URL/agent-workspaces.html"
