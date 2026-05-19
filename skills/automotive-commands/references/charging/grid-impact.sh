#!/usr/bin/env bash
# grid-impact.sh - Calculate grid impact of multiple EV chargers at a location
# Analyzes power demand, load profiles, and transformer capacity

set -euo pipefail

# Default values
NUM_CHARGERS=10
CHARGER_POWER=150  # kW per charger
UTILIZATION=0.6    # 60% average utilization
TRANSFORMER_CAPACITY=0  # kVA (0 = calculate recommended)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Calculate electrical grid impact of EV charging infrastructure.

Options:
    -n, --num-chargers NUM    Number of charging stations (default: 10)
    -p, --power KW            Power per charger in kW (default: 150)
    -u, --utilization PCT     Average utilization factor 0-1 (default: 0.6)
    -c, --capacity KVA        Existing transformer capacity in kVA (default: auto)
    -h, --help                Show this help message

Examples:
    # Analyze 10x 150kW DC fast chargers
    $0 -n 10 -p 150

    # Check if existing 2MVA transformer is sufficient
    $0 -n 20 -p 50 -u 0.8 -c 2000

    # AC Level 2 charging station
    $0 -n 50 -p 11 -u 0.3

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--num-chargers) NUM_CHARGERS="$2"; shift 2 ;;
        -p|--power) CHARGER_POWER="$2"; shift 2 ;;
        -u|--utilization) UTILIZATION="$2"; shift 2 ;;
        -c|--capacity) TRANSFORMER_CAPACITY="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== Grid Impact Analysis ===${NC}"
echo "Number of chargers: $NUM_CHARGERS"
echo "Power per charger: $CHARGER_POWER kW"
echo "Utilization factor: $(echo "$UTILIZATION * 100" | bc)%"
echo ""

# Calculate peak demand
PEAK_DEMAND=$(echo "scale=2; $NUM_CHARGERS * $CHARGER_POWER" | bc)
echo -e "${YELLOW}[Peak Demand]${NC}"
echo "  Installed capacity: ${PEAK_DEMAND} kW"
echo ""

# Calculate average demand
AVG_DEMAND=$(echo "scale=2; $PEAK_DEMAND * $UTILIZATION" | bc)
echo "  Average demand (${UTILIZATION} utilization): ${AVG_DEMAND} kW"
echo ""

# Calculate daily energy consumption (assuming 8 hours of operation)
DAILY_ENERGY=$(echo "scale=0; $AVG_DEMAND * 8" | bc)
MONTHLY_ENERGY=$(echo "scale=0; $DAILY_ENERGY * 30" | bc)

echo -e "${YELLOW}[Energy Consumption]${NC}"
echo "  Daily: ${DAILY_ENERGY} kWh"
echo "  Monthly: ${MONTHLY_ENERGY} kWh"
echo ""

# Transformer sizing (apply diversity factor)
# Diversity factor accounts for not all chargers running at peak simultaneously
DIVERSITY_FACTOR=$(echo "scale=2; 0.7 + (0.3 * $UTILIZATION)" | bc)
RECOMMENDED_TRANSFORMER=$(echo "scale=0; $PEAK_DEMAND * $DIVERSITY_FACTOR / 0.8 / 1" | bc)  # 0.8 power factor

echo -e "${YELLOW}[Transformer Requirements]${NC}"
echo "  Diversity factor: $DIVERSITY_FACTOR"
echo "  Recommended transformer: ${RECOMMENDED_TRANSFORMER} kVA minimum"
echo ""

