#!/usr/bin/env bash
# v2x-simulate.sh - Launch V2X message simulation (CAM, DENM, SPaT, MAP)
# Supports ETSI ITS-G5 and SAE J2735 message sets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
MESSAGE_TYPE="CAM"
STANDARD="ETSI"
FREQUENCY=10
DURATION=60
OUTPUT_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Launch V2X message simulation for testing cooperative awareness systems.

Options:
    -t, --type TYPE           Message type: CAM, DENM, SPaT, MAP, BSM (default: CAM)
    -s, --standard STD        Standard: ETSI, SAE (default: ETSI)
    -f, --frequency HZ        Transmission frequency (default: 10 Hz for CAM, 1 Hz for DENM)
    -d, --duration SECONDS    Simulation duration (default: 60)
    -o, --output FILE         Log messages to file (PCAP format)
    -h, --help                Show this help message

Message Types:
    CAM (ETSI)   - Cooperative Awareness Message (position, speed, heading)
    DENM (ETSI)  - Decentralized Environmental Notification (warnings)
    SPaT (SAE)   - Signal Phase and Timing (traffic lights)
    MAP (SAE)    - MAP topology
    BSM (SAE)    - Basic Safety Message (equivalent to CAM)

Examples:
    # Simulate CAM messages at 10 Hz
    $0 -t CAM -f 10

    # Simulate DENM warning messages
    $0 -t DENM -s ETSI -d 30

    # Capture SPaT messages to PCAP
    $0 -t SPaT -s SAE -o traffic_signal.pcap

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) MESSAGE_TYPE="$2"; shift 2 ;;
        -s|--standard) STANDARD="$2"; shift 2 ;;
        -f|--frequency) FREQUENCY="$2"; shift 2 ;;
        -d|--duration) DURATION="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== V2X Message Simulator ===${NC}"
echo "Message Type: $MESSAGE_TYPE"
echo "Standard: $STANDARD"
echo "Frequency: $FREQUENCY Hz"
echo "Duration: $DURATION seconds"
echo ""

# Validate message type and standard combination
if [[ "$STANDARD" == "ETSI" && ! "$MESSAGE_TYPE" =~ ^(CAM|DENM|CPM|MCM)$ ]]; then
    echo -e "${RED}Error: Invalid ETSI message type${NC}"
    exit 1
fi

if [[ "$STANDARD" == "SAE" && ! "$MESSAGE_TYPE" =~ ^(BSM|SPaT|MAP|TIM|RSA)$ ]]; then
    echo -e "${RED}Error: Invalid SAE message type${NC}"
    exit 1
fi

case "$MESSAGE_TYPE" in
    CAM|BSM)
        echo "Simulating Cooperative Awareness Messages..."
        echo "  - Sending position, speed, heading, acceleration"
        echo "  - Frequency: $FREQUENCY Hz"
        echo ""

        # Simulate vehicle moving in a straight line
        INTERVAL=$(echo "scale=3; 1.0 / $FREQUENCY" | bc)
        END_TIME=$(($(date +%s) + DURATION))

        LAT=37.4220
        LON=-122.0840
        SPEED=50  # km/h
        HEADING=90  # degrees

        COUNTER=0
        while [[ $(date +%s) -lt $END_TIME ]]; do
            TIMESTAMP=$(date -Iseconds)

            # Simulate movement
            LAT=$(echo "$LAT + 0.00001" | bc)
            LON=$(echo "$LON + 0.00001" | bc)

            echo -e "${GREEN}[CAM #$COUNTER]${NC} $TIMESTAMP"
            echo "  Position: ($LAT, $LON)"
            echo "  Speed: $SPEED km/h, Heading: $HEADING°"
            echo ""

            ((COUNTER++))
            sleep "$INTERVAL"
        done
        ;;

    DENM)
        echo "Simulating Decentralized Environmental Notification Messages..."
        echo "  - Warning: Road hazard detected"
        echo ""

        EVENT_TYPE="Hazardous Location - Dangerous Curve"
        LAT=37.4220
        LON=-122.0840

        for i in $(seq 1 $DURATION); do
            TIMESTAMP=$(date -Iseconds)

            echo -e "${YELLOW}[DENM #$i]${NC} $TIMESTAMP"
            echo "  Event: $EVENT_TYPE"
            echo "  Position: ($LAT, $LON)"
            echo "  Severity: High"
            echo "  Detection time: $(date -d '-30 seconds' -Iseconds)"
            echo ""

            sleep 1
        done
        ;;

    SPaT)
        echo "Simulating Signal Phase and Timing messages..."
        echo "  - Traffic signal state changes"
        echo ""

        INTERSECTION_ID=1234
        STATES=("Green" "Yellow" "Red")
        DURATIONS=(30 3 27)

        END_TIME=$(($(date +%s) + DURATION))
        STATE_INDEX=0

        while [[ $(date +%s) -lt $END_TIME ]]; do
            CURRENT_STATE="${STATES[$STATE_INDEX]}"
            TIME_REMAINING="${DURATIONS[$STATE_INDEX]}"

            TIMESTAMP=$(date -Iseconds)
            echo -e "${GREEN}[SPaT]${NC} $TIMESTAMP - Intersection $INTERSECTION_ID"
            echo "  Phase: $CURRENT_STATE"
            echo "  Time Remaining: $TIME_REMAINING seconds"
            echo ""

            sleep "${DURATIONS[$STATE_INDEX]}"
            STATE_INDEX=$(( (STATE_INDEX + 1) % 3 ))
        done
        ;;

    MAP)
        echo "Simulating MAP topology message..."
        echo "  - Road geometry and lane information"
        echo ""

        cat <<MAPDATA
{
  "intersectionId": 1234,
  "laneSet": [
    {
      "laneId": 1,
      "ingressApproach": true,
      "connectsTo": [2, 3],
      "nodeList": [
        {"lat": 37.4220, "lon": -122.0840},
        {"lat": 37.4225, "lon": -122.0835}
      ]
    }
  ],
  "timestamp": "$(date -Iseconds)"
}
MAPDATA
        ;;
esac

echo -e "${GREEN}✓ Simulation complete${NC}"

if [[ -n "$OUTPUT_FILE" ]]; then
    echo ""
    echo -e "${YELLOW}Note: PCAP capture requires tcpdump or Wireshark${NC}"
    echo "Run: tcpdump -i any -w $OUTPUT_FILE port 2001"
fi
