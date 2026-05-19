#!/bin/bash
# QNX Deploy Script
# Deploy binaries and files to QNX target system

set -e

# Default configuration
BINARY=""
TARGET_IP=""
TARGET_PORT="22"
TARGET_PATH="/tmp"
TARGET_USER="root"
AUTO_START=0
VERBOSE=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy QNX applications to target hardware.

OPTIONS:
    -b, --binary FILE       Binary file to deploy (required)
    -i, --ip ADDRESS        Target IP address (required)
    -p, --port PORT         SSH port (default: 22)
    -d, --dest PATH         Destination path on target (default: /tmp)
    -u, --user USER         Target username (default: root)
    -s, --start             Auto-start after deployment
    -v, --verbose           Verbose output
    -h, --help              Show this help message

EXAMPLES:
    # Deploy to target
    $0 --binary build/aarch64le/release/can_service --ip 192.168.1.100

    # Deploy and start automatically
    $0 -b my_app -i 192.168.1.100 -d /usr/local/bin -s

    # Deploy with custom user and port
    $0 -b test_app -i 10.0.0.50 -p 2222 -u admin

EOF
    exit 0
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_target_reachable() {
    local target="$1"
    local port="$2"

    log_info "Checking target connectivity: $target:$port"

    if ! ping -c 1 -W 2 "$target" > /dev/null 2>&1; then
        log_warn "Target not responding to ping, but trying SSH anyway..."
    fi

    # Test SSH connection
    if ! ssh -p "$port" -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
         "$TARGET_USER@$target" "echo 'connected'" > /dev/null 2>&1; then
        log_error "Cannot connect to target via SSH"
        log_error "Please check:"
        log_error "  1. Target IP address is correct"
        log_error "  2. SSH is running on target"
        log_error "  3. Network connectivity"
        exit 1
    fi

    log_info "Target is reachable"
}

deploy_binary() {
    local binary="$1"
    local target="$2"
    local port="$3"
    local dest_path="$4"

    if [ ! -f "$binary" ]; then
        log_error "Binary not found: $binary"
        exit 1
    fi

    local binary_name=$(basename "$binary")
    local dest="$TARGET_USER@$target:$dest_path/$binary_name"

    log_info "Deploying: $binary"
    log_info "Destination: $dest"

    # Copy binary
    if [ $VERBOSE -eq 1 ]; then
        scp -P "$port" -o StrictHostKeyChecking=no "$binary" "$dest"
    else
        scp -q -P "$port" -o StrictHostKeyChecking=no "$binary" "$dest" 2>&1
    fi

    if [ $? -ne 0 ]; then
        log_error "Deployment failed"
        exit 1
    fi

    # Set executable permissions
    ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "chmod +x $dest_path/$binary_name"

    log_info "Deployment successful"

    # Get file info on target
    log_info "File info on target:"
    ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "ls -lh $dest_path/$binary_name"
}

start_application() {
    local target="$1"
    local port="$2"
    local dest_path="$3"
    local binary_name="$4"

    log_info "Starting application on target..."

    # Kill existing process if running
    ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "slay $binary_name 2>/dev/null || true"

    sleep 1

    # Start new process in background
    ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "on -p 50 $dest_path/$binary_name &"

    if [ $? -eq 0 ]; then
        log_info "Application started"

        # Check if process is running
        sleep 1
        local pid=$(ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
                   "pidin -p $binary_name | grep $binary_name | awk '{print \$1}'")

        if [ -n "$pid" ]; then
            log_info "Process running with PID: $pid"
        else
            log_warn "Process may not be running, check target logs"
        fi
    else
        log_error "Failed to start application"
        exit 1
    fi
}

get_system_info() {
    local target="$1"
    local port="$2"

    log_info "Target system information:"

    # Get QNX version
    ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "uname -a" 2>/dev/null || log_warn "Could not get system info"

    # Get available memory
    ssh -p "$port" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "pidin info | head -5" 2>/dev/null || true
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--binary)
            BINARY="$2"
            shift 2
            ;;
        -i|--ip)
            TARGET_IP="$2"
            shift 2
            ;;
        -p|--port)
            TARGET_PORT="$2"
            shift 2
            ;;
        -d|--dest)
            TARGET_PATH="$2"
            shift 2
            ;;
        -u|--user)
            TARGET_USER="$2"
            shift 2
            ;;
        -s|--start)
            AUTO_START=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$BINARY" ]; then
    log_error "Binary file is required (-b/--binary)"
    usage
fi

if [ -z "$TARGET_IP" ]; then
    log_error "Target IP address is required (-i/--ip)"
    usage
fi

# Check target connectivity
check_target_reachable "$TARGET_IP" "$TARGET_PORT"

# Get system info
if [ $VERBOSE -eq 1 ]; then
    get_system_info "$TARGET_IP" "$TARGET_PORT"
fi

# Deploy binary
deploy_binary "$BINARY" "$TARGET_IP" "$TARGET_PORT" "$TARGET_PATH"

# Auto-start if requested
if [ $AUTO_START -eq 1 ]; then
    start_application "$TARGET_IP" "$TARGET_PORT" "$TARGET_PATH" "$(basename $BINARY)"
fi

log_info "Deployment complete!"
