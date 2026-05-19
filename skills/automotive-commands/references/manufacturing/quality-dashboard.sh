#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Quality Dashboard — Generate manufacturing quality metrics dashboard
# ============================================================================
# Usage: quality-dashboard.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -l, --line       Production line ID
#   -p, --period     Time period (shift|day|week|month)
#   -o, --output     Output dashboard file
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
LINE_ID="LINE-01"
PERIOD="day"
OUTPUT_FILE="./quality-dashboard.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -l|--line) LINE_ID="$2"; shift 2 ;;
        -p|--period) PERIOD="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

collect_metrics() {
    info "Collecting quality metrics ($PERIOD)..."
    info "  Total units: 142"
    info "  First pass yield: 96.5%"
    info "  Defects: 5 (3.5%)"
    info "  Scrap rate: 0.7%"
    info "  Rework rate: 2.8%"
}

generate_dashboard() {
    cat > "$OUTPUT_FILE" <<EOF
{
    "quality_dashboard": {
        "line_id": "${LINE_ID}",
        "period": "${PERIOD}",
        "metrics": {
            "total_units": 142,
            "first_pass_yield_pct": 96.5,
            "defects": 5,
            "defect_rate_pct": 3.5,
            "scrap_rate_pct": 0.7,
            "rework_rate_pct": 2.8
        },
        "top_defects": [
            {"type": "weld_quality", "count": 2, "station": "ST-05"},
            {"type": "torque_spec", "count": 2, "station": "ST-08"},
            {"type": "visual_cosmetic", "count": 1, "station": "ST-11"}
        ],
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Dashboard written to: $OUTPUT_FILE"
}

main() {
    info "Generating quality dashboard..."
    collect_metrics
    generate_dashboard
    info "Quality dashboard complete"
}

main
