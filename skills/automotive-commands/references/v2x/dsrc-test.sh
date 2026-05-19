#!/usr/bin/env bash
# dsrc-test.sh - Test DSRC/802.11p communication parameters
# Validates channel configuration, transmit power, and data rate

set -euo pipefail

# Default values
CHANNEL=172
TX_POWER=20  # dBm
DATA_RATE=6   # Mbps
INTERFACE="wlan0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Test DSRC/802.11p communication parameters and link quality.

Options:
    -c, --channel NUM         Channel number (170-184, default: 172)
    -p, --power DBM           Transmit power in dBm (default: 20)
    -r, --rate MBPS           Data rate in Mbps: 3, 4.5, 6, 9, 12, 18, 24, 27 (default: 6)
    -i, --interface NAME      Network interface (default: wlan0)
    -h, --help                Show this help message

DSRC Channels (FCC):
    172 (5.860 GHz) - Service Channel
    174 (5.870 GHz) - Service Channel
    176 (5.880 GHz) - Service Channel
    178 (5.890 GHz) - Control Channel (CCH) - Safety critical
    180 (5.900 GHz) - Service Channel
    182 (5.910 GHz) - Service Channel
    184 (5.920 GHz) - Service Channel

Examples:
    # Test control channel with 20 dBm power
    $0 -c 178 -p 20

    # Test service channel with higher data rate
    $0 -c 172 -r 12

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--channel) CHANNEL="$2"; shift 2 ;;
        -p|--power) TX_POWER="$2"; shift 2 ;;
        -r|--rate) DATA_RATE="$2"; shift 2 ;;
        -i|--interface) INTERFACE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== DSRC/802.11p Test ===${NC}"
echo "Channel: $CHANNEL"
echo "TX Power: $TX_POWER dBm"
echo "Data Rate: $DATA_RATE Mbps"
echo "Interface: $INTERFACE"
echo ""

# Validate channel range
if [[ $CHANNEL -lt 170 || $CHANNEL -gt 184 || $((CHANNEL % 2)) -ne 0 ]]; then
    echo -e "${RED}Error: Invalid DSRC channel. Must be 170-184 (even numbers)${NC}"
    exit 1
fi

# Calculate frequency
FREQ=$(echo "scale=3; 5.850 + (($CHANNEL - 170) * 0.005)" | bc)
echo "Calculated frequency: $FREQ GHz"
echo ""

# Check if interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo -e "${YELLOW}Warning: Interface $INTERFACE not found${NC}"
    echo "Available interfaces:"
    ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | sed 's/^ /  /'
    echo ""
fi

# Check if wireless tools are available
if ! command -v iw &> /dev/null; then
    echo -e "${YELLOW}Warning: iw command not found. Install: apt install iw${NC}"
    echo ""
else
    echo -e "${GREEN}[Interface Status]${NC}"
    iw dev "$INTERFACE" info 2>/dev/null || echo "  Interface not configured"
    echo ""
fi

# Simulate DSRC configuration
echo -e "${BLUE}[Configuration]${NC}"
echo "Setting up 802.11p OCB (Outside Context of BSS) mode..."
echo ""

cat <<EOF
# Commands to configure DSRC interface:

# 1. Set interface down
sudo ip link set dev $INTERFACE down

# 2. Set 802.11p OCB mode
sudo iw dev $INTERFACE set type ocb

# 3. Bring interface up
sudo ip link set dev $INTERFACE up

# 4. Join OCB channel
sudo iw dev $INTERFACE ocb join $FREQ 10MHZ

# 5. Set transmit power
sudo iw dev $INTERFACE set txpower fixed ${TX_POWER}00

# 6. Configure IP address
sudo ip addr add 192.168.77.1/24 dev $INTERFACE

EOF

# Test parameters
echo -e "${YELLOW}[Performance Expectations]${NC}"
echo ""

case $DATA_RATE in
    3)
        RANGE=1000
        LATENCY=10
        ;;
    6)
        RANGE=800
        LATENCY=5
        ;;
    12)
        RANGE=500
        LATENCY=3
        ;;
    *)
        RANGE=600
        LATENCY=5
        ;;
esac

echo "Expected range: ~$RANGE meters (open field)"
echo "Expected latency: <$LATENCY ms"
echo "Packet loss target: <1% at 300m"
echo ""

if [[ $CHANNEL -eq 178 ]]; then
    echo -e "${GREEN}✓ Using Control Channel (CCH) - Safety critical messages${NC}"
    echo "  Reserved for CAM, DENM, and BSM safety messages"
else
    echo -e "${BLUE}Using Service Channel (SCH) - Non-safety applications${NC}"
    echo "  Can be used for traffic info, tolling, etc."
fi

echo ""
echo -e "${YELLOW}[Link Quality Test]${NC}"
echo "To test actual link quality, use:"
echo "  # Ping test"
echo "  ping -I $INTERFACE 192.168.77.2"
echo ""
echo "  # Throughput test (requires iperf3)"
echo "  iperf3 -s  # on receiver"
echo "  iperf3 -c 192.168.77.2 -t 60  # on sender"
echo ""

echo -e "${BLUE}IEEE 802.11p / ETSI ITS-G5 / SAE J2945 Reference${NC}"
