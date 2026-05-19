#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Range Estimate — Calculate EV range based on driving conditions
# ============================================================================
# Usage: range-estimate.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -s, --soc        Current SOC percentage
#   -c, --capacity   Battery capacity in kWh
#   -w, --weather    Weather condition (warm|mild|cold|freezing)
#   -d, --driving    Driving style (eco|normal|sport)
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
CURRENT_SOC=75
BATTERY_CAPACITY_KWH=75
WEATHER="mild"
DRIVING_STYLE="normal"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -s, --soc        Current SOC percentage"
            echo "  -c, --capacity   Battery capacity in kWh"
            echo "  -w, --weather    Weather (warm|mild|cold|freezing)"
            echo "  -d, --driving    Driving style (eco|normal|sport)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -s|--soc) CURRENT_SOC="$2"; shift 2 ;;
        -c|--capacity) BATTERY_CAPACITY_KWH="$2"; shift 2 ;;
        -w|--weather) WEATHER="$2"; shift 2 ;;
        -d|--driving) DRIVING_STYLE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

get_weather_factor() {
    case "$WEATHER" in
        warm) echo 95 ;;
        mild) echo 100 ;;
        cold) echo 80 ;;
        freezing) echo 65 ;;
        *) error "Invalid weather: $WEATHER"; echo 100 ;;
    esac
}

get_driving_factor() {
    case "$DRIVING_STYLE" in
        eco) echo 115 ;;
        normal) echo 100 ;;
        sport) echo 75 ;;
        *) error "Invalid driving style: $DRIVING_STYLE"; echo 100 ;;
    esac
}

calculate_range() {
    info "Calculating range estimate..."
    local available_kwh=$((BATTERY_CAPACITY_KWH * CURRENT_SOC / 100))
    local base_consumption_wh_per_km=160
    local weather_factor
    weather_factor=$(get_weather_factor)
    local driving_factor
    driving_factor=$(get_driving_factor)

    local adjusted_consumption=$((base_consumption_wh_per_km * 100 / weather_factor * 100 / driving_factor))
    local range_km=$((available_kwh * 1000 / adjusted_consumption))

    $VERBOSE && info "Available energy: ${available_kwh}kWh"
    $VERBOSE && info "Base consumption: ${base_consumption_wh_per_km}Wh/km"
    $VERBOSE && info "Weather factor: ${weather_factor}%, Driving factor: ${driving_factor}%"
    $VERBOSE && info "Adjusted consumption: ${adjusted_consumption}Wh/km"

    info "Estimated range: ${range_km}km"
    echo "$range_km"
}

generate_range_report() {
    local range_km="$1"
    local report_file="./range-estimate.json"
    info "Generating range report..."

    cat > "$report_file" <<EOF
{
    "range_estimate": {
        "current_soc_percent": ${CURRENT_SOC},
        "battery_capacity_kwh": ${BATTERY_CAPACITY_KWH},
        "weather": "${WEATHER}",
        "driving_style": "${DRIVING_STYLE}",
        "estimated_range_km": ${range_km},
        "confidence_interval": {
            "low_km": $((range_km * 85 / 100)),
            "high_km": $((range_km * 115 / 100))
        },
        "reserve_range_km": $((range_km * 5 / 100)),
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Report written to: $report_file"
}

check_range_warnings() {
    local range_km="$1"
    if (( range_km < 50 )); then
        warn "Low range warning: ${range_km}km remaining"
        warn "Consider finding a charging station"
    elif (( range_km < 100 )); then
        info "Range advisory: ${range_km}km - plan charging stop for longer trips"
    fi
}

main() {
    info "Starting range estimation..."
    local range_km
    range_km=$(calculate_range | tail -1)
    check_range_warnings "$range_km"
    generate_range_report "$range_km"
    info "Range estimation complete"
}

main
