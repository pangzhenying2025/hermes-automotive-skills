#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Ambient Lighting — Configure vehicle interior ambient lighting system
# ============================================================================
# Usage: ambient-lighting.sh [options]
# Options:
#   -h, --help      Show help
#   -v, --verbose   Verbose output
#   -c, --color     Base color in hex (e.g., FF6B35)
#   -m, --mode      Lighting mode (static|breathing|dynamic|music-sync)
#   -i, --intensity Intensity level (0-100)
#   -z, --zone      Zone (all|dashboard|doors|footwell|ceiling)
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
COLOR="4A90D9"
MODE="static"
INTENSITY=60
LIGHT_ZONE="all"
OUTPUT_DIR="./lighting-config"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -c, --color     Base color in hex (e.g., FF6B35)"
            echo "  -m, --mode      Lighting mode (static|breathing|dynamic|music-sync)"
            echo "  -i, --intensity Intensity level (0-100)"
            echo "  -z, --zone      Zone (all|dashboard|doors|footwell|ceiling)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -c|--color) COLOR="$2"; shift 2 ;;
        -m|--mode) MODE="$2"; shift 2 ;;
        -i|--intensity) INTENSITY="$2"; shift 2 ;;
        -z|--zone) LIGHT_ZONE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

validate_color() {
    if [[ ! "$COLOR" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        error "Invalid hex color: $COLOR (expected 6 hex digits)"
        return 1
    fi
    local r=$((16#${COLOR:0:2}))
    local g=$((16#${COLOR:2:2}))
    local b=$((16#${COLOR:4:2}))
    info "Color validated: #$COLOR (R=$r G=$g B=$b)"
}

validate_mode() {
    case "$MODE" in
        static|breathing|dynamic|music-sync) info "Lighting mode: $MODE" ;;
        *) error "Invalid mode: $MODE"; return 1 ;;
    esac
}

generate_lighting_config() {
    info "Generating ambient lighting configuration..."
    mkdir -p "$OUTPUT_DIR"
    local config_file="$OUTPUT_DIR/ambient_${LIGHT_ZONE}.json"

    local transition_ms=0
    case "$MODE" in
        static) transition_ms=0 ;;
        breathing) transition_ms=2000 ;;
        dynamic) transition_ms=500 ;;
        music-sync) transition_ms=100 ;;
    esac

    cat > "$config_file" <<EOF
{
    "ambient_lighting": {
        "zone": "${LIGHT_ZONE}",
        "base_color": "#${COLOR}",
        "mode": "${MODE}",
        "intensity_percent": ${INTENSITY},
        "transition_ms": ${transition_ms},
        "led_strips": {
            "dashboard": $([ "$LIGHT_ZONE" = "all" ] || [ "$LIGHT_ZONE" = "dashboard" ] && echo "true" || echo "false"),
            "doors": $([ "$LIGHT_ZONE" = "all" ] || [ "$LIGHT_ZONE" = "doors" ] && echo "true" || echo "false"),
            "footwell": $([ "$LIGHT_ZONE" = "all" ] || [ "$LIGHT_ZONE" = "footwell" ] && echo "true" || echo "false"),
            "ceiling": $([ "$LIGHT_ZONE" = "all" ] || [ "$LIGHT_ZONE" = "ceiling" ] && echo "true" || echo "false")
        },
        "auto_dimming": true,
        "night_mode_reduction_percent": 30,
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "Lighting config written to: $config_file"
}

simulate_lighting_preview() {
    info "Simulating lighting preview..."
    $VERBOSE && info "Mode: $MODE at $INTENSITY% intensity with color #$COLOR"
    info "Preview simulation complete"
}

main() {
    info "Starting ambient lighting configuration..."
    validate_color
    validate_mode
    generate_lighting_config
    simulate_lighting_preview
    info "Ambient lighting setup complete for zone: $LIGHT_ZONE"
}

main
