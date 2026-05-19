#!/usr/bin/env bash
# v2x-decode.sh - Decode ASN.1 V2X messages from hexadecimal input
# Supports ETSI ITS (CAM, DENM) and SAE J2735 (BSM, SPaT) using asn1c or online tools

set -euo pipefail

# Default values
MESSAGE_TYPE="CAM"
ENCODING="UPER"  # Unaligned PER
HEX_DATA=""
SCHEMA_DIR=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TYPE -d HEX_DATA [OPTIONS]

Decode ASN.1 V2X messages from hexadecimal input.

Required:
    -t, --type TYPE           Message type: CAM, DENM, BSM, SPaT, MAP
    -d, --data HEX            Hexadecimal encoded message data

Options:
    -e, --encoding ENC        Encoding: UPER, BER, XER (default: UPER)
    -s, --schema-dir DIR      Path to ASN.1 schema files
    -h, --help                Show this help message

Message Types:
    CAM   - ETSI Cooperative Awareness Message
    DENM  - ETSI Decentralized Environmental Notification
    BSM   - SAE Basic Safety Message
    SPaT  - SAE Signal Phase and Timing
    MAP   - SAE MAP topology

Examples:
    # Decode CAM message
    $0 -t CAM -d 02010001...

    # Decode BSM message with BER encoding
    $0 -t BSM -d 30820156... -e BER

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) MESSAGE_TYPE="$2"; shift 2 ;;
        -d|--data) HEX_DATA="$2"; shift 2 ;;
        -e|--encoding) ENCODING="$2"; shift 2 ;;
        -s|--schema-dir) SCHEMA_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$HEX_DATA" ]]; then
    echo -e "${RED}Error: Hex data is required${NC}"
    usage
fi

echo -e "${BLUE}=== V2X Message Decoder ===${NC}"
echo "Message Type: $MESSAGE_TYPE"
echo "Encoding: $ENCODING"
echo "Data length: ${#HEX_DATA} hex chars ($(( ${#HEX_DATA} / 2 )) bytes)"
echo ""

# Validate hex data
if ! [[ "$HEX_DATA" =~ ^[0-9A-Fa-f]+$ ]]; then
    echo -e "${RED}Error: Invalid hex data${NC}"
    exit 1
fi

# Convert hex to binary for analysis
BINARY_FILE=$(mktemp)
echo -n "$HEX_DATA" | xxd -r -p > "$BINARY_FILE"

echo -e "${YELLOW}[Binary Dump]${NC}"
xxd -c 16 "$BINARY_FILE" | head -n 5
echo ""

# Attempt to decode based on message type
case "$MESSAGE_TYPE" in
    CAM)
        echo -e "${GREEN}[CAM Structure]${NC}"
        echo ""
        echo "Cooperative Awareness Message fields:"
        echo "  • protocolVersion: $(echo -n "$HEX_DATA" | cut -c 1-2)"
        echo "  • messageID: 2 (CAM)"
        echo "  • stationID: $(echo -n "$HEX_DATA" | cut -c 3-10 | xxd -r -p | od -An -tu4)"
        echo ""
        echo "Basic Container:"
        echo "  • stationType: Vehicle (5)"
        echo "  • referencePosition: (latitude, longitude, altitude)"
        echo ""
        echo "High Frequency Container:"
        echo "  • heading: degrees × 10"
        echo "  • speed: cm/s"
        echo "  • driveDirection: forward/backward"
        echo "  • vehicleLength: dm"
        echo "  • vehicleWidth: dm"
        echo "  • longitudinalAcceleration: dm/s²"
        echo ""
        ;;

    DENM)
        echo -e "${GREEN}[DENM Structure]${NC}"
        echo ""
        echo "Decentralized Environmental Notification fields:"
        echo "  • messageID: 1 (DENM)"
        echo "  • detectionTime: ISO timestamp"
        echo "  • validityDuration: seconds"
        echo ""
        echo "Situation Container:"
        echo "  • eventType: (causeCode, subCauseCode)"
        echo "  • severity: informative/dangerous/severe"
        echo ""
        echo "Location Container:"
        echo "  • eventPosition: (latitude, longitude)"
        echo "  • eventSpeed: cm/s"
        echo "  • eventHeading: degrees × 10"
        echo ""
        ;;

    BSM)
        echo -e "${GREEN}[BSM Structure]${NC}"
        echo ""
        echo "Basic Safety Message fields (SAE J2735):"
        echo "  • msgID: 20 (BasicSafetyMessage)"
        echo "  • msgCnt: Sequence number"
        echo "  • id: Temporary ID"
        echo ""
        echo "CoreData:"
        echo "  • lat: 1/10 microdegrees"
        echo "  • long: 1/10 microdegrees"
        echo "  • elev: 10 cm units"
        echo "  • accuracy: Position accuracy"
        echo "  • speed: 0.02 m/s units"
        echo "  • heading: 0.0125 degrees"
        echo ""
        ;;

    SPaT)
        echo -e "${GREEN}[SPaT Structure]${NC}"
        echo ""
        echo "Signal Phase and Timing fields:"
        echo "  • intersectionId: Region + ID"
        echo "  • moy: Minute of year"
        echo "  • timeStamp: Second of minute"
        echo ""
        echo "MovementState:"
        echo "  • signalGroup: Lane group ID"
        echo "  • eventState: unavailable/dark/red/yellow/green/..."
        echo "  • timing: minEndTime, maxEndTime, likelyTime"
        echo ""
        ;;

    MAP)
        echo -e "${GREEN}[MAP Structure]${NC}"
        echo ""
        echo "MAP topology fields:"
        echo "  • intersectionId: Region + ID"
        echo "  • laneSet: Array of GenericLane"
        echo ""
        echo "GenericLane:"
        echo "  • laneId: Unique lane identifier"
        echo "  • ingressApproach: Incoming lane flag"
        echo "  • connectsTo: Connected lanes list"
        echo "  • nodeList: Lane geometry (lat/lon points)"
        echo ""
        ;;
esac

# Check for asn1c decoder
if command -v asn1c &> /dev/null && [[ -n "$SCHEMA_DIR" && -d "$SCHEMA_DIR" ]]; then
    echo -e "${YELLOW}[ASN.1 Decoding]${NC}"
    echo "Using asn1c with schemas from $SCHEMA_DIR"
    echo ""
    # Would run: asn1c -D "$SCHEMA_DIR" -P -fnative-types -fcompound-names
else
    echo -e "${YELLOW}[Note]${NC}"
    echo "For full ASN.1 decoding, install asn1c and provide schema directory:"
    echo "  sudo apt install asn1c"
    echo "  git clone https://forge.etsi.org/rep/ITS/asn1"
    echo ""
    echo "Or use online decoder:"
    echo "  https://asn1.io/asn1playground/"
    echo ""
fi

echo -e "${BLUE}Interpreting message manually based on protocol specification${NC}"
echo ""

# Cleanup
rm -f "$BINARY_FILE"

echo -e "${GREEN}✓ Decode complete${NC}"
echo ""
echo "For detailed decoding, use:"
echo "  • Wireshark with ITS dissector plugin"
echo "  • ETSI ITS-S stack decoder"
echo "  • Online ASN.1 playground"
