# HIL Testing - Detailed Implementation Guide

## dSPACE SCALEXIO Setup Guide

### Hardware Configuration

**Step 1: Rack Assembly**
```
SCALEXIO Rack Configuration:
Slot 1: DS6001 Processor Board (QNX Real-Time OS)
Slot 2: DS2655 FPGA Board (high-speed I/O processing)
Slot 3: DS2655_DIOMTDAC Multi-I/O Board
        - 32 digital inputs/outputs
        - 16 analog inputs (16-bit)
        - 8 analog outputs (16-bit)
Slot 4: DS6121 CAN/CAN FD MultiMessage Board (8 CAN channels)
Slot 5: DS2004 A/D Board (32 analog inputs, high-speed sampling)
Slot 6: Empty (expansion)

Power Supply: PS6002 (redundant supply recommended for 24/7 operation)
```

**Step 2: I/O Wiring**
```
Breakout Box Connections:

Wheel Speed Sensors (FL/FR/RL/RR):
  DS2655 Digital Out Ch 0-3 → Frequency generators (0-10 kHz)
  Formula: Freq [Hz] = Speed [km/h] × Pulses_per_km / 3600
  Example: 100 km/h, 4000 pulses/km = 111 Hz

Accelerator Pedal Position:
  DS2655 Analog Out Ch 0 → 0-5V → ECU ADC Pin 15
  0V = 0% pedal, 5V = 100% pedal

Brake Pressure:
  DS2655 Analog Out Ch 1 → 0.5-4.5V → ECU ADC Pin 20
  0.5V = 0 bar, 4.5V = 200 bar

CAN Bus:
  DS6121 CAN Ch 0 → ECU CAN-H/CAN-L (120Ω termination)
  Speed: 500 kbps
```

**Step 3: Network Configuration**
```bash
# Assign IP to SCALEXIO
# dSPACE ConfigurationDesk → Platform Manager
SCALEXIO IP: 192.168.1.10
Automation PC IP: 192.168.1.100
Subnet: 255.255.255.0

# Test connection
ping 192.168.1.10
```

### Model Compilation (Simulink → SCALEXIO)

**Step 1: Prepare Simulink Model**
```matlab
% vehicle_dynamics_model.slx
% Sampling time: 1ms (1 kHz)
% Solver: Fixed-step, ode4 (Runge-Kutta)

% Model structure:
% Inputs: Throttle, Brake, Steering
% Outputs: Vehicle speed, Wheel speeds (4x), Yaw rate

% Add Simulink blocks:
% - Vehicle Body block (from dSPACE ASM library)
% - Tire Model block (Magic Formula)
% - Engine block (lookup table: Torque vs RPM, throttle)
```

**Step 2: Configure Build**
```matlab
% MATLAB Command Window
configSet = getActiveConfigSet(gcs);

% Set target: dSPACE SCALEXIO
set_param(configSet, 'SystemTargetFile', 'rti1401.tlc');
set_param(configSet, 'TemplateMakefile', 'rti_vc.tmf');

% Real-time constraints
set_param(configSet, 'FixedStep', '0.001');  % 1ms
set_param(configSet, 'SolverType', 'Fixed-step');
set_param(configSet, 'Solver', 'ode4');

% Build model
rtwbuild(gcs);
```

**Step 3: Download to SCALEXIO**
```
dSPACE ControlDesk:
1. File → Open Application → vehicle_dynamics_model.sdf
2. Platform → Download to Hardware (DS6001)
3. Wait for compilation (2-5 minutes for typical model)
4. Status: "Application running" → Ready for testing
```

### ControlDesk Instrumentation

**Create Virtual Instrumentation Panel**:
```
ControlDesk Layout:

┌────────────────────────────────────────────┐
│  Inputs (Stimuli)                          │
│  [Slider] Throttle: 0-100%                 │
│  [Slider] Brake: 0-100%                    │
│  [Slider] Steering: -540° to +540°         │
│  [Button] Emergency Stop                   │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│  Outputs (Measurements)                    │
│  [Gauge] Vehicle Speed: 0-200 km/h         │
│  [Plotter] Wheel Speeds (4 traces)         │
│  [Plotter] Yaw Rate: -50 to +50 deg/s      │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│  ECU Monitoring                            │
│  [LED] ECU Power: ON/OFF                   │
│  [Value] CAN Message Count: 12345          │
│  [Table] DTCs: P0500, C1234                │
└────────────────────────────────────────────┘
```

