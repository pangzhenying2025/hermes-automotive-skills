#!/bin/bash
# SIL Test Command
# Execute Software-in-the-Loop testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Execute Software-in-the-Loop testing for ECU software.

OPTIONS:
    -b, --binary BINARY        ECU binary or container image
    -a, --arch ARCH            Target architecture (arm-cortex-m4, arm-cortex-a53, x86_64)
    -m, --mode MODE            Simulation mode (qemu, docker, canoe)
    -t, --tests SUITE          Test suite to execute
    -c, --coverage             Enable code coverage analysis
    -f, --fault-injection      Enable fault injection scenarios
    -o, --output DIR           Output directory for results
    -h, --help                 Show this help message

EXAMPLES:
    # Run BMS SIL test with QEMU
    $(basename "$0") --binary build/bms_application.elf --arch arm-cortex-m4 --mode qemu --tests tests/sil/bms_comprehensive.yaml --coverage

    # Docker-based SIL with fault injection
    $(basename "$0") --binary docker://gateway-ecu:latest --arch x86_64 --mode docker --tests tests/sil/gateway_routing.yaml --fault-injection

    # CANoe SIL simulation
    $(basename "$0") --binary models/tcm_model.vtt --arch tricore-tc39x --mode canoe --tests tests/sil/tcm_state_machine.yaml

EOF
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
BINARY=""
ARCH="arm-cortex-m4"
MODE="qemu"
TEST_SUITE=""
COVERAGE=false
FAULT_INJECTION=false
OUTPUT_DIR="results/sil"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--binary)
            BINARY="$2"
            shift 2
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -t|--tests)
            TEST_SUITE="$2"
            shift 2
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -f|--fault-injection)
            FAULT_INJECTION=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$BINARY" ]; then
    log_error "ECU binary not specified"
    usage
fi

if [ -z "$TEST_SUITE" ]; then
    log_error "Test suite not specified"
    usage
fi

log_info "SIL Test - Binary: $BINARY, Architecture: $ARCH, Mode: $MODE"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Setup virtual ECU environment
log_info "Creating virtual ECU environment..."
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/qemu_adapter.py" --create-vm --architecture "$ARCH"

if [ $? -ne 0 ]; then
    log_error "Virtual ECU creation failed"
    exit 1
fi

log_info "Loading binary: $BINARY"
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/qemu_adapter.py" --load-binary "$BINARY"

if [ $? -ne 0 ]; then
    log_error "Binary loading failed"
    exit 1
fi

# Configure virtual CAN network
log_info "Configuring virtual network..."
sudo modprobe vcan 2>/dev/null || true
sudo ip link add dev vcan0 type vcan 2>/dev/null || true
sudo ip link set up vcan0 2>/dev/null || true
sudo ip link add dev vcan1 type vcan 2>/dev/null || true
sudo ip link set up vcan1 2>/dev/null || true

log_info "Virtual network configured"

# Start virtual ECU simulation
log_info "Starting virtual ECU simulation..."
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${MODE}_adapter.py" --start &
SIMULATION_PID=$!

sleep 2

# Check if simulation is running
if ! kill -0 $SIMULATION_PID 2>/dev/null; then
    log_error "Simulation failed to start"
    exit 1
fi

log_info "Simulation running (PID: $SIMULATION_PID)"

# Execute test suite
log_info "Executing test suite: $TEST_SUITE"
pytest "$TEST_SUITE" -v --junitxml="$OUTPUT_DIR/test_results.xml" \
    ${COVERAGE:+--cov=. --cov-report=html:$OUTPUT_DIR/coverage}

TEST_RESULT=$?

# Run fault injection tests if enabled
if [ "$FAULT_INJECTION" = true ]; then
    log_info "Running fault injection tests..."
    python3 tests/sil/fault_injection.py --target "$BINARY" --output "$OUTPUT_DIR/fault_injection.log"
fi

# Generate code coverage report
if [ "$COVERAGE" = true ]; then
    log_info "Generating code coverage report..."
    lcov --capture --directory . --output-file "$OUTPUT_DIR/coverage.info"
    genhtml "$OUTPUT_DIR/coverage.info" --output-directory "$OUTPUT_DIR/coverage_html"
    log_info "Coverage report: $OUTPUT_DIR/coverage_html/index.html"
fi

# Analyze execution traces
log_info "Analyzing execution traces..."
python3 tools/analysis/trace_analyzer.py --input sil_traces.log --output "$OUTPUT_DIR/trace_analysis.json"

# Generate test report
log_info "Generating test report..."
python3 tools/reporting/sil_report_generator.py --results "$OUTPUT_DIR" --output "$OUTPUT_DIR/sil_report.html"

# Cleanup
log_info "Stopping virtual ECU..."
kill $SIMULATION_PID 2>/dev/null || true
wait $SIMULATION_PID 2>/dev/null || true

log_info "Cleaning up virtual network..."
sudo ip link set down vcan0 2>/dev/null || true
sudo ip link delete vcan0 2>/dev/null || true
sudo ip link set down vcan1 2>/dev/null || true
sudo ip link delete vcan1 2>/dev/null || true

log_info "SIL test complete"
log_info "Results: $OUTPUT_DIR/"
log_info "Report: $OUTPUT_DIR/sil_report.html"

exit $TEST_RESULT
