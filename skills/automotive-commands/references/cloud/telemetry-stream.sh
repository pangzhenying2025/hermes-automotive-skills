#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Telemetry Stream — Configure vehicle telemetry data streaming
# ============================================================================
# Usage: telemetry-stream.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -e, --endpoint   Cloud endpoint URL
#   -p, --protocol   Streaming protocol (mqtt|amqp|kafka|http)
#   -r, --rate       Telemetry rate in Hz (default: 1)
#   -s, --signals    Signal list (comma-separated)
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
ENDPOINT=""
PROTOCOL="mqtt"
RATE_HZ=1
SIGNALS="soc,voltage,current,temperature,speed,location"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -e|--endpoint) ENDPOINT="$2"; shift 2 ;;
        -p|--protocol) PROTOCOL="$2"; shift 2 ;;
        -r|--rate) RATE_HZ="$2"; shift 2 ;;
        -s|--signals) SIGNALS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

configure_stream() {
    info "Configuring telemetry stream..."
    info "  Protocol: $PROTOCOL"
    info "  Endpoint: ${ENDPOINT:-auto-detect}"
    info "  Rate: ${RATE_HZ}Hz"
    IFS=',' read -ra SIG_LIST <<< "$SIGNALS"
    info "  Signals: ${#SIG_LIST[@]}"
    for sig in "${SIG_LIST[@]}"; do
        $VERBOSE && info "    - $sig"
    done
}

estimate_bandwidth() {
    IFS=',' read -ra SIG_LIST <<< "$SIGNALS"
    local bytes_per_msg=$((${#SIG_LIST[@]} * 8 + 50))
    local bps=$((bytes_per_msg * RATE_HZ * 8))
    info "  Estimated bandwidth: $((bps / 1000)) kbps"
}

generate_stream_config() {
    local config="./telemetry-stream.json"
    cat > "$config" <<EOF
{
    "telemetry_stream": {
        "protocol": "${PROTOCOL}",
        "endpoint": "${ENDPOINT:-mqtt://iot-hub.cloud.local:8883}",
        "rate_hz": ${RATE_HZ},
        "signals": $(echo "$SIGNALS" | tr ',' '\n' | jq -Rn '[inputs]' 2>/dev/null || echo '["soc","voltage","current","temperature","speed","location"]'),
        "compression": "gzip",
        "encryption": "tls1.3",
        "qos": $([ "$PROTOCOL" = "mqtt" ] && echo 1 || echo "null"),
        "batch_size": $([ "$RATE_HZ" -gt 10 ] && echo 10 || echo 1),
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Stream config written to: $config"
}

main() {
    info "Starting telemetry stream configuration..."
    configure_stream
    estimate_bandwidth
    generate_stream_config
    info "Telemetry stream configured"
}

main
