# HIL Testing - Conceptual Architecture

## HIL System Components

### Real-Time Simulator Hardware

**Purpose**: Execute plant models with deterministic timing.

**Architecture**:
```
Real-Time Simulator
├── Processor Board
│   ├── Multi-core CPU (Intel Xeon, AMD EPYC)
│   ├── FPGA (for time-critical calculations)
│   └── Real-time OS (QNX, RTLinux, VxWorks)
├── I/O Boards
│   ├── Analog I/O (16-bit, ±10V)
│   ├── Digital I/O (sourcing/sinking)
│   ├── PWM I/O (1-20 kHz)
│   ├── CAN/LIN interfaces
│   └── Automotive Ethernet (100BASE-T1, 1000BASE-T1)
└── Power Supply
    ├── ECU power (configurable 6-18V)
    └── Sensor supply (5V, 3.3V)
```

**Commercial Platforms**:

**dSPACE SCALEXIO**:
- Modular system (backplane architecture)
- DS6001 processor board (Intel Xeon, QNX)
- DS2655 FPGA board (Xilinx, 1 μs timestep)
- 100+ I/O channels per rig

**National Instruments PXI**:
- CompactPCI eXtensions for Instrumentation
- PXI-8880 controller (Intel i7, Windows/Linux RT)
- Modular I/O cards (NI-6363, NI-9862 CAN)
- Cost-effective, COTS hardware

**Typhoon HIL**:
- Specialized for power electronics
- Ultra-low latency (< 1 μs)
- Built-in inverter simulation
- Ideal for battery, motor drive testing

### I/O Boards and Signal Conditioning

#### Analog I/O

**Purpose**: Interface with analog sensors (temperature, pressure, position).

**Specifications**:
- Resolution: 12-16 bit
- Voltage range: ±10V, 0-5V (configurable)
- Sample rate: 1 kHz - 100 kHz
- Channels per board: 8-32

**Signal Conditioning**:
- **Voltage scaling**: Thermistor voltage divider emulation
- **Current sourcing**: 4-20mA sensor emulation
- **Fault injection**: Open, short-to-ground, short-to-battery

**Example Circuit**:
```
HIL Analog Output → Resistor Divider → ECU Analog Input

Thermistor Simulation:
HIL DAC (0-5V) → R_divider → ECU ADC
Temperature -40°C: 4.8V
Temperature +125°C: 0.5V
```

#### Digital I/O

**Purpose**: Interface with digital sensors/actuators (switches, relays).

**Types**:
- **Sourcing**: HIL provides voltage (simulates powered sensor)
- **Sinking**: HIL provides ground (simulates grounded switch)
- **Bidirectional**: Configurable input/output

**Specifications**:
- Voltage levels: 0V/5V, 0V/12V
- Current: 100 mA per channel
- Frequency: DC to 10 kHz
- Channels: 32-64 per board

**Use Cases**:
- Hall-effect sensor simulation (wheel speed, crankshaft position)
- Switch status (brake pedal, ignition key)
- Relay drive monitoring (fuel pump, cooling fan)

#### CAN/LIN/FlexRay Interfaces

**CAN Interface**:
- Channels: 2-16 per board
- Speed: 125 kbps, 250 kbps, 500 kbps, 1 Mbps
- CAN FD support: 2 Mbps, 5 Mbps data phase
- Features: Error injection, bus load simulation

**LIN Interface**:
- Channels: 4-8 per board
- Speed: 9.6 kbps, 19.2 kbps
- Master/slave mode
- Features: Header transmission, checksum errors

**Automotive Ethernet**:
- 100BASE-T1 (2-wire, 100 Mbps)
- 1000BASE-T1 (2-wire, 1 Gbps)
- SOME/IP, AVB/TSN support
- Use: Camera data injection, high-bandwidth sensors

#### PWM I/O

**Purpose**: Drive/measure pulse-width modulated signals.

**Output Mode** (HIL → ECU):
- Frequency: 100 Hz - 20 kHz
- Duty cycle: 0-100%
- Use: Sensor simulation (MAP sensor, throttle position)

