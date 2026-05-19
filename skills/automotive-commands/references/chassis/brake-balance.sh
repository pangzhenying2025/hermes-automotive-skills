#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Brake Balance — Configure front/rear brake balance distribution
# ============================================================================
# Usage: brake-balance.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -f, --front      Front brake percentage (default: 65)
#   -m, --mode       Brake mode (normal|regen-blend|sport)
#   --abs-tune       ABS tuning (comfort|sport|off-road)
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
FRONT_PCT=65
BRAKE_MODE="normal"
ABS_TUNE="comfort"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -f|--front) FRONT_PCT="$2"; shift 2 ;;
        -m|--mode) BRAKE_MODE="$2"; shift 2 ;;
        --abs-tune) ABS_TUNE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

configure_balance() {
    local rear_pct=$((100 - FRONT_PCT))
    info "Configuring brake balance..."
    info "  Front: ${FRONT_PCT}%, Rear: ${rear_pct}%"
    info "  Mode: $BRAKE_MODE"
    if [[ "$BRAKE_MODE" == "regen-blend" ]]; then
        info "  Regen braking: 60% of rear braking below 0.2g"
    fi
    info "  ABS tuning: $ABS_TUNE"
}

generate_config() {
    local config="./brake-balance.json"
    cat > "$config" <<EOF
{
    "brake_balance": {
        "front_pct": ${FRONT_PCT},
        "rear_pct": $((100 - FRONT_PCT)),
        "mode": "${BRAKE_MODE}",
        "abs_tune": "${ABS_TUNE}",
        "regen_blend": $([ "$BRAKE_MODE" = "regen-blend" ] && echo true || echo false),
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Config written to: $config"
}

main() {
    info "Starting brake balance configuration..."
    configure_balance
    generate_config
    info "Brake balance complete"
}

main
