#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Charging Optimize — Optimize EV charging strategy for battery longevity
# ============================================================================
# Usage: charging-optimize.sh [options]
# Options:
#   -h, --help        Show help
#   -v, --verbose     Verbose output
#   -s, --soc-target  Target SOC percentage (default: 80)
#   -m, --mode        Charging mode (fast|balanced|longevity)
#   -t, --departure   Departure time (HH:MM)
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
SOC_TARGET=80
CHARGE_MODE="balanced"
DEPARTURE_TIME=""
CURRENT_SOC=35

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -s, --soc-target  Target SOC percentage (default: 80)"
            echo "  -m, --mode        Charging mode (fast|balanced|longevity)"
            echo "  -t, --departure   Departure time (HH:MM)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -s|--soc-target) SOC_TARGET="$2"; shift 2 ;;
        -m|--mode) CHARGE_MODE="$2"; shift 2 ;;
        -t|--departure) DEPARTURE_TIME="$2"; shift 2 ;;
        *) shift ;;
    esac
done

calculate_charge_curve() {
    info "Calculating optimal charge curve..."
    local max_power_kw
    case "$CHARGE_MODE" in
        fast) max_power_kw=150 ;;
        balanced) max_power_kw=50 ;;
        longevity) max_power_kw=22 ;;
        *) error "Invalid charge mode: $CHARGE_MODE"; return 1 ;;
    esac
    info "Max charging power: ${max_power_kw}kW (mode: $CHARGE_MODE)"

    local energy_needed_kwh=$(( (SOC_TARGET - CURRENT_SOC) * 75 / 100 ))
    local est_time_min=$(( energy_needed_kwh * 60 / max_power_kw ))
    info "Energy needed: ${energy_needed_kwh}kWh, Est. time: ${est_time_min} minutes"
}

check_battery_preconditioning() {
    info "Checking battery preconditioning requirements..."
    local battery_temp_c=18
    local optimal_min_c=20
    local optimal_max_c=35
    if (( battery_temp_c < optimal_min_c )); then
        warn "Battery below optimal temperature (${battery_temp_c}C < ${optimal_min_c}C)"
        info "Preconditioning recommended before fast charging"
    else
        info "Battery temperature optimal for charging: ${battery_temp_c}C"
    fi
}

schedule_charging() {
    if [[ -n "$DEPARTURE_TIME" ]]; then
        info "Scheduling charge to complete by $DEPARTURE_TIME"
        info "Delayed start recommended to reduce battery stress"
    else
        info "Immediate charging start (no departure time set)"
    fi
}

generate_charge_plan() {
    local plan_file="./charge-plan.json"
    info "Generating charge plan..."
    cat > "$plan_file" <<EOF
{
    "charge_plan": {
        "current_soc_percent": ${CURRENT_SOC},
        "target_soc_percent": ${SOC_TARGET},
        "mode": "${CHARGE_MODE}",
        "departure_time": "${DEPARTURE_TIME:-immediate}",
        "phases": [
            {"soc_range": "35-60", "power_kw": $([ "$CHARGE_MODE" = "fast" ] && echo 150 || echo 50), "duration_min": 15},
            {"soc_range": "60-80", "power_kw": $([ "$CHARGE_MODE" = "fast" ] && echo 80 || echo 40), "duration_min": 20}
        ],
        "preconditioning": true,
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "Charge plan written to: $plan_file"
}

main() {
    info "Starting charging optimization..."
    info "Current SOC: ${CURRENT_SOC}%, Target: ${SOC_TARGET}%"
    check_battery_preconditioning
    calculate_charge_curve
    schedule_charging
    generate_charge_plan
    info "Charging optimization complete"
}

main
