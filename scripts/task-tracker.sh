#!/bin/bash
# OCMI Task Tracker - Report to Cluster Hub
# Reports task status to central Cluster Hub

HUB_URL="${HUB_URL:-http://100.80.211.39:8090}"
TASK_FILE="${1:-tasks.json}"

echo "=== OCMI Task Reporter ==="
echo "Hub: $HUB_URL"

# List tasks
echo ""
echo "1. Fetching tasks from Hub..."
curl -s "$HUB_URL/api/tasks" | python3 -c "
import sys,json
tasks = json.load(sys.stdin)
print(f'Found {len(tasks)} tasks:')
for t in tasks[:5]:
    status = t.get('status','unknown')
    title = t.get('title','untitled')[:40]
    print(f'  [{status}] {title}')
" 2>/dev/null || echo "Failed to fetch tasks"

# Create new task
echo ""
echo "2. To create a task, call:"
echo "curl -X POST $HUB_URL/api/tasks/create -H 'Content-Type: application/json' -d '{\"title\":\"Task Name\",\"status\":\"open\",\"assignee\":\"machine\"}'"

# Update task
echo ""
echo "3. To update a task:"
echo "curl -X PUT $HUB_URL/api/tasks/<task_id> -H 'Content-Type: application/json' -d '{\"status\":\"done\"}'"

# Monitor
echo ""
echo "4. Monitor tasks (continuous):"
echo "watch curl -s $HUB_URL/api/tasks"

echo ""
echo "=== Quick Commands ==="
echo "View all tasks: curl -s $HUB_URL/api/tasks"
echo "View pending:   curl -s $HUB_URL/api/tasks?status=open"
echo "View done:     curl -s $HUB_URL/api/tasks?status=done"
echo "Add task:      curl -X POST $HUB_URL/api/tasks/create -d '{\"title\":\"...\"}'"
