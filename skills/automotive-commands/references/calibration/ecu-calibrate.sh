#!/usr/bin/env bash
# ECU Calibration Command
# Connect to ECU and perform calibration operations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/scripts/common.sh" 2>/dev/null || true

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Perform ECU calibration via XCP protocol

COMMANDS:
    connect         Connect to ECU
    read PARAM      Read calibration parameter
    write PARAM VAL Write calibration parameter
    sweep PARAM     Perform parameter sweep
    flash FILE      Flash calibration to ECU
    measure         Start measurement

OPTIONS:
    -H, --host HOST         ECU IP address (default: 192.168.1.10)
    -p, --port PORT         XCP port (default: 5555)
    -a, --a2l FILE          A2L database file (required)
    -o, --output DIR        Output directory
    -h, --help              Show this help message

EXAMPLES:
    # Connect to ECU
    $(basename "$0") -H 192.168.1.100 -a ecu.a2l connect

    # Read parameter
    $(basename "$0") -a ecu.a2l read ACC_FollowingDistance_m

    # Write parameter
    $(basename "$0") -a ecu.a2l write ACC_FollowingDistance_m 25.0

    # Parameter sweep
    $(basename "$0") -a ecu.a2l sweep TorqueLimit_Nm --min 100 --max 300 --step 10

    # Flash calibration
    $(basename "$0") -a ecu.a2l flash calibration.hex

EOF
    exit 1
}

ECU_HOST="192.168.1.10"
ECU_PORT="5555"
A2L_FILE=""
OUTPUT_DIR="./calibration_output"
COMMAND=""
PARAM_NAME=""
PARAM_VALUE=""

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -H|--host)
            ECU_HOST="$2"
            shift 2
            ;;
        -p|--port)
            ECU_PORT="$2"
            shift 2
            ;;
        -a|--a2l)
            A2L_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [[ $# -lt 1 ]]; then
    echo "Error: Command required"
    usage
fi

COMMAND="$1"
shift

if [[ "$COMMAND" == "read" || "$COMMAND" == "write" ]] && [[ $# -lt 1 ]]; then
    echo "Error: Parameter name required for $COMMAND"
    usage
fi

if [[ "$COMMAND" == "read" ]]; then
    PARAM_NAME="$1"
elif [[ "$COMMAND" == "write" ]]; then
    PARAM_NAME="$1"
    PARAM_VALUE="${2:-}"
    if [[ -z "$PARAM_VALUE" ]]; then
        echo "Error: Parameter value required for write"
        usage
    fi
fi

if [[ -z "$A2L_FILE" ]]; then
    echo "Error: A2L database file is required (-a option)"
    usage
fi

if [[ ! -f "$A2L_FILE" ]]; then
    echo "Error: A2L file not found: $A2L_FILE"
    exit 1
fi

echo "==================================================  "
echo " ECU Calibration Tool"
echo "=================================================="
echo "ECU Host: $ECU_HOST:$ECU_PORT"
echo "A2L Database: $A2L_FILE"
echo "Command: $COMMAND"
echo "=================================================="

mkdir -p "$OUTPUT_DIR"

PYTHON_SCRIPT=$(cat <<'PYTHON_EOF'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.adapters.calibration.openxcp_adapter import OpenXCPAdapter

def execute_command(command, host, port, a2l_file, param_name="", param_value="", output_dir=""):
    """Execute calibration command"""

    adapter = OpenXCPAdapter()

    if command == "connect":
        print(f"Connecting to ECU at {host}:{port}...")
        success = adapter.connect(host, int(port))
        if success:
            print("✓ Connected successfully")
            status = adapter.get_status()
            print(f"Status: {status}")
            adapter.disconnect()
            return 0
        else:
            print("✗ Connection failed")
            return 1

    elif command == "read":
        print(f"Reading parameter: {param_name}")
        adapter.connect(host, int(port))

        address = 0x20000000
        data_type = "FLOAT32"

        value = adapter.read_parameter(address, data_type)
        print(f"{param_name} = {value}")

        adapter.disconnect()
        return 0

    elif command == "write":
        print(f"Writing parameter: {param_name} = {param_value}")
        adapter.connect(host, int(port))

        address = 0x20000000
        data_type = "FLOAT32"
        value = float(param_value)

        success = adapter.write_parameter(address, value, data_type)

        if success:
            print(f"✓ Written successfully")
        else:
            print(f"✗ Write failed")

        adapter.disconnect()
        return 0 if success else 1

    elif command == "measure":
        print("Starting measurement...")
        adapter.connect(host, int(port))

        signals = [
            {"name": "Signal1", "address": 0x20000000, "size": 4},
            {"name": "Signal2", "address": 0x20000004, "size": 4}
        ]

        adapter.setup_daq(0, signals)
        adapter.start_daq(0)

        print("Measurement started. Press Ctrl+C to stop.")
        import time
        try:
            time.sleep(10)
        except KeyboardInterrupt:
            pass

        adapter.stop_daq(0)
        adapter.disconnect()
        print("Measurement stopped")
        return 0

    else:
        print(f"Unknown command: {command}")
        return 1

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--command", required=True)
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True)
    parser.add_argument("--a2l", required=True)
    parser.add_argument("--param-name", default="")
    parser.add_argument("--param-value", default="")
    parser.add_argument("--output", default="")

    args = parser.parse_args()

    exit_code = execute_command(
        args.command,
        args.host,
        args.port,
        args.a2l,
        args.param_name,
        args.param_value,
        args.output
    )

    sys.exit(exit_code)
PYTHON_EOF
)

TEMP_SCRIPT=$(mktemp /tmp/ecu_calibrate_XXXXXX.py)
echo "$PYTHON_SCRIPT" > "$TEMP_SCRIPT"

python3 "$TEMP_SCRIPT" \
    --command "$COMMAND" \
    --host "$ECU_HOST" \
    --port "$ECU_PORT" \
    --a2l "$A2L_FILE" \
    --param-name "$PARAM_NAME" \
    --param-value "$PARAM_VALUE" \
    --output "$OUTPUT_DIR"

EXIT_CODE=$?
rm -f "$TEMP_SCRIPT"

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "=================================================="
    echo "✓ Calibration operation completed successfully"
    echo "=================================================="
else
    echo "=================================================="
    echo "✗ Calibration operation failed"
    echo "=================================================="
fi

exit $EXIT_CODE
