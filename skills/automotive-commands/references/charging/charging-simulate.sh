#!/usr/bin/env bash
# charging-simulate.sh - Simulate EV charging session with realistic power curves
# Models battery charging behavior with CC/CV (Constant Current/Constant Voltage)

set -euo pipefail

# Default values
BATTERY_CAPACITY=75  # kWh
INITIAL_SOC=20       # %
TARGET_SOC=80        # %
MAX_POWER=150        # kW (DC fast charging)
DURATION=0           # seconds (auto-calculated)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Simulate EV charging session with realistic power curve.

Options:
    -b, --battery KWH         Battery capacity in kWh (default: 75)
    -s, --soc-start PCT       Initial SOC percentage (default: 20)
    -t, --soc-target PCT      Target SOC percentage (default: 80)
    -p, --power KW            Maximum charging power in kW (default: 150)
    -d, --duration SEC        Override duration in seconds (auto if not set)
    -h, --help                Show this help message

Charging Curves:
    • CC Phase: Constant current from soc-start to ~70%
    • CV Phase: Constant voltage, tapering current from ~70% to target
    • Battery thermal limits reduce power above 80% SOC

Examples:
    # Simulate DC fast charging 20-80%
    $0 -b 75 -s 20 -t 80 -p 150

    # Simulate AC Level 2 charging
    $0 -b 60 -s 40 -t 100 -p 11

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--battery) BATTERY_CAPACITY="$2"; shift 2 ;;
        -s|--soc-start) INITIAL_SOC="$2"; shift 2 ;;
        -t|--soc-target) TARGET_SOC="$2"; shift 2 ;;
        -p|--power) MAX_POWER="$2"; shift 2 ;;
        -d|--duration) DURATION="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== EV Charging Simulation ===${NC}"
echo "Battery Capacity: ${BATTERY_CAPACITY} kWh"
echo "Initial SOC: ${INITIAL_SOC}%"
echo "Target SOC: ${TARGET_SOC}%"
echo "Max Power: ${MAX_POWER} kW"
echo ""

# Calculate energy to be charged
ENERGY_TO_CHARGE=$(echo "scale=2; $BATTERY_CAPACITY * ($TARGET_SOC - $INITIAL_SOC) / 100" | bc)
echo "Energy to charge: ${ENERGY_TO_CHARGE} kWh"
echo ""

# Estimate duration if not provided
if [[ $DURATION -eq 0 ]]; then
    # Average power is ~80% of max due to CV taper
    AVG_POWER=$(echo "scale=2; $MAX_POWER * 0.8" | bc)
    DURATION=$(echo "scale=0; $ENERGY_TO_CHARGE / $AVG_POWER * 3600" | bc)
fi

DURATION_MIN=$(echo "scale=0; $DURATION / 60" | bc)
echo "Estimated duration: ${DURATION_MIN} minutes"
echo ""

# Simulate charging curve
echo -e "${YELLOW}[Charging Curve Simulation]${NC}"
echo ""
printf "%-10s %-10s %-10s %-10s %-10s\n" "Time(min)" "SOC(%)" "Power(kW)" "Energy(kWh)" "Current(A)"
printf "%s\n" "------------------------------------------------------------"

CURRENT_SOC=$INITIAL_SOC
TOTAL_ENERGY=0
VOLTAGE=400  # Nominal pack voltage

for ((t=0; t<=$DURATION; t+=60)); do
    CURRENT_SOC_FLOAT=$(echo "scale=2; $CURRENT_SOC" | bc)

    # Determine charging power based on SOC (CC/CV curve)
    if (( $(echo "$CURRENT_SOC < 70" | bc -l) )); then
        # CC phase: full power
        POWER=$MAX_POWER
    elif (( $(echo "$CURRENT_SOC < 80" | bc -l) )); then
        # CV phase: linear taper
        TAPER=$(echo "scale=2; (80 - $CURRENT_SOC) / 10" | bc)
        POWER=$(echo "scale=2; $MAX_POWER * (0.5 + 0.5 * $TAPER)" | bc)
    else
        # High SOC: further reduced power
        TAPER=$(echo "scale=2; (100 - $CURRENT_SOC) / 20" | bc)
        POWER=$(echo "scale=2; $MAX_POWER * 0.3 * $TAPER" | bc)
    fi

    # Calculate current (simplified, assuming constant voltage)
    CURRENT=$(echo "scale=1; $POWER * 1000 / $VOLTAGE" | bc)

    # Energy added in this minute
    ENERGY_DELTA=$(echo "scale=3; $POWER / 60" | bc)
    TOTAL_ENERGY=$(echo "scale=2; $TOTAL_ENERGY + $ENERGY_DELTA" | bc)

    # Update SOC
    SOC_DELTA=$(echo "scale=2; $ENERGY_DELTA / $BATTERY_CAPACITY * 100" | bc)
    CURRENT_SOC=$(echo "scale=2; $CURRENT_SOC + $SOC_DELTA" | bc)

    # Stop if target reached
    if (( $(echo "$CURRENT_SOC >= $TARGET_SOC" | bc -l) )); then
        CURRENT_SOC=$TARGET_SOC
    fi

    TIME_MIN=$((t / 60))

    # Print every 5 minutes
    if (( t % 300 == 0 )) || (( $(echo "$CURRENT_SOC >= $TARGET_SOC" | bc -l) )); then
        printf "%-10d %-10.1f %-10.1f %-10.2f %-10.1f\n" \
            "$TIME_MIN" "$CURRENT_SOC" "$POWER" "$TOTAL_ENERGY" "$CURRENT"
    fi

    # Exit if target reached
    if (( $(echo "$CURRENT_SOC >= $TARGET_SOC" | bc -l) )); then
        break
    fi
done

echo ""
echo -e "${GREEN}✓ Charging simulation complete${NC}"
echo ""
echo -e "${YELLOW}[Session Summary]${NC}"
echo "  Total energy delivered: ${TOTAL_ENERGY} kWh"
echo "  Final SOC: ${CURRENT_SOC}%"
echo "  Actual duration: $(( t / 60 )) minutes"
echo "  Average power: $(echo "scale=1; $TOTAL_ENERGY / ($t / 3600)" | bc) kW"
echo ""

# Cost estimation (assuming $0.40/kWh for DC fast charging)
COST=$(echo "scale=2; $TOTAL_ENERGY * 0.40" | bc)
echo "  Estimated cost (@ \$0.40/kWh): \$$COST"
echo ""

echo -e "${BLUE}Charging Standards:${NC}"
echo "  • CCS (Combined Charging System): Up to 350 kW"
echo "  • CHAdeMO: Up to 100 kW (v2.0), 400 kW (v3.0)"
echo "  • Tesla Supercharger V3: Up to 250 kW"
echo "  • GB/T: Up to 237 kW"
