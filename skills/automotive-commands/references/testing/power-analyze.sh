#!/bin/bash
#
# Power Analysis Command
# Measure battery power parameters using Yokogawa power analyzer
#
# Usage: power-analyze.sh [OPTIONS]
#
# Options:
#   --model MODEL         Power analyzer model (WT1800E, WT5000, WT3000E)
#   --address ADDR        VISA address (e.g., GPIB0::1::INSTR, TCPIP0::192.168.1.10::INSTR)
#   --channel CH          Channel number (1-N)
#   --voltage-range V     Voltage range in V
#   --current-range A     Current range in A
#   --integration         Start energy/charge integration
#   --duration SECS       Measurement duration in seconds
#   --output FILE         Output CSV file for data
#   --help                Show this help message

set -euo pipefail

# Default values
MODEL="WT1800E"
ADDRESS="GPIB0::1::INSTR"
CHANNEL=1
VOLTAGE_RANGE=300
CURRENT_RANGE=50
INTEGRATION=false
DURATION=60
OUTPUT="power_measurement.csv"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --address)
            ADDRESS="$2"
            shift 2
            ;;
        --channel)
            CHANNEL="$2"
            shift 2
            ;;
        --voltage-range)
            VOLTAGE_RANGE="$2"
            shift 2
            ;;
        --current-range)
            CURRENT_RANGE="$2"
            shift 2
            ;;
        --integration)
            INTEGRATION=true
            shift
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --help)
            grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate model
VALID_MODELS="WT1800E WT5000 WT3000E WT1600"
if [[ ! " $VALID_MODELS " =~ " $MODEL " ]]; then
    echo "Error: Invalid model '$MODEL'"
    echo "Supported models: $VALID_MODELS"
    exit 1
fi

echo "========================================="
echo "Yokogawa Power Analyzer Measurement"
echo "========================================="
echo "Model:          $MODEL"
echo "Address:        $ADDRESS"
echo "Channel:        $CHANNEL"
echo "Voltage Range:  ${VOLTAGE_RANGE}V"
echo "Current Range:  ${CURRENT_RANGE}A"
echo "Integration:    $INTEGRATION"
echo "Duration:       ${DURATION}s"
echo "Output File:    $OUTPUT"
echo "========================================="
echo

# Create Python script for measurement
PYTHON_SCRIPT=$(mktemp /tmp/power_analyze_XXXXXX.py)
trap "rm -f $PYTHON_SCRIPT" EXIT

cat > "$PYTHON_SCRIPT" << 'EOF'
import sys
import os

# Add tools path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'tools', 'adapters', 'testing'))

