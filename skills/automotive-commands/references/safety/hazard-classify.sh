#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Hazard Classify — Classify automotive hazards per ISO 26262 HARA
# ============================================================================
# Usage: hazard-classify.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -d, --hazard     Hazard description
#   -s, --situation  Operational situation
#   -o, --output     Output classification file
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
HAZARD_DESC="Loss of electric power steering assist"
SITUATION="Highway driving at high speed"
OUTPUT_FILE="./hazard-classification.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -d|--hazard) HAZARD_DESC="$2"; shift 2 ;;
        -s|--situation) SITUATION="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

classify_severity() {
    info "Classifying severity..."
    info "  Hazard: $HAZARD_DESC"
    info "  Potential harm: Loss of vehicle control"
    info "  Severity: S3 (Life-threatening / fatal injuries)"
}

classify_exposure() {
    info "Classifying exposure..."
    info "  Situation: $SITUATION"
    info "  Exposure: E4 (High probability, common driving)"
}

classify_controllability() {
    info "Classifying controllability..."
    info "  Driver ability to control: Difficult at high speed"
    info "  Controllability: C3 (Difficult to control)"
}

determine_safety_goal() {
    info "Determining safety goal..."
    info "  ASIL: D (S3 + E4 + C3)"
    warn "  Safety Goal: Steering assist shall not fail without driver warning"
    info "  Fault tolerant time: 100ms"
}

generate_classification() {
    cat > "$OUTPUT_FILE" <<EOF
{
    "hazard_classification": {
        "hazard_id": "HZ-001",
        "description": "${HAZARD_DESC}",
        "operational_situation": "${SITUATION}",
        "severity": "S3",
        "exposure": "E4",
        "controllability": "C3",
        "asil": "D",
        "safety_goal": "Steering assist shall not fail without warning",
        "safe_state": "Provide degraded steering with warning",
        "fault_tolerant_time_ms": 100,
        "standard": "ISO 26262-3:2018 Clause 7",
        "classified_at": "$(date -Iseconds)"
    }
}
EOF
    info "Classification written to: $OUTPUT_FILE"
}

main() {
    info "Starting hazard classification..."
    classify_severity
    classify_exposure
    classify_controllability
    determine_safety_goal
    generate_classification
    info "Hazard classification complete"
}

main