**Input Mode** (ECU → HIL):
- Frequency measurement: 1 Hz - 100 kHz
- Duty cycle measurement: 0-100%
- Use: Injector pulse monitoring, solenoid drive

### Plant Model Development

**Model Types**:

**Physics-Based Models**:
- Derived from first principles (Newton's laws, thermodynamics)
- High accuracy, computationally intensive
- Example: Engine combustion model (Wiebe function)

**Empirical Models**:
- Derived from test data (lookup tables, regression)
- Fast execution, limited extrapolation
- Example: Tire force model (lookup table vs. slip angle)

**Black-Box Models**:
- Neural networks, system identification
- No physical insight, data-driven
- Example: Catalyst temperature prediction

**Model Fidelity Tradeoff**:
```
High Fidelity (detailed physics)
    ↑
    |  Slow execution (may not meet real-time)
    |  High development effort
    |  Accurate extrapolation
    |
    ↓
Low Fidelity (lookup tables)
    |  Fast execution (easy real-time)
    |  Low development effort
    |  Limited extrapolation
    ↓
```

**Development Tools**:
- MATLAB/Simulink: Graphical modeling (80% of automotive HIL)
- C/C++: Hand-coded models (performance-critical)
- Modelica: Multi-domain physics (Dymola, OpenModelica)
- CarMaker/ASM: Commercial vehicle dynamics

### Test Automation Layers

**Layer 1: Test Execution Engine**:
- Executes test steps (set stimuli, wait, check response)
- Examples: Python scripts, CAPL (CANalyzer), AutomationDesk

**Layer 2: Test Case Management**:
- Organizes test cases, parameters, expected results
- Examples: TestWeaver, vTESTstudio, NI TestStand

**Layer 3: Requirements Traceability**:
- Links test cases to requirements
- Tracks coverage (which requirements tested)
- Examples: DOORS, Polarion, Jama

**Layer 4: CI/CD Integration**:
- Triggers tests automatically on code commit
- Publishes results to dashboard
- Examples: Jenkins, GitLab CI, Azure DevOps

**Automation Architecture**:
```
┌────────────────────────────────────────┐
│  Requirements Management (DOORS)       │
│  REQ-001 ← TC-001, TC-002              │
└────────────────┬───────────────────────┘
                 ↓ Trace
┌────────────────────────────────────────┐
│  Test Management (TestWeaver)          │
│  Test Suite → Test Case → Test Step   │
└────────────────┬───────────────────────┘
                 ↓ Execute
┌────────────────────────────────────────┐
│  Test Scripts (Python, CAPL)           │
│  Set CAN signal, Wait, Check DTC       │
└────────────────┬───────────────────────┘
                 ↓ Control
┌────────────────────────────────────────┐
│  HIL Simulator (dSPACE, NI)            │
│  Real-time model execution             │
└────────────────┬───────────────────────┘
                 ↓ I/O
┌────────────────────────────────────────┐
│  ECU Under Test                        │
└────────────────────────────────────────┘
```

## Real-Time Operating Systems

### QNX (dSPACE Default)

**Characteristics**:
- Microkernel architecture (message-passing)
- Hard real-time guarantees
- Deterministic scheduling
- High reliability (used in safety-critical systems)

**Typical Cycle Time**: 100 μs - 1 ms

### RTLinux / Preempt-RT

**Characteristics**:
- Linux with real-time patches
- Soft real-time (occasional overruns tolerated)
- Open-source, flexible
- Larger ecosystem (drivers, tools)

**Typical Cycle Time**: 1 ms - 10 ms

### VxWorks

**Characteristics**:
- Real-time operating system (Wind River)
- Hard real-time, deterministic
- Widely used in aerospace, automotive
- Commercial, licensed

**Typical Cycle Time**: 100 μs - 1 ms

### Selection Criteria

| Requirement | QNX | RTLinux | VxWorks |
|-------------|-----|---------|---------|
| Hard real-time (< 1ms) | ✓✓✓ | ✓✓ | ✓✓✓ |
| Soft real-time (1-10ms) | ✓✓✓ | ✓✓✓ | ✓✓✓ |
| Open-source | ✗ | ✓ | ✗ |
| Automotive heritage | ✓✓✓ | ✓✓ | ✓✓ |
| Cost | High | Low | High |

## Fault Injection Techniques

### Hardware Fault Injection

**Relay-Based FIU (Fault Injection Unit)**:
```
ECU Sensor Input ─┬─ Normal Path ────┐
                  │                   ├─→ Multiplexer ─→ Sensor Signal
                  └─ Fault Path ──────┘
                      (Open, GND, VBAT)

Control: Digital output from HIL
Faults: Open circuit, short to ground, short to battery
```

**Solid-State FIU**:
- Faster switching (< 1 ms)
- No mechanical wear
- Higher cost

### Software Fault Injection

**CAN Message Manipulation**:
```python
# Inject missing message (timeout)
can_signal.set_enabled(False)
sleep(0.5)  # ECU should detect timeout (500ms)
assert ecu.dtc_present(0xC12345)  # Check DTC set

# Inject out-of-range value
can_signal.set_value(255)  # Invalid wheel speed
assert ecu.dtc_present(0xC12346)  # Check plausibility DTC
```

**Signal Ramping (Simulate Gradual Failure)**:
```python
# Simulate sensor drift
for voltage in range(0, 50, 1):  # 0 to 5V in 0.1V steps
    analog_out.set_voltage(voltage / 10.0)
    sleep(0.1)
    if ecu.dtc_present(0xC12347):
        print(f"Fault detected at {voltage/10.0}V")
        break
```

## Model Calibration and Validation

### Calibration Process

**Step 1: Identify Parameters**:
- Model parameters needing calibration (mass, friction, time constants)

**Step 2: Collect Reference Data**:
- Vehicle test data (measured inputs/outputs)
- Dynamometer data
- Component bench tests

**Step 3: Optimize Parameters**:
- Manual tuning (adjust, compare, iterate)
- Automated optimization (least squares, genetic algorithm)

**Step 4: Validate**:
- Compare model output vs. measured data
- Check error metrics (RMSE, max error)
- Validate with independent dataset (not used in calibration)

### Validation Metrics

**Root Mean Square Error (RMSE)**:
```
RMSE = sqrt(mean((y_measured - y_model)^2))

Acceptance: RMSE < 5% of signal range
```

**Maximum Absolute Error**:
```
Max_Error = max(abs(y_measured - y_model))

Acceptance: Max_Error < 10% of signal range
```

**Example**:
```
Signal: Engine speed
Range: 0 - 6000 RPM
RMSE: 45 RPM (0.75% of range) → PASS
Max Error: 120 RPM (2% of range) → PASS
```

## HIL Lab Infrastructure

### Physical Setup

**HIL Rack**:
- 19" standard rack (42U height)
- dSPACE/NI hardware: 6-10U
- Power distribution: 2U
- Network switch: 1U
- Spare slots for expansion

**Cabling**:
- Automotive-grade connectors (Deutsch, TE Connectivity)
- Shielded cables (minimize EMI)
- Cable management (label, route cleanly)
- Breakout boxes (easy connection changes)

**Environmental Control**:
- Climate chamber integration (optional)
- Temperature range: -40°C to +125°C
- HVAC for equipment cooling (racks generate heat)

### Safety Considerations

**Electrical Safety**:
- Isolation barriers (HIL from mains)
- Ground fault protection (GFCI)
- Emergency stop button (kill power)
- Warning labels (high voltage if applicable)

**Fire Safety**:
- Smoke detectors in lab
- Fire suppression (clean agent for electronics)
- Flammable material storage (limited)

**Operational Safety**:
- Moving parts guarded (if using motor emulators)
- Personal protective equipment (safety glasses if testing power electronics)

## Next Steps

- **Level 3**: Detailed dSPACE/NI setup, Simulink model development, test scripting
- **Level 4**: Signal lists, I/O mapping templates, test case formats
- **Level 5**: Virtual HIL, cloud HIL, multi-ECU co-simulation

## References

- dSPACE SCALEXIO Hardware Installation and Configuration
- NI VeriStand Getting Started Guide
- SAE J2617 HIL Simulation Best Practices
- ISO 26262-4:2018 System Integration (Clause 7: HIL testing)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: HIL engineers, test automation engineers