**Variable Mapping**:
```
ControlDesk → Experiment

Input Variables (Host → SCALEXIO):
  Slider "Throttle" → Model/Inputs/Throttle_pct
  Slider "Brake" → Model/Inputs/Brake_pct

Output Variables (SCALEXIO → Host):
  Model/Outputs/VehicleSpeed_kph → Gauge "Vehicle Speed"
  Model/Outputs/WheelSpeed_FL_kph → Plotter "FL trace"
```

### AutomationDesk Test Scripting

**Test Case Structure**:
```python
# AutomationDesk Test Case: ESC Intervention Test
# Requirement: SYS-ESC-042 (ESC activates on wheel slip > 20%)

def test_esc_intervention():
    # Preconditions
    set_vehicle_speed(100)  # km/h
    set_road_friction(0.3)  # Wet road (mu = 0.3)
    wait_stable(5.0)  # Wait 5 seconds for steady-state

    # Stimulus: Apply braking while cornering
    set_steering_angle(90)  # degrees (sharp left turn)
    set_brake_pressure(100)  # bar (hard braking)

    # Wait for ESC activation
    wait(0.5)  # ESC should activate within 500ms

    # Verification
    assert_true(ecu.esc_active(), "ESC should be active")
    assert_less_than(wheel_slip_FL(), 25, "FL wheel slip < 25%")
    assert_less_than(wheel_slip_FR(), 25, "FR wheel slip < 25%")

    # Check brake modulation
    assert_true(brake_pressure_FL() < 100, "FL brake modulated")

    # Cleanup
    set_brake_pressure(0)
    set_steering_angle(0)
    wait_stable(5.0)
```

**AutomationDesk API (Python)**:
```python
import automationdesk as ad

# Connect to SCALEXIO
ad.connect('192.168.1.10')

# Load application
ad.load_application('vehicle_dynamics_model.sdf')

# Set variable
ad.set_variable('Model/Inputs/Throttle_pct', 50.0)

# Read variable
speed = ad.get_variable('Model/Outputs/VehicleSpeed_kph')
print(f"Vehicle speed: {speed} km/h")

# Start/stop simulation
ad.start_simulation()
ad.stop_simulation()

# CAN message handling
can_msg = ad.can_read(channel=0, can_id=0x123)
print(f"CAN 0x123 data: {can_msg.data}")

ad.can_write(channel=0, can_id=0x456, data=[0x12, 0x34, 0x56, 0x78])
```

## NI VeriStand Alternative

### Hardware Setup (NI PXI)

**Chassis Configuration**:
```
NI PXIe-1085 Chassis (18-slot)
Slot 1: PXI-8880 Controller (Intel i7, Windows 10 / NI Linux RT)
Slot 2: PXI-6363 (32 AI, 4 AO, 48 DIO)
Slot 3: PXI-6289 (32 AI high-speed, 500 kS/s)
Slot 4: PXI-8512 (2 CAN ports)
Slot 5: PXI-8531 (1 LIN port)
Slot 6-18: Empty (expansion)
```

### VeriStand Project Setup

**Step 1: Create System Definition**:
```
NI VeriStand System Explorer:

1. File → New System Definition
2. Add Hardware:
   - Targets → Add → PXI-8880
   - Chassis → Add → PXIe-1085
   - Devices → Add → PXI-6363, PXI-8512
3. Configure I/O Channels:
   - PXI-6363/AI0 → "Throttle_Sensor_V" (0-5V)
   - PXI-6363/AO0 → "Wheel_Speed_FL_V" (0-10V)
   - PXI-8512/CAN0 → "VehicleCAN" (500 kbps)
```

**Step 2: Import Simulink Model**:
```
1. Models → Add → Import from Simulink
2. Select: vehicle_dynamics.slx
3. Build for VeriStand Target:
   - Solver: Fixed-step, 1ms
   - Code generation: Embedded Coder
4. Compile and upload to PXI controller
```

**Step 3: Map Signals**:
```
System Mapping:

Hardware → Model:
  PXI-6363/AI0 (Throttle_Sensor_V) → vehicle_dynamics/Inputs/Throttle

Model → Hardware:
  vehicle_dynamics/Outputs/WheelSpeed_FL → PXI-6363/AO0

Model → CAN:
  vehicle_dynamics/Outputs/VehicleSpeed → CAN Msg 0x123 Signal "Speed"
```

### Python API for Test Automation

