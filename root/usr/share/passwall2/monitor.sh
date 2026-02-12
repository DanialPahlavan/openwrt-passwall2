#!/bin/sh
# PassWall2 System Monitor
# Lightweight monitoring script for low-resource routers
# Memory impact: ~500KB when running

LOG_FILE="/tmp/passwall2_monitor.log"
MAX_LOG_SIZE=10240  # 10KB max log size
STATS_FILE="/tmp/passwall2_stats.json"

# Function to rotate logs if too large
rotate_logs() {
    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            tail -n 50 "$LOG_FILE" > "$LOG_FILE.tmp"
            mv "$LOG_FILE.tmp" "$LOG_FILE"
        fi
    fi
}

# Get current bandwidth usage
get_bandwidth() {
    local iface="${1:-br-lan}"
    local rx_bytes=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx_bytes=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0)
    echo "$rx_bytes $tx_bytes"
}

# Get connection count
get_connections() {
    netstat -an 2>/dev/null | grep ESTABLISHED | wc -l
}

# Get system uptime
get_uptime() {
    cat /proc/uptime | awk '{print int($1)}'
}

# Check if PassWall2 is running
check_service() {
    local status=0
    if pgrep -f "passwall2" > /dev/null 2>&1; then
        status=1
    fi
    echo "$status"
}

# Calculate bandwidth rate (bytes/sec)
calculate_rate() {
    local prev_file="/tmp/pw2_prev_bw"
    local current_rx=$1
    local current_tx=$2
    
    if [ -f "$prev_file" ]; then
        local prev_data=$(cat "$prev_file")
        local prev_rx=$(echo "$prev_data" | awk '{print $1}')
        local prev_tx=$(echo "$prev_data" | awk '{print $2}')
        local prev_time=$(echo "$prev_data" | awk '{print $3}')
        local current_time=$(date +%s)
        
        local time_diff=$((current_time - prev_time))
        if [ "$time_diff" -gt 0 ]; then
            local rx_rate=$(( (current_rx - prev_rx) / time_diff ))
            local tx_rate=$(( (current_tx - prev_tx) / time_diff ))
            echo "$rx_rate $tx_rate"
        else
            echo "0 0"
        fi
    else
        echo "0 0"
    fi
    
    # Save current values
    echo "$current_rx $current_tx $(date +%s)" > "$prev_file"
}

# Main monitoring function
monitor_stats() {
    local bw=$(get_bandwidth)
    local rx=$(echo "$bw" | awk '{print $1}')
    local tx=$(echo "$bw" | awk '{print $2}')
    local rates=$(calculate_rate "$rx" "$tx")
    local rx_rate=$(echo "$rates" | awk '{print $1}')
    local tx_rate=$(echo "$rates" | awk '{print $2}')
    local connections=$(get_connections)
    local uptime=$(get_uptime)
    local service_status=$(check_service)
    
    # Create JSON stats file
    cat > "$STATS_FILE" <<EOF
{
    "timestamp": $(date +%s),
    "service_running": $service_status,
    "connections": $connections,
    "uptime": $uptime,
    "bandwidth": {
        "rx_bytes": $rx,
        "tx_bytes": $tx,
        "rx_rate": $rx_rate,
        "tx_rate": $tx_rate
    }
}
EOF
    
    # Log to file
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Status: $service_status, Connections: $connections, RX: $rx_rate B/s, TX: $tx_rate B/s" >> "$LOG_FILE"
}

# Cleanup old data
cleanup() {
    rotate_logs
    # Keep only last 24 hours of stats
    find /tmp -name "passwall2_stats_*.json" -mtime +1 -delete 2>/dev/null
}

# Main execution
case "$1" in
    start)
        while true; do
            monitor_stats
            cleanup
            sleep 30  # Update every 30 seconds
        done
        ;;
    stats)
        if [ -f "$STATS_FILE" ]; then
            cat "$STATS_FILE"
        else
            echo '{"error": "No stats available"}'
        fi
        ;;
    stop)
        pkill -f "passwall2.*monitor"
        ;;
    *)
        echo "Usage: $0 {start|stop|stats}"
        exit 1
        ;;
esac
