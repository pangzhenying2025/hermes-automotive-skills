#!/usr/bin/env bash
# CAN Network Simulation Command
# Decode, encode, and replay CAN messages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

CAN network simulation and analysis

COMMANDS:
    decode LOG_FILE DBC_FILE     Decode CAN messages from log
    encode MSG_NAME DBC_FILE     Encode CAN message
    replay LOG_FILE              Replay CAN trace
    analyze LOG_FILE             Analyze bus load
    filter LOG_FILE              Filter messages

OPTIONS:
    -o, --output FILE       Output file
    -i, --ids IDS           Message ID filter (comma-separated)
    -s, --speed SPEED       Replay speed multiplier
    -h, --help              Show this help message

EXAMPLES:
    # Decode CAN log
    $(basename "$0") decode can_trace.asc vehicle.dbc -o decoded.csv

    # Encode message
    $(basename "$0") encode EngineStatus vehicle.dbc

    # Replay with 2x speed
    $(basename "$0") replay can_trace.blf --speed 2.0

    # Filter by message IDs
    $(basename "$0") filter can_trace.asc --ids 0x100,0x200,0x300

EOF
    exit 1
}

COMMAND=""
LOG_FILE=""
DBC_FILE=""
OUTPUT_FILE=""
MESSAGE_IDS=""
REPLAY_SPEED="1.0"

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -i|--ids)
            MESSAGE_IDS="$2"
            shift 2
            ;;
        -s|--speed)
            REPLAY_SPEED="$2"
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
    usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
    decode)
        if [[ $# -lt 2 ]]; then
            echo "Error: decode requires LOG_FILE and DBC_FILE"
            usage
        fi
        LOG_FILE="$1"
        DBC_FILE="$2"
        ;;
    encode)
        if [[ $# -lt 2 ]]; then
            echo "Error: encode requires MSG_NAME and DBC_FILE"
            usage
        fi
        MSG_NAME="$1"
        DBC_FILE="$2"
        ;;
    replay|analyze|filter)
        if [[ $# -lt 1 ]]; then
            echo "Error: $COMMAND requires LOG_FILE"
            usage
        fi
        LOG_FILE="$1"
        ;;
    *)
        echo "Error: Unknown command: $COMMAND"
        usage
        ;;
esac

echo "CAN Network Simulation"
echo "Command: $COMMAND"
[[ -n "$LOG_FILE" ]] && echo "Log file: $LOG_FILE"
[[ -n "$DBC_FILE" ]] && echo "DBC file: $DBC_FILE"

python3 - "$COMMAND" "$LOG_FILE" "$DBC_FILE" "$OUTPUT_FILE" "$MESSAGE_IDS" "$REPLAY_SPEED" <<'PYTHON_EOF'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.adapters.network.savvycan_adapter import SavvyCANAdapter

def main():
    command = sys.argv[1]
    log_file = sys.argv[2] if len(sys.argv) > 2 else ""
    dbc_file = sys.argv[3] if len(sys.argv) > 3 else ""
    output_file = sys.argv[4] if len(sys.argv) > 4 else ""
    message_ids_str = sys.argv[5] if len(sys.argv) > 5 else ""
    replay_speed = float(sys.argv[6]) if len(sys.argv) > 6 else 1.0

    adapter = SavvyCANAdapter()

    if command == "decode":
        if not log_file or not dbc_file:
            print("Error: decode requires log file and DBC file")
            sys.exit(1)

        print(f"Parsing DBC: {dbc_file}")
        messages_def = adapter.parse_dbc(Path(dbc_file))
        print(f"Loaded {len(messages_def)} message definitions")

        print(f"Reading CAN log: {log_file}")
        can_messages = adapter.read_log_file(Path(log_file), "asc")
        print(f"Read {len(can_messages)} CAN frames")

        print("Decoding messages...")
        decoded_count = 0
        for can_msg in can_messages[:10]:
            decoded = adapter.decode_message(can_msg, Path(dbc_file).stem)
            if decoded:
                print(f"ID 0x{can_msg.can_id:03X} @ {can_msg.timestamp:.3f}s:")
                for signal_name, signal_data in decoded.items():
                    print(f"  {signal_name}: {signal_data['value']:.2f} {signal_data['unit']}")
                decoded_count += 1

        print(f"Decoded {decoded_count} messages")

    elif command == "analyze":
        print(f"Analyzing CAN log: {log_file}")
        can_messages = adapter.read_log_file(Path(log_file), "asc")

        unique_ids = set(msg.can_id for msg in can_messages)
        print(f"Total messages: {len(can_messages)}")
        print(f"Unique IDs: {len(unique_ids)}")

        if can_messages:
            duration = can_messages[-1].timestamp - can_messages[0].timestamp
            avg_rate = len(can_messages) / duration if duration > 0 else 0
            print(f"Duration: {duration:.2f}s")
            print(f"Average rate: {avg_rate:.1f} msg/s")

    elif command == "filter":
        print(f"Filtering CAN log: {log_file}")
        can_messages = adapter.read_log_file(Path(log_file), "asc")

        if message_ids_str:
            filter_ids = [int(id_str.strip(), 0) for id_str in message_ids_str.split(',')]
            filtered = adapter.filter_messages(can_messages, message_ids=filter_ids)
        else:
            filtered = can_messages

        print(f"Filtered: {len(can_messages)} -> {len(filtered)} messages")

        if output_file:
            adapter.write_log_file(filtered, Path(output_file), "csv")
            print(f"Saved to: {output_file}")

    else:
        print(f"Command not implemented: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()
PYTHON_EOF

echo "✓ Operation completed"
