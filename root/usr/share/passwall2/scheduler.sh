#!/bin/sh
# PassWall2 Scheduler
# Manages scheduled tasks using system cron
# Memory impact: Minimal (uses existing cron)

CRON_FILE="/etc/crontabs/root"
SCHEDULE_DIR="/etc/passwall2/schedules"

# Ensure schedule directory exists
mkdir -p "$SCHEDULE_DIR"

# Add a scheduled task
add_task() {
    local task_name="$1"
    local schedule="$2"
    local command="$3"
    
    if [ -z "$task_name" ] || [ -z "$schedule" ] || [ -z "$command" ]; then
        echo "Error: Missing parameters"
        echo "Usage: add_task <name> <schedule> <command>"
        return 1
    fi
    
    # Create task file
    cat > "$SCHEDULE_DIR/$task_name" <<EOF
SCHEDULE=$schedule
COMMAND=$command
ENABLED=1
EOF
    
    # Update cron
    update_cron
    echo "Task '$task_name' added successfully"
}

# Remove a scheduled task
remove_task() {
    local task_name="$1"
    
    if [ -f "$SCHEDULE_DIR/$task_name" ]; then
        rm -f "$SCHEDULE_DIR/$task_name"
        update_cron
        echo "Task '$task_name' removed successfully"
    else
        echo "Task '$task_name' not found"
        return 1
    fi
}

# Enable/disable a task
toggle_task() {
    local task_name="$1"
    local enable="$2"
    
    if [ -f "$SCHEDULE_DIR/$task_name" ]; then
        sed -i "s/^ENABLED=.*/ENABLED=$enable/" "$SCHEDULE_DIR/$task_name"
        update_cron
        if [ "$enable" = "1" ]; then
            echo "Task '$task_name' enabled"
        else
            echo "Task '$task_name' disabled"
        fi
    else
        echo "Task '$task_name' not found"
        return 1
    fi
}

# Update cron file with all enabled tasks
update_cron() {
    # Backup existing cron
    cp "$CRON_FILE" "$CRON_FILE.bak" 2>/dev/null
    
    # Remove old PassWall2 tasks
    sed -i '/# PassWall2 Scheduled Task:/d' "$CRON_FILE" 2>/dev/null
    sed -i '/# End PassWall2 Task/d' "$CRON_FILE" 2>/dev/null
    
    # Add enabled tasks
    for task_file in "$SCHEDULE_DIR"/*; do
        if [ -f "$task_file" ]; then
            . "$task_file"
            if [ "$ENABLED" = "1" ]; then
                local task_name=$(basename "$task_file")
                echo "# PassWall2 Scheduled Task: $task_name" >> "$CRON_FILE"
                echo "$SCHEDULE $COMMAND" >> "$CRON_FILE"
                echo "# End PassWall2 Task" >> "$CRON_FILE"
            fi
        fi
    done
    
    # Reload cron
    /etc/init.d/cron restart >/dev/null 2>&1
}

# List all tasks
list_tasks() {
    echo "PassWall2 Scheduled Tasks:"
    echo "=========================="
    
    for task_file in "$SCHEDULE_DIR"/*; do
        if [ -f "$task_file" ]; then
            . "$task_file"
            local task_name=$(basename "$task_file")
            local status="Disabled"
            [ "$ENABLED" = "1" ] && status="Enabled"
            
            echo ""
            echo "Task: $task_name"
            echo "  Status: $status"
            echo "  Schedule: $SCHEDULE"
            echo "  Command: $COMMAND"
        fi
    done
}

# Add default tasks
setup_default_tasks() {
    # Subscription update (daily at 3 AM)
    add_task "subscription_update" "0 3 * * *" "/usr/share/passwall2/subscription_update.sh"
    
    # Node test (every 6 hours)
    add_task "node_test" "0 */6 * * *" "/usr/share/passwall2/test_nodes.sh"
    
    # Cleanup logs (daily at 2 AM)
    add_task "cleanup_logs" "0 2 * * *" "find /tmp -name 'passwall2*.log' -mtime +7 -delete"
    
    echo "Default tasks created"
}

# Main execution
case "$1" in
    add)
        shift
        add_task "$@"
        ;;
    remove)
        remove_task "$2"
        ;;
    enable)
        toggle_task "$2" "1"
        ;;
    disable)
        toggle_task "$2" "0"
        ;;
    list)
        list_tasks
        ;;
    update)
        update_cron
        ;;
    setup)
        setup_default_tasks
        ;;
    *)
        echo "PassWall2 Scheduler"
        echo "Usage: $0 {add|remove|enable|disable|list|update|setup}"
        echo ""
        echo "Commands:"
        echo "  add <name> <schedule> <command>  - Add a new task"
        echo "  remove <name>                     - Remove a task"
        echo "  enable <name>                     - Enable a task"
        echo "  disable <name>                    - Disable a task"
        echo "  list                              - List all tasks"
        echo "  update                            - Update cron configuration"
        echo "  setup                             - Create default tasks"
        echo ""
        echo "Schedule format: minute hour day month weekday"
        echo "Example: 0 3 * * * (daily at 3 AM)"
        exit 1
        ;;
esac
