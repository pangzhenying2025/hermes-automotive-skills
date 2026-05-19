#!/bin/bash
# QNX Remote Debug Script
# Launch GDB debugging session on QNX target

set -e

# Default configuration
BINARY=""
TARGET_IP=""
TARGET_PORT="8000"
GDB_PORT="8001"
TARGET_USER="root"
ATTACH_PID=""
ATTACH_NAME=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# QNX Environment
: ${QNX_HOST:=/opt/qnx710/host/linux/x86_64}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Launch remote GDB debugging session on QNX target.

OPTIONS:
    -b, --binary FILE       Local binary file with debug symbols
    -i, --ip ADDRESS        Target IP address (required)
    -p, --port PORT         qconn/SSH port (default: 8000)
    -g, --gdb-port PORT     GDB server port (default: 8001)
    -u, --user USER         Target username (default: root)
    -a, --attach PID        Attach to running process by PID
    -n, --name NAME         Attach to running process by name
    -h, --help              Show this help message

DEBUG MODES:
    1. Launch new process:
       $0 -b my_app -i 192.168.1.100

    2. Attach to running process (by name):
       $0 -b my_app -i 192.168.1.100 -n my_app

    3. Attach to running process (by PID):
       $0 -b my_app -i 192.168.1.100 -a 12345

EXAMPLES:
    # Debug new process
    $0 --binary build/aarch64le/debug/can_service --ip 192.168.1.100

    # Attach to running process
    $0 -b my_app -i 192.168.1.100 -n my_app

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

check_qnx_environment() {
    if [ ! -d "$QNX_HOST" ]; then
        log_error "QNX_HOST not found: $QNX_HOST"
        log_error "Please source QNX environment"
        exit 1
    fi

    local GDB="$QNX_HOST/usr/bin/ntoaarch64-gdb"
    if [ ! -x "$GDB" ]; then
        GDB="$QNX_HOST/usr/bin/ntox86_64-gdb"
        if [ ! -x "$GDB" ]; then
            log_error "QNX GDB not found in $QNX_HOST/usr/bin/"
            exit 1
        fi
    fi

    log_info "Using GDB: $GDB"
}

check_target_reachable() {
    local target="$1"
    local port="$2"

    log_info "Checking target connectivity: $target:$port"

    if ! ping -c 1 -W 2 "$target" > /dev/null 2>&1; then
        log_warn "Target not responding to ping"
    fi

    # Test SSH connection
    if ! ssh -p "$port" -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
         "$TARGET_USER@$target" "echo 'connected'" > /dev/null 2>&1; then
        log_warn "Cannot connect via SSH, trying qconn..."
    fi
}

get_process_pid() {
    local target="$1"
    local process_name="$2"

    log_info "Finding PID for process: $process_name"

    local pid=$(ssh -p "$TARGET_PORT" -o StrictHostKeyChecking=no \
                "$TARGET_USER@$target" \
                "pidin -p $process_name | grep $process_name | awk '{print \$1}'" 2>/dev/null)

    if [ -z "$pid" ]; then
        log_error "Process not found: $process_name"
        log_error "Check running processes with: ssh $TARGET_USER@$target pidin"
        exit 1
    fi

    echo "$pid"
}

start_gdb_server() {
    local target="$1"
    local gdb_port="$2"
    local binary_path="$3"
    local attach_pid="$4"

    log_info "Starting GDB server on target..."

    # Kill existing gdbserver
    ssh -p "$TARGET_PORT" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
        "slay pdebug 2>/dev/null || true"

    sleep 1

    # Start pdebug (QNX debug agent)
    if [ -n "$attach_pid" ]; then
        log_info "Attaching to PID: $attach_pid"
        ssh -p "$TARGET_PORT" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
            "pdebug -p $gdb_port $attach_pid &" > /dev/null 2>&1
    else
        log_info "Starting new process: $binary_path"
        ssh -p "$TARGET_PORT" -o StrictHostKeyChecking=no "$TARGET_USER@$target" \
            "pdebug -p $gdb_port $binary_path &" > /dev/null 2>&1
    fi

    sleep 2
    log_info "GDB server ready on port $gdb_port"
}

launch_gdb_client() {
    local target="$1"
    local gdb_port="$2"
    local binary="$3"

    # Determine GDB binary based on target architecture
    local GDB="$QNX_HOST/usr/bin/ntoaarch64-gdb"
    if [ ! -x "$GDB" ]; then
        GDB="$QNX_HOST/usr/bin/ntox86_64-gdb"
    fi

    log_info "Launching GDB client..."
    log_info "Binary: $binary"
    log_info "Target: $target:$gdb_port"

    # Create GDB command file
    local gdb_commands=$(mktemp)
    cat > "$gdb_commands" << EOF
# QNX Remote Debug Session
set sysroot $QNX_TARGET
set solib-search-path $QNX_TARGET/aarch64le/lib:$QNX_TARGET/aarch64le/usr/lib
target qnx $target:$gdb_port
EOF

    log_info "GDB Commands:"
    cat "$gdb_commands"

    # Launch GDB
    "$GDB" -x "$gdb_commands" "$binary"

    # Cleanup
    rm -f "$gdb_commands"
}

show_debug_tips() {
    log_info "Debug session tips:"
    echo ""
    echo "  Common GDB commands:"
    echo "    break main          - Set breakpoint at main()"
    echo "    continue            - Continue execution"
    echo "    step                - Step into function"
    echo "    next                - Step over function"
    echo "    print variable      - Print variable value"
    echo "    backtrace           - Show call stack"
    echo "    info threads        - List all threads"
    echo "    thread 2            - Switch to thread 2"
    echo ""
    echo "  QNX-specific:"
    echo "    info proc           - Show process information"
    echo "    info mem            - Show memory regions"
    echo ""
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
        -g|--gdb-port)
            GDB_PORT="$2"
            shift 2
            ;;
        -u|--user)
            TARGET_USER="$2"
            shift 2
            ;;
        -a|--attach)
            ATTACH_PID="$2"
            shift 2
            ;;
        -n|--name)
            ATTACH_NAME="$2"
            shift 2
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

if [ ! -f "$BINARY" ]; then
    log_error "Binary not found: $BINARY"
    exit 1
fi

if [ -z "$TARGET_IP" ]; then
    log_error "Target IP address is required (-i/--ip)"
    usage
fi

# Check QNX environment
check_qnx_environment

# Check target connectivity
check_target_reachable "$TARGET_IP" "$TARGET_PORT"

# Get PID if attaching by name
if [ -n "$ATTACH_NAME" ]; then
    ATTACH_PID=$(get_process_pid "$TARGET_IP" "$ATTACH_NAME")
    log_info "Found PID: $ATTACH_PID"
fi

# Show debug tips
show_debug_tips

# Start GDB server on target
BINARY_NAME=$(basename "$BINARY")
if [ -n "$ATTACH_PID" ]; then
    start_gdb_server "$TARGET_IP" "$GDB_PORT" "" "$ATTACH_PID"
else
    # Deploy binary first if not attaching
    log_info "Deploying binary to target..."
    scp -q -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$BINARY" \
        "$TARGET_USER@$TARGET_IP:/tmp/$BINARY_NAME"
    ssh -p "$TARGET_PORT" -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" \
        "chmod +x /tmp/$BINARY_NAME"

    start_gdb_server "$TARGET_IP" "$GDB_PORT" "/tmp/$BINARY_NAME" ""
fi

# Launch GDB client
launch_gdb_client "$TARGET_IP" "$GDB_PORT" "$BINARY"

log_info "Debug session ended"
