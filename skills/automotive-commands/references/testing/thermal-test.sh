#!/bin/bash
#
# Thermal Chamber Test Command
# Execute temperature cycling test with environmental chamber
#
# Usage: thermal-test.sh [OPTIONS]
#
# Options:
#   --ip IP                   Chamber IP address
#   --hot-temp C              Hot temperature in degC
#   --cold-temp C             Cold temperature in degC
#   --soak-time SECS          Soak time at each temperature in seconds
#   --cycles N                Number of temperature cycles
#   --ramp-rate C/MIN         Temperature ramp rate in degC/min
#   --humidity PCT            Humidity setpoint in %RH
#   --output FILE             Output CSV file
#   --help                    Show this help message

set -euo pipefail

# Default values
IP="192.168.1.50"
HOT_TEMP=60.0
COLD_TEMP=-20.0
SOAK_TIME=1800
CYCLES=10
RAMP_RATE=5.0
HUMIDITY=50.0
OUTPUT="thermal_cycle_log.csv"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ip) IP="$2"; shift 2 ;;
        --hot-temp) HOT_TEMP="$2"; shift 2 ;;
        --cold-temp) COLD_TEMP="$2"; shift 2 ;;
        --soak-time) SOAK_TIME="$2"; shift 2 ;;
        --cycles) CYCLES="$2"; shift 2 ;;
        --ramp-rate) RAMP_RATE="$2"; shift 2 ;;
        --humidity) HUMIDITY="$2"; shift 2 ;;
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
echo "Environmental Chamber Temperature Test"
echo "========================================="
echo "Chamber IP:         $IP"
echo "Hot Temperature:    ${HOT_TEMP}°C"
echo "Cold Temperature:   ${COLD_TEMP}°C"
echo "Soak Time:          ${SOAK_TIME}s ($(($SOAK_TIME / 60)) min)"
echo "Cycles:             $CYCLES"
echo "Ramp Rate:          ${RAMP_RATE}°C/min"
echo "Humidity:           ${HUMIDITY}%RH"
echo "Output File:        $OUTPUT"
echo "========================================="
echo

# Validate temperature range
if (( $(echo "$HOT_TEMP > 180" | bc -l) )); then
    echo "Error: Hot temperature exceeds 180°C limit"
    exit 1
fi

if (( $(echo "$COLD_TEMP < -40" | bc -l) )); then
    echo "Error: Cold temperature below -40°C limit"
    exit 1
fi

# Calculate estimated test time
RAMP_TIME=$(echo "scale=1; (($HOT_TEMP - $COLD_TEMP) / $RAMP_RATE) * 60" | bc)
CYCLE_TIME=$(echo "scale=1; ($RAMP_TIME * 2) + ($SOAK_TIME * 2)" | bc)
TOTAL_TIME=$(echo "scale=1; $CYCLE_TIME * $CYCLES" | bc)

echo "Estimated test duration:"
echo "  Per cycle: $(echo "scale=1; $CYCLE_TIME / 3600" | bc) hours"
echo "  Total:     $(echo "scale=1; $TOTAL_TIME / 3600" | bc) hours"
echo

read -p "Proceed with test? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled by user"
    exit 0
fi

# Create Python script
PYTHON_SCRIPT=$(mktemp /tmp/thermal_test_XXXXXX.py)
trap "rm -f $PYTHON_SCRIPT" EXIT

cat > "$PYTHON_SCRIPT" << 'EOF'
import sys
import time
import csv
from datetime import datetime

