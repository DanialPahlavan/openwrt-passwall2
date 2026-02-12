#!/bin/sh
# PassWall 3 Beta Error Logger
# Logs errors and issues for debugging

LOG_DIR="/tmp/passwall3/logs"
ERROR_LOG="$LOG_DIR/error.log"
DEBUG_LOG="$LOG_DIR/debug.log"
CRASH_LOG="$LOG_DIR/crash.log"
MAX_LOG_SIZE=5242880  # 5MB per log file
MAX_LOG_FILES=5

# Create log directory
mkdir -p "$LOG_DIR"

# Function to rotate logs
rotate_logs() {
    local log_file="$1"
    
    if [ -f "$log_file" ] && [ $(stat -c%s "$log_file" 2>/dev/null || echo 0) -ge $MAX_LOG_SIZE ]; then
        # Rotate old logs
        for i in $(seq $((MAX_LOG_FILES - 1)) -1 1); do
            [ -f "${log_file}.$i" ] && mv "${log_file}.$i" "${log_file}.$((i + 1))"
        done
        mv "$log_file" "${log_file}.1"
        touch "$log_file"
    fi
}

# Function to log error
log_error() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    rotate_logs "$ERROR_LOG"
    
    echo "[$timestamp] [$level] [$component] $message" >> "$ERROR_LOG"
}

# Function to log debug info
log_debug() {
    local component="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    rotate_logs "$DEBUG_LOG"
    
    echo "[$timestamp] [DEBUG] [$component] $message" >> "$DEBUG_LOG"
}

# Function to log crash
log_crash() {
    local component="$1"
    local error_msg="$2"
    local stack_trace="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    rotate_logs "$CRASH_LOG"
    
    {
        echo "================== CRASH REPORT =================="
        echo "Timestamp: $timestamp"
        echo "Component: $component"
        echo "Error: $error_msg"
        echo ""
        echo "Stack Trace:"
        echo "$stack_trace"
        echo ""
        echo "System Info:"
        uname -a
        echo "Memory:"
        free -h
        echo "=================================================="
        echo ""
    } >> "$CRASH_LOG"
}

# Function to export logs as archive
export_logs() {
    local export_file="/tmp/passwall3-logs-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    tar -czf "$export_file" -C "$LOG_DIR" .
    echo "$export_file"
}

# Function to clear old logs
clear_logs() {
    local days="$1"
    [ -z "$days" ] && days=7
    
    find "$LOG_DIR" -name "*.log*" -mtime +$days -delete
    log_debug "Logger" "Cleared logs older than $days days"
}

# Function to get log summary
get_log_summary() {
    {
        echo "=== PassWall 3 Beta Log Summary ==="
        echo "Generated: $(date)"
        echo ""
        echo "Error Log:"
        [ -f "$ERROR_LOG" ] && tail -n 20 "$ERROR_LOG" || echo "  No errors"
        echo ""
        echo "Recent Crashes:"
        [ -f "$CRASH_LOG" ] && tail -n 50 "$CRASH_LOG" || echo "  No crashes"
        echo ""
        echo "Log Files:"
        ls -lh "$LOG_DIR"
    }
}

# Function to monitor PassWall service
monitor_service() {
    while true; do
        # Check if PassWall is running
        if ! pgrep -f "passwall" > /dev/null; then
            log_error "ERROR" "Monitor" "PassWall service not running"
        fi
        
        # Check memory usage
        mem_usage=$(ps aux | grep passwall | grep -v grep | awk '{sum+=$4} END {print sum}')
        if [ -n "$mem_usage" ] && [ $(echo "$mem_usage > 10" | bc 2>/dev/null || echo 0) -eq 1 ]; then
            log_error "WARNING" "Monitor" "High memory usage: ${mem_usage}%"
        fi
        
        # Check CPU usage
        cpu_usage=$(ps aux | grep passwall | grep -v grep | awk '{sum+=$3} END {print sum}')
        if [ -n "$cpu_usage" ] && [ $(echo "$cpu_usage > 50" | bc 2>/dev/null || echo 0) -eq 1 ]; then
            log_error "WARNING" "Monitor" "High CPU usage: ${cpu_usage}%"
        fi
        
        sleep 300  # Check every 5 minutes
    done
}

# Handle script arguments
case "$1" in
    error)
        log_error "${2:-ERROR}" "${3:-Unknown}" "${4:-No message}"
        ;;
    debug)
        log_debug "${2:-Unknown}" "${3:-No message}"
        ;;
    crash)
        log_crash "${2:-Unknown}" "${3:-No error message}" "${4:-No stack trace}"
        ;;
    export)
        export_logs
        ;;
    clear)
        clear_logs "$2"
        ;;
    summary)
        get_log_summary
        ;;
    monitor)
        monitor_service &
        echo $! > "$LOG_DIR/monitor.pid"
        ;;
    stop-monitor)
        [ -f "$LOG_DIR/monitor.pid" ] && kill $(cat "$LOG_DIR/monitor.pid") 2>/dev/null
        rm -f "$LOG_DIR/monitor.pid"
        ;;
    *)
        echo "PassWall 3 Beta Error Logger"
        echo "Usage: $0 {error|debug|crash|export|clear|summary|monitor|stop-monitor}"
        echo ""
        echo "Commands:"
        echo "  error <level> <component> <message>  - Log an error"
        echo "  debug <component> <message>          - Log debug info"
        echo "  crash <component> <error> <trace>    - Log a crash"
        echo "  export                               - Export logs as tar.gz"
        echo "  clear [days]                         - Clear logs older than N days"
        echo "  summary                              - Show log summary"
        echo "  monitor                              - Start service monitor"
        echo "  stop-monitor                         - Stop service monitor"
        exit 1
        ;;
esac

exit 0
