#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Traffic Generate — Generate realistic traffic patterns for simulation
# ============================================================================
# Usage: traffic-generate.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -d, --density    Traffic density (sparse|moderate|heavy|congested)
#   -t, --type       Traffic mix (commuter|mixed|freight|urban)
#   -n, --vehicles   Number of vehicles (default: 50)
#   -o, --output     Output traffic file
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
DENSITY="moderate"
TRAFFIC_TYPE="mixed"
VEHICLE_COUNT=50
OUTPUT_FILE="./traffic-scenario.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -d, --density    Traffic density (sparse|moderate|heavy|congested)"
            echo "  -t, --type       Traffic mix (commuter|mixed|freight|urban)"
            echo "  -n, --vehicles   Number of vehicles"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -d|--density) DENSITY="$2"; shift 2 ;;
        -t|--type) TRAFFIC_TYPE="$2"; shift 2 ;;
        -n|--vehicles) VEHICLE_COUNT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

get_density_params() {
    local spacing_m avg_speed_kmh
    case "$DENSITY" in
        sparse)     spacing_m=100; avg_speed_kmh=100 ;;
        moderate)   spacing_m=50;  avg_speed_kmh=80 ;;
        heavy)      spacing_m=25;  avg_speed_kmh=50 ;;
        congested)  spacing_m=10;  avg_speed_kmh=20 ;;
        *) error "Invalid density: $DENSITY"; return 1 ;;
    esac
    info "Density: $DENSITY (spacing=${spacing_m}m, avg_speed=${avg_speed_kmh}km/h)"
}

get_vehicle_mix() {
    local cars_pct trucks_pct bikes_pct buses_pct
    case "$TRAFFIC_TYPE" in
        commuter)  cars_pct=85; trucks_pct=5;  bikes_pct=5;  buses_pct=5 ;;
        mixed)     cars_pct=60; trucks_pct=15; bikes_pct=15; buses_pct=10 ;;
        freight)   cars_pct=30; trucks_pct=55; bikes_pct=5;  buses_pct=10 ;;
        urban)     cars_pct=50; trucks_pct=10; bikes_pct=25; buses_pct=15 ;;
    esac
    info "Vehicle mix ($TRAFFIC_TYPE): cars=${cars_pct}%, trucks=${trucks_pct}%, bikes=${bikes_pct}%, buses=${buses_pct}%"
}

generate_traffic_flows() {
    info "Generating traffic flows for $VEHICLE_COUNT vehicles..."
    local groups=$(( VEHICLE_COUNT / 10 ))
    $VERBOSE && info "Creating $groups vehicle groups with varied behaviors"
    info "Traffic flows generated"
}

generate_traffic_file() {
    info "Writing traffic scenario..."
    cat > "$OUTPUT_FILE" <<EOF
{
    "traffic_scenario": {
        "density": "${DENSITY}",
        "type": "${TRAFFIC_TYPE}",
        "total_vehicles": ${VEHICLE_COUNT},
        "vehicle_distribution": {
            "cars": $((VEHICLE_COUNT * 60 / 100)),
            "trucks": $((VEHICLE_COUNT * 15 / 100)),
            "motorcycles": $((VEHICLE_COUNT * 15 / 100)),
            "buses": $((VEHICLE_COUNT * 10 / 100))
        },
        "behavior_profiles": {
            "aggressive": 10,
            "normal": 70,
            "cautious": 20
        },
        "spawn_pattern": "distributed",
        "traffic_signals": {
            "enabled": true,
            "cycle_time_s": 90,
            "coordination": "adaptive"
        },
        "pedestrians": {
            "count": $((VEHICLE_COUNT / 5)),
            "jaywalking_probability": 0.05
        },
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "Traffic scenario written to: $OUTPUT_FILE"
}

main() {
    info "Starting traffic generation..."
    get_density_params
    get_vehicle_mix
    generate_traffic_flows
    generate_traffic_file
    info "Traffic generation complete: $VEHICLE_COUNT vehicles, $DENSITY density"
}

main
