#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Hybrid Strategy — Configure hybrid powertrain energy management strategy
# ============================================================================
# Usage: hybrid-strategy.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -t, --type       Hybrid type (parallel|series|power-split)
#   -m, --mode       Strategy mode (eco|normal|sport|ev-only)
#   -s, --soc-target Target battery SOC (default: 50)
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
HYBRID_TYPE="power-split"
STRATEGY_MODE="eco"
SOC_TARGET=50

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -t|--type) HYBRID_TYPE="$2"; shift 2 ;;
        -m|--mode) STRATEGY_MODE="$2"; shift 2 ;;
        -s|--soc-target) SOC_TARGET="$2"; shift 2 ;;
        *) shift ;;
    esac
done

configure_strategy() {
    info "Configuring $HYBRID_TYPE hybrid ($STRATEGY_MODE mode)..."
    info "  SOC target: ${SOC_TARGET}%"
    case "$STRATEGY_MODE" in
        eco) info "  ICE: minimum operation, max regen braking" ;;
        normal) info "  ICE: balanced operation" ;;
        sport) info "  ICE + EM: maximum performance" ;;
        ev-only) info "  Pure electric (ICE off)" ;;
    esac
    info "  Regenerative braking: max 0.3g"
}

generate_config() {
    local config="./hybrid-strategy.json"
    cat > "$config" <<EOF
{
    "hybrid_strategy": {
        "type": "${HYBRID_TYPE}",
        "mode": "${STRATEGY_MODE}",
        "soc_target_pct": ${SOC_TARGET},
        "regen_limit_g": 0.3,
        "ice_off_below_kmh": $([ "$STRATEGY_MODE" = "eco" ] && echo 50 || echo 20),
        "ev_range_km": 60,
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Strategy written to: $config"
}

main() {
    info "Starting hybrid strategy configuration..."
    configure_strategy
    generate_config
    info "Hybrid strategy complete"
}

main
