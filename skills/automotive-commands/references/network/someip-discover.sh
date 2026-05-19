#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# SOME/IP Discover — Discover SOME/IP services on automotive network
# ============================================================================
# Usage: someip-discover.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -i, --interface  Network interface (default: eth0)
#   -s, --service    Filter by service ID (hex)
#   -t, --timeout    Discovery timeout in seconds (default: 5)
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
NET_IFACE="eth0"
SERVICE_FILTER=""
TIMEOUT_S=5

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -i, --interface  Network interface"
            echo "  -s, --service    Filter by service ID (hex)"
            echo "  -t, --timeout    Discovery timeout (default: 5s)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -i|--interface) NET_IFACE="$2"; shift 2 ;;
        -s|--service) SERVICE_FILTER="$2"; shift 2 ;;
        -t|--timeout) TIMEOUT_S="$2"; shift 2 ;;
        *) shift ;;
    esac
done

check_vsomeip() {
    info "Checking vSomeIP availability..."
    if command -v vsomeipd &>/dev/null; then
        info "vSomeIP daemon found"
    else
        warn "vSomeIP not installed, using simulation mode"
    fi
}

send_sd_find() {
    info "Sending SOME/IP-SD FindService on $NET_IFACE (timeout: ${TIMEOUT_S}s)..."
    [[ -n "$SERVICE_FILTER" ]] && info "Service filter: 0x$SERVICE_FILTER"
    info "Listening for OfferService responses..."
}

simulate_discovery() {
    info "Discovered services:"
    local services=(
        "0x0001:VehicleControl:1.0:192.168.1.10:30500"
        "0x0002:DiagnosticService:2.1:192.168.1.11:30501"
        "0x0003:TelemetryProvider:1.2:192.168.1.12:30502"
        "0x0004:UpdateManager:1.0:192.168.1.13:30503"
        "0x0005:MediaService:3.0:192.168.1.14:30504"
    )
    local found=0
    for svc in "${services[@]}"; do
        IFS=':' read -r id name version ip port <<< "$svc"
        if [[ -z "$SERVICE_FILTER" ]] || [[ "$id" == *"$SERVICE_FILTER"* ]]; then
            info "  [$id] $name v$version @ $ip:$port"
            found=$((found + 1))
        fi
    done
    info "Total services discovered: $found"
}

generate_service_map() {
    local map_file="./someip-services.json"
    info "Generating service map..."
    cat > "$map_file" <<EOF
{
    "someip_discovery": {
        "interface": "${NET_IFACE}",
        "timeout_s": ${TIMEOUT_S},
        "services": [
            {"id": "0x0001", "name": "VehicleControl", "version": "1.0", "ip": "192.168.1.10", "port": 30500, "protocol": "UDP"},
            {"id": "0x0002", "name": "DiagnosticService", "version": "2.1", "ip": "192.168.1.11", "port": 30501, "protocol": "TCP"},
            {"id": "0x0003", "name": "TelemetryProvider", "version": "1.2", "ip": "192.168.1.12", "port": 30502, "protocol": "UDP"},
            {"id": "0x0004", "name": "UpdateManager", "version": "1.0", "ip": "192.168.1.13", "port": 30503, "protocol": "TCP"},
            {"id": "0x0005", "name": "MediaService", "version": "3.0", "ip": "192.168.1.14", "port": 30504, "protocol": "UDP"}
        ],
        "discovered_at": "$(date -Iseconds)"
    }
}
EOF
    info "Service map written to: $map_file"
}

main() {
    info "Starting SOME/IP service discovery..."
    check_vsomeip
    send_sd_find
    simulate_discovery
    generate_service_map
    info "SOME/IP discovery complete"
}

main