```python
from niveristand import nivs_rt_sequence

# Connect to VeriStand
session = nivs_rt_sequence.create_session('localhost')

# Set channel value
session.set_channel_value('Throttle_Sensor_V', 2.5)  # 50% throttle

# Read channel value
speed = session.get_channel_value('VehicleSpeed_kph')
print(f"Speed: {speed} km/h")

# Wait for condition
session.wait_until_channel_equals('ESC_Active', True, timeout=5.0)

# Record data
session.start_data_logging('esc_test_001.tdms')
session.run_test_sequence()
session.stop_data_logging()
```

## Plant Model Development (Simulink)

### Simple Engine Model

```matlab
% Engine torque lookup table
% Inputs: RPM, Throttle (0-100%)
% Output: Torque (Nm)

RPM_breakpoints = [500, 1000, 2000, 3000, 4000, 5000, 6000];
Throttle_breakpoints = [0, 25, 50, 75, 100];

Torque_map = [
    % RPM:  500  1000  2000  3000  4000  5000  6000
    [   10,   20,   40,   60,   70,   65,   50];  % Throttle 0%
    [   30,   60,  120,  180,  210,  195,  150];  % Throttle 25%
    [   50,  100,  200,  300,  350,  325,  250];  % Throttle 50%
    [   70,  140,  280,  420,  490,  455,  350];  % Throttle 75%
    [   90,  180,  360,  540,  630,  585,  450];  % Throttle 100%
];

% In Simulink: 2-D Lookup Table block
% Row input: Throttle
% Column input: RPM
% Table data: Torque_map
```

### Vehicle Dynamics Model

```matlab
% Longitudinal dynamics (simple)
% F_drive - F_drag - F_roll = m × a

% Parameters
m = 1500;  % Vehicle mass (kg)
Cd = 0.3;  % Drag coefficient
A = 2.5;   % Frontal area (m^2)
Cr = 0.015; % Rolling resistance coefficient
g = 9.81;  % Gravity (m/s^2)
rho = 1.225; % Air density (kg/m^3)

% Forces
F_drive = Torque × gear_ratio / wheel_radius;
F_drag = 0.5 × rho × Cd × A × v^2;
F_roll = Cr × m × g;

% Acceleration
a = (F_drive - F_drag - F_roll) / m;

% Velocity (integrate acceleration)
v = integral(a, dt);

% In Simulink:
% Torque → [Gain: gear_ratio/wheel_radius] → F_drive
% v → [Fcn: 0.5*rho*Cd*A*u^2] → F_drag
% → [Sum: F_drive - F_drag - F_roll] → a
% → [Integrator] → v
```

## Fault Injection Examples

### CAN Message Timeout

```python
# Test: ECU detects missing wheel speed message

def test_can_timeout():
    # Normal operation
    start_can_transmission(msg_id=0x120, period=10)  # 10ms period
    wait(1.0)
    assert_equal(ecu.dtc_present(0xC12345), False)

    # Stop CAN message (simulate timeout)
    stop_can_transmission(msg_id=0x120)
    wait(0.5)  # ECU timeout threshold: 500ms

    # Verify DTC set
    assert_equal(ecu.dtc_present(0xC12345), True)
    assert_equal(ecu.esc_state(), 'DEGRADED')

    # Resume message
    start_can_transmission(msg_id=0x120, period=10)
    wait(1.0)

    # DTC should clear (or remain pending)
    assert_equal(ecu.esc_state(), 'ACTIVE')
```

### Analog Sensor Out-of-Range

```python
# Test: ECU detects out-of-range throttle sensor

def test_throttle_out_of_range():
    # Normal range: 0.5V to 4.5V
    set_analog_voltage('Throttle_V', 2.5)
    wait(0.1)
    assert_false(ecu.dtc_present(0xP2135))

    # Inject out-of-range (short to battery)
    set_analog_voltage('Throttle_V', 12.0)
    wait(0.1)

    # Verify detection
    assert_true(ecu.dtc_present(0xP2135))
    assert_equal(ecu.throttle_value(), 0)  # Limp-home: 0% throttle

    # Restore
    set_analog_voltage('Throttle_V', 2.5)
```

## Next Steps

- **Level 4**: Signal lists, I/O mapping templates, test case templates
- **Level 5**: Virtual HIL, cloud HIL, multi-ECU co-simulation

## References

- dSPACE Implementation Guide
- NI VeriStand User Manual
- MATLAB Simulink Real-Time Workshop Documentation

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: HIL engineers, test developers
