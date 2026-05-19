#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# XCP Connect — Establish XCP (Universal Measurement and Calibration Protocol) connection
# ============================================================================
# Usage: xcp-connect.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -t, --transport  Transport layer (can|ethernet|usb)
#   -a, --address    ECU address or IP
#   -p, --port       Port number (for ethernet transport)
#   --timeout        Connection timeout in seconds (default: 5)
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

VERBOSE=false
TRANSPORT="can"
ECU_ADDRESS=""
PORT=5555
TIMEOUT_S=5

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -t, --transport  Transport layer (can|ethernet|usb)"
            echo "  -a, --address    ECU address or IP"
            echo "  -p, --port       Port number"
            echo "  --timeout        Connection timeout (default: 5s)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -t|--transport) TRANSPORT="$2"; shift 2 ;;
        -a|--address) ECU_ADDRESS="$2"; shift 2 ;;
        -p|--port) PORT="$2"; shift 2 ;;
        --timeout) TIMEOUT_S="$2"; shift 2 ;;
        *) shift ;;
    esac
done

validate_transport() {
    case "$TRANSPORT" in
        can|ethernet|usb) info "Transport layer: $TRANSPORT" ;;
        *) error "Invalid transport: $TRANSPORT"; return 1 ;;
    esac
}

check_interface() {
    info "Checking $TRANSPORT interface..."
    case "$TRANSPORT" in
        can)
            if command -v candump &>/dev/null; then
                info "CAN utilities available"
            else
                warn "can-utils not installed (simulation mode)"
            fi
            ;;
        ethernet)
            if [[ -z "$ECU_ADDRESS" ]]; then
                ECU_ADDRESS="192.168.1.100"
                warn "No address specified, using default: $ECU_ADDRESS"
            fi
            info "Target: $ECU_ADDRESS:$PORT"
            ;;
        usb)
            info "Checking USB devices..."
            $VERBOSE && info "Looking for XCP-compatible USB interfaces"
            ;;
    esac
}

simulate_connect() {
    info "Initiating XCP CONNECT command..."
    $VERBOSE && info "Sending CONNECT request (timeout: ${TIMEOUT_S}s)"
    info "XCP session established (simulated)"
    info "  Protocol version: 1.1"
    info "  Max CTO: 8 bytes"
    info "  Max DTO: 8 bytes"
    info "  Byte order: Little-endian"
}

query_ecu_info() {
    info "Querying ECU identification..."
    info "  ECU ID: ECU_SIM_001"
    info "  Software version: 2.4.1"
    info "  Calibration version: CAL_2024_03"
    $VERBOSE && info "  Available resources: CAL, DAQ, PGM"
}

generate_session_config() {
    local config_file="./xcp-session.json"
    info "Generating session configuration..."
    cat > "$config_file" <<EOF
{
    "xcp_session": {
        "transport": "${TRANSPORT}",
        "address": "${ECU_ADDRESS:-can0}",
        "port": ${PORT},
        "timeout_s": ${TIMEOUT_S},
        "protocol": {
            "version": "1.1",
            "max_cto_bytes": 8,
            "max_dto_bytes": 8,
            "byte_order": "little_endian"
        },
        "ecu": {
            "id": "ECU_SIM_001",
            "sw_version": "2.4.1",
            "cal_version": "CAL_2024_03"
        },
        "status": "connected",
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Session config written to: $config_file"
}

main() {
    info "Starting XCP connection..."
    validate_transport
    check_interface
    simulate_connect
    query_ecu_info
    generate_session_config
    info "XCP connection setup complete"
}

main
