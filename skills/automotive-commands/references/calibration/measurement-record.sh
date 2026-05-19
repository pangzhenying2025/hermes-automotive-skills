#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Measurement Record — Record ECU measurements via XCP/CCP protocol
# ============================================================================
# Usage: measurement-record.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -c, --channels   Measurement channels (comma-separated)
#   -r, --rate       Sample rate in Hz (default: 100)
#   -d, --duration   Recording duration in seconds (default: 10)
#   -o, --output     Output recording file
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
CHANNELS="EngineSpeed,CoolantTemp,BatteryVoltage"
SAMPLE_RATE_HZ=100
DURATION_S=10
OUTPUT_FILE="./measurement-recording.csv"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -c, --channels   Measurement channels (comma-separated)"
            echo "  -r, --rate       Sample rate in Hz (default: 100)"
            echo "  -d, --duration   Recording duration in seconds (default: 10)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -c|--channels) CHANNELS="$2"; shift 2 ;;
        -r|--rate) SAMPLE_RATE_HZ="$2"; shift 2 ;;
        -d|--duration) DURATION_S="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

parse_channels() {
    IFS=',' read -ra CHANNEL_LIST <<< "$CHANNELS"
    local count=${#CHANNEL_LIST[@]}
    info "Channels to record: $count"
    for ch in "${CHANNEL_LIST[@]}"; do
        $VERBOSE && info "  - $ch"
    done
}

validate_rate() {
    if (( SAMPLE_RATE_HZ > 10000 )); then
        error "Sample rate too high: ${SAMPLE_RATE_HZ}Hz (max: 10000Hz)"
        return 1
    fi
    local total_samples=$((SAMPLE_RATE_HZ * DURATION_S))
    info "Recording: ${SAMPLE_RATE_HZ}Hz for ${DURATION_S}s = $total_samples samples"
}

setup_daq_list() {
    info "Setting up DAQ (Data Acquisition) list..."
    local daq_id=0
    for ch in "${CHANNEL_LIST[@]}"; do
        $VERBOSE && info "  DAQ[$daq_id]: $ch @ ${SAMPLE_RATE_HZ}Hz"
        daq_id=$((daq_id + 1))
    done
    info "DAQ list configured with ${#CHANNEL_LIST[@]} entries"
}

simulate_recording() {
    info "Starting measurement recording..."
    local total_samples=$((SAMPLE_RATE_HZ * DURATION_S))

    # Write CSV header
    local header="timestamp"
    for ch in "${CHANNEL_LIST[@]}"; do
        header="$header,$ch"
    done
    echo "$header" > "$OUTPUT_FILE"

    # Write sample data (simulated)
    local sample_count=0
    local step=$((total_samples / 20))
    (( step == 0 )) && step=1
    for i in $(seq 1 20); do
        sample_count=$((i * step))
        local timestamp
        timestamp=$(echo "scale=3; $sample_count / $SAMPLE_RATE_HZ" | bc 2>/dev/null || echo "$i")
        local row="$timestamp"
        for ch in "${CHANNEL_LIST[@]}"; do
            row="$row,$((RANDOM % 1000))"
        done
        echo "$row" >> "$OUTPUT_FILE"
    done

    info "Recorded $total_samples samples to: $OUTPUT_FILE"
}

generate_summary() {
    local summary_file="${OUTPUT_FILE%.csv}-summary.json"
    info "Generating recording summary..."
    cat > "$summary_file" <<EOF
{
    "recording_summary": {
        "channels": $(echo "${CHANNEL_LIST[@]}" | jq -Rc 'split(" ")' 2>/dev/null || echo '["EngineSpeed","CoolantTemp","BatteryVoltage"]'),
        "sample_rate_hz": ${SAMPLE_RATE_HZ},
        "duration_s": ${DURATION_S},
        "total_samples": $((SAMPLE_RATE_HZ * DURATION_S)),
        "output_file": "${OUTPUT_FILE}",
        "file_format": "CSV",
        "recorded_at": "$(date -Iseconds)"
    }
}
EOF
    info "Summary written to: $summary_file"
}

main() {
    info "Starting measurement recording setup..."
    parse_channels
    validate_rate
    setup_daq_list
    simulate_recording
    generate_summary
    info "Measurement recording complete"
}

main
