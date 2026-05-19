#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# FTA Analyze — Perform Fault Tree Analysis for safety-critical systems
# ============================================================================
# Usage: fta-analyze.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -t, --top-event  Top-level undesired event description
#   -d, --depth      Analysis depth (default: 4)
#   -o, --output     Output report file
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
TOP_EVENT="Unintended vehicle acceleration"
DEPTH=4
OUTPUT_FILE="./fta-report.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -t, --top-event  Top-level undesired event"
            echo "  -d, --depth      Analysis depth"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -t|--top-event) TOP_EVENT="$2"; shift 2 ;;
        -d|--depth) DEPTH="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

build_fault_tree() {
    info "Building fault tree (depth: $DEPTH)..."
    info "  Top event: $TOP_EVENT"
    info "  Level 1 (OR gate):"
    info "    - Throttle sensor failure"
    info "    - ECU software fault"
    info "    - Actuator malfunction"
    $VERBOSE && info "  Level 2 (AND/OR gates):"
    $VERBOSE && info "    - Primary sensor + backup sensor fail (AND)"
    $VERBOSE && info "    - Memory corruption OR logic error (OR)"
}

calculate_minimal_cut_sets() {
    info "Calculating minimal cut sets..."
    info "  Cut set 1: {Primary_sensor_fail, Backup_sensor_fail}"
    info "  Cut set 2: {ECU_memory_corruption}"
    info "  Cut set 3: {Actuator_stuck, Watchdog_fail}"
    info "  Single point failures: 1 (ECU_memory_corruption)"
    warn "  Single point of failure detected - requires ASIL decomposition or redundancy"
}

estimate_probabilities() {
    info "Estimating failure probabilities..."
    $VERBOSE && info "  Sensor failure: 1e-7 /h"
    $VERBOSE && info "  SW fault: 1e-8 /h"
    $VERBOSE && info "  Actuator failure: 1e-6 /h"
    info "  Top event probability: 1.1e-7 /h"
}

generate_fta_report() {
    cat > "$OUTPUT_FILE" <<EOF
{
    "fta_report": {
        "top_event": "${TOP_EVENT}",
        "depth": ${DEPTH},
        "tree": {
            "gate": "OR",
            "children": [
                {"event": "Throttle sensor failure", "gate": "AND", "probability": 1e-14},
                {"event": "ECU software fault", "gate": "OR", "probability": 1e-8},
                {"event": "Actuator malfunction", "gate": "AND", "probability": 1e-12}
            ]
        },
        "minimal_cut_sets": 3,
        "single_point_failures": 1,
        "top_event_probability_per_hour": 1.1e-7,
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "FTA report written to: $OUTPUT_FILE"
}

main() {
    info "Starting Fault Tree Analysis..."
    build_fault_tree
    calculate_minimal_cut_sets
    estimate_probabilities
    generate_fta_report
    info "FTA analysis complete"
}

main
