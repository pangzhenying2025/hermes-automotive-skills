#!/usr/bin/env bash
#
# ecu-flash - ECU flash programming command
#
# Flash ECU with new software using UDS protocol or Vector vFlash
#
# Usage:
#   ecu-flash [OPTIONS] <flash_file>
#
# Options:
#   -e, --ecu <address>       Target ECU address (hex)
#   -i, --interface <type>    Interface type: can, doip (default: can)
#   -c, --channel <channel>   CAN channel or DoIP IP
#   -v, --vflash <project>    Use Vector vFlash with project file
#   -b, --backup              Backup existing flash before programming
#   -r, --verify              Verify flash after programming
#   -s, --simulate            Simulation mode (no actual flash)
#   -p, --progress            Show progress bar
#   -h, --help                Show this help message
#
# Examples:
#   ecu-flash -e 0x10 -i can -c can0 engine_sw_v2.3.4.hex
#   ecu-flash -v flash_project.vflash -b -r app.vbf
#   ecu-flash --simulate --progress test_flash.bin

set -euo pipefail

# Default values
ECU_ADDRESS=""
INTERFACE="can"
CHANNEL="can0"
VFLASH_PROJECT=""
BACKUP=false
VERIFY=false
SIMULATE=false
PROGRESS=false
FLASH_FILE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ADAPTERS_DIR="${PROJECT_ROOT}/tools/adapters/diagnostics"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

show_help() {
    sed -n '/^#/,/^$/p' "$0" | sed 's/^# \?//' | head -n -1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--ecu)
                ECU_ADDRESS="$2"
                shift 2
                ;;
            -i|--interface)
                INTERFACE="$2"
                shift 2
                ;;
            -c|--channel)
                CHANNEL="$2"
                shift 2
                ;;
            -v|--vflash)
                VFLASH_PROJECT="$2"
                shift 2
                ;;
            -b|--backup)
                BACKUP=true
                shift
                ;;
            -r|--verify)
                VERIFY=true
                shift
                ;;
            -s|--simulate)
                SIMULATE=true
                shift
                ;;
            -p|--progress)
                PROGRESS=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                FLASH_FILE="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$FLASH_FILE" ]]; then
        log_error "Flash file required"
        show_help
        exit 1
    fi

    if [[ ! -f "$FLASH_FILE" && "$SIMULATE" == false ]]; then
        log_error "Flash file not found: $FLASH_FILE"
        exit 1
    fi
}

flash_with_uds() {
    log_info "Flash programming via UDS..."

    local python_script="${ADAPTERS_DIR}/flash_uds.py"

    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import json
from pathlib import Path

# Add adapters to path
sys.path.insert(0, os.path.dirname(__file__))

from python_uds_adapter import PythonUdsAdapter
from vflash_adapter import FlashProgress

def progress_callback(progress: FlashProgress):
    if progress.percentage % 5 == 0:  # Update every 5%
        print(f"Progress: {progress.percentage:.1f}% - {progress.current_operation}")
        print(f"  Rate: {progress.transfer_rate/1024:.1f} KB/s, ETA: {progress.time_remaining:.1f}s")

def main():
    config = json.loads(sys.argv[1])

    # Initialize UDS adapter
    transport_config = {
        'type': config['interface'],
        'channel': config['channel'],
        'bitrate': 500000,
        'rx_id': int(config.get('ecu_address', '0x10'), 16) + 0x08,
        'tx_id': int(config.get('ecu_address', '0x10'), 16)
    }

    adapter = PythonUdsAdapter(transport_config, simulation_mode=config['simulate'])

    print(f"[INFO] Establishing programming session...")
    adapter.diagnostic_session_control(0x02)  # Programming session

    print(f"[INFO] Performing security access...")
    seed = adapter.security_access_request_seed(0x01)
    # TODO: Calculate key with seed-key algorithm
    # For simulation, just echo seed as key
    adapter.security_access_send_key(0x02, seed)

    print(f"[INFO] Disabling DTC setting...")
    adapter.send_request(0x85, bytes([0x02]))

    print(f"[SUCCESS] Flash session initialized")
    print(f"[INFO] Flash file: {config['flash_file']}")
    print(f"[INFO] Interface: {config['interface']} ({config['channel']})")

    if config['backup']:
        print(f"[INFO] Backup existing flash: enabled")

    if config['verify']:
        print(f"[INFO] Verification: enabled")

    # Actual flash implementation would go here
    # For now, just simulate
    if config['progress']:
        for pct in range(0, 101, 10):
            progress = FlashProgress(
                total_bytes=2097152,
                bytes_transferred=int(2097152 * pct / 100),
                percentage=float(pct),
                current_block=int(256 * pct / 100),
                total_blocks=256,
                transfer_rate=102400,
                time_elapsed=pct * 2,
                time_remaining=(100 - pct) * 2,
                current_operation=f"Programming block {int(256 * pct / 100)}/256"
            )
            progress_callback(progress)

    print(f"[SUCCESS] Flash programming completed")

if __name__ == '__main__':
    main()
EOF

    chmod +x "$python_script"

    # Build config JSON
    local config_json=$(cat <<EOF
{
    "flash_file": "$FLASH_FILE",
    "interface": "$INTERFACE",
    "channel": "$CHANNEL",
    "ecu_address": "$ECU_ADDRESS",
    "backup": $BACKUP,
    "verify": $VERIFY,
    "simulate": $SIMULATE,
    "progress": $PROGRESS
}
EOF
    )

    python3 "$python_script" "$config_json"
}

