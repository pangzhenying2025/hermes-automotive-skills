#!/bin/bash
# HIL Setup Command
# Configure Hardware-in-the-Loop testbench

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

Configure HIL testbench for automotive ECU testing.

OPTIONS:
    -p, --platform PLATFORM    HIL platform (dspace-scalexio, ni-pxi, etas-labcar, vector-vt)
    -e, --ecu ECU              ECU type (bms, inverter, tcm, bcm, gateway, adas-ecu)
    -c, --config FILE          Interface configuration file (JSON)
    -s, --scenario FILE        Test scenario file
    -v, --validate             Validate platform readiness
    -h, --help                 Show this help message

EXAMPLES:
    # Setup dSPACE SCALEXIO for BMS testing
    $(basename "$0") --platform dspace-scalexio --ecu bms --config config/bms_interfaces.json

    # Setup NI PXI with validation
    $(basename "$0") --platform ni-pxi --ecu tcm --config config/tcm_interfaces.json --validate

    # Load test scenario
    $(basename "$0") --platform dspace-scalexio --scenario scenarios/bms_charge_discharge.yaml

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
PLATFORM=""
ECU=""
CONFIG_FILE=""
SCENARIO_FILE=""
VALIDATE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -e|--ecu)
            ECU="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -s|--scenario)
            SCENARIO_FILE="$2"
            shift 2
            ;;
        -v|--validate)
            VALIDATE=true
            shift
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
if [ -z "$PLATFORM" ]; then
    log_error "Platform not specified"
    usage
fi

log_info "HIL Setup - Platform: $PLATFORM"

# Check platform connectivity
log_info "Checking platform connection..."
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${PLATFORM//-/_}_adapter.py" --check-connection

if [ $? -ne 0 ]; then
    log_error "Platform connection failed"
    exit 1
fi

log_info "Platform connection successful"

# Configure interfaces
if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    log_info "Configuring interfaces from: $CONFIG_FILE"
    python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${PLATFORM//-/_}_adapter.py" \
        --configure "$CONFIG_FILE"

    if [ $? -ne 0 ]; then
        log_error "Interface configuration failed"
        exit 1
    fi

    log_info "Interfaces configured successfully"
fi

# Load ECU model
if [ -n "$ECU" ]; then
    log_info "Loading ECU model: $ECU"

    # Find ECU model file
    ECU_MODEL=$(find "$PROJECT_ROOT/models" -name "*${ECU}*" -type f | head -1)

    if [ -z "$ECU_MODEL" ]; then
        log_warn "ECU model not found in models/ directory"
    else
        python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${PLATFORM//-/_}_adapter.py" \
            --load-ecu "$ECU_MODEL" --ecu-type "$ECU"

        if [ $? -ne 0 ]; then
            log_error "ECU model loading failed"
            exit 1
        fi

        log_info "ECU model loaded successfully"
    fi
fi

# Configure I/O channels
if [ -n "$CONFIG_FILE" ]; then
    log_info "Configuring I/O channels..."
    python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${PLATFORM//-/_}_adapter.py" \
        --configure-io "$CONFIG_FILE"

    if [ $? -ne 0 ]; then
        log_error "I/O configuration failed"
        exit 1
    fi

    log_info "I/O channels configured"
fi

# Load test scenario
if [ -n "$SCENARIO_FILE" ]; then
    if [ ! -f "$SCENARIO_FILE" ]; then
        log_error "Scenario file not found: $SCENARIO_FILE"
        exit 1
    fi

    log_info "Loading test scenario: $SCENARIO_FILE"
    python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${PLATFORM//-/_}_adapter.py" \
        --load-scenario "$SCENARIO_FILE"

    if [ $? -ne 0 ]; then
        log_error "Scenario loading failed"
        exit 1
    fi

    log_info "Test scenario loaded"
fi

# Validate platform readiness
if [ "$VALIDATE" = true ]; then
    log_info "Validating platform readiness..."
    python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${PLATFORM//-/_}_adapter.py" --validate

    if [ $? -ne 0 ]; then
        log_error "Platform validation failed"
        exit 1
    fi

    log_info "Platform validation successful"
fi

log_info "HIL setup complete"
log_info "Platform: $PLATFORM"
log_info "ECU: ${ECU:-N/A}"
log_info "Configuration: ${CONFIG_FILE:-N/A}"
log_info "Scenario: ${SCENARIO_FILE:-N/A}"

exit 0
