#!/bin/bash
# model-validate.sh - Validate MBD models for quality and compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TOOL=""
MODEL_PATH=""
STANDARD="MAAB"
REPORT_PATH=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TOOL -m MODEL_PATH [OPTIONS]

Validate MBD models for quality and compliance.

Required:
    -t, --tool TOOL           Tool: simulink, scade
    -m, --model PATH          Path to model file

Options:
    -s, --standard STD        Standard: MAAB, JMAAB, MISRA, ISO26262
    -r, --report PATH         Report output path
    -h, --help                Show help

Examples:
    $0 -t simulink -m EngineControl.slx -s MAAB
    $0 -t scade -m BrakeController.etp -s ISO26262

EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tool) TOOL="$2"; shift 2 ;;
        -m|--model) MODEL_PATH="$2"; shift 2 ;;
        -s|--standard) STANDARD="$2"; shift 2 ;;
        -r|--report) REPORT_PATH="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

[[ -z "$TOOL" || -z "$MODEL_PATH" ]] && usage
[[ ! -f "$MODEL_PATH" ]] && { echo -e "${RED}Model not found: $MODEL_PATH${NC}"; exit 1; }

# Default report path
[[ -z "$REPORT_PATH" ]] && REPORT_PATH="$(basename ${MODEL_PATH%.*})_validation_report.html"

echo "=== Model Validation ==="
echo "Tool: $TOOL"
echo "Model: $MODEL_PATH"
echo "Standard: $STANDARD"
echo ""

case "$TOOL" in
    simulink)
        python3 <<EOF
import sys
sys.path.insert(0, '${PROJECT_ROOT}')
from tools.adapters.mbd import SimulinkAdapter

adapter = SimulinkAdapter()

if not adapter.is_available:
    print("${RED}Error: MATLAB/Simulink not available${NC}")
    sys.exit(1)

# Determine check configuration
check_map = {
    'MAAB': 'mathworks.maab',
    'JMAAB': 'mathworks.jmaab',
    'MISRA': 'mathworks.misra',
    'ISO26262': 'mathworks.design'
}
checks = check_map.get('${STANDARD}', 'mathworks.design')

result = adapter.execute('validate_model', {
    'model_path': '${MODEL_PATH}',
    'checks': checks,
    'report_path': '${REPORT_PATH}'
})

if result['success']:
    print("${GREEN}✓ Model validation completed${NC}")
    print(f"Report: {result['report_path']}")
else:
    print("${RED}✗ Model validation failed${NC}")
    print(f"Error: {result.get('error', 'Unknown error')}")
    sys.exit(1)
EOF
        ;;

    scade)
        python3 <<EOF
import sys, os
sys.path.insert(0, '${PROJECT_ROOT}')
from tools.adapters.mbd import ScadeAdapter

adapter = ScadeAdapter()

if not adapter.is_available:
    print("${RED}Error: SCADE not available${NC}")
    sys.exit(1)

model_name = os.path.splitext(os.path.basename('${MODEL_PATH}'))[0]

# Run Design Verifier
result = adapter.execute('verify', {
    'project_file': '${MODEL_PATH}',
    'node': model_name,
    'proof_level': 'auto',
    'report_path': '${REPORT_PATH}'
})

if result['success']:
    print("${GREEN}✓ Formal verification completed${NC}")
    print(f"Verified properties: {result['verified_properties']}")
    print(f"Failed properties: {result['failed_properties']}")
    print(f"Report: {result['report_path']}")

    if result['failed_properties'] > 0:
        print("${YELLOW}⚠ Some properties could not be verified${NC}")
        sys.exit(1)
else:
    print("${RED}✗ Verification failed${NC}")
    sys.exit(1)
EOF
        ;;

    *)
        echo -e "${RED}Unsupported tool: $TOOL${NC}"
        exit 1
        ;;
esac

echo ""
echo "=== Validation Complete ==="
echo "Check report: $REPORT_PATH"
