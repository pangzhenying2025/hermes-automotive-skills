# HIL Testing - Quick Reference

## Signal Lists

### Common Analog Inputs (ECU → HIL)

| Signal | Type | Range | Resolution | Purpose |
|--------|------|-------|------------|---------|
| Throttle Position Sensor (TPS) | Voltage | 0.5-4.5V | 12-bit | Accelerator pedal position |
| Manifold Absolute Pressure (MAP) | Voltage | 0.5-4.5V | 12-bit | Engine load |
| Coolant Temperature Sensor (CTS) | Resistance | 250Ω-6kΩ | - | Engine temperature |
| Oxygen Sensor (O2) | Voltage | 0-1V | 12-bit | Exhaust lambda |
| Battery Voltage | Voltage | 6-18V | 12-bit | System voltage monitoring |

### Common Digital Inputs (ECU → HIL)

| Signal | Type | Voltage | Frequency | Purpose |
|--------|------|---------|-----------|---------|
| Crankshaft Position | Hall/VR | 0/5V or ±0.5V | 10-10000 Hz | Engine position |
| Camshaft Position | Hall | 0/5V | 5-500 Hz | Valve timing |
| Wheel Speed (x4) | Hall | 0/5V | 0-5000 Hz | Vehicle/wheel speed |
| Brake Pedal Switch | Digital | 0/12V | - | Brake applied |

### Common PWM/Frequency Outputs (HIL → ECU)

| Signal | Type | Frequency | Duty Cycle | Purpose |
|--------|------|-----------|------------|---------|
| Injector Drive | PWM | - | 0.5-10 ms pulse | Fuel injection |
| Ignition Coil | PWM | - | Variable | Spark timing |
| Variable Valve Timing (VVT) | PWM | 100-500 Hz | 0-100% | VVT control |
| Cooling Fan | PWM | 1 kHz | 0-100% | Fan speed control |

### Common CAN Messages (500 kbps)

| CAN ID | Name | Period | Signals |
|--------|------|--------|---------|
| 0x100 | EngineStatus | 10 ms | RPM (0-8000), Load (0-100%), Temp (-40-150°C) |
| 0x120 | WheelSpeeds | 20 ms | FL/FR/RL/RR speeds (0-300 km/h) |
| 0x200 | VehicleDynamics | 20 ms | Yaw rate, Lateral accel, Longitudinal accel |
| 0x300 | BrakePressure | 10 ms | Master cylinder pressure (0-200 bar) |
| 0x400 | GearboxStatus | 100 ms | Current gear, Requested gear, Clutch status |

## I/O Mapping Templates

### dSPACE SCALEXIO Mapping

```
# DS2655 Multi-I/O Board (Slot 3)

## Analog Outputs (ECU Inputs)
AO0  → Throttle Position Sensor (TPS)        0-5V
AO1  → MAP Sensor                            0.5-4.5V  
AO2  → Coolant Temperature Sensor (via R)    Variable
AO3  → Battery Voltage (Sense)               6-18V

## Digital Outputs (ECU Inputs)
DO0  → Wheel Speed FL (Frequency)            0-5 kHz
DO1  → Wheel Speed FR (Frequency)            0-5 kHz
DO2  → Wheel Speed RL (Frequency)            0-5 kHz
DO3  → Wheel Speed RR (Frequency)            0-5 kHz
DO4  → Crankshaft Position                   Variable
DO5  → Brake Pedal Switch                    0/12V

## Analog Inputs (ECU Outputs)
AI0  → Injector 1 Pulse (via RC filter)      Measurement
AI1  → Injector 2 Pulse                      Measurement
AI2  → VVT Solenoid PWM                      Measurement

## Digital Inputs (ECU Outputs)
DI0  → Fuel Pump Relay                       0/12V
DI1  → Cooling Fan Relay                     0/12V
DI2  → MIL (Malfunction Indicator Lamp)      0/12V

# DS6121 CAN Board (Slot 4)
CAN0 → Powertrain CAN (500 kbps)
CAN1 → Chassis CAN (500 kbps)
CAN2 → Body CAN (125 kbps)
```

### NI PXI Mapping

