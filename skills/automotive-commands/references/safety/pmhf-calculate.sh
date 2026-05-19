#!/usr/bin/env bash
# pmhf-calculate.sh - Calculate PMHF (Probabilistic Metric for Hardware Failure)
# Per ISO 26262-5 Annex B - quantitative safety metric for random hardware failures

set -euo pipefail

# Default values
ASIL_LEVEL=""
CONFIG_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -a ASIL_LEVEL [OPTIONS]

Calculate PMHF target and verify against component failure rates.

Required:
    -a, --asil LEVEL          ASIL level (A, B, C, D)

Options:
    -c, --config FILE         JSON config with component failure rates
    -h, --help                Show this help message

Config file format (JSON):
{
  "components": [
    {"name": "MCU", "lambda": 50, "unit": "FIT", "diagnostic_coverage": 0.95},
    {"name": "Sensor", "lambda": 100, "unit": "FIT", "diagnostic_coverage": 0.90}
  ],
  "vehicle_lifetime_km": 150000,
  "exposure_time_hours": 10000
}

Note: 1 FIT = 1 failure per 10^9 hours

Examples:
    # Show PMHF targets for ASIL D
    $0 -a D

    # Calculate PMHF from component data
    $0 -a C -c components.json

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--asil) ASIL_LEVEL="$2"; shift 2 ;;
        -c|--config) CONFIG_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$ASIL_LEVEL" ]]; then
    echo -e "${RED}Error: ASIL level is required${NC}"
    usage
fi

if [[ ! "$ASIL_LEVEL" =~ ^[ABCD]$ ]]; then
    echo -e "${RED}Error: Invalid ASIL level${NC}"
    exit 1
fi

echo -e "${BLUE}=== PMHF Calculator ===${NC}"
echo "ASIL Level: $ASIL_LEVEL"
echo ""

# PMHF targets per ISO 26262-5 Table 4
case "$ASIL_LEVEL" in
    A|B)
        TARGET_PMHF=100
        ;;
    C)
        TARGET_PMHF=100
        ;;
    D)
        TARGET_PMHF=10
        ;;
esac

echo -e "${GREEN}PMHF Target per ISO 26262-5:${NC}"
echo "  ASIL $ASIL_LEVEL: < $TARGET_PMHF FIT"
echo "  (Failures per 10^9 hours of operation)"
echo ""

if [[ -n "$CONFIG_FILE" ]]; then
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
        exit 1
    fi

    echo "Calculating PMHF from component data..."

    python3 <<EOF
import json
import sys

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

components = config['components']
total_pmhf = 0.0

print("Component Failure Contributions:")
print("-" * 80)

for comp in components:
    name = comp['name']
    lambda_fit = comp['lambda']
    dc = comp.get('diagnostic_coverage', 0.0)

    # Residual failure rate after diagnostics
    residual_lambda = lambda_fit * (1 - dc)
    total_pmhf += residual_lambda

    print(f"  {name:20s}: {lambda_fit:6.1f} FIT × (1 - {dc:.2f}) = {residual_lambda:6.2f} FIT")

print("-" * 80)
print(f"Total PMHF: {total_pmhf:.2f} FIT")
print()

target = $TARGET_PMHF

if total_pmhf < target:
    print("${GREEN}✓ PMHF target MET (${total_pmhf:.2f} < $target FIT)${NC}")
    sys.exit(0)
else:
    print("${RED}✗ PMHF target EXCEEDED (${total_pmhf:.2f} >= $target FIT)${NC}")
    print()
    print("${YELLOW}Recommendations:${NC}")
    print("  1. Increase diagnostic coverage for high-lambda components")
    print("  2. Use redundant architecture to reduce residual risk")
    print("  3. Select components with lower base failure rates")
    sys.exit(1)
EOF

else
    echo -e "${YELLOW}Example calculation:${NC}"
    echo ""
    echo "Assuming two components:"
    echo "  - MCU: 50 FIT, 95% diagnostic coverage"
    echo "  - Sensor: 100 FIT, 90% diagnostic coverage"
    echo ""
    echo "Residual failure rates:"
    echo "  - MCU: 50 × (1 - 0.95) = 2.5 FIT"
    echo "  - Sensor: 100 × (1 - 0.90) = 10.0 FIT"
    echo "  - Total PMHF: 12.5 FIT"
    echo ""

    if [[ "$ASIL_LEVEL" == "D" ]]; then
        echo -e "${RED}✗ PMHF target EXCEEDED for ASIL D (12.5 >= 10 FIT)${NC}"
    else
        echo -e "${GREEN}✓ PMHF target MET for ASIL $ASIL_LEVEL (12.5 < $TARGET_PMHF FIT)${NC}"
    fi

    echo ""
    echo "Provide -c config.json to calculate with real component data"
fi

echo ""
echo -e "${BLUE}ISO 26262-5:2018 Annex B Reference${NC}"