try:
    from pymodbus.client import ModbusTcpClient

    ip = sys.argv[1]
    hot_temp = float(sys.argv[2])
    cold_temp = float(sys.argv[3])
    soak_time = int(sys.argv[4])
    cycles = int(sys.argv[5])
    ramp_rate = float(sys.argv[6])
    humidity = float(sys.argv[7])
    output_file = sys.argv[8]

    print(f"Connecting to chamber at {ip}...")
    client = ModbusTcpClient(ip, port=502)

    if not client.connect():
        print(f"Error: Failed to connect to chamber at {ip}:502")
        print("Please check:")
        print("  1. Chamber is powered on")
        print("  2. IP address is correct")
        print("  3. Modbus TCP is enabled on chamber")
        print("  4. Network connectivity")
        sys.exit(1)

    print("Connected successfully")
    print()

    # Initialize CSV file
    csvfile = open(output_file, 'w', newline='')
    writer = csv.DictWriter(csvfile, fieldnames=[
        'timestamp', 'cycle', 'phase', 'setpoint_c', 'actual_c',
        'humidity_setpoint', 'humidity_actual', 'alarm'
    ])
    writer.writeheader()

    def read_temperature():
        """Read current chamber temperature via Modbus."""
        try:
            result = client.read_holding_registers(address=100, count=1)
            if not result.isError():
                return result.registers[0] / 10.0
        except:
            pass
        return 25.0  # Default

    def read_humidity():
        """Read current chamber humidity via Modbus."""
        try:
            result = client.read_holding_registers(address=102, count=1)
            if not result.isError():
                return result.registers[0] / 10.0
        except:
            pass
        return 50.0  # Default

    def set_temperature(temp):
        """Set chamber temperature setpoint."""
        value = int(temp * 10)
        client.write_register(address=200, value=value)
        print(f"Temperature setpoint: {temp}°C")

    def set_humidity(rh):
        """Set chamber humidity setpoint."""
        value = int(rh * 10)
        client.write_register(address=202, value=value)

    def wait_for_stable(target, tolerance=1.0, duration=60):
        """Wait until temperature is stable at target."""
        print(f"Waiting for temperature to reach {target}±{tolerance}°C...")

        stable_count = 0
        required_stable = duration // 6  # Must be stable for duration

        while stable_count < required_stable:
            current = read_temperature()
            humidity_actual = read_humidity()

            if abs(current - target) <= tolerance:
                stable_count += 1
            else:
                stable_count = 0

            print(f"  Current: {current:.1f}°C, Humidity: {humidity_actual:.1f}%RH "
                  f"[Stable: {stable_count}/{required_stable}]", end='\r')

            time.sleep(6)

        print()
        print(f"Temperature stable at {read_temperature():.1f}°C")

    # Main test loop
    print(f"Starting {cycles} temperature cycles...")
    print("=" * 60)

    try:
        # Set humidity
        set_humidity(humidity)

        for cycle in range(1, cycles + 1):
            print(f"\n{'='*60}")
            print(f"CYCLE {cycle}/{cycles}")
            print(f"{'='*60}")

            # HOT PHASE
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Ramping to HOT: {hot_temp}°C")
            set_temperature(hot_temp)
            wait_for_stable(hot_temp, tolerance=1.0, duration=60)

            print(f"Soaking at {hot_temp}°C for {soak_time}s ({soak_time//60} min)...")
            soak_start = time.time()

            while time.time() - soak_start < soak_time:
                temp = read_temperature()
                humidity_actual = read_humidity()

                writer.writerow({
                    'timestamp': datetime.now().isoformat(),
                    'cycle': cycle,
                    'phase': 'HOT_SOAK',
                    'setpoint_c': hot_temp,
                    'actual_c': temp,
                    'humidity_setpoint': humidity,
                    'humidity_actual': humidity_actual,
                    'alarm': False
                })

                elapsed = int(time.time() - soak_start)
                remaining = soak_time - elapsed
                print(f"  Temp: {temp:.1f}°C, RH: {humidity_actual:.1f}% "
                      f"[{elapsed}s / {soak_time}s - {remaining}s remaining]", end='\r')

                time.sleep(10)

            print()

            # COLD PHASE
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Ramping to COLD: {cold_temp}°C")
            set_temperature(cold_temp)
            wait_for_stable(cold_temp, tolerance=1.0, duration=60)

            print(f"Soaking at {cold_temp}°C for {soak_time}s ({soak_time//60} min)...")
            soak_start = time.time()

            while time.time() - soak_start < soak_time:
                temp = read_temperature()
                humidity_actual = read_humidity()

                writer.writerow({
                    'timestamp': datetime.now().isoformat(),
                    'cycle': cycle,
                    'phase': 'COLD_SOAK',
                    'setpoint_c': cold_temp,
                    'actual_c': temp,
                    'humidity_setpoint': humidity,
                    'humidity_actual': humidity_actual,
                    'alarm': False
                })

                elapsed = int(time.time() - soak_start)
                remaining = soak_time - elapsed
                print(f"  Temp: {temp:.1f}°C, RH: {humidity_actual:.1f}% "
                      f"[{elapsed}s / {soak_time}s - {remaining}s remaining]", end='\r')

                time.sleep(10)

            print()
            print(f"Cycle {cycle} complete")

    except KeyboardInterrupt:
        print("\n\nTest stopped by user")

    finally:
        # Return to ambient
        print("\nReturning to ambient (25°C)...")
        set_temperature(25.0)

        # Close CSV file
        csvfile.close()

        # Close Modbus connection
        client.close()

        print(f"\nData logged to {output_file}")
        print("Test complete!")

except ImportError:
    print("Error: pymodbus not installed")
    print("Please install: pip install pymodbus")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

python3 "$PYTHON_SCRIPT" "$IP" "$HOT_TEMP" "$COLD_TEMP" "$SOAK_TIME" "$CYCLES" "$RAMP_RATE" "$HUMIDITY" "$OUTPUT"
