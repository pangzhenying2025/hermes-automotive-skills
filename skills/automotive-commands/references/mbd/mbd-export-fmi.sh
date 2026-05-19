#!/bin/bash
# mbd-export-fmi.sh - Export models as FMU (Functional Mock-up Unit)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TOOL=""
MODEL_PATH=""
FMI_VERSION="2.0"
FMU_TYPE="cs"  # cs=CoSimulation, me=ModelExchange
OUTPUT_DIR="./fmu_export"
VALIDATE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TOOL -m MODEL_PATH [OPTIONS]

Export model as FMU for co-simulation.

Required:
    -t, --tool TOOL           Tool: simulink, openmodelica
    -m, --model PATH          Path to model file

Options:
    -v, --fmi-version VER     FMI version: 2.0, 3.0 (default: 2.0)
    -T, --type TYPE           FMU type: cs, me (default: cs)
    -o, --output DIR          Output directory (default: ./fmu_export)
    -V, --validate            Validate FMU with FMU Checker
    -h, --help                Show help

Examples:
    $0 -t openmodelica -m BatteryPack.mo -v 2.0 -T cs -V
    $0 -t simulink -m MotorController.slx -v 2.0

EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tool) TOOL="$2"; shift 2 ;;
        -m|--model) MODEL_PATH="$2"; shift 2 ;;
        -v|--fmi-version) FMI_VERSION="$2"; shift 2 ;;
        -T|--type) FMU_TYPE="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -V|--validate) VALIDATE=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

[[ -z "$TOOL" || -z "$MODEL_PATH" ]] && usage
[[ ! -f "$MODEL_PATH" ]] && { echo -e "${RED}Model not found: $MODEL_PATH${NC}"; exit 1; }

mkdir -p "$OUTPUT_DIR"

echo "=== FMU Export ==="
echo "Tool: $TOOL"
echo "Model: $MODEL_PATH"
echo "FMI version: $FMI_VERSION"
echo "FMU type: $FMU_TYPE"
echo ""

case "$TOOL" in
    simulink)
        python3 <<EOF
import sys
sys.path.insert(0, '${PROJECT_ROOT}')
from tools.adapters.mbd import SimulinkAdapter

adapter = SimulinkAdapter()
result = adapter.execute('export_fmu', {
    'model_path': '${MODEL_PATH}',
    'fmu_type': '${FMU_TYPE}'.upper().replace('CS', 'CoSimulation').replace('ME', 'ModelExchange'),
    'fmi_version': '${FMI_VERSION}',
    'output_dir': '${OUTPUT_DIR}'
})

if result['success']:
    print("${GREEN}✓ FMU export successful${NC}")
    print(f"FMU: {result['fmu_path']}")
    fmu_path = result['fmu_path']
else:
    print("${RED}✗ FMU export failed${NC}")
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

result = adapter.execute('export_fmu', {
    'model_file': '${MODEL_PATH}',
    'model_name': model_name,
    'fmi_version': '${FMI_VERSION}',
    'fmu_type': '${FMU_TYPE}',
    'output_dir': '${OUTPUT_DIR}'
})

if result['success']:
    print("${GREEN}✓ FMU export successful${NC}")
    print(f"FMU: {result['fmu_path']}")

    # Save FMU path for validation
    with open('/tmp/fmu_path.txt', 'w') as f:
        f.write(result['fmu_path'])
else:
    print("${RED}✗ FMU export failed${NC}")
    sys.exit(1)
EOF
        ;;

    *)
        echo -e "${RED}Unsupported tool: $TOOL${NC}"
        exit 1
        ;;
esac

# Validate FMU if requested
if [[ "$VALIDATE" == "true" ]]; then
    echo ""
    echo "Validating FMU..."

    if command -v fmuCheck.linux64 &> /dev/null; then
        FMU_PATH=$(cat /tmp/fmu_path.txt 2>/dev/null || echo "${OUTPUT_DIR}/*.fmu")
        fmuCheck.linux64 -h 0.01 -s 10 "$FMU_PATH"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓ FMU validation passed${NC}"
        else
            echo -e "${RED}✗ FMU validation failed${NC}"
        fi
    else
        echo "FMU Checker not found - install from https://github.com/modelica-tools/FMUChecker"
    fi
fi

echo ""
echo "=== FMU Export Complete ==="
echo "Output directory: $OUTPUT_DIR"