```
# PXI-6363 (Slot 2)

## Analog Outputs
PXI-6363/AO0 → Throttle_V             (0-5V)
PXI-6363/AO1 → MAP_V                  (0.5-4.5V)
PXI-6363/AO2 → Battery_V              (6-18V)

## Analog Inputs
PXI-6363/AI0 → Injector1_V            (0-12V, measure pulse)
PXI-6363/AI1 → Injector2_V            (0-12V)

## Digital I/O (Port 0)
PXI-6363/P0.0 → WheelSpeed_FL_Freq    (Output, 0-5kHz)
PXI-6363/P0.1 → WheelSpeed_FR_Freq    (Output)
PXI-6363/P0.2 → WheelSpeed_RL_Freq    (Output)
PXI-6363/P0.3 → WheelSpeed_RR_Freq    (Output)
PXI-6363/P0.4 → FuelPump_Relay        (Input, 0/12V)
PXI-6363/P0.5 → MIL_Lamp              (Input, 0/12V)

# PXI-8512 CAN (Slot 4)
PXI-8512/CAN0 → Powertrain_CAN        (500 kbps)
PXI-8512/CAN1 → Chassis_CAN           (500 kbps)
```

## Test Case Format

### Test Case Template

```yaml
test_case:
  id: TC-HIL-ESC-042
  title: ESC Intervention on Wheel Slip
  requirement: SYS-ESC-042
  asil: D
  author: John Smith
  date: 2026-03-15
  version: 1.2

preconditions:
  - ECU powered and initialized
  - No DTCs present
  - Vehicle speed > 10 km/h

test_steps:
  - step: 1
    action: Set vehicle speed to 100 km/h
    command: set_vehicle_speed(100)
    expected: Speed stabilizes at 100 ±2 km/h

  - step: 2
    action: Set low friction road surface
    command: set_road_friction(0.3)
    expected: Friction coefficient = 0.3

  - step: 3
    action: Apply hard braking while cornering
    commands:
      - set_steering_angle(90)
      - set_brake_pressure(150)
    expected: Brake pressure reaches 150 bar

  - step: 4
    action: Verify ESC activation
    wait: 0.5
    assertions:
      - ecu.esc_active() == True
      - wheel_slip_FL() < 25%
      - brake_pressure_modulated() == True
    expected: ESC active, wheel slip controlled

pass_criteria:
  - ESC activates within 500 ms
  - Wheel slip on all wheels < 25%
  - Brake pressure modulated on at least one wheel
  - No unintended DTCs set

cleanup:
  - set_brake_pressure(0)
  - set_steering_angle(0)
  - wait_stable(5.0)

```

## Pass/Fail Criteria Templates

### Functional Test Criteria

```python
# Timing Criteria
assert response_time < 100, f"Response time {response_time}ms exceeds 100ms"

# Range Criteria
assert 95 <= vehicle_speed <= 105, f"Speed {vehicle_speed} out of tolerance"

# Boolean Criteria
assert ecu.esc_active() == True, "ESC not active when expected"

# DTC Criteria
assert len(ecu.get_active_dtcs()) == 0, "Unexpected DTCs present"

# Signal Quality Criteria
signal_noise = calculate_snr(wheel_speed_signal)
assert signal_noise > 40, f"SNR {signal_noise} dB below threshold"
```

### Coverage Criteria

```
Requirement Coverage:
  Total requirements: 150
  Covered by HIL tests: 145
  Coverage: 96.7% (target ≥ 95%)

Test Execution:
  Total test cases: 420
  Passed: 415
  Failed: 3
  Not executed: 2
  Pass rate: 98.8%
```

## Common Plant Model Blocks

### Simulink Library Blocks

| Block | Library | Parameters | Purpose |
|-------|---------|------------|---------|
| Vehicle Body 3DOF | ASM Vehicle Dynamics | Mass, Inertia, CG height | Longitudinal/lateral/yaw dynamics |
| Magic Formula Tire | ASM Tire | Tire coefficients | Force/slip relationship |
| Engine Mean Value | Powertrain Blockset | Displacement, compression | Torque/speed map |
| Brake System | ASM Brakes | Caliper area, pad coefficient | Brake torque calculation |
| Battery | Simscape Electrical | Capacity, SOC, R_internal | Battery voltage/current |

