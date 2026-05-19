#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Suspension Tune — Tune adaptive suspension parameters
# ============================================================================
# Usage: suspension-tune.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -m, --mode       Suspension mode (comfort|normal|sport|track)
#   -t, --type       System type (passive|semi-active|active|air)
#   -o, --output     Output tuning parameters
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
SUSP_MODE="comfort"
SYSTEM_TYPE="semi-active"
OUTPUT_FILE="./suspension-tune.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -m|--mode) SUSP_MODE="$2"; shift 2 ;;
        -t|--type) SYSTEM_TYPE="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

set_damping_params() {
    info "Setting damping parameters ($SUSP_MODE mode)..."
    local compression rebound
    case "$SUSP_MODE" in
        comfort) compression=30; rebound=40 ;;
        normal) compression=50; rebound=60 ;;
        sport) compression=70; rebound=80 ;;
        track) compression=90; rebound=95 ;;
    esac
    info "  Compression: ${compression}% of max"
    info "  Rebound: ${rebound}% of max"
    info "  Roll stiffness: $([ "$SUSP_MODE" = "sport" ] && echo 'high' || echo 'medium')"
}

generate_tune_config() {
    cat > "$OUTPUT_FILE" <<EOF
{
    "suspension_tune": {
        "mode": "${SUSP_MODE}",
        "system_type": "${SYSTEM_TYPE}",
        "damping": {"compression_pct": $([ "$SUSP_MODE" = "comfort" ] && echo 30 || echo 70), "rebound_pct": $([ "$SUSP_MODE" = "comfort" ] && echo 40 || echo 80)},
        "ride_height_mm": $([ "$SUSP_MODE" = "track" ] && echo -15 || echo 0),
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Tune config written to: $OUTPUT_FILE"
}

main() {
    info "Starting suspension tuning..."
    set_damping_params
    generate_tune_config
    info "Suspension tuning complete"
}

main
