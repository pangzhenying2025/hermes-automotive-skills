#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# CARLA Launch — Launch and configure CARLA autonomous driving simulator
# ============================================================================
# Usage: carla-launch.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -m, --map        Map name (Town01-Town10)
#   -w, --weather    Weather preset (clear|rain|fog|night)
#   -p, --port       Server port (default: 2000)
#   -q, --quality    Rendering quality (low|medium|high|epic)
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
MAP="Town03"
WEATHER="clear"
PORT=2000
QUALITY="high"
CARLA_ROOT="${CARLA_ROOT:-/opt/carla}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -m, --map        Map name (Town01-Town10)"
            echo "  -w, --weather    Weather preset (clear|rain|fog|night)"
            echo "  -p, --port       Server port (default: 2000)"
            echo "  -q, --quality    Rendering quality (low|medium|high|epic)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -m|--map) MAP="$2"; shift 2 ;;
        -w|--weather) WEATHER="$2"; shift 2 ;;
        -p|--port) PORT="$2"; shift 2 ;;
        -q|--quality) QUALITY="$2"; shift 2 ;;
        *) shift ;;
    esac
done

check_prerequisites() {
    info "Checking CARLA prerequisites..."
    if [[ -d "$CARLA_ROOT" ]]; then
        info "CARLA installation found at: $CARLA_ROOT"
    else
        warn "CARLA not found at $CARLA_ROOT (simulation mode)"
    fi
    if command -v python3 &>/dev/null; then
        info "Python3 available: $(python3 --version 2>&1)"
    else
        warn "Python3 not found, CARLA Python API unavailable"
    fi
}

check_gpu() {
    info "Checking GPU availability..."
    if command -v nvidia-smi &>/dev/null; then
        local gpu_info
        gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "unknown")
        info "GPU detected: $gpu_info"
    else
        warn "No NVIDIA GPU detected, software rendering may be used"
    fi
}

generate_launch_config() {
    local config_file="./carla-launch.json"
    info "Generating CARLA launch configuration..."

    local weather_params=""
    case "$WEATHER" in
        clear)  weather_params='"sun_altitude": 60, "cloudiness": 10, "precipitation": 0' ;;
        rain)   weather_params='"sun_altitude": 45, "cloudiness": 80, "precipitation": 80' ;;
        fog)    weather_params='"sun_altitude": 30, "cloudiness": 90, "fog_density": 70' ;;
        night)  weather_params='"sun_altitude": -10, "cloudiness": 20, "precipitation": 0' ;;
    esac

    cat > "$config_file" <<EOF
{
    "carla_config": {
        "server": {"host": "localhost", "port": ${PORT}},
        "map": "${MAP}",
        "quality": "${QUALITY}",
        "weather": {${weather_params}},
        "rendering": {
            "resolution": {"width": 1920, "height": 1080},
            "fps_target": 30,
            "no_rendering": false
        },
        "traffic_manager": {"port": $((PORT + 6000)), "hybrid_mode": true},
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "Launch config written to: $config_file"
}

launch_server() {
    info "CARLA server launch command prepared:"
    info "  ${CARLA_ROOT}/CarlaUE4.sh -carla-rpc-port=${PORT} -quality-level=${QUALITY}"
    $VERBOSE && info "  Map: $MAP, Weather: $WEATHER, Port: $PORT"
    info "Server launch configuration ready (dry run - not executing)"
}

main() {
    info "Starting CARLA simulator setup..."
    check_prerequisites
    check_gpu
    generate_launch_config
    launch_server
    info "CARLA launch preparation complete"
}

main
