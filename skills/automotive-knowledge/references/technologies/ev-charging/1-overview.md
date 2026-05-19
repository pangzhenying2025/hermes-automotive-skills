# EV Charging - Overview

## Charging Landscape

Electric vehicle charging encompasses a wide range of power levels, connector types, and communication protocols. The charging ecosystem has evolved rapidly to support mass EV adoption.

### Charging Levels

**Level 1 (AC, 120V):**
- Power: 1.4-1.9 kW
- Connector: Standard household outlet (NEMA 5-15)
- Charge time: 40-50 hours for 60 kWh battery
- Use case: Emergency backup, overnight home charging

**Level 2 (AC, 240V):**
- Power: 3.7-19.2 kW (typical 7.2 kW residential)
- Connector: J1772 (North America), Type 2/Mennekes (Europe)
- Charge time: 4-10 hours for 60 kWh battery
- Use case: Home, workplace, destination charging

**DC Fast Charging (Level 3):**
- Power: 50-350 kW
- Connector: CCS (Combined Charging System), CHAdeMO, NACS/Tesla
- Charge time: 15-45 minutes (10-80%)
- Use case: Highway corridors, urban fast charging

**Ultra-Fast Charging:**
- Power: 350+ kW (up to 1 MW for trucks)
- Connector: CCS2 (MCS for megawatt charging)
- Charge time: 10-20 minutes (10-80%)
- Use case: Future high-power charging

## Charging Standards

### North America

**CCS1 (Combined Charging System Type 1):**
- Combines J1772 (AC) with two DC pins
- Supports up to 350 kW DC fast charging
- Adopted by most non-Tesla OEMs

**NACS (North American Charging Standard):**
- Tesla's proprietary connector (now open standard)
- Single connector for AC and DC (up to 1 MW)
- Compact design, widely deployed Supercharger network
- Ford, GM, Rivian adopting for 2025+ vehicles

**CHAdeMO:**
- Japanese standard (Nissan, Mitsubishi)
- Up to 400 kW (CHAdeMO 3.0)
- Declining adoption in favor of CCS/NACS

### Europe

**CCS2 (Type 2 Combo):**
- Combines Type 2 Mennekes (AC) with DC pins
- Standard across EU (mandatory for fast charging)
- Up to 350 kW

**Type 2 (Mennekes):**
- AC charging only (up to 43 kW three-phase)
- Widely deployed for destination charging

### China

**GB/T:**
- National standard (GB/T 20234)
- DC fast charging up to 250 kW
- Incompatible with CCS/CHAdeMO (different physical connector)

## Charging Architecture

### AC Charging

```
Grid (AC) → EVSE → Vehicle Inlet → Onboard Charger → Battery
                    ↓
              Control Pilot (PWM signal for power level)
```

**Onboard Charger (OBC):**
- Converts AC to DC for battery charging
- Power electronics: PFC + DC-DC converter
- Typically 3.7-11 kW (limited by vehicle packaging)

### DC Charging

```
Grid (AC) → Off-Board Charger → DC Power → Vehicle Inlet → Battery
              (Rectifier +           ↓
               DC-DC)           Charge Control (CAN/PLC)
```

**Off-Board Charger:**
- High-power AC-DC conversion (50-350 kW)
- Directly charges battery (bypasses OBC)
- Communication with BMS for charge curve

## Communication Protocols

### IEC 61851 (Basic Control Pilot)

PWM signal on control pilot pin indicates available current:

```
Duty Cycle:  Available Current
  10%  →     6 A
  20%  →     12 A
  30%  →     18 A
  ...
  85%  →     51 A
  90%  →     60 A
  97%  →     80 A (max for AC)
```

### ISO 15118 (Plug & Charge)

High-level communication over PLC (Power Line Communication):

- **Authentication**: PKI certificates for secure identification
- **Smart charging**: Dynamic power control, bidirectional (V2G)
- **Payment**: Automatic billing without RFID card
- **Language**: EXI (Efficient XML Interchange) messages

**Message Flow:**
```
1. EVSE → EV: SessionSetup
2. EV → EVSE: ServiceDiscovery (charge parameters)
3. EVSE → EV: PaymentOptions
4. EV → EVSE: AuthorizationRequest (certificate)
5. EVSE → EV: AuthorizationResponse (approved)
6. EV → EVSE: ChargeParameterDiscovery (target SOC, max current)
7. EVSE → EV: Start charging
8. (During charge): PowerDelivery messages
9. EV → EVSE: ChargingStop
10. EVSE → EV: SessionStop
```

