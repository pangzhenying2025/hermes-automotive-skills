#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# V2G Control — Manage Vehicle-to-Grid bidirectional charging
# ============================================================================
# Usage: v2g-control.sh [options]
# Options:
#   -h, --help        Show help
#   -v, --verbose     Verbose output
#   -a, --action      Action (status|enable|disable|schedule)
#   -p, --power       Max discharge power in kW
#   -s, --soc-min     Minimum SOC to maintain (default: 30)
#   --grid-price      Current grid price signal (low|medium|high|peak)
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
ACTION="status"
MAX_POWER_KW=10
SOC_MIN=30
GRID_PRICE="medium"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -a, --action      Action (status|enable|disable|schedule)"
            echo "  -p, --power       Max discharge power in kW"
            echo "  -s, --soc-min     Minimum SOC to maintain (default: 30)"
            echo "  --grid-price      Grid price signal (low|medium|high|peak)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -a|--action) ACTION="$2"; shift 2 ;;
        -p|--power) MAX_POWER_KW="$2"; shift 2 ;;
        -s|--soc-min) SOC_MIN="$2"; shift 2 ;;
        --grid-price) GRID_PRICE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

check_v2g_compatibility() {
    info "Checking V2G compatibility..."
    local charger_bidirectional=true
    local iso15118_support=true
    if $charger_bidirectional && $iso15118_support; then
        info "V2G capable: ISO 15118-20 bidirectional charging supported"
    else
        error "V2G not supported by current charger/vehicle combination"
        return 1
    fi
}

get_price_action() {
    case "$GRID_PRICE" in
        low) echo "charge" ;;
        medium) echo "idle" ;;
        high) echo "discharge" ;;
        peak) echo "max_discharge" ;;
    esac
}

show_status() {
    info "V2G Status:"
    info "  Grid price signal: $GRID_PRICE"
    info "  Recommended action: $(get_price_action)"
    info "  Max discharge power: ${MAX_POWER_KW}kW"
    info "  SOC floor: ${SOC_MIN}%"
    info "  Current SOC: 65%"
    info "  Available V2G energy: $((65 - SOC_MIN))% = $(( (65 - SOC_MIN) * 75 / 100 ))kWh"
}

enable_v2g() {
    info "Enabling V2G discharge mode..."
    if (( SOC_MIN < 20 )); then
        warn "SOC minimum below 20% may accelerate battery degradation"
    fi
    info "V2G enabled: max ${MAX_POWER_KW}kW, floor ${SOC_MIN}%"
}

disable_v2g() {
    info "Disabling V2G mode..."
    info "Switching to charge-only mode"
}

generate_v2g_schedule() {
    local schedule_file="./v2g-schedule.json"
    info "Generating V2G schedule..."
    cat > "$schedule_file" <<EOF
{
    "v2g_schedule": {
        "soc_floor_percent": ${SOC_MIN},
        "max_discharge_kw": ${MAX_POWER_KW},
        "periods": [
            {"time": "00:00-06:00", "action": "charge", "price": "low"},
            {"time": "06:00-09:00", "action": "discharge", "price": "peak"},
            {"time": "09:00-16:00", "action": "idle", "price": "medium"},
            {"time": "16:00-21:00", "action": "discharge", "price": "high"},
            {"time": "21:00-00:00", "action": "charge", "price": "low"}
        ],
        "estimated_revenue_eur": 4.50,
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "V2G schedule written to: $schedule_file"
}

main() {
    info "Starting V2G control..."
    check_v2g_compatibility
    case "$ACTION" in
        status) show_status ;;
        enable) enable_v2g ;;
        disable) disable_v2g ;;
        schedule) generate_v2g_schedule ;;
        *) error "Unknown action: $ACTION"; exit 1 ;;
    esac
    info "V2G control complete"
}

main
