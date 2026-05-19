#!/bin/bash
# mbd-generate.sh - Generate production code from MBD models
# Supports: Simulink, TargetLink, SCADE, OpenModelica

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
TOOL=""
MODEL_PATH=""
OUTPUT_DIR="./generated_code"
TARGET="ert"
OPTIMIZATION="balanced"
GENERATE_REPORT=true
MISRA_CHECK=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TOOL -m MODEL_PATH [OPTIONS]

Generate production code from MBD models.

Required:
    -t, --tool TOOL           Tool: simulink, scade, targetlink, openmodelica
    -m, --model PATH          Path to model file (.slx, .etp, .mo)

Options:
    -o, --output DIR          Output directory (default: ./generated_code)
    -T, --target TARGET       Code generation target (ert, grt, autosar)
    -O, --optimize GOAL       Optimization: speed, rom, ram, balanced
    -r, --report              Generate code generation report (default: true)
    -M, --misra               Run MISRA compliance check
    -h, --help                Show this help message

Examples:
    # Simulink Embedded Coder
    $0 -t simulink -m models/BatteryControl.slx -O speed

    # SCADE qualified code generation
    $0 -t scade -m models/BrakeController.etp -M

    # OpenModelica FMU export
    $0 -t openmodelica -m models/EVPowertrain.mo

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tool)
            TOOL="$2"
            shift 2
            ;;
        -m|--model)
            MODEL_PATH="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -T|--target)
            TARGET="$2"
            shift 2
            ;;
        -O|--optimize)
            OPTIMIZATION="$2"
            shift 2
            ;;
        -r|--report)
            GENERATE_REPORT=true
            shift
            ;;
        -M|--misra)
            MISRA_CHECK=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$TOOL" || -z "$MODEL_PATH" ]]; then
    echo -e "${RED}Error: Tool and model path are required${NC}"
    usage
fi

# Validate model exists
if [[ ! -f "$MODEL_PATH" ]]; then
    echo -e "${RED}Error: Model file not found: $MODEL_PATH${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== MBD Code Generation ==="
echo "Tool: $TOOL"
echo "Model: $MODEL_PATH"
echo "Output: $OUTPUT_DIR"
echo "Target: $TARGET"
echo "Optimization: $OPTIMIZATION"
echo ""

case "$TOOL" in
    simulink)
        echo "Generating code with Simulink Embedded Coder..."

        # Call Python adapter
        python3 <<EOF
import sys
sys.path.insert(0, '${PROJECT_ROOT}')

from tools.adapters.mbd import SimulinkAdapter

adapter = SimulinkAdapter()

if not adapter.is_available:
    print("${RED}Error: MATLAB/Simulink not available${NC}")
    sys.exit(1)

if not adapter.license_valid:
    print("${RED}Error: MATLAB license invalid${NC}")
    sys.exit(1)

result = adapter.execute('build_model', {
    'model_path': '${MODEL_PATH}',
    'output_dir': '${OUTPUT_DIR}',
    'target': '${TARGET}',
    'optimization': '${OPTIMIZATION}',
    'generate_report': ${GENERATE_REPORT}
})

if result['success']:
    print("${GREEN}✓ Code generation successful${NC}")
    print(f"Generated code: {result['output_dir']}")
else:
    print("${RED}✗ Code generation failed${NC}")
    print(f"Error: {result.get('error', 'Unknown error')}")
    sys.exit(1)
EOF
        ;;

    scade)
        echo "Generating qualified code with SCADE KCG..."

        python3 <<EOF
import sys
sys.path.insert(0, '${PROJECT_ROOT}')

from tools.adapters.mbd import ScadeAdapter

adapter = ScadeAdapter()

if not adapter.is_available:
    print("${RED}Error: SCADE not available${NC}")
    sys.exit(1)

# Extract node name from model path
import os
model_name = os.path.splitext(os.path.basename('${MODEL_PATH}'))[0]

result = adapter.execute('generate_code', {
    'project_file': '${MODEL_PATH}',
    'node': model_name,
    'target': 'C',
    'standard': 'ISO26262',
    'asil_level': 'ASIL_D',
    'optimization': 'none',
    'output_dir': '${OUTPUT_DIR}'
})

if result['success']:
    print("${GREEN}✓ Qualified code generation successful${NC}")
    print(f"Generated files: {len(result['generated_files'])}")

    # MISRA check if requested
    if ${MISRA_CHECK}:
        print("\nRunning MISRA compliance check...")
        misra_result = adapter.check_misra_compliance('${OUTPUT_DIR}')
        if misra_result['compliant']:
            print("${GREEN}✓ MISRA C:2012 compliant${NC}")
        else:
            print("${YELLOW}⚠ MISRA violations found: {misra_result['violations']}${NC}")
else:
    print("${RED}✗ Code generation failed${NC}")
    print(f"Error: {result.get('error', 'Unknown error')}")
    sys.exit(1)
EOF
        ;;

    openmodelica)
        echo "Compiling with OpenModelica..."

        python3 <<EOF
import sys
sys.path.insert(0, '${PROJECT_ROOT}')

from tools.adapters.mbd import OpenModelicaAdapter

adapter = OpenModelicaAdapter()

if not adapter.is_available:
    print("${RED}Error: OpenModelica not available${NC}")
    sys.exit(1)

# Extract model name
import os
model_name = os.path.splitext(os.path.basename('${MODEL_PATH}'))[0]

# Compile model
result = adapter.execute('compile', {
    'model_file': '${MODEL_PATH}',
    'model_name': model_name,
    'output_dir': '${OUTPUT_DIR}'
})

if result['success']:
    print("${GREEN}✓ Model compiled successfully${NC}")

    # Export as FMU
    print("\nExporting FMU...")
    fmu_result = adapter.execute('export_fmu', {
        'model_file': '${MODEL_PATH}',
        'model_name': model_name,
        'fmi_version': '2.0',
        'fmu_type': 'cs',
        'output_dir': '${OUTPUT_DIR}'
    })

    if fmu_result['success']:
        print("${GREEN}✓ FMU export successful${NC}")
        print(f"FMU file: {fmu_result['fmu_path']}")
    else:
        print("${YELLOW}⚠ FMU export failed${NC}")
else:
    print("${RED}✗ Compilation failed${NC}")
    print(f"Error: {result.get('error', 'Unknown error')}")
    sys.exit(1)
EOF
        ;;

    targetlink)
        echo -e "${YELLOW}TargetLink support requires dSPACE installation${NC}"
        echo "Please use dSPACE TargetLink GUI or batch mode"
        exit 1
        ;;

    *)
        echo -e "${RED}Error: Unknown tool: $TOOL${NC}"
        echo "Supported tools: simulink, scade, openmodelica, targetlink"
        exit 1
        ;;
esac

echo ""
echo "=== Code Generation Complete ==="
echo "Check output in: $OUTPUT_DIR"