### Custom Model Blocks

```matlab
% Wheel Speed Sensor Model
% Input: Wheel angular velocity (rad/s)
% Output: Frequency (Hz)

function freq_Hz = wheel_speed_sensor(omega_rad_s, pulses_per_rev)
    % omega_rad_s: Wheel angular velocity
    % pulses_per_rev: Encoder resolution (e.g., 48 pulses)
    
    freq_Hz = (omega_rad_s / (2*pi)) * pulses_per_rev;
    
    % Add noise (±1% random noise)
    noise = randn() * 0.01 * freq_Hz;
    freq_Hz = freq_Hz + noise;
    
    % Clamp to realistic range
    freq_Hz = max(0, min(freq_Hz, 10000));
end
```

## Troubleshooting Checklist

### HIL System Not Responding

- [ ] Check Ethernet connection (ping SCALEXIO IP)
- [ ] Verify real-time application running (ControlDesk status)
- [ ] Check I/O board LEDs (power, activity)
- [ ] Restart SCALEXIO (power cycle)
- [ ] Re-download application

### ECU Not Communicating

- [ ] Check ECU power supply (measure voltage at connector)
- [ ] Verify CAN termination (120Ω between CAN-H and CAN-L)
- [ ] Check CAN bus voltage (2.5V idle, oscillates when transmitting)
- [ ] Verify CAN bitrate matches ECU (500 kbps typical)
- [ ] Check for CAN error frames (bus-off condition)

### Real-Time Overruns

- [ ] Reduce model complexity (simplify physics)
- [ ] Increase timestep (1ms → 2ms if acceptable)
- [ ] Move calculations to FPGA (DS2655)
- [ ] Disable unnecessary logging
- [ ] Optimize Simulink blocks (use lookup tables vs. equations)

### Incorrect Sensor Values

- [ ] Verify I/O mapping (signal connected to correct channel)
- [ ] Check signal scaling (0-5V mapped to correct engineering units)
- [ ] Measure voltage at ECU connector (multimeter)
- [ ] Check for ground offset (differential measurement)
- [ ] Verify sensor pull-up resistors (if required)

## Common Configuration Files

### ControlDesk Experiment (.cdx)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Experiment>
  <Variables>
    <Variable name="Throttle_pct" path="Model/Inputs/Throttle_pct" type="Float32" />
    <Variable name="VehicleSpeed_kph" path="Model/Outputs/VehicleSpeed_kph" type="Float32" />
  </Variables>
  <Layouts>
    <Layout name="Main">
      <Instrument type="Slider" variable="Throttle_pct" min="0" max="100" />
      <Instrument type="Numeric" variable="VehicleSpeed_kph" />
    </Layout>
  </Layouts>
</Experiment>
```

### CAN Database (.dbc)

```
VERSION ""

NS_ :
  NS_DESC_
  CM_
  BA_DEF_
  BA_
  VAL_
  CAT_DEF_
  CAT_
  FILTER
  BA_DEF_DEF_
  EV_DATA_
  ENVVAR_DATA_
  SGTYPE_
  SGTYPE_VAL_
  BA_DEF_SGTYPE_
  BA_SGTYPE_
  SIG_TYPE_REF_
  VAL_TABLE_
  SIG_GROUP_
  SIG_VALTYPE_
  SIGTYPE_VALTYPE_
  BO_TX_BU_
  CAT_
  FILTER

BS_:

BU_: ECU HIL

BO_ 256 EngineStatus: 8 ECU
 SG_ EngineRPM : 0|16@1+ (0.25,0) [0|8000] "rpm" HIL
 SG_ EngineLoad : 16|8@1+ (1,0) [0|100] "%" HIL
 SG_ CoolantTemp : 24|8@1+ (1,-40) [-40|150] "degC" HIL

CM_ SG_ 256 EngineRPM "Engine speed in RPM, 0.25 resolution";
```

## References

- dSPACE ControlDesk User Guide
- NI VeriStand Reference Manual
- Vector CANdb++ Editor Documentation

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All HIL users