### CHAdeMO Protocol

CAN-based communication (250 kbps):

- **Battery side**: SOC, voltage, current limits
- **Charger side**: Available power, status
- **Control loop**: 100 ms update rate

## Charging Curve Optimization

Batteries accept less power as SOC increases. Optimal charging follows a multi-stage curve:

```
Power
  │
  │  Constant Power          Constant Voltage
  │  ┌─────────────┐        ┌──────────────╲
  │  │             │        │                ╲
  │  │             │        │                 ╲ Taper
  │  │             │        │                  ╲
  │──┴─────────────┴────────┴───────────────────╲──────→ Time
     0%           60%       80%                  100% SOC

Stage 1 (0-60%): Constant power (limited by charger or BMS)
Stage 2 (60-80%): Begin tapering (cell voltage approaching limit)
Stage 3 (80-100%): Constant voltage, current tapers (balancing, protection)
```

**Typical 350 kW Charging Session (80 kWh battery):**
- 0-10%: Ramp up to 350 kW (battery cold, limit charge rate)
- 10-50%: 350 kW constant power
- 50-70%: Taper to 200 kW
- 70-80%: Taper to 100 kW
- 80-100%: Taper to 50 kW → 20 kW (slow balancing)

## Infrastructure Growth

### Global Deployment (2026)

| Region | Level 2 Ports | DC Fast Chargers | Notes |
|--------|---------------|------------------|-------|
| USA | 300,000+ | 50,000+ | NEVI funding accelerating buildout |
| Europe | 500,000+ | 100,000+ | EU mandate: 1 charger per 60 km highway |
| China | 2,000,000+ | 800,000+ | Leading global deployment |
| World Total | 4,000,000+ | 1,200,000+ | Growing 40% annually |

### Cost Trends

| Component | 2020 | 2026 | Notes |
|-----------|------|------|-------|
| Level 2 EVSE (hardware) | $600 | $400 | Commoditization |
| 50 kW DC fast charger | $40,000 | $25,000 | Improved power electronics |
| 350 kW DC fast charger | $120,000 | $80,000 | Economies of scale |
| Installation (L2 home) | $1,000 | $800 | Electrical work, permit |
| Installation (DC public) | $50,000 | $35,000 | Grid connection, civil work |

## Key Challenges

### Grid Integration
- **Peak demand**: Fast chargers stress local distribution
- **Load balancing**: Dynamic power sharing among stalls
- **Grid services**: V2G can stabilize grid (frequency regulation)

### Charging Speed vs Battery Life
- **Fast charging heat**: Degrades battery faster
- **Lithium plating**: Risk during cold weather fast charging
- **Optimal strategy**: Preheat battery, charge to 80%, slow taper

### Standardization
- **Connector fragmentation**: CCS vs CHAdeMO vs NACS
- **Protocol versions**: ISO 15118-2 vs 15118-20
- **Roaming**: Cross-network compatibility (OCPP, OCPI protocols)

### User Experience
- **Charger availability**: "Broken charger" problem
- **Payment friction**: Multiple apps, RFID cards
- **Charge time anxiety**: Unpredictable session duration

## Business Models

### Charging Network Operators

- **Tesla Supercharger**: Proprietary (opening to other OEMs)
- **Electrify America**: VW-funded, CCS network (USA)
- **Ionity**: Joint venture (BMW, Mercedes, Ford, Hyundai) — Europe
- **ChargePoint, EVgo, Blink**: Independent networks (USA)

### Revenue Streams

1. **Per-kWh pricing**: $0.30-0.60/kWh (varies by location)
2. **Time-based pricing**: $0.10-0.30/minute (discourages overstaying)
3. **Subscription**: Flat monthly fee for unlimited charging
4. **Idle fees**: Penalty for staying after charge complete

## Next Steps

- **Level 2**: Conceptual understanding of AC vs DC architecture, communication stack
- **Level 3**: Detailed ISO 15118 Plug & Charge implementation
- **Level 4**: Connector pinouts, power level tables, protocol message catalog
- **Level 5**: V2G grid services, smart charging optimization, wireless charging

## References

- IEC 61851: Electric vehicle conductive charging system
- ISO 15118: Road vehicles — Vehicle to grid communication interface
- SAE J1772: SAE Electric Vehicle and Plug in Hybrid Electric Vehicle Conductive Charge Coupler
- CHAdeMO Protocol: https://www.chademo.com/

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: EV engineers, charging infrastructure developers, product managers
