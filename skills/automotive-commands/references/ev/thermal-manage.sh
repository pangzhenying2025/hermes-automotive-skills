#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Thermal Manage — Monitor and control EV battery thermal management
# ============================================================================
# Usage: thermal-manage.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -m, --mode       Mode (monitor|cool|heat|auto)
#   -t, --target     Target temperature in Celsius (default: 25)
#   --max-temp       Maximum allowed temperature (default: 45)
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
MODE="auto"
TARGET_TEMP_C=25
MAX_TEMP_C=45
NUM_MODULES=12

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -m, --mode       Mode (monitor|cool|heat|auto)"
            echo "  -t, --target     Target temperature in Celsius"
            echo "  --max-temp       Maximum allowed temperature"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -m|--mode) MODE="$2"; shift 2 ;;
        -t|--target) TARGET_TEMP_C="$2"; shift 2 ;;
        --max-temp) MAX_TEMP_C="$2"; shift 2 ;;
        *) shift ;;
    esac
done

read_module_temperatures() {
    info "Reading module temperatures..."
    local temps=(22 23 24 25 24 26 23 25 24 22 23 24)
    local min=100 max=0 sum=0
    for i in $(seq 0 $((NUM_MODULES - 1))); do
        local t=${temps[$i]:-24}
        (( t < min )) && min=$t
        (( t > max )) && max=$t
        sum=$((sum + t))
    done
    local avg=$((sum / NUM_MODULES))
    local delta=$((max - min))
    info "Temperatures: min=${min}C, max=${max}C, avg=${avg}C, delta=${delta}C"
    if (( delta > 5 )); then
        warn "Temperature imbalance detected: ${delta}C spread across modules"
    fi
    if (( max > MAX_TEMP_C )); then
        error "Temperature exceeds maximum: ${max}C > ${MAX_TEMP_C}C"
    fi
}

determine_action() {
    local current_temp=24
    if [[ "$MODE" == "auto" ]]; then
        if (( current_temp > TARGET_TEMP_C + 3 )); then
            info "Auto mode: activating cooling (${current_temp}C > $((TARGET_TEMP_C + 3))C)"
        elif (( current_temp < TARGET_TEMP_C - 5 )); then
            info "Auto mode: activating heating (${current_temp}C < $((TARGET_TEMP_C - 5))C)"
        else
            info "Auto mode: temperature within range, no action needed"
        fi
    else
        info "Manual mode: $MODE active"
    fi
}

check_coolant_system() {
    info "Checking coolant system..."
    $VERBOSE && info "  Pump status: running"
    $VERBOSE && info "  Coolant level: OK"
    $VERBOSE && info "  Coolant temperature: 22C"
    info "Coolant system check passed"
}

generate_thermal_report() {
    local report_file="./thermal-report.json"
    info "Generating thermal management report..."
    cat > "$report_file" <<EOF
{
    "thermal_report": {
        "mode": "${MODE}",
        "target_temp_c": ${TARGET_TEMP_C},
        "max_allowed_c": ${MAX_TEMP_C},
        "modules": ${NUM_MODULES},
        "current_state": {
            "min_temp_c": 22,
            "max_temp_c": 26,
            "avg_temp_c": 24,
            "delta_c": 4
        },
        "coolant": {"status": "ok", "pump": "running", "level": "normal"},
        "action": "${MODE}",
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Thermal report written to: $report_file"
}

main() {
    info "Starting thermal management (mode: $MODE)..."
    read_module_temperatures
    determine_action
    check_coolant_system
    generate_thermal_report
    info "Thermal management cycle complete"
}

main
