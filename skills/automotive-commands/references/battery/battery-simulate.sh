#!/bin/bash
# Battery Simulation using PyBaMM
# Usage: ./battery-simulate.sh [chemistry] [test_type]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
CHEMISTRY="${1:-NMC}"
TEST_TYPE="${2:-discharge}"
VENV_PATH="$PROJECT_ROOT/.venv"

echo "=========================================="
echo "Battery Simulation with PyBaMM"
echo "=========================================="
echo "Chemistry: $CHEMISTRY"
echo "Test Type: $TEST_TYPE"
echo ""

# Activate virtual environment
if [ -d "$VENV_PATH" ]; then
    source "$VENV_PATH/bin/activate"
    echo "Virtual environment activated"
else
    echo "Warning: Virtual environment not found at $VENV_PATH"
fi

# Check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    python3 -c "import pybamm, numpy, matplotlib" 2>/dev/null || {
        echo "Error: Missing dependencies. Install with:"
        echo "  pip install pybamm numpy matplotlib"
        exit 1
    }
    echo "Dependencies OK"
}

# Run simulation
run_simulation() {
    echo ""
    echo "Starting battery simulation..."

    export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"

    python3 <<EOF
import sys
sys.path.insert(0, '$PROJECT_ROOT')

from tools.adapters.battery.pybamm_adapter import PyBaMMAdapter, BatteryChemistry, ModelType
import numpy as np
import matplotlib.pyplot as plt

def main():
    chemistry = BatteryChemistry['$CHEMISTRY']
    test_type = '$TEST_TYPE'

    print(f"Initializing {chemistry.value} battery model...")

    # Initialize adapter
    adapter = PyBaMMAdapter(
        chemistry=chemistry,
        model_type=ModelType.SPMe
    )

    # Set cell parameters (50 Ah cell)
    adapter.set_cell_parameters(capacity_ah=50.0)

    if test_type == 'discharge':
        print("\nRunning constant current discharge test (1C rate)...")
        result = adapter.simulate_constant_current(
            current_a=50.0,  # 1C discharge
            duration_s=3600,
            initial_soc=1.0,
            cutoff_voltage_v=3.0
        )

        print(f"\nDischarge Results:")
        print(f"  Capacity: {result.capacity_ah:.2f} Ah")
        print(f"  Energy: {result.energy_wh:.2f} Wh")
        print(f"  Average Voltage: {result.average_voltage_v:.3f} V")
        print(f"  Final Temperature: {result.temperature_c[-1]:.1f}°C")
        print(f"  Duration: {result.time_s[-1]/60:.1f} minutes")

    elif test_type == 'charge':
        print("\nRunning CC-CV charge test (1C rate)...")
        result = adapter.simulate_cccv_charge(
            charge_current_a=-50.0,  # 1C charge
            target_voltage_v=4.2,
            cutoff_current_a=2.5,  # C/20 cutoff
            initial_soc=0.0
        )

        print(f"\nCharge Results:")
        print(f"  Capacity: {result.capacity_ah:.2f} Ah")
        print(f"  Energy: {result.energy_wh:.2f} Wh")
        print(f"  Charge Time: {result.time_s[-1]/60:.1f} minutes")
        print(f"  Final Temperature: {result.temperature_c[-1]:.1f}°C")

    elif test_type == 'ocv':
        print("\nGenerating OCV curve...")
        soc_points = np.linspace(0, 1, 21)
        soc_values, ocv_values = adapter.get_ocv_curve(soc_points=soc_points)

        print(f"\nOCV Curve:")
        print("SOC (%) | OCV (V)")
        print("-" * 25)
        for soc, ocv in zip(soc_values, ocv_values):
            print(f"{soc*100:6.1f}  | {ocv:7.4f}")

        # Plot OCV curve
        plt.figure(figsize=(10, 6))
        plt.plot(soc_values * 100, ocv_values, 'b-', linewidth=2)
        plt.xlabel('State of Charge (%)')
        plt.ylabel('Open Circuit Voltage (V)')
        plt.title(f'{chemistry.value} Battery OCV Curve')
        plt.grid(True)
        plt.tight_layout()
        plt.savefig('$PROJECT_ROOT/battery_ocv_curve.png', dpi=150)
        print(f"\nOCV curve saved to battery_ocv_curve.png")

    elif test_type == 'cycle':
        print("\nRunning charge-discharge cycle...")

        # Discharge
        print("  Phase 1: Discharge at 1C...")
        result_discharge = adapter.simulate_constant_current(
            current_a=50.0,
            duration_s=3600,
            initial_soc=1.0,
            cutoff_voltage_v=3.0
        )

        # Charge
        print("  Phase 2: Charge at 1C CC-CV...")
        result_charge = adapter.simulate_cccv_charge(
            charge_current_a=-50.0,
            target_voltage_v=4.2,
            cutoff_current_a=2.5,
            initial_soc=0.0
        )

        print(f"\nCycle Results:")
        print(f"  Discharge:")
        print(f"    Capacity: {result_discharge.capacity_ah:.2f} Ah")
        print(f"    Energy: {result_discharge.energy_wh:.2f} Wh")
        print(f"  Charge:")
        print(f"    Capacity: {result_charge.capacity_ah:.2f} Ah")
        print(f"    Energy: {result_charge.energy_wh:.2f} Wh")
        print(f"  Round-trip efficiency: {(result_discharge.energy_wh / result_charge.energy_wh) * 100:.1f}%")

    else:
        print(f"Unknown test type: {test_type}")
        print("Valid types: discharge, charge, ocv, cycle")
        return 1

    # Plot results
    if test_type in ['discharge', 'charge']:
        fig, axes = plt.subplots(3, 1, figsize=(12, 10))

        # Voltage
        axes[0].plot(result.time_s / 60, result.voltage_v, 'b-', linewidth=2)
        axes[0].set_xlabel('Time (minutes)')
        axes[0].set_ylabel('Voltage (V)')
        axes[0].set_title(f'{chemistry.value} Battery {test_type.capitalize()} - Voltage')
        axes[0].grid(True)

        # Current
        axes[1].plot(result.time_s / 60, result.current_a, 'r-', linewidth=2)
        axes[1].set_xlabel('Time (minutes)')
        axes[1].set_ylabel('Current (A)')
        axes[1].set_title('Current')
        axes[1].grid(True)

        # Temperature
        axes[2].plot(result.time_s / 60, result.temperature_c, 'g-', linewidth=2)
        axes[2].set_xlabel('Time (minutes)')
        axes[2].set_ylabel('Temperature (°C)')
        axes[2].set_title('Temperature')
        axes[2].grid(True)

        plt.tight_layout()
        filename = f'$PROJECT_ROOT/battery_{test_type}_results.png'
        plt.savefig(filename, dpi=150)
        print(f"\nResults plotted to {filename}")

    print("\nSimulation complete!")
    return 0

if __name__ == '__main__':
    exit(main())
EOF
}

# Main execution
main() {
    check_dependencies
    run_simulation
}

main
