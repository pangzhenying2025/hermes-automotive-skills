# EV Charging - Quick Reference

## Connector Pinouts

### CCS1 (Combo 1 - North America)

```
J1772 AC Section (Top 5 pins):
Pin 1: L1 (AC Line 1) - 240V AC
Pin 2: L2 (AC Line 2) - 240V AC  
Pin 3: PE (Protective Earth) - Ground
Pin 4: CP (Control Pilot) - 12V PWM signaling
Pin 5: PP (Proximity Pilot) - Cable detection

DC Section (Bottom 2 pins):
Pin 6: DC+ (Positive DC power)
Pin 7: DC- (Negative DC power / Ground)

Communication:
- AC: PWM on Control Pilot (pin 4)
- DC: CAN (250 kbps) or PLC (HomePlug Green PHY) on Control Pilot
```

### CCS2 (Combo 2 - Europe/Global)

```
Type 2 AC Section (Top 7 pins):
Pin 1: L1 (Phase 1)
Pin 2: L2 (Phase 2)  
Pin 3: L3 (Phase 3)
Pin 4: N (Neutral)
Pin 5: PE (Protective Earth)
Pin 6: CP (Control Pilot)
Pin 7: PP (Proximity Pilot)

DC Section (Bottom 2 pins):
Pin 8: DC+ 
Pin 9: DC-
```

### NACS (Tesla/North American Charging Standard)

```
Compact 5-pin design (AC and DC in same pins):

Pin A1: AC Line 1 / DC+ (High voltage)
Pin A2: AC Line 2 / DC- (High voltage)
Pin B1: Neutral / Ground
Pin B2: Control Pilot (PWM + PLC)
Pin B3: Proximity detection

Max ratings:
- AC: 277V, 80A (19.2 kW single-phase)
- DC: 1000V, 1000A (1 MW)
```

### CHAdeMO

```
10-pin DC connector:

Pin 1: Ground chassis
Pin 2: Charge enable input
Pin 3: Charge permission
Pin 4: Charge stop control
Pin 5: CAN High (vehicle-charger communication)
Pin 6: CAN Low
Pin 7: DC+ (Positive power)
Pin 8: DC- (Negative power)
Pin 9: Proximity detection
Pin 10: Start button

CAN bus: 250 kbps, 120Ω termination both ends
```

## Power Level Tables

### AC Charging Power Levels

| Phase | Voltage (V) | Current (A) | Power (kW) | Typical Use |
|-------|-------------|-------------|------------|-------------|
| **Single-phase (North America)** |
| 1-phase | 120 | 12 | 1.4 | Level 1 (emergency) |
| 1-phase | 120 | 16 | 1.9 | Level 1 (max) |
| 1-phase | 240 | 16 | 3.8 | Level 2 (basic) |
| 1-phase | 240 | 32 | 7.7 | Level 2 (home) |
| 1-phase | 240 | 40 | 9.6 | Level 2 (high) |
| 1-phase | 240 | 80 | 19.2 | Level 2 (max) |
| **Three-phase (Europe)** |
| 3-phase | 400 | 16 | 11.0 | Home charging |
| 3-phase | 400 | 32 | 22.0 | Public AC charging |
| 3-phase | 400 | 63 | 43.0 | Rare (few vehicles support) |

Formula: P = √3 × V_line × I × cos(φ)  
For single-phase: P = V × I

### DC Fast Charging Power Levels

| Standard | Voltage (V) | Current (A) | Power (kW) | Deployment |
|----------|-------------|-------------|------------|------------|
| **CCS** |
| CCS 50 kW | 200-500 | 100-125 | 50 | Early DC chargers |
| CCS 150 kW | 300-500 | 300 | 150 | Common highway |
| CCS 350 kW | 400-800 | 400-500 | 350 | Ultra-fast (2024+) |
| CCS 1 MW | 800-1000 | 1000 | 1000 | Future trucks (MCS) |
| **CHAdeMO** |
| CHAdeMO 1.x | 200-500 | 125 | 62.5 | Gen 1 |
| CHAdeMO 2.0 | 200-500 | 200 | 100-200 | Current |
| CHAdeMO 3.0 | 200-1000 | 400 | 400 | Future (rare) |
| **NACS** |
| Supercharger V2 | 400 | 350 | 150 | Tesla (2012-2019) |
| Supercharger V3 | 400 | 625 | 250 | Tesla (2019+) |
| Supercharger V4 | 400-800 | 1000 | 350-1000 | Tesla (2024+), supports CCS |

