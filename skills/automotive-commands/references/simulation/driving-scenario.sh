#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Driving Scenario — Generate and manage driving test scenarios
# ============================================================================
# Usage: driving-scenario.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -s, --scenario   Scenario type (highway|urban|rural|parking)
#   -d, --duration   Scenario duration in seconds (default: 60)
#   -n, --npcs       Number of NPC vehicles (default: 10)
#   -o, --output     Output scenario file
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
SCENARIO="highway"
DURATION_S=60
NPC_COUNT=10
OUTPUT_FILE="./scenario.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -s, --scenario   Scenario type (highway|urban|rural|parking)"
            echo "  -d, --duration   Duration in seconds"
            echo "  -n, --npcs       Number of NPC vehicles"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -s|--scenario) SCENARIO="$2"; shift 2 ;;
        -d|--duration) DURATION_S="$2"; shift 2 ;;
        -n|--npcs) NPC_COUNT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

get_scenario_params() {
    local speed_limit_kmh lanes road_type
    case "$SCENARIO" in
        highway) speed_limit_kmh=130; lanes=3; road_type="motorway" ;;
        urban)   speed_limit_kmh=50; lanes=2; road_type="city_street" ;;
        rural)   speed_limit_kmh=90; lanes=1; road_type="country_road" ;;
        parking) speed_limit_kmh=10; lanes=0; road_type="parking_lot" ;;
        *) error "Invalid scenario: $SCENARIO"; return 1 ;;
    esac
    info "Scenario: $SCENARIO (${speed_limit_kmh}km/h, ${lanes} lanes)"
}

generate_waypoints() {
    info "Generating ego vehicle waypoints..."
    local num_waypoints=$((DURATION_S / 5))
    $VERBOSE && info "Generating $num_waypoints waypoints over ${DURATION_S}s"
    info "Waypoints generated: $num_waypoints points"
}

generate_npc_behaviors() {
    info "Generating NPC vehicle behaviors..."
    local behaviors=("lane_follow" "lane_change" "decelerate" "accelerate" "turn")
    for i in $(seq 1 "$NPC_COUNT"); do
        local behavior=${behaviors[$((i % ${#behaviors[@]}))]}
        $VERBOSE && info "  NPC $i: $behavior"
    done
    info "NPC behaviors assigned for $NPC_COUNT vehicles"
}

generate_scenario_file() {
    info "Writing scenario file..."
    cat > "$OUTPUT_FILE" <<EOF
{
    "scenario": {
        "type": "${SCENARIO}",
        "duration_s": ${DURATION_S},
        "ego_vehicle": {
            "start_position": {"x": 0, "y": 0, "z": 0.5},
            "start_heading_deg": 0,
            "initial_speed_kmh": 0
        },
        "npc_vehicles": ${NPC_COUNT},
        "environment": {
            "road_type": "$(echo "$SCENARIO" | tr '[:lower:]' '[:upper:]')_ROAD",
            "time_of_day": "12:00",
            "weather": "clear"
        },
        "events": [
            {"time_s": 5, "type": "ego_start", "target_speed_kmh": 60},
            {"time_s": 15, "type": "npc_cut_in", "npc_id": 1},
            {"time_s": 30, "type": "traffic_light", "state": "red"},
            {"time_s": 45, "type": "pedestrian_crossing", "position": "ahead_50m"}
        ],
        "pass_criteria": {
            "no_collision": true,
            "max_deceleration_mps2": 6.0,
            "min_ttc_s": 1.5
        },
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "Scenario file written to: $OUTPUT_FILE"
}

main() {
    info "Starting driving scenario generation..."
    get_scenario_params
    generate_waypoints
    generate_npc_behaviors
    generate_scenario_file
    info "Scenario generation complete: $SCENARIO (${DURATION_S}s, ${NPC_COUNT} NPCs)"
}

main
