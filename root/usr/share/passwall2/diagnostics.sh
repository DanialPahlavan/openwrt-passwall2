#!/bin/sh
# PassWall2 Diagnostics Tool
# Enhanced diagnostic functions for troubleshooting
# Memory impact: Runs on-demand only

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test DNS resolution
test_dns() {
    local test_domain="${1:-www.google.com}"
    echo -n "Testing DNS resolution for $test_domain... "
    
    if nslookup "$test_domain" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Test internet connectivity
test_connectivity() {
    local test_url="${1:-http://www.google.com/generate_204}"
    echo -n "Testing connectivity to $test_url... "
    
    if curl -s --connect-timeout 5 "$test_url" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Test port connectivity
test_port() {
    local host="$1"
    local port="$2"
    echo -n "Testing connection to $host:$port... "
    
    if nc -z -w 3 "$host" "$port" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Check routing table
check_routes() {
    echo -e "\n${YELLOW}=== Routing Table ===${NC}"
    ip route show | head -n 10
}

# Check firewall rules
check_firewall() {
    echo -e "\n${YELLOW}=== Firewall Rules (PassWall2) ===${NC}"
    iptables -t nat -L PASSWALL2 2>/dev/null | head -n 20 || echo "No PassWall2 chains found"
}

# Check process status
check_processes() {
    echo -e "\n${YELLOW}=== PassWall2 Processes ===${NC}"
    ps | grep passwall2 | grep -v grep
}

# Memory usage
check_memory() {
    echo -e "\n${YELLOW}=== Memory Usage ===${NC}"
    free -m | awk 'NR==1{print "        "$1"   "$2"      "$3"      "$4}'
    free -m | awk 'NR==2{printf "RAM:    %5d   %5d    %5d\n", $2,$3,$4}'
}

# Check log files
check_logs() {
    local log_file="${1:-/tmp/passwall2.log}"
    echo -e "\n${YELLOW}=== Last 10 Log Entries ===${NC}"
    
    if [ -f "$log_file" ]; then
        tail -n 10 "$log_file"
    else
        echo "No log file found at $log_file"
    fi
}

# Network interfaces status
check_interfaces() {
    echo -e "\n${YELLOW}=== Network Interfaces ===${NC}"
    ip link show | grep -E "^[0-9]+:|state"
}

# Full diagnostic report
full_diagnostic() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  PassWall2 Diagnostic Report${NC}"
    echo -e "${GREEN}  $(date)${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    test_dns
    test_connectivity
    check_processes
    check_memory
    check_interfaces
    check_routes
    check_firewall
    check_logs
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Diagnostic Complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Main execution
case "$1" in
    dns)
        test_dns "$2"
        ;;
    connectivity)
        test_connectivity "$2"
        ;;
    port)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 port <host> <port>"
            exit 1
        fi
        test_port "$2" "$3"
        ;;
    routes)
        check_routes
        ;;
    firewall)
        check_firewall
        ;;
    processes)
        check_processes
        ;;
    memory)
        check_memory
        ;;
    logs)
        check_logs "$2"
        ;;
    interfaces)
        check_interfaces
        ;;
    full)
        full_diagnostic
        ;;
    *)
        echo "Usage: $0 {dns|connectivity|port|routes|firewall|processes|memory|logs|interfaces|full}"
        echo ""
        echo "Examples:"
        echo "  $0 dns www.google.com"
        echo "  $0 connectivity http://www.google.com"
        echo "  $0 port 8.8.8.8 53"
        echo "  $0 full"
        exit 1
        ;;
esac