## Cable Specifications

| Power Level | Conductor Size (AWG) | Max Length (m) | Cooling | Weight (kg/m) |
|-------------|----------------------|----------------|---------|---------------|
| 3.8 kW (16A) | 14 AWG | 7.5 | None | 0.3 |
| 7.7 kW (32A) | 10 AWG | 7.5 | None | 0.5 |
| 19.2 kW (80A) | 4 AWG | 5.0 | None | 1.2 |
| 50 kW | 25 mm² | 5.0 | None | 2.0 |
| 150 kW | 35 mm² | 5.0 | Optional | 2.5 |
| 350 kW | 70 mm² | 3.0 | Liquid-cooled | 3.5 |

**Liquid-Cooled Cable:**
- Coolant: 50% water / 50% glycol
- Flow rate: 2-4 L/min
- Temperature: 20-40°C
- Allows 50% higher current density (thinner cables)

## Temperature Limits

### Connector Derating

| Ambient Temp | CCS Power Limit | NACS Power Limit | Notes |
|--------------|-----------------|------------------|-------|
| -30°C | 50% | 70% | Cold derating, battery preheating |
| -10°C | 80% | 90% | Moderate cold |
| 0-40°C | 100% | 100% | Nominal operation |
| 45°C | 90% | 95% | Hot ambient |
| 50°C | 80% | 85% | High derating, may pause |
| 55°C+ | 0% | 0% | Emergency shutdown |

### Connector Pin Temperature Limits

| Component | Warning (°C) | Fault (°C) | Shutdown (°C) |
|-----------|--------------|------------|---------------|
| Contact pin | 70 | 90 | 105 |
| Cable insulation | 80 | 100 | 120 |
| Inlet housing | 60 | 80 | 100 |
| Liquid coolant | 50 | 60 | 70 |

Monitoring: RTD sensors (PT100/PT1000) in connector and cable

## Protocol Message Catalog

### ISO 15118 Key Messages

```
Session Management:
- SessionSetupReq/Res: Establish charging session
- SessionStopReq/Res: End charging session

Service Discovery:
- ServiceDiscoveryReq/Res: List available services (AC, DC, payment)
- ServiceDetailReq/Res: Get details of selected service

Payment:
- PaymentServiceSelectionReq/Res: Choose payment method
- PaymentDetailsReq/Res: Provide payment information
- AuthorizationReq/Res: Authorize with contract certificate

Charging Control:
- ChargeParameterDiscoveryReq/Res: Negotiate charge parameters (voltage, current)
- CableCheckReq/Res: Verify high-voltage isolation (DC only)
- PreChargeReq/Res: Match charger voltage to battery voltage (DC only)
- PowerDeliveryReq/Res: Start/stop power flow
- CurrentDemandReq/Res: Request specific current (DC, 100 ms loop)
- ChargingStatusReq/Res: Monitor charging progress (AC)
```

### CHAdeMO CAN Messages

```
Vehicle → Charger (100 ms):
0x100: Vehicle status (SOC, voltage, current request, enable)
0x101: Vehicle limits (max voltage, max current)
0x102: Vehicle parameters (capacity, target voltage)

Charger → Vehicle (100 ms):
0x108: Charger status (output voltage, output current, status flags)
0x109: Charger limits (available voltage, available current)
0x10A: Charger parameters (protocol version, max power)

Error Codes:
0x00: No error
0x01: Battery overvoltage
0x02: Battery overheat
0x04: Battery overcurrent
0x08: Ground fault
0x10: Charger malfunction
0x20: Communication timeout
```

