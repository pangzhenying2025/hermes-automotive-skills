#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Sensor Simulate — Configure and simulate automotive sensor models
# ============================================================================
# Usage: sensor-simulate.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -s, --sensor     Sensor type (lidar|radar|camera|ultrasonic)
#   -n, --noise      Noise model (none|gaussian|realistic)
#   -r, --rate       Output rate in Hz (default: 10)
#   -o, --output     Output configuration file
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
SENSOR_TYPE="lidar"
NOISE_MODEL="gaussian"
OUTPUT_RATE_HZ=10
OUTPUT_FILE="./sensor-config.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -s, --sensor     Sensor type (lidar|radar|camera|ultrasonic)"
            echo "  -n, --noise      Noise model (none|gaussian|realistic)"
            echo "  -r, --rate       Output rate in Hz (default: 10)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -s|--sensor) SENSOR_TYPE="$2"; shift 2 ;;
        -n|--noise) NOISE_MODEL="$2"; shift 2 ;;
        -r|--rate) OUTPUT_RATE_HZ="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

generate_sensor_config() {
    info "Generating $SENSOR_TYPE sensor configuration..."
    local sensor_json=""

    case "$SENSOR_TYPE" in
        lidar)
            sensor_json='"channels": 64, "range_m": 120, "fov_v_deg": 40, "rotation_freq_hz": 20, "points_per_second": 1200000'
            ;;
        radar)
            sensor_json='"range_m": 250, "fov_h_deg": 60, "fov_v_deg": 20, "max_detections": 64, "doppler_enabled": true'
            ;;
        camera)
            sensor_json='"resolution": {"width": 1920, "height": 1080}, "fov_deg": 90, "lens": "pinhole", "format": "rgb8"'
            ;;
        ultrasonic)
            sensor_json='"range_m": 5.0, "fov_deg": 60, "frequency_khz": 40, "beam_pattern": "conical"'
            ;;
        *) error "Invalid sensor type: $SENSOR_TYPE"; return 1 ;;
    esac

    cat > "$OUTPUT_FILE" <<EOF
{
    "sensor_simulation": {
        "type": "${SENSOR_TYPE}",
        "output_rate_hz": ${OUTPUT_RATE_HZ},
        "parameters": {${sensor_json}},
        "noise": {
            "model": "${NOISE_MODEL}",
            "range_std_m": $([ "$NOISE_MODEL" = "none" ] && echo "0.0" || echo "0.02"),
            "angular_std_deg": $([ "$NOISE_MODEL" = "none" ] && echo "0.0" || echo "0.1"),
            "false_positive_rate": $([ "$NOISE_MODEL" = "realistic" ] && echo "0.01" || echo "0.0"),
            "dropout_rate": $([ "$NOISE_MODEL" = "realistic" ] && echo "0.005" || echo "0.0")
        },
        "mounting": {
            "position": {"x": 2.0, "y": 0.0, "z": 1.5},
            "rotation": {"roll": 0, "pitch": 0, "yaw": 0}
        },
        "generated_at": "$(date -Iseconds)"
    }
}
EOF
    info "Sensor config written to: $OUTPUT_FILE"
}

validate_rate() {
    if (( OUTPUT_RATE_HZ < 1 || OUTPUT_RATE_HZ > 100 )); then
        warn "Output rate ${OUTPUT_RATE_HZ}Hz outside typical range (1-100Hz)"
    fi
}

estimate_bandwidth() {
    info "Estimating data bandwidth..."
    local bandwidth_mbps=0
    case "$SENSOR_TYPE" in
        lidar)      bandwidth_mbps=$((OUTPUT_RATE_HZ * 48)) ;;
        radar)      bandwidth_mbps=$((OUTPUT_RATE_HZ * 2)) ;;
        camera)     bandwidth_mbps=$((OUTPUT_RATE_HZ * 60)) ;;
        ultrasonic) bandwidth_mbps=1 ;;
    esac
    info "Estimated bandwidth: ${bandwidth_mbps} Mbps"
    if (( bandwidth_mbps > 500 )); then
        warn "High bandwidth: consider reducing rate or resolution"
    fi
}

main() {
    info "Starting sensor simulation setup..."
    validate_rate
    generate_sensor_config
    estimate_bandwidth
    info "Sensor simulation configured: $SENSOR_TYPE at ${OUTPUT_RATE_HZ}Hz"
}

main