try:
    from yokogawa_adapter import YokogawaAdapter
    import time
    import csv
    from datetime import datetime

    # Parse command line arguments
    model = sys.argv[1]
    address = sys.argv[2]
    channel = int(sys.argv[3])
    voltage_range = float(sys.argv[4])
    current_range = float(sys.argv[5])
    integration = sys.argv[6] == 'true'
    duration = int(sys.argv[7])
    output_file = sys.argv[8]

    print(f"Initializing {model} adapter...")
    adapter = YokogawaAdapter(model=model, interface='pyvisa')

    if not adapter.is_available:
        print("Error: Power analyzer not available")
        print("Please check:")
        print("  1. PyVISA is installed: pip install pyvisa pyvisa-py")
        print("  2. VISA backend is available (NI-VISA or pyvisa-py)")
        print("  3. Instrument is connected and powered on")
        print("  4. VISA address is correct")
        sys.exit(1)

    # Configure channel
    print(f"Configuring channel {channel}...")
    config_result = adapter.execute('configure_channels', {
        'channel': channel,
        'voltage_range': voltage_range,
        'current_range': current_range,
        'mode': 'DC'
    })

    if not config_result['success']:
        print(f"Error: {config_result.get('error', 'Configuration failed')}")
        sys.exit(1)

    print(f"Channel configured: {voltage_range}V, {current_range}A")
    print(f"Measurement accuracy: ±{config_result['accuracy_pct']}%")
    print()

    # Start integration if requested
    if integration:
        print("Starting energy/charge integration...")
        integ_result = adapter.execute('start_integration', {
            'mode': 'CONTINUOUS'
        })
        if integ_result['success']:
            print("Integration started")
        print()

    # Perform continuous measurement
    print(f"Starting measurement for {duration} seconds...")
    print("Press Ctrl+C to stop early")
    print()

    measurements = []
    start_time = time.time()
    sample_count = 0

    try:
        while time.time() - start_time < duration:
            # Read power measurement
            result = adapter.execute('measure_power', {
                'visa_address': address,
                'channel': channel,
                'elements': ['V', 'I', 'P', 'S', 'Q', 'PF']
            })

            if result['success']:
                measurement = result['measurements']
                timestamp = datetime.now()

                measurements.append({
                    'timestamp': timestamp.isoformat(),
                    'voltage_v': measurement['V'],
                    'current_a': measurement['I'],
                    'power_w': measurement['P'],
                    'apparent_power_va': measurement['S'],
                    'reactive_power_var': measurement['Q'],
                    'power_factor': measurement['PF']
                })

                sample_count += 1

                # Print progress every 10 samples
                if sample_count % 10 == 0:
                    print(f"Sample {sample_count}: {measurement['V']:.2f}V, "
                          f"{measurement['I']:.2f}A, {measurement['P']:.1f}W, "
                          f"PF={measurement['PF']:.3f}")

            time.sleep(1.0)  # 1 Hz sampling

    except KeyboardInterrupt:
        print("\nMeasurement stopped by user")

    print()
    print(f"Measurement complete: {len(measurements)} samples collected")

    # Read integration if enabled
    if integration:
        print("\nReading integration results...")
        integ_result = adapter.execute('read_integration', {
            'channel': channel
        })

        if integ_result['success']:
            integ_data = integ_result['integration']
            print(f"Energy (charge): {integ_data['energy_wh_plus']:.2f} Wh")
            print(f"Energy (discharge): {integ_data['energy_wh_minus']:.2f} Wh")
            print(f"Net Energy: {integ_data['energy_wh']:.2f} Wh")
            print(f"Charge: {integ_data['charge_ah']:.3f} Ah")
            print(f"Integration Time: {integ_data['integration_time_s']:.1f} s")
            print(f"Efficiency: {integ_result['efficiency_pct']:.2f}%")

    # Export to CSV
    print(f"\nExporting data to {output_file}...")
    with open(output_file, 'w', newline='') as csvfile:
        if measurements:
            fieldnames = measurements[0].keys()
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(measurements)

    print(f"Data exported successfully: {len(measurements)} samples")
    print()
    print("Summary Statistics:")
    if measurements:
        voltages = [m['voltage_v'] for m in measurements]
        currents = [m['current_a'] for m in measurements]
        powers = [m['power_w'] for m in measurements]

        print(f"  Voltage: {min(voltages):.2f} - {max(voltages):.2f} V (avg: {sum(voltages)/len(voltages):.2f})")
        print(f"  Current: {min(currents):.2f} - {max(currents):.2f} A (avg: {sum(currents)/len(currents):.2f})")
        print(f"  Power:   {min(powers):.1f} - {max(powers):.1f} W (avg: {sum(powers)/len(powers):.1f})")

    print("\nMeasurement complete!")

except ImportError as e:
    print(f"Error: Required module not found: {e}")
    print("Please install: pip install pyvisa pyvisa-py")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

# Execute Python script
python3 "$PYTHON_SCRIPT" "$MODEL" "$ADDRESS" "$CHANNEL" "$VOLTAGE_RANGE" "$CURRENT_RANGE" "$INTEGRATION" "$DURATION" "$OUTPUT"