### IEC 61851 Control Pilot PWM

| Duty Cycle (%) | Available Current (A) | Cable Rating | Notes |
|----------------|-----------------------|--------------|-------|
| 10 | 6 | 14 AWG | Minimum |
| 20 | 12 | 12 AWG | |
| 30 | 18 | 10 AWG | |
| 40 | 24 | 8 AWG | |
| 50 | 30 | 6 AWG | |
| 60 | 36 | 4 AWG | |
| 70 | 42 | 2 AWG | |
| 80 | 48 | 1 AWG | |
| 85 | 51 | 1/0 AWG | |
| 90 | 60 | 2/0 AWG | |
| 96 | 80 | 4/0 AWG | Maximum |

Formula: I = Duty Cycle (%) × 0.6 A  
(For duty cycles 10-85%)

## Charging Session Metrics

### Typical Session Duration (80 kWh battery, 10-80% SOC)

| Charger Power | Energy Delivered | Duration | Cost @ $0.40/kWh |
|---------------|------------------|----------|------------------|
| 7.2 kW (Level 2) | 56 kWh | 7.8 hours | $22.40 |
| 50 kW (DC Fast) | 56 kWh | 1.1 hours | $22.40 |
| 150 kW (DC Fast) | 56 kWh | 22 minutes | $22.40 |
| 350 kW (DC Ultra) | 56 kWh | 10 minutes | $22.40 |

Note: Assumes average power accounting for charge curve taper

### Energy Efficiency

| Component | Typical Loss | Range |
|-----------|--------------|-------|
| Grid → EVSE (AC) | 2-5% | 1-8% |
| Onboard charger (AC→DC) | 5-8% | 3-12% |
| Off-board charger (DC) | 3-5% | 2-7% |
| Cable resistance | 1-3% | 0.5-5% |
| Battery (charging) | 2-5% | 1-8% |
| **Total (AC charging)** | **10-21%** | **8-33%** |
| **Total (DC charging)** | **6-13%** | **4-20%** |

## Debugging Checklist

- [ ] Control pilot signal present and correct frequency (1 kHz ± 1%)
- [ ] Duty cycle matches cable rating
- [ ] Ground continuity verified (<0.1Ω resistance)
- [ ] Proximity pilot resistance correct for cable (150Ω, 480Ω, 1kΩ)
- [ ] Vehicle inlet temperature sensors functional
- [ ] CAN/PLC communication established (check bus termination)
- [ ] TLS handshake successful (verify certificates not expired)
- [ ] Charge curve follows BMS limits (no overpower)
- [ ] Contactor closing/opening properly (check precharge resistor)
- [ ] Current imbalance between phases <10% (three-phase)

## Common Fault Codes

| Code | Description | Cause | Resolution |
|------|-------------|-------|------------|
| E01 | Ground fault | Insulation failure | Check HV isolation (>100kΩ) |
| E02 | Overvoltage | BMS limit exceeded | Reduce charge power |
| E03 | Overcurrent | Cable/charger overload | Check current limits |
| E04 | Overtemperature | Connector/cable hot | Pause charging, inspect connector |
| E05 | Communication timeout | CAN/PLC failure | Check bus, cables, termination |
| E06 | Authentication failed | Invalid certificate | Verify contract cert validity |
| E07 | Payment declined | Backend rejection | Contact CPO support |
| E08 | Charger fault | Internal charger error | Reset charger, contact CPO |

## Next Steps

- **Level 5**: V2G grid services, virtual power plants, wireless charging
- **Standards**: IEC 61851, ISO 15118-20 (bidirectional), OCPP 2.0.1
- **Tools**: Vector CANalyzer for protocol analysis, Keysight AC/DC source for testing

## References

- IEC 61851-1: EV conductive charging system
- ISO 15118 series: Vehicle-to-grid communication
- SAE J1772: EV/PHEV conductive coupler
- CharIN (Charging Interface Initiative) specifications
- NACS Connector Specification (Tesla/SAE)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All EV charging engineers (quick lookup during development and troubleshooting)
