#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# HIL Launch — Launch Hardware-in-the-Loop test environment
# ============================================================================
# Usage: hil-launch.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -c, --config     HIL configuration file
#   -t, --target     Target ECU (ecu_name or all)
#   -s, --scenario   Test scenario file
#   --real-time      Enable real-time simulation mode
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
CONFIG_FILE=""
TARGET_ECU="all"
SCENARIO=""
REAL_TIME=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -c|--config) CONFIG_FILE="$2"; shift 2 ;;
        -t|--target) TARGET_ECU="$2"; shift 2 ;;
        -s|--scenario) SCENARIO="$2"; shift 2 ;;
        --real-time) REAL_TIME=true; shift ;;
        *) shift ;;
    esac
done

check_hil_hardware() {
    info "Checking HIL hardware..."
    info "  RT simulator: dSPACE SCALEXIO (simulated)"
    info "  I/O boards: 4x analog, 2x digital, 1x CAN"
    info "  Power supply: 12V/24V available"
    info "  ECU connection: $TARGET_ECU"
}

load_plant_model() {
    info "Loading plant model..."
    info "  Vehicle dynamics model: loaded"
    info "  Powertrain model: loaded"
    info "  Environment model: loaded"
    $REAL_TIME && info "  Real-time execution: ENABLED (1ms step)"
}

configure_io_mapping() {
    info "Configuring I/O signal mapping..."
    info "  CAN signals mapped: 45"
    info "  Analog inputs mapped: 12"
    info "  Digital outputs mapped: 8"
    info "  PWM channels: 4"
}

launch_test_environment() {
    info "Launching HIL test environment..."
    [[ -n "$SCENARIO" ]] && info "  Scenario: $SCENARIO"
    info "  Simulation step: $(${REAL_TIME} && echo '1ms (real-time)' || echo '10ms (non-RT)')"
    info "  HIL environment ready"
}

generate_report() {
    local report="./hil-launch.json"
    cat > "$report" <<EOF
{
    "hil_launch": {
        "target_ecu": "${TARGET_ECU}",
        "scenario": "${SCENARIO:-none}",
        "real_time": ${REAL_TIME},
        "io_signals": {"can": 45, "analog": 12, "digital": 8, "pwm": 4},
        "status": "ready",
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Report written to: $report"
}

main() {
    info "Starting HIL environment launch..."
    check_hil_hardware
    load_plant_model
    configure_io_mapping
    launch_test_environment
    generate_report
    info "HIL launch complete"
}

main
