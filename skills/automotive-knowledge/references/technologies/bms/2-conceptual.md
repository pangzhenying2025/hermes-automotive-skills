# Battery Management System - Conceptual Architecture

## SOC/SOH/SOP/SOE Concepts

### State of Charge (SOC)

SOC represents the available capacity as a percentage of the nominal capacity.

```
SOC = (Remaining Capacity / Nominal Capacity) × 100%

Example:
- Nominal capacity: 75 Ah
- Remaining capacity: 45 Ah
- SOC = 60%
```

**SOC Estimation Challenges:**
- Cannot be directly measured (unlike voltage/current)
- Depends on temperature, age, and load history
- Different definitions: Ah-based vs energy-based SOC

**Key Applications:**
- Range estimation for driver display
- Charge/discharge power limit calculation
- Battery protection (prevent deep discharge)

### State of Health (SOH)

SOH quantifies battery degradation relative to a new cell.

```
SOH_capacity = (Current Max Capacity / Initial Capacity) × 100%
SOH_resistance = (Initial Resistance / Current Resistance) × 100%

End-of-life criteria:
- Capacity SOH < 80% (typical EV requirement)
- Resistance increased by 2x (power fade)
```

**Degradation Mechanisms:**
- **SEI growth**: Solid Electrolyte Interface thickens over time
- **Lithium plating**: Irreversible lithium loss during fast charging
- **Active material loss**: Mechanical stress, phase transitions
- **Electrolyte decomposition**: Gassing, pressure buildup

**SOH Impact:**
- Reduced driving range
- Lower power capability
- Increased internal resistance (heat generation)

### State of Power (SOP)

SOP defines the maximum charge/discharge power without violating limits.

```
P_max_charge = min(P_voltage_limit, P_current_limit, P_temperature_limit)
P_max_discharge = min(P_voltage_limit, P_current_limit, P_temperature_limit, P_SOC_limit)

Example calculations:
- Voltage limit: (V_max - V_current) / R_internal
- Current limit: I_max × V_current
- Temperature limit: Derate_factor(T) × P_rated
```

**SOP Use Cases:**
- Regenerative braking limit
- Acceleration power availability
- Fast charging power negotiation

### State of Energy (SOE)

SOE estimates available energy in kWh.

```
SOE = SOC × (Capacity_Ah) × (Average_Voltage) / 1000

Example:
- SOC: 80%
- Capacity: 75 Ah
- Average voltage: 360V
- SOE = 0.8 × 75 × 360 / 1000 = 21.6 kWh
```

## Cell Modeling

### Equivalent Circuit Model (ECM)

The ECM represents a cell's electrical behavior using resistors and capacitors.

**First-Order RC Model:**
```
          R0
    ──────┬─────────
          │
         ┌┴┐
    OCV  │ │  R1 ─── C1
         └┬┘     (RC pair for diffusion)
          │
    ──────┴─────────

Terminal voltage:
V_terminal = OCV(SOC) - I × R0 - V_R1C1

where V_R1C1 evolves according to:
dV_R1C1/dt = -V_R1C1 / (R1 × C1) + I / C1
```

**Second-Order RC Model:**
```
Adds another RC pair for improved accuracy:
V_terminal = OCV(SOC) - I × R0 - V_R1C1 - V_R2C2
```

**Parameter Identification:**
1. OCV curve: Measure voltage at various SOC levels after 2-hour rest
2. R0: Measure voltage drop during pulse test (instant response)
3. R1, C1: Fit exponential decay after current step
4. R2, C2: Fit long-time constant dynamics

### Electrochemical Models

Physics-based models (Pseudo-2D, Single Particle Model) simulate internal chemistry.

**Single Particle Model (SPM):**
```
Assumptions:
- Each electrode represented by a single spherical particle
- Concentration gradients only in radial direction
- No temperature gradients

Equations:
∂c/∂t = D × (1/r²) × ∂/∂r(r² × ∂c/∂r)  # Diffusion in particle
J = i / (A × F)                          # Flux at particle surface
V = U_pos - U_neg - I × R_film - I × R_electrolyte
```

**Advantages:**
- Accurate across wide SOC/temperature ranges
- Captures internal states (lithium concentration)
- Enables physics-based SOH estimation

**Disadvantages:**
- Computationally expensive (difficult for real-time BMS)
- Requires many parameters (hard to identify)
- Model complexity

## Thermal Modeling

Battery thermal behavior affects performance and safety.

### Lumped Thermal Model

```
Heat generation:
Q_gen = I² × R_internal + I × (OCV - V_terminal)
       (Joule heating)    (Entropy heat/reversible heat)

Heat dissipation:
Q_loss = h × A × (T_cell - T_ambient)

Temperature dynamics:
m × Cp × dT/dt = Q_gen - Q_loss

where:
- m: Cell mass (kg)
- Cp: Specific heat capacity (J/kg·K)
- h: Heat transfer coefficient (W/m²·K)
- A: Surface area (m²)
```

**Implementation:**
```python
class ThermalModel:
    def __init__(self, mass_kg=0.5, cp=900, h=10, area=0.02):
        self.mass = mass_kg
        self.cp = cp
        self.h = h
        self.area = area
        self.temp = 25.0  # Initial temperature (°C)

    def update(self, current, voltage, ocv, ambient_temp, dt):
        # Heat generation
        R_internal = abs((ocv - voltage) / current) if current != 0 else 0.01
        Q_gen = current**2 * R_internal + current * (ocv - voltage)

        # Heat loss (convection)
        Q_loss = self.h * self.area * (self.temp - ambient_temp)

        # Temperature update
        dT_dt = (Q_gen - Q_loss) / (self.mass * self.cp)
        self.temp += dT_dt * dt

        return self.temp
```

### Multi-Node Thermal Model

For pack-level simulation, model each module/cell as a node:

```
T_i: Temperature of node i
C_i: Thermal capacitance
R_ij: Thermal resistance between nodes i and j

dT_i/dt = (Q_gen_i - Σ_j (T_i - T_j) / R_ij) / C_i
```

## Balancing Strategies

### Passive Balancing

Dissipate excess energy from high cells using resistors.

```
Circuit:
    Cell ─┬─── Switch ─── Resistor ─── GND
          │
        (Parallel to cell)

Balancing current:
I_balance = (V_cell - V_target) / R_balance

Typical values:
- R_balance: 10-50 Ω
- I_balance: 50-200 mA
- Balancing time: Hours
```

**Algorithm:**
```python
def passive_balance(cell_voltages, target_voltage=3.7, threshold=0.010):
    """Enable balancing for cells above target + threshold"""
    balance_commands = []
    for v in cell_voltages:
        if v > target_voltage + threshold:
            balance_commands.append(True)  # Enable balancing resistor
        else:
            balance_commands.append(False)
    return balance_commands
```

**Advantages:**
- Simple, low cost
- Reliable (no active components except switch)

**Disadvantages:**
- Slow (limited by heat dissipation)
- Wastes energy as heat
- Cannot charge low cells (only discharge high cells)

### Active Balancing

Transfer energy between cells using inductors or capacitors.

**Flyback Converter (Inductive):**
```
High Cell ─── Switch ─── Inductor ─── Switch ─── Low Cell

Energy transfer:
E = 0.5 × L × I_peak²

Typical efficiency: 80-90%
Balancing current: 1-5 A (much faster than passive)
```

**Capacitor Shuttling:**
```
Switch network connects a flying capacitor to adjacent cells:
C_fly charges from high cell, then discharges to low cell

Transfer per cycle:
ΔQ = C_fly × (V_high - V_low)
```

**Algorithm:**
```python
def active_balance(cell_voltages):
    """Transfer energy from highest to lowest cell"""
    V_max = max(cell_voltages)
    V_min = min(cell_voltages)
    idx_max = cell_voltages.index(V_max)
    idx_min = cell_voltages.index(V_min)

    if V_max - V_min > 0.050:  # 50mV threshold
        # Command active balancing circuit
        return {
            'source_cell': idx_max,
            'target_cell': idx_min,
            'duration_ms': 100
        }
    else:
        return None  # Cells balanced
```

**Advantages:**
- Fast balancing (5-10x faster than passive)
- Energy efficient (no dissipation)
- Can balance at any SOC (not just top-of-charge)

**Disadvantages:**
- Higher cost and complexity
- Additional components (inductors, capacitors, switches)
- EMI/EMC challenges

## Cell Balancing Strategies by Application

| Application | Strategy | Balancing Time | Cost Impact |
|-------------|----------|----------------|-------------|
| **Consumer (phone, laptop)** | Passive | Overnight charge OK | Low |
| **Budget EV** | Passive | During long charge sessions | Low |
| **Performance EV** | Active | Minimize charge time | Medium |
| **Grid Storage** | Active | Maximize roundtrip efficiency | High |
| **Fast-Swap Batteries** | Active + Passive | Must balance quickly | High |

## Communication Protocols

### Cell Monitoring ICs

**isoSPI (Linear Technology):**
```
Daisy-chain topology:
Master ── isoSPI ── Slave 1 ── isoSPI ── Slave 2 ── ... ── Slave N

Features:
- 1 Mbps data rate
- Galvanic isolation (no isolated power needed)
- Long cable runs (100m+)
- EMI robust
```

**SPI (Standard):**
```
Master ─── CS/CLK/MOSI/MISO ─── Slave 1
                         └────── Slave 2
                         └────── Slave N

Requires isolated power for high-voltage slaves
Lower cost than isoSPI
```

### Vehicle Communication

**CAN (Controller Area Network):**
```
BMS broadcasts messages at fixed intervals:
- Battery status: SOC, voltage, current, temp (10 Hz)
- Fault flags: Overvoltage, overcurrent, etc. (event-driven)
- Limits: Max charge/discharge power (100 Hz)

Message format (CAN 2.0B):
ID: 0x18FF50E5 (J1939 format for BMS)
Data: [SOC%, SOH%, V_pack_H, V_pack_L, I_pack_H, I_pack_L, T_max, T_min]
```

**Automotive Ethernet:**
```
For next-gen BMS with high data needs:
- Cell-level voltage/temperature streaming (100+ Hz)
- Impedance spectroscopy data
- Diagnostics and calibration

Bandwidth: 100 Mbps to 1 Gbps
Latency: <100 μs
```

## Next Steps

- **Level 3**: Detailed EKF implementation for SOC estimation, dual EKF for SOC+SOH
- **Level 4**: Cell datasheets, voltage curves, protocol specifications
- **Level 5**: Neural network SOC/SOH, digital twin BMS, fleet learning

## References

- Plett, G.L. "Battery Management Systems, Volume I: Battery Modeling", Artech House 2015
- Hu, X. et al. "Battery Lifetime Prognostics", Joule 2020
- ISO 16750: Road vehicles — Environmental conditions and testing for electrical and electronic equipment
- LTC6811 Datasheet: Multicell Battery Stack Monitor with isoSPI

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: BMS architects, battery algorithm engineers, thermal management engineers
