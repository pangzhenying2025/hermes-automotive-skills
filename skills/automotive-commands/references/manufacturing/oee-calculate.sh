#!/usr/bin/env bash
set -euo pipefail
# OEE (Overall Equipment Effectiveness) calculator
AVAILABILITY=0.85
PERFORMANCE=0.90
QUALITY=0.95
OEE=$(echo "scale=4; $AVAILABILITY * $PERFORMANCE * $QUALITY * 100" | bc)
echo "OEE: ${OEE}%"
echo "Target: >85% (World Class)"
