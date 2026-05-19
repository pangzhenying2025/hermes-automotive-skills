#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# FMEA Generate — Generate Failure Mode and Effects Analysis templates
# ============================================================================
# Usage: fmea-generate.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -t, --type       FMEA type (design|process|system)
#   -c, --component  Component name
#   -a, --asil       Target ASIL level (A|B|C|D|QM)
#   -o, --output     Output file
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
FMEA_TYPE="design"
COMPONENT="BMS_Controller"
ASIL_LEVEL="C"
OUTPUT_FILE="./fmea-report.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -t, --type       FMEA type (design|process|system)"
            echo "  -c, --component  Component name"
            echo "  -a, --asil       ASIL level (A|B|C|D|QM)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -t|--type) FMEA_TYPE="$2"; shift 2 ;;
        -c|--component) COMPONENT="$2"; shift 2 ;;
        -a|--asil) ASIL_LEVEL="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

generate_failure_modes() {
    info "Generating failure modes for: $COMPONENT"
    local modes=("Incorrect output" "Loss of function" "Unintended activation" "Degraded performance" "Timing failure")
    for mode in "${modes[@]}"; do
        $VERBOSE && info "  Failure mode: $mode"
    done
    info "  ${#modes[@]} failure modes identified"
}

calculate_rpn() {
    info "Calculating Risk Priority Numbers..."
    info "  Severity x Occurrence x Detection = RPN"
    $VERBOSE && info "  Incorrect output: 8 x 3 x 4 = 96"
    $VERBOSE && info "  Loss of function: 9 x 2 x 3 = 54"
    $VERBOSE && info "  Unintended activation: 10 x 2 x 5 = 100"
    info "  Highest RPN: 100 (Unintended activation)"
    if [[ "$ASIL_LEVEL" =~ ^[CD]$ ]]; then
        warn "  ASIL $ASIL_LEVEL: RPN > 80 requires mitigation"
    fi
}

generate_fmea_report() {
    info "Generating FMEA report..."
    cat > "$OUTPUT_FILE" <<EOF
{
    "fmea": {
        "type": "${FMEA_TYPE}",
        "component": "${COMPONENT}",
        "asil_level": "${ASIL_LEVEL}",
        "standard": "ISO 26262 / AIAG-VDA FMEA",
        "failure_modes": [
            {"id": "FM-001", "mode": "Incorrect output", "effect": "Wrong control signal", "cause": "Software bug", "severity": 8, "occurrence": 3, "detection": 4, "rpn": 96, "action": "Code review + unit test"},
            {"id": "FM-002", "mode": "Loss of function", "effect": "System shutdown", "cause": "HW failure", "severity": 9, "occurrence": 2, "detection": 3, "rpn": 54, "action": "Redundancy"},
            {"id": "FM-003", "mode": "Unintended activation", "effect": "Unexpected behavior", "cause": "EMI interference", "severity": 10, "occurrence": 2, "detection": 5, "rpn": 100, "action": "EMC shielding + monitoring"},
            {"id": "FM-004", "mode": "Degraded performance", "effect": "Reduced accuracy", "cause": "Sensor drift", "severity": 5, "occurrence": 4, "detection": 3, "rpn": 60, "action": "Calibration check"},
            {"id": "FM-005", "mode": "Timing failure", "effect": "Late response", "cause": "CPU overload", "severity": 7, "occurrence": 3, "detection": 4, "rpn": 84, "action": "WCET analysis"}
        ],
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "FMEA report written to: $OUTPUT_FILE"
}

main() {
    info "Starting FMEA generation ($FMEA_TYPE for $COMPONENT, ASIL $ASIL_LEVEL)..."
    generate_failure_modes
    calculate_rpn
    generate_fmea_report
    info "FMEA generation complete"
}

main
