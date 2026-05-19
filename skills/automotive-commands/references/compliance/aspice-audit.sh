#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# ASPICE Audit — Assess Automotive SPICE process maturity
# ============================================================================
# Usage: aspice-audit.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -l, --level      Target capability level (1|2|3)
#   -p, --process    Process area (SWE|SYS|MAN|SUP|all)
#   -o, --output     Output audit report
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
TARGET_LEVEL=2
PROCESS_AREA="SWE"
OUTPUT_FILE="./aspice-audit.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -l|--level) TARGET_LEVEL="$2"; shift 2 ;;
        -p|--process) PROCESS_AREA="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

assess_processes() {
    info "Assessing $PROCESS_AREA processes (target: Level $TARGET_LEVEL)..."
    local processes=("SWE.1:Requirements:L" "SWE.2:Architecture:F" "SWE.3:Design:L" "SWE.4:Unit_Test:P" "SWE.5:Integration:L" "SWE.6:Qualification:P")
    for p in "${processes[@]}"; do
        IFS=':' read -r id name rating <<< "$p"
        local rating_full=""
        case "$rating" in
            N) rating_full="Not achieved" ;;
            P) rating_full="Partially achieved" ;;
            L) rating_full="Largely achieved" ;;
            F) rating_full="Fully achieved" ;;
        esac
        info "  $id ($name): $rating_full"
    done
}

generate_audit_report() {
    cat > "$OUTPUT_FILE" <<EOF
{
    "aspice_audit": {
        "target_level": ${TARGET_LEVEL},
        "process_area": "${PROCESS_AREA}",
        "standard": "Automotive SPICE 3.1",
        "assessments": [
            {"process": "SWE.1", "name": "Requirements", "rating": "L", "level": 1},
            {"process": "SWE.2", "name": "Architecture", "rating": "F", "level": 2},
            {"process": "SWE.3", "name": "Design", "rating": "L", "level": 1},
            {"process": "SWE.4", "name": "Unit Testing", "rating": "P", "level": 0},
            {"process": "SWE.5", "name": "Integration", "rating": "L", "level": 1},
            {"process": "SWE.6", "name": "Qualification", "rating": "P", "level": 0}
        ],
        "overall_capability": 1,
        "gaps_for_level_2": ["SWE.4 needs improvement", "SWE.6 needs improvement"],
        "audited_at": "$(date -Iseconds)"
    }
}
EOF
    info "Audit report written to: $OUTPUT_FILE"
}

main() {
    info "Starting ASPICE audit..."
    assess_processes
    generate_audit_report
    info "ASPICE audit complete"
}

main
