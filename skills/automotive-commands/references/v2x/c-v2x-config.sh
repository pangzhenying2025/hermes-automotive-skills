#!/usr/bin/env bash
# c-v2x-config.sh - Configure Cellular V2X (C-V2X) sidelink parameters
# 3GPP Release 14/15 PC5 interface configuration for Mode 4 autonomous resource selection

set -euo pipefail

# Default values
BAND="47"  # 5.9 GHz ITS band
TX_POWER=23  # dBm
POOL_ID=1
MCS=10  # Modulation and Coding Scheme

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Configure C-V2X PC5 sidelink parameters for direct vehicle-to-vehicle communication.

Options:
    -b, --band NUM            Operating band (47 = 5.9 GHz ITS, default: 47)
    -p, --power DBM           Transmit power in dBm (max 23, default: 23)
    -m, --mcs NUM             Modulation and Coding Scheme 0-20 (default: 10)
    --pool-id ID              Resource pool ID (default: 1)
    -h, --help                Show this help message

C-V2X Modes:
    Mode 3: Network-scheduled (eNB control) - infrastructure required
    Mode 4: UE-autonomous (distributed) - works without infrastructure

3GPP Bands:
    Band 47: 5855-5925 MHz (ITS dedicated, global)
    Band 38: 2570-2620 MHz (China specific)

Examples:
    # Configure for 5.9 GHz ITS band
    $0 -b 47 -p 23

    # Lower MCS for extended range
    $0 -b 47 -m 5

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--band) BAND="$2"; shift 2 ;;
        -p|--power) TX_POWER="$2"; shift 2 ;;
        -m|--mcs) MCS="$2"; shift 2 ;;
        --pool-id) POOL_ID="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== C-V2X Sidelink Configuration ===${NC}"
echo "Operating Band: $BAND"
echo "TX Power: $TX_POWER dBm"
echo "MCS: $MCS"
echo "Resource Pool: $POOL_ID"
echo ""

# Band-specific parameters
case "$BAND" in
    47)
        FREQ_START=5855
        FREQ_END=5925
        BANDWIDTH=70
        echo "Frequency range: $FREQ_START-$FREQ_END MHz (ITS dedicated)"
        ;;
    38)
        FREQ_START=2570
        FREQ_END=2620
        BANDWIDTH=50
        echo "Frequency range: $FREQ_START-$FREQ_END MHz (China)"
        ;;
    *)
        echo -e "${RED}Error: Unsupported band $BAND${NC}"
        exit 1
        ;;
esac

echo "Bandwidth: $BANDWIDTH MHz"
echo ""

# Calculate expected range based on MCS
if [[ $MCS -le 7 ]]; then
    RANGE=1200
    THROUGHPUT=2
elif [[ $MCS -le 14 ]]; then
    RANGE=800
    THROUGHPUT=5
else
    RANGE=400
    THROUGHPUT=10
fi

echo -e "${YELLOW}[Performance Expectations]${NC}"
echo "Expected range: ~$RANGE meters (open field)"
echo "Approximate throughput: ~$THROUGHPUT Mbps"
echo "Latency: <20 ms (3GPP requirement)"
echo ""

# Generate configuration
echo -e "${GREEN}[Configuration Parameters]${NC}"
echo ""

cat <<EOF
# SL-CommResourcePool Configuration (Mode 4)
{
  "resourcePoolId": $POOL_ID,
  "operatingBand": $BAND,
  "subchannelBitmap": "0xFFFFFFFFFFFFFFFF",
  "adjacencyPSCCH-PSSCH": true,
  "sizeSubchannel": 10,  // RBs per subchannel
  "numSubchannel": 5,
  "startRB-Subchannel": 0,
  "sl-OffsetIndicator": 0,
  "mcs": $MCS,
  "txPower": $TX_POWER,
  "priorityThreshold": 4,
  "resourceReservationPeriod": 100  // ms
}

# PSSCH (Physical Sidelink Shared Channel) Parameters
{
  "modulationScheme": "$(if [[ $MCS -lt 10 ]]; then echo QPSK; elif [[ $MCS -lt 17 ]]; then echo 16QAM; else echo 64QAM; fi)",
  "codeRate": "$(echo "scale=2; $MCS / 20" | bc)"
}

# Resource Selection Window
{
  "T1": 4,    // Selection window start (subframes)
  "T2": 100,  // Selection window end (subframes)
  "sensingWindow": 1000  // ms
}

# Priority Mapping (TS 23.287)
Priority 1-2: Safety critical (collision warning, emergency braking)
Priority 3-4: Safety related (cooperative awareness, lane change)
Priority 5-6: Traffic efficiency
Priority 7-8: Infotainment

EOF

echo -e "${YELLOW}[Mode 4 Resource Selection]${NC}"
echo ""
echo "1. Sensing: Monitor sidelink transmissions in past 1000 ms"
echo "2. Selection: Choose resources from available pool"
echo "3. Reservation: Reserve resources for periodic transmission"
echo "4. Pre-emption: Higher priority can override lower priority"
echo ""

echo -e "${BLUE}[V2X Service Types]${NC}"
echo ""
echo "Supported message types:"
echo "  • CAM (Cooperative Awareness Message): 10 Hz, Priority 3"
echo "  • DENM (Decentralized Event Notification): Triggered, Priority 1"
echo "  • CPM (Collective Perception): Variable, Priority 4"
echo "  • MCM (Maneuver Coordination): Event-driven, Priority 2"
echo ""

echo -e "${YELLOW}[Quality of Service]${NC}"
echo ""
echo "3GPP QoS Requirements (TS 22.186):"
echo "  • End-to-end latency: <20 ms (advanced driving)"
echo "  • Reliability: >99.99% (safety critical)"
echo "  • Communication range: 150-1000m"
echo "  • Relative speed: Up to 500 km/h"
echo ""

echo -e "${GREEN}✓ Configuration complete${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Load configuration to C-V2X modem"
echo "  2. Enable PC5 interface"
echo "  3. Start V2X service layer (ITS-S)"
echo "  4. Begin transmitting CAM messages"
echo ""
echo -e "${BLUE}3GPP TS 36.213, TS 36.331 Reference${NC}"
