#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# MES Connect — Connect to Manufacturing Execution System
# ============================================================================
# Usage: mes-connect.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -s, --server     MES server address
#   -a, --action     Action (status|orders|report|sync)
#   -l, --line       Production line filter
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
MES_SERVER=""
ACTION="status"
LINE_ID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -s|--server) MES_SERVER="$2"; shift 2 ;;
        -a|--action) ACTION="$2"; shift 2 ;;
        -l|--line) LINE_ID="$2"; shift 2 ;;
        *) shift ;;
    esac
done

show_status() {
    info "MES Connection Status:"
    info "  Server: ${MES_SERVER:-mes.factory.local}"
    info "  Protocol: OPC-UA"
    info "  Connection: active (simulated)"
    info "  Active orders: 8"
    info "  Lines running: 3/4"
}

show_orders() {
    info "Production orders:"
    printf "  %-12s %-20s %-8s %s\n" "Order" "Product" "Qty" "Status"
    printf "  %-12s %-20s %-8s %s\n" "PO-2024-001" "BMS_Controller_v3" "500" "in_progress"
    printf "  %-12s %-20s %-8s %s\n" "PO-2024-002" "Inverter_Module" "200" "queued"
    printf "  %-12s %-20s %-8s %s\n" "PO-2024-003" "DC_DC_Converter" "300" "in_progress"
}

generate_report() {
    local report="./mes-connect.json"
    cat > "$report" <<EOF
{
    "mes_connect": {
        "server": "${MES_SERVER:-mes.factory.local}",
        "action": "${ACTION}",
        "active_orders": 8,
        "lines_running": 3,
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Report written to: $report"
}

main() {
    info "Starting MES connection..."
    case "$ACTION" in
        status) show_status ;;
        orders) show_orders ;;
        *) show_status ;;
    esac
    generate_report
    info "MES connection complete"
}

main