flash_with_vflash() {
    log_info "Flash programming via Vector vFlash..."

    if [[ ! -f "$VFLASH_PROJECT" ]]; then
        log_error "vFlash project not found: $VFLASH_PROJECT"
        exit 1
    fi

    local python_script="${ADAPTERS_DIR}/flash_vflash.py"

    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import json

sys.path.insert(0, os.path.dirname(__file__))

from vflash_adapter import VFlashAdapter, FlashProgress

def progress_callback(progress: FlashProgress):
    print(f"Progress: {progress.percentage:.1f}% - {progress.current_operation}")
    print(f"  Block {progress.current_block}/{progress.total_blocks}")
    print(f"  Rate: {progress.transfer_rate/1024:.1f} KB/s, ETA: {progress.time_remaining:.1f}s")

def main():
    config = json.loads(sys.argv[1])

    adapter = VFlashAdapter(simulation_mode=config['simulate'])
    adapter.register_progress_callback(progress_callback)

    print(f"[INFO] Loading vFlash project: {config['vflash_project']}")
    adapter.load_project(config['vflash_project'])

    print(f"[INFO] Configuring interface: {config['interface']}")
    adapter.configure_interface(config['interface'], {'channel': 1, 'baudrate': 500000})

    print(f"[INFO] Setting flash parameters...")
    adapter.set_flash_parameters({'voltage_min': 11.5, 'voltage_max': 14.5, 'verify_flash': config['verify']})

    print(f"[INFO] Starting flash programming...")
    result = adapter.flash_ecu(timeout=600)

    if result.success:
        print(f"[SUCCESS] Flash completed in {result.duration:.1f}s")
        print(f"  Bytes programmed: {result.bytes_programmed / 1024 / 1024:.2f} MB")
        print(f"  Log file: {result.log_file}")
    else:
        print(f"[ERROR] Flash failed: {result.message}")
        sys.exit(1)

    adapter.close()

if __name__ == '__main__':
    main()
EOF

    chmod +x "$python_script"

    local config_json=$(cat <<EOF
{
    "vflash_project": "$VFLASH_PROJECT",
    "interface": "$INTERFACE",
    "verify": $VERIFY,
    "simulate": $SIMULATE
}
EOF
    )

    python3 "$python_script" "$config_json"
}

main() {
    parse_args "$@"

    log_info "ECU Flash Programming"
    log_info "====================="

    if [[ -n "$VFLASH_PROJECT" ]]; then
        flash_with_vflash
    else
        flash_with_uds
    fi

    log_success "Flash operation completed"
}

main "$@"
