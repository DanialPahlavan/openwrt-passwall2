#!/bin/sh
# PassWall2 Enhanced Backup Script
# Supports scheduled backups, incremental backups, and USB storage
# Memory impact: ~1MB during operation

BACKUP_DIR="/tmp/passwall2_backups"
USB_BACKUP_DIR="/mnt/sda1/passwall2_backups"
CONFIG_FILES="
/etc/config/passwall2
/etc/passwall2/
/usr/share/passwall2/subscriptions/
"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename
get_backup_filename() {
    local backup_type="${1:-full}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "passwall2_${backup_type}_${timestamp}.tar.gz"
}

# Create full backup
create_full_backup() {
    local filename=$(get_backup_filename "full")
    local filepath="$BACKUP_DIR/$filename"
    
    echo "Creating full backup: $filename"
    
    tar -czf "$filepath" $CONFIG_FILES 2>/dev/null
    
    if [ $? -eq 0 ]; then
        local size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        echo "Backup created successfully: $filepath ($size bytes)"
        echo "$filepath"
        return 0
    else
        echo "Error creating backup"
        return 1
    fi
}

# Create incremental backup
create_incremental_backup() {
    local last_backup="$BACKUP_DIR/.last_full_backup"
    local filename=$(get_backup_filename "incremental")
    local filepath="$BACKUP_DIR/$filename"
    
    echo "Creating incremental backup: $filename"
    
    if [ -f "$last_backup" ]; then
        tar -czf "$filepath" --newer="$last_backup" $CONFIG_FILES 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "Incremental backup created: $filepath"
            echo "$filepath"
            return 0
        fi
    else
        echo "No previous full backup found. Creating full backup..."
        create_full_backup
        touch "$last_backup"
    fi
}

# Copy to USB storage
backup_to_usb() {
    local source_file="$1"
    
    if [ ! -d "/mnt/sda1" ]; then
        echo "USB storage not mounted at /mnt/sda1"
        return 1
    fi
    
    mkdir -p "$USB_BACKUP_DIR"
    
    local filename=$(basename "$source_file")
    local dest_file="$USB_BACKUP_DIR/$filename"
    
    cp "$source_file" "$dest_file"
    
    if [ $? -eq 0 ]; then
        echo "Backup copied to USB: $dest_file"
        return 0
    else
        echo "Error copying to USB"
        return 1
    fi
}

# List backups
list_backups() {
    echo "Available backups:"
    echo "==================="
    
    if [ -d "$BACKUP_DIR" ]; then
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print $9, "-", $5}'
    fi
    
    if [ -d "$USB_BACKUP_DIR" ]; then
        echo ""
        echo "USB Backups:"
        ls -lh "$USB_BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print $9, "-", $5}'
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        echo "Backup file not found: $backup_file"
        return 1
    fi
    
    echo "Restoring from: $backup_file"
    echo "WARNING: This will overwrite current configuration!"
    echo -n "Continue? (yes/no): "
    read confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled"
        return 1
    fi
    
    tar -xzf "$backup_file" -C / 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "Restore completed successfully"
        echo "Restarting PassWall2..."
        /etc/init.d/passwall2 restart
        return 0
    else
        echo "Error restoring backup"
        return 1
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    local keep_count="${1:-5}"
    
    echo "Cleaning up old backups (keeping last $keep_count)..."
    
    local backup_list=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null)
    local count=0
    
    for backup in $backup_list; do
        count=$((count + 1))
        if [ $count -gt $keep_count ]; then
            echo "Removing old backup: $backup"
            rm -f "$backup"
        fi
    done
}

# Scheduled backup function
scheduled_backup() {
    local backup_file=$(create_full_backup)
    
    if [ $? -eq 0 ] && [ -n "$backup_file" ]; then
        # Try to copy to USB if mounted
        if [ -d "/mnt/sda1" ]; then
            backup_to_usb "$backup_file"
        fi
        
        # Cleanup old backups
        cleanup_old_backups 5
    fi
}

# Main execution
case "$1" in
    full)
        backup_file=$(create_full_backup)
        [ $? -eq 0 ] && echo "Backup file: $backup_file"
        ;;
    incremental)
        backup_file=$(create_incremental_backup)
        [ $? -eq 0 ] && echo "Backup file: $backup_file"
        ;;
    usb)
        if [ -z "$2" ]; then
            echo "Usage: $0 usb <backup_file>"
            exit 1
        fi
        backup_to_usb "$2"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: $0 restore <backup_file>"
            exit 1
        fi
        restore_backup "$2"
        ;;
    list)
        list_backups
        ;;
    cleanup)
        cleanup_old_backups "${2:-5}"
        ;;
    scheduled)
        scheduled_backup
        ;;
    *)
        echo "PassWall2 Enhanced Backup Tool"
        echo "Usage: $0 {full|incremental|usb|restore|list|cleanup|scheduled}"
        echo ""
        echo "Commands:"
        echo "  full                - Create full backup"
        echo "  incremental         - Create incremental backup"
        echo "  usb <file>          - Copy backup to USB"
        echo "  restore <file>      - Restore from backup"
        echo "  list                - List all backups"
        echo "  cleanup [count]     - Remove old backups (default: keep 5)"
        echo "  scheduled           - Run scheduled backup"
        exit 1
        ;;
esac
