#!/bin/bash
# Cluster Hub Auto-Restart Script
# Monitors port 8090 and restarts if down

HUB_DIR="/home/x2/.openclaw/workspace/cluster-hub"
LOG_FILE="/tmp/cluster-hub-monitor.log"
CHECK_INTERVAL=30

echo "$(date): Cluster Hub Monitor started" >> $LOG_FILE

while true; do
    if curl -s --max-time 5 http://100.80.211.39:8090/health > /dev/null 2>&1; then
        echo "$(date): Cluster Hub OK" >> $LOG_FILE
    else
        echo "$(date): Cluster Hub DOWN - restarting..." >> $LOG_FILE
        
        # Kill existing
        pkill -f "cluster-hub-server.py" 2>/dev/null
        sleep 2
        
        # Restart
        cd $HUB_DIR
        nohup python3 cluster-hub-server.py >> $LOG_FILE 2>&1 &
        
        sleep 5
        
        # Verify
        if curl -s --max-time 5 http://100.80.211.39:8090/health > /dev/null 2>&1; then
            echo "$(date): Cluster Hub restarted successfully" >> $LOG_FILE
        else
            echo "$(date): Restart failed" >> $LOG_FILE
        fi
    fi
    
    sleep $CHECK_INTERVAL
done