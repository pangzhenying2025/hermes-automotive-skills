# EV Charging - Conceptual Architecture

## AC vs DC Charging Architecture

### AC Charging System

```
Grid (3-phase) → EVSE (J1772/Type2) → Vehicle Inlet → OBC → HV Battery
      240V              ↓ Control Pilot (PWM)        (AC→DC)
                   Contactor Control
```

**Components:**

**1. EVSE (Electric Vehicle Supply Equipment):**
- Ground fault protection (GFCI/RCD)
- Control pilot signal generation
- Contactor control (energize inlet when vehicle connected)
- Current limiting based on circuit capacity

**2. Control Pilot:**
```
12V PWM signal encoding available current:
- Frequency: 1 kHz
- Duty cycle: 10-97% (maps to 6-80A)
- Voltage levels:
  +12V: EVSE present, no vehicle
  +9V:  Vehicle connected, ready
  +6V:  Vehicle charging
  +3V:  Ventilation required
  -12V: Fault condition
```

**3. Onboard Charger (OBC):**

Power electronics topology:
```
AC Input → PFC (Power Factor Correction) → LLC Resonant Converter → DC Output
   ↓                                                                      ↓
Rectifier + Boost                                                   HV Battery
(Near unity PF)
```

**PFC Stage:**
- Boosts AC voltage to 400V DC
- Achieves power factor > 0.99
- Reduces harmonics (THD < 5%)

**LLC Resonant Converter:**
- High efficiency (>96%)
- Soft switching (reduces EMI)
- Galvanic isolation (transformer)
- Regulates output voltage/current

### DC Fast Charging System

```
Grid (3-phase) → Off-Board Charger → CCS/CHAdeMO Inlet → HV Battery
    400-800V         (Rectifier +              ↓
                      DC-DC)             CAN/PLC Communication
```

**Off-Board Charger Architecture:**

```
AC Input → 3-Phase Rectifier → DC-DC Converter → DC Output (200-920V)
    │                               ↓
 Grid Filter                   Interleaved Buck
                               (50-350 kW)
```

**Key Differences from AC:**
- No onboard charger (vehicle just routes power to battery)
- Charger controls voltage/current (not vehicle)
- Higher power requires liquid cooling
- Communication essential (charge curve negotiation)

## Onboard Charger Design

### Bidirectional OBC (V2G Capable)

```
AC Grid ←→ Bidirectional Inverter ←→ DC-DC Converter ←→ Battery
             (3.3-22 kW)                 (Isolated)
```

**Modes:**
1. **G2V (Grid-to-Vehicle)**: Charging mode
2. **V2G (Vehicle-to-Grid)**: Discharge to grid
3. **V2H (Vehicle-to-Home)**: Backup power for home
4. **V2L (Vehicle-to-Load)**: Power external devices

**Control Requirements:**
- Grid synchronization (PLL for frequency/phase)
- Current control (meet grid codes)
- Islanding protection (detect grid loss)
- Reactive power support (Q control)

### Three-Phase OBC (11-22 kW)

```
Phase A ──┐
Phase B ──┼──→ 3-Phase PFC → LLC Converter → Battery
Phase C ──┘

Power: P = √3 × V_line × I_line × cos(φ)
Example: √3 × 400V × 32A × 0.99 = 21.9 kW
```

## Power Electronics Topology

### Totem-Pole PFC (Bridgeless)

Higher efficiency than traditional boost PFC:

```
L_boost
   │
AC ─┴─── Q1 ──┬──── DC+
             D1│
        ┌─────┴─────┐
        Q2         Q3    (SiC MOSFETs)
        │           │
AC ────┴───────────┴──── DC-

Efficiency: 98% (vs 95% for conventional)
```

### LLC Resonant Converter

```
Primary Side:          Transformer:         Secondary Side:
    ┌─ Q1 ─┐               ┌───┐             ┌─ D1 ─┐
DC+ ─┤     ├─┬─ Lr ─┬─────┤   ├─────┬───────┤     ├─ DC+
    └─ Q2 ─┘ │      │     │ T │     │       └─ D2 ─┘
             Cr     Lm     └───┘     Co
             │      │               │
DC- ─────────┴──────┴───────────────┴─────────────── DC-

Lr: Resonant inductor
Cr: Resonant capacitor
Lm: Magnetizing inductance

Resonant frequency: f_r = 1 / (2π√(Lr × Cr))
Soft switching at f_r (ZVS for MOSFETs, ZCS for diodes)
```

## Communication Stack

### ISO 15118 Protocol Stack

```
Application Layer:   EXI Messages (charge params, payment)
                          ↕
Session Layer:       TLS 1.2 (mutual authentication)
                          ↕
Transport Layer:     TCP/IPv6
                          ↕
Network Layer:       IPv6 (link-local addressing)
                          ↕
Data Link Layer:     HomePlug Green PHY (PLC)
                          ↕
Physical Layer:      Control Pilot (PWM + PLC modulation)
```

### PLC (Power Line Communication)

Superimpose data on control pilot wire:

```
Control Pilot Signal = 1 kHz PWM (DC component)
                     + 2-30 MHz OFDM (AC component for data)

HomePlug Green PHY:
- Bandwidth: 1.8-30 MHz
- Modulation: OFDM with QPSK/16-QAM
- Data rate: Up to 10 Mbps
- PHY/MAC from HomePlug AV
```

### State Machine (EVCC Perspective)

```
┌────────────┐
│  Unplug    │
└──────┬─────┘
       │ Plug in
       ↓
┌────────────┐
│  Connected │───→ (SLAC matching)
└──────┬─────┘
       │ SLAC OK
       ↓
┌────────────┐
│ Session    │───→ (TLS handshake)
│ Setup      │
└──────┬─────┘
       │ Authenticated
       ↓
┌────────────┐
│ Service    │───→ (Negotiate charge params)
│ Discovery  │
└──────┬─────┘
       │ Params agreed
       ↓
┌────────────┐
│ Charging   │───→ (Power delivery)
└──────┬─────┘
       │ Target SOC reached
       ↓
┌────────────┐
│ Session    │
│ Stop       │
└────────────┘
```

## Charge Curve Management

### BMS-Charger Negotiation

```python
class ChargeController:
    def __init__(self, bms):
        self.bms = bms

    def compute_charge_limits(self):
        """Calculate max power based on battery state"""
        SOC = self.bms.get_SOC()
        temp = self.bms.get_temperature()
        SOH = self.bms.get_SOH()
        cell_voltages = self.bms.get_cell_voltages()

        # Base limits from cell specs
        I_max_cell = 2.0 * self.bms.cell_capacity  # 2C rate

        # Temperature derating
        if temp < 10:
            I_max_cell *= 0.7  # Cold derating
        elif temp > 45:
            I_max_cell *= 0.8  # Hot derating

        # SOC-based derating (taper at high SOC)
        if SOC > 80:
            I_max_cell *= (100 - SOC) / 20  # Linear taper 80-100%

        # Cell voltage limit (constant voltage phase)
        V_max_cell = 4.2  # NMC chemistry
        if max(cell_voltages) > 4.15:
            # Enter CV mode
            I_max_cell = min(I_max_cell, (V_max_cell - max(cell_voltages)) / 0.005)

        # Pack-level limits
        num_parallel = self.bms.num_parallel_cells
        I_max_pack = I_max_cell * num_parallel

        V_pack = self.bms.get_pack_voltage()
        P_max = V_pack * I_max_pack

        return {
            'max_current_A': I_max_pack,
            'max_voltage_V': V_pack + 10,  # Allow slight margin
            'max_power_kW': P_max / 1000
        }
```

### Multi-Stage Charging

```
Stage 1: Preconditioning (if battery cold)
- Run coolant pump, battery heater
- Bring battery to 15-25°C
- Duration: 5-15 minutes

Stage 2: Constant Power (CP)
- Charge at maximum rate (limited by charger or BMS)
- SOC: 10-60%
- Power: 150-350 kW

Stage 3: Taper Phase 1
- Begin reducing power to protect cells
- SOC: 60-80%
- Power: 350 kW → 100 kW

Stage 4: Taper Phase 2 (Constant Voltage)
- Cell voltages at limit, reduce current
- SOC: 80-100%
- Power: 100 kW → 20 kW
- Focus on cell balancing
```

## Connector Design

### CCS Combo Connector (CCS1)

```
    ┌─────────────────┐
    │  J1772 Pins     │  ← AC charging (L1, L2, GND, CP, PP)
    │  o   o   o      │
    │    o   o        │
    ├─────────────────┤
    │  DC Pins        │  ← DC fast charging
    │   ●       ●     │     (DC+, DC-)
    └─────────────────┘

Pin assignments:
AC: L1, L2, PE, CP (Control Pilot), PP (Proximity Pilot)
DC: DC+, DC-
```

### NACS (Tesla/North American Charging Standard)

```
Compact single connector for AC and DC:

    ┌───┐
    │ o │  ← High voltage pins (AC or DC)
    │o o│
    └───┘

Advantages:
- Smaller, lighter than CCS
- Same connector for all power levels
- Proven reliability (Supercharger network)
```

## Thermal Management

Heat generation during charging:

```
Q_charger = P_loss_charger + P_loss_cable + P_loss_battery

P_loss_charger: Typically 3-5% of power (350 kW → 10-17 kW heat)
P_loss_cable: I² × R_cable
P_loss_battery: I² × R_internal + entropic heat
```

**Cooling Systems:**

**Liquid-Cooled Cables (>150 kW):**
- Coolant circulates through cable
- Allows thinner cables (higher current density)
- Required for 350 kW+ charging

**Battery Thermal Management:**
- Active cooling during fast charging
- Target: Keep cells below 45°C
- Coolant flow rate increases with charge power

## Next Steps

- **Level 3**: Detailed ISO 15118 message implementation, SECC/EVCC state machines
- **Level 4**: Connector pinouts, protocol message catalog, temperature limits
- **Level 5**: V2G grid services, smart charging optimization, wireless charging

## References

- ISO 15118-2: Road vehicles — Vehicle to grid communication interface — Part 2: Network and application protocol requirements
- IEC 61851-1: Electric vehicle conductive charging system — Part 1: General requirements
- SAE J1772: SAE Electric Vehicle and Plug in Hybrid Electric Vehicle Conductive Charge Coupler
- CharIN (Charging Interface Initiative): CCS specifications

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Charging system architects, power electronics engineers, communication protocol developers
