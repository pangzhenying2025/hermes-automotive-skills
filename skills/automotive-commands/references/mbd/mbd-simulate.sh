#!/bin/bash
# mbd-simulate.sh - Simulate MBD models
# Supports: Simulink, OpenModelica, SCADE

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TOOL=""
MODEL_PATH=""
STOP_TIME=10.0
OUTPUT_FORMAT="csv"
PLOT_RESULTS=false

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TOOL -m MODEL_PATH [OPTIONS]

Simulate MBD models.

Required:
    -t, --tool TOOL           Tool: simulink, openmodelica
    -m, --model PATH          Path to model file

Options:
    -s, --stop-time TIME      Stop time (default: 10.0)
    -f, --format FORMAT       Output format: csv, mat, plt
    -p, --plot                Plot results after simulation
    -h, --help                Show help

Examples:
    $0 -t openmodelica -m EVPowertrain.mo -s 100 -p
    $0 -t simulink -m BatteryModel.slx -s 50

EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tool) TOOL="$2"; shift 2 ;;
        -m|--model) MODEL_PATH="$2"; shift 2 ;;
        -s|--stop-time) STOP_TIME="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        -p|--plot) PLOT_RESULTS=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

[[ -z "$TOOL" || -z "$MODEL_PATH" ]] && usage
[[ ! -f "$MODEL_PATH" ]] && { echo -e "${RED}Model not found: $MODEL_PATH${NC}"; exit 1; }

echo "=== MBD Simulation ==="
echo "Tool: $TOOL"
echo "Model: $MODEL_PATH"
echo "Stop time: ${STOP_TIME}s"
echo ""

case "$TOOL" in
    simulink)
        python3 <<EOF
import sys
sys.path.insert(0, '${PROJECT_ROOT}')
from tools.adapters.mbd import SimulinkAdapter

adapter = SimulinkAdapter()
result = adapter.execute('simulate', {
    'model_path': '${MODEL_PATH}',
    'stop_time': ${STOP_TIME},
    'save_output': True
})

if result['success']:
    print("${GREEN}✓ Simulation completed${NC}")
    print(f"Output: {result['output_file']}")
else:
    print("${RED}✗ Simulation failed${NC}")
    sys.exit(1)
EOF
        ;;

    openmodelica)
        python3 <<EOF
import sys, os
sys.path.insert(0, '${PROJECT_ROOT}')
from tools.adapters.mbd import OpenModelicaAdapter

adapter = OpenModelicaAdapter()
model_name = os.path.splitext(os.path.basename('${MODEL_PATH}'))[0]

result = adapter.execute('simulate', {
    'model_file': '${MODEL_PATH}',
    'model_name': model_name,
    'stop_time': ${STOP_TIME},
    'output_format': '${OUTPUT_FORMAT}'
})

if result['success']:
    print("${GREEN}✓ Simulation completed${NC}")
    print(f"Results: {result['result_file']}")

    if ${PLOT_RESULTS}:
        import matplotlib.pyplot as plt
        import DyMat
        data = DyMat.DyMatFile(result['result_file'])
        # Basic plot (customize as needed)
        plt.plot(data.abscissa('time'), data.data('voltage'))
        plt.xlabel('Time [s]')
        plt.ylabel('Voltage [V]')
        plt.grid(True)
        plt.show()
else:
    print("${RED}✗ Simulation failed${NC}")
    sys.exit(1)
EOF
        ;;

    *)
        echo -e "${RED}Unsupported tool: $TOOL${NC}"
        exit 1
        ;;
esac
