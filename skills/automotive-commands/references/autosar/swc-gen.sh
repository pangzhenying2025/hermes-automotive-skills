#!/usr/bin/env bash
# AUTOSAR SWC Generation Command
# Generate Software Component with ports and runnables

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/scripts/common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate AUTOSAR Classic Software Component

OPTIONS:
    -n, --name NAME         SWC name (required)
    -t, --type TYPE         SWC type (Application, SensorActuator, etc.)
    -p, --ports PORTS       Port definitions (JSON or YAML file)
    -r, --runnables LIST    Comma-separated runnable names
    -o, --output DIR        Output directory for ARXML
    -h, --help              Show this help message

EXAMPLES:
    # Generate basic SWC
    $(basename "$0") -n BatteryMonitor -t ApplicationSWC -o ./arxml

    # Generate SWC with ports from file
    $(basename "$0") -n EngineControl -p ports.yaml -r Init,Cyclic10ms,Cyclic100ms

    # Full example with all options
    $(basename "$0") --name VehicleSpeed --type SensorActuatorSWC \\
        --ports ports.json --runnables Init,Process --output ./output

EOF
    exit 1
}

SWC_NAME=""
SWC_TYPE="ApplicationSWC"
PORTS_FILE=""
RUNNABLES=""
OUTPUT_DIR="./autosar_output"

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            SWC_NAME="$2"
            shift 2
            ;;
        -t|--type)
            SWC_TYPE="$2"
            shift 2
            ;;
        -p|--ports)
            PORTS_FILE="$2"
            shift 2
            ;;
        -r|--runnables)
            RUNNABLES="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            ;;
    esac
done

if [[ -z "$SWC_NAME" ]]; then
    echo "Error: SWC name is required"
    usage
fi

log_info "Generating AUTOSAR SWC: $SWC_NAME"

mkdir -p "$OUTPUT_DIR"

PYTHON_SCRIPT=$(cat <<'PYTHON_EOF'
import sys
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.adapters.autosar.tresos_adapter import TresosAdapter

def generate_swc(name, swc_type, ports_file, runnables, output_dir):
    """Generate AUTOSAR SWC"""

    adapter = TresosAdapter()
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    arxml_file = output_path / f"{name}.arxml"

    arxml_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<AUTOSAR xsi:schemaLocation="http://autosar.org/schema/r4.0 AUTOSAR_4-2-2.xsd"
         xmlns="http://autosar.org/schema/r4.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>ComponentTypes</SHORT-NAME>
      <ELEMENTS>
        <{swc_type}>
          <SHORT-NAME>{name}</SHORT-NAME>
          <PORTS>
            <!-- Ports will be added here -->
          </PORTS>
          <INTERNAL-BEHAVIORS>
            <SWC-INTERNAL-BEHAVIOR>
              <SHORT-NAME>{name}_InternalBehavior</SHORT-NAME>
              <EVENTS>
"""

    if runnables:
        runnable_list = runnables.split(',')
        for runnable in runnable_list:
            runnable = runnable.strip()
            arxml_content += f"""                <TIMING-EVENT>
                  <SHORT-NAME>TimingEvent_{runnable}</SHORT-NAME>
                  <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">/{name}_InternalBehavior/{runnable}</START-ON-EVENT-REF>
                  <PERIOD>0.01</PERIOD>
                </TIMING-EVENT>
"""

    arxml_content += f"""              </EVENTS>
              <RUNNABLES>
"""

    if runnables:
        for runnable in runnable_list:
            runnable = runnable.strip()
            arxml_content += f"""                <RUNNABLE-ENTITY>
                  <SHORT-NAME>{runnable}</SHORT-NAME>
                  <MINIMUM-START-INTERVAL>0.0</MINIMUM-START-INTERVAL>
                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>
                  <SYMBOL>{runnable}</SYMBOL>
                </RUNNABLE-ENTITY>
"""

    arxml_content += f"""              </RUNNABLES>
            </SWC-INTERNAL-BEHAVIOR>
          </INTERNAL-BEHAVIORS>
        </{swc_type}>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
"""

    arxml_file.write_text(arxml_content)

    print(f"Generated SWC ARXML: {arxml_file}")
    print(f"SWC Name: {name}")
    print(f"SWC Type: {swc_type}")
    if runnables:
        print(f"Runnables: {', '.join(runnable_list)}")

    return str(arxml_file)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--name", required=True)
    parser.add_argument("--type", default="ApplicationSWC")
    parser.add_argument("--ports", default="")
    parser.add_argument("--runnables", default="")
    parser.add_argument("--output", required=True)

    args = parser.parse_args()

    result = generate_swc(
        args.name,
        args.type,
        args.ports,
        args.runnables,
        args.output
    )

    sys.exit(0)
PYTHON_EOF
)

TEMP_SCRIPT=$(mktemp /tmp/swc_gen_XXXXXX.py)
echo "$PYTHON_SCRIPT" > "$TEMP_SCRIPT"

python3 "$TEMP_SCRIPT" \
    --name "$SWC_NAME" \
    --type "$SWC_TYPE" \
    --ports "$PORTS_FILE" \
    --runnables "$RUNNABLES" \
    --output "$OUTPUT_DIR"

EXIT_CODE=$?
rm -f "$TEMP_SCRIPT"

if [[ $EXIT_CODE -eq 0 ]]; then
    log_success "SWC generation completed successfully"
    log_info "Output directory: $OUTPUT_DIR"
else
    log_error "SWC generation failed"
    exit 1
fi

exit 0