if [[ $TRANSFORMER_CAPACITY -gt 0 ]]; then
    LOAD_PCT=$(echo "scale=1; ($PEAK_DEMAND * $DIVERSITY_FACTOR) / $TRANSFORMER_CAPACITY * 100" | bc)

    echo "  Existing transformer: ${TRANSFORMER_CAPACITY} kVA"
    echo "  Load percentage: ${LOAD_PCT}%"
    echo ""

    if (( $(echo "$LOAD_PCT < 80" | bc -l) )); then
        echo -e "  ${GREEN}✓ Existing transformer is adequate${NC}"
    elif (( $(echo "$LOAD_PCT < 100" | bc -l) )); then
        echo -e "  ${YELLOW}⚠ Transformer will be heavily loaded (${LOAD_PCT}%)${NC}"
        echo "  Consider load management or upgrade"
    else
        echo -e "  ${RED}✗ Transformer capacity insufficient (${LOAD_PCT}% of rated)${NC}"
        echo "  Upgrade required to ${RECOMMENDED_TRANSFORMER} kVA minimum"
    fi
else
    echo "  Recommended transformer sizes:"
    echo "    - Standard: ${RECOMMENDED_TRANSFORMER} kVA"
    echo "    - With 20% margin: $(echo "scale=0; $RECOMMENDED_TRANSFORMER * 1.2 / 1" | bc) kVA"
fi

echo ""

# Power quality considerations
echo -e "${YELLOW}[Power Quality]${NC}"

# Harmonics (non-linear load from power electronics)
echo "  • Total Harmonic Distortion (THD): < 5% (IEEE 519)"
echo "  • Recommend active harmonic filtering for >500kW installations"
echo ""

# Power factor
PF=0.98  # Typical for modern EV chargers with PFC
REACTIVE_POWER=$(echo "scale=0; $PEAK_DEMAND * sqrt(1 / ($PF * $PF) - 1) / 1" | bc -l)
echo "  • Power factor: $PF (with PFC)"
echo "  • Reactive power: ${REACTIVE_POWER} kVAR"
echo ""

# Grid connection requirements
echo -e "${YELLOW}[Grid Connection]${NC}"

if (( $(echo "$PEAK_DEMAND > 1000" | bc -l) )); then
    echo "  • Connection level: Medium voltage (MV)"
    echo "  • Voltage: 11 kV or 33 kV distribution"
    echo "  • Protection: Distance protection, differential protection"
elif (( $(echo "$PEAK_DEMAND > 300" | bc -l) )); then
    echo "  • Connection level: Low voltage (LV) main"
    echo "  • Voltage: 400V 3-phase"
    echo "  • Requires dedicated transformer"
else
    echo "  • Connection level: Low voltage (LV)"
    echo "  • Voltage: 400V 3-phase"
fi

echo ""

# Load management recommendations
echo -e "${YELLOW}[Load Management]${NC}"

if (( $(echo "$NUM_CHARGERS > 5" | bc -l) )); then
    echo "  • Dynamic load management recommended"
    echo "  • Smart charging algorithms to prevent peak demand charges"
    echo "  • Consider V1G (smart charging) or V2G (vehicle-to-grid)"
    echo "  • Implement queuing system during high demand periods"
fi

echo ""

# Cost estimation
DEMAND_CHARGE=$(echo "scale=0; $AVG_DEMAND * 15 / 1" | bc)  # $15/kW/month typical
ENERGY_CHARGE=$(echo "scale=0; $MONTHLY_ENERGY * 0.12 / 1" | bc)  # $0.12/kWh
TOTAL_MONTHLY_COST=$(echo "scale=0; $DEMAND_CHARGE + $ENERGY_CHARGE / 1" | bc)

echo -e "${YELLOW}[Cost Estimation]${NC}"
echo "  Monthly demand charge (@ \$15/kW): \$${DEMAND_CHARGE}"
echo "  Monthly energy charge (@ \$0.12/kWh): \$${ENERGY_CHARGE}"
echo "  Total monthly cost: \$${TOTAL_MONTHLY_COST}"
echo "  Annual cost: \$$(echo "scale=0; $TOTAL_MONTHLY_COST * 12 / 1" | bc)"
echo ""

echo -e "${GREEN}Recommendations:${NC}"
echo "  1. Implement dynamic load management to reduce demand charges"
echo "  2. Consider on-site energy storage (battery) for peak shaving"
echo "  3. Install solar PV to offset energy costs"
echo "  4. Use time-of-use tariffs for off-peak charging"
echo "  5. Monitor power quality (THD, voltage sag) regularly"
