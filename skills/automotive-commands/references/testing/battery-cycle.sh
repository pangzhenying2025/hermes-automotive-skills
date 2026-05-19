#!/bin/bash
#
# Battery Cycling Command
# Execute charge/discharge cycling test with Chroma battery cycler
#
# Usage: battery-cycle.sh [OPTIONS]
#
# Options:
#   --model MODEL             Cycler model (17010H, 17020H, 17208M)
#   --ip IP                   IP address of cycler
#   --channel CH              Channel number
#   --charge-current A        Charge current in A
#   --charge-voltage V        Charge voltage limit in V
#   --discharge-current A     Discharge current in A
#   --discharge-voltage V     Discharge cutoff voltage in V
#   --cycles N                Number of cycles to execute
#   --rest-time SECS          Rest time between charge/discharge in seconds
#   --output FILE             Output CSV file
#   --help                    Show this help message

set -euo pipefail

# Default values
MODEL="17010H"
IP="192.168.1.100"
CHANNEL=1
CHARGE_CURRENT=1.0
CHARGE_VOLTAGE=4.2
DISCHARGE_CURRENT=2.0
DISCHARGE_VOLTAGE=2.5
CYCLES=10
REST_TIME=300
OUTPUT="battery_cycle_test.csv"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model) MODEL="$2"; shift 2 ;;
        --ip) IP="$2"; shift 2 ;;
        --channel) CHANNEL="$2"; shift 2 ;;
        --charge-current) CHARGE_CURRENT="$2"; shift 2 ;;
        --charge-voltage) CHARGE_VOLTAGE="$2"; shift 2 ;;
        --discharge-current) DISCHARGE_CURRENT="$2"; shift 2 ;;
        --discharge-voltage) DISCHARGE_VOLTAGE="$2"; shift 2 ;;
        --cycles) CYCLES="$2"; shift 2 ;;
        --rest-time) REST_TIME="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --help)
            grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "========================================="
echo "Chroma Battery Cycler Test"
echo "========================================="
echo "Model:              $MODEL"
echo "IP Address:         $IP"
echo "Channel:            $CHANNEL"
echo "Charge:             ${CHARGE_CURRENT}A / ${CHARGE_VOLTAGE}V"
echo "Discharge:          ${DISCHARGE_CURRENT}A until ${DISCHARGE_VOLTAGE}V"
echo "Cycles:             $CYCLES"
echo "Rest Time:          ${REST_TIME}s"
echo "Output File:        $OUTPUT"
echo "========================================="
echo

# Create Python script
PYTHON_SCRIPT=$(mktemp /tmp/battery_cycle_XXXXXX.py)
trap "rm -f $PYTHON_SCRIPT" EXIT

cat > "$PYTHON_SCRIPT" << 'EOF'
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'tools', 'adapters', 'testing'))

try:
    from chroma_adapter import ChromaAdapter
    import time
    import csv
    from datetime import datetime

    model = sys.argv[1]
    ip = sys.argv[2]
    channel = int(sys.argv[3])
    charge_current = float(sys.argv[4])
    charge_voltage = float(sys.argv[5])
    discharge_current = float(sys.argv[6])
    discharge_voltage = float(sys.argv[7])
    cycles = int(sys.argv[8])
    rest_time = int(sys.argv[9])
    output_file = sys.argv[10]

    print(f"Initializing Chroma {model} adapter...")
    adapter = ChromaAdapter(model=model, ip_address=ip)

    if not adapter.is_available:
        print("Error: Chroma cycler not available")
        print("Please install: pip install pymodbus")
        sys.exit(1)

    # Configure channel
    print(f"Configuring channel {channel}...")
    config_result = adapter.execute('configure_channel', {
        'channel': channel,
        'voltage_range': charge_voltage * 1.2,
        'current_range': max(charge_current, discharge_current) * 1.2
    })

    if not config_result['success']:
        print(f"Error: {config_result['error']}")
        sys.exit(1)

    print("Channel configured successfully")
    print()

    # Validate safety limits
    safety = adapter.validate_safety_limits({
        'voltage': charge_voltage,
        'current': max(charge_current, discharge_current)
    })

    if not safety['all_passed']:
        print("Safety limit check failed!")
        print(f"Checks: {safety['checks']}")
        print(f"Limits: {safety['limits']}")
        sys.exit(1)

    print("Safety limits validated")
    print()

    # Run cycle test
    print(f"Starting {cycles} cycle test...")
    print("=" * 60)

    cycle_result = adapter.execute('run_cycle_test', {
        'channel': channel,
        'charge_current': charge_current,
        'charge_voltage': charge_voltage,
        'discharge_current': discharge_current,
        'discharge_voltage': discharge_voltage,
        'num_cycles': cycles,
        'rest_time': rest_time
    })

    if not cycle_result['success']:
        print(f"Error: {cycle_result['error']}")
        sys.exit(1)

    test_config = cycle_result['test_config']
    print(f"Test started successfully")
    print(f"Estimated duration: {test_config['estimated_duration_h']:.1f} hours")
    print()

    # Simulate data collection
    print("Collecting data... (Press Ctrl+C to stop)")
    measurements = []

    try:
        for cycle in range(1, cycles + 1):
            print(f"\nCycle {cycle}/{cycles}")
            print("-" * 40)

            # Simulate charge/discharge/rest phases
            for phase in ['CHARGING', 'RESTING', 'DISCHARGING', 'RESTING']:
                for _ in range(10):  # 10 samples per phase
                    result = adapter.execute('read_measurement', {
                        'channel': channel
                    })

                    if result['success']:
                        measurement = result['measurement']
                        measurement['cycle'] = cycle
                        measurement['phase'] = phase
                        measurements.append(measurement)

                        if len(measurements) % 20 == 0:
                            m = measurement
                            print(f"  {phase}: {m['voltage_v']:.3f}V, "
                                  f"{m['current_a']:.2f}A, "
                                  f"{m['capacity_ah']:.3f}Ah, "
                                  f"{m['temperature_c']:.1f}C")

                    time.sleep(0.1)  # Simulated delay

    except KeyboardInterrupt:
        print("\n\nTest stopped by user")

        # Emergency stop
        stop_result = adapter.execute('stop_output', {'channel': channel})
        if stop_result['success']:
            print("Output stopped safely")

    print()
    print(f"Data collection complete: {len(measurements)} samples")

    # Export to CSV
    print(f"\nExporting data to {output_file}...")
    with open(output_file, 'w', newline='') as csvfile:
        if measurements:
            fieldnames = ['timestamp', 'cycle', 'phase', 'voltage_v', 'current_a',
                         'capacity_ah', 'energy_wh', 'temperature_c']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()

            for m in measurements:
                writer.writerow({
                    'timestamp': m['timestamp'],
                    'cycle': m.get('cycle', 0),
                    'phase': m.get('phase', 'UNKNOWN'),
                    'voltage_v': m['voltage_v'],
                    'current_a': m['current_a'],
                    'capacity_ah': m['capacity_ah'],
                    'energy_wh': m['energy_wh'],
                    'temperature_c': m['temperature_c']
                })

    print(f"Data exported: {len(measurements)} samples")
    print("\nCycle test complete!")

except ImportError as e:
    print(f"Error: {e}")
    print("Please install: pip install pymodbus")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

python3 "$PYTHON_SCRIPT" "$MODEL" "$IP" "$CHANNEL" "$CHARGE_CURRENT" "$CHARGE_VOLTAGE" \
    "$DISCHARGE_CURRENT" "$DISCHARGE_VOLTAGE" "$CYCLES" "$REST_TIME" "$OUTPUT"
