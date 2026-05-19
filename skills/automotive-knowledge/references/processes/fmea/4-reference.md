# FMEA - Reference Tables and Templates

## Quick Reference: S-O-D Rating Scales

### Severity (S) Rating Table

| S | Effect Classification | Criteria | Automotive Examples |
|---|---------------------|----------|-------------------|
| 10 | Hazardous without warning | Safety hazard, violates regulations, no warning | Brake failure without warning light; airbag non-deployment; thermal runaway fire |
| 9 | Hazardous with warning | Safety hazard with prior warning | Brake failure with ABS warning; power steering loss with dashboard alert |
| 8 | Very High | Vehicle/system inoperable | Complete powertrain shutdown; HV battery isolation; total communication loss |
| 7 | High | Vehicle operable with major performance loss | 50% power reduction; ADAS system disabled; degraded braking performance |
| 6 | Moderate | Vehicle operable with moderate performance loss | 20% range reduction; delayed response (<5s); moderate NVH increase |
| 5 | Low | Vehicle operable with minor performance loss | 5% efficiency loss; minor feature unavailable; slight increase in charging time |
| 4 | Very Low | Minor inconvenience to customer | Cosmetic defect; non-critical feature delayed start; minor UI glitch |
| 3 | Minor | Minimal customer impact | Visual blemish not normally visible; very minor performance variation |
| 2 | Very Minor | Barely noticeable defect | Fit/finish variation within tolerance; unnoticeable performance variation |
| 1 | None | No effect | Defect has no customer or regulatory impact |

### Occurrence (O) Rating Table

| O | Probability | Failure Rate (PPM) | Cpk | Probability (%) | Automotive Interpretation |
|---|------------|------------------|-----|--------------|--------------------------|
| 10 | Very High | ≥100,000 | <0.55 | ≥10% | Failure almost certain; inherent design weakness |
| 9 | High | 50,000 | 0.55 | 5% | Repeated failures in similar designs; poor process capability |
| 8 | High | 20,000 | 0.78 | 2% | Frequent failures in testing or field; design margin inadequate |
| 7 | Moderate | 10,000 | 0.86 | 1% | Occasional failures in testing; borderline design margin |
| 6 | Moderate | 2,000 | 1.00 | 0.2% | Some failures observed in validation; acceptable process |
| 5 | Low | 500 | 1.10 | 0.05% | Few failures in extensive testing; good design margin |
| 4 | Low | 100 | 1.20 | 0.01% | Rare failures only in accelerated testing; robust design |
| 3 | Very Low | 20 | 1.30 | 0.002% | Isolated failures in extreme conditions; highly reliable |
| 2 | Remote | 2 | 1.67 | 0.0002% | Theoretically possible but never observed; excellent design |
| 1 | Nearly Impossible | <0.1 | >1.67 | <0.00001% | Failure mode physically prevented by design |

**PPM Conversion**:
- 1% = 10,000 PPM
- 0.1% = 1,000 PPM
- 100 PPM = 0.01% = 1 in 10,000

### Detection (D) Rating Table

| D | Detection Capability | Likelihood of Detection | Control Type | Automotive Examples |
|---|-------------------|----------------------|--------------|-------------------|
| 10 | Absolute Uncertainty | Cannot detect | None | No test exists; failure mode unknown until field failure |
| 9 | Very Remote | Very unlikely to detect | Indirect, subjective | Random visual inspection; operator feel/sound assessment |
| 8 | Remote | Remote chance | Manual inspection | Manual measurement with hand tools; visual solder joint check |
| 7 | Very Low | Very low chance | Manual with gauge | Go/no-go gauge; manual torque wrench check |
| 6 | Low | Low chance | Manual inspection 100% | 100% manual dimensional check; operator-triggered test |
| 5 | Moderate | Moderate chance | Statistical sampling | SPC control charts; sample-based testing (AQL) |
| 4 | Moderately High | High chance | Automated with override | Automated test with manual pass/fail decision |
| 3 | High | Very high chance | Automated detection | 100% automated EOL test; in-circuit test (ICT) |
| 2 | Very High | Detection almost certain | Automated with fail-safe | Built-in self-test (BIST) with safe mode; redundant sensors |
| 1 | Almost Certain | Defect cannot escape | Design prevents failure | Physical design prevents failure mode occurrence |

## Action Priority (AP) Matrix

Alternative to RPN calculation (AIAG FMEA-4 and newer).

### AP Matrix: Severity 9-10

| Occurrence → | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|--------------|---|---|---|---|---|---|---|---|---|-----|
| **Detection** |
| 1 | M | M | M | H | H | H | H | H | H | H |
| 2 | M | M | M | H | H | H | H | H | H | H |
| 3 | M | M | H | H | H | H | H | H | H | H |
| 4 | M | H | H | H | H | H | H | H | H | H |
| 5 | M | H | H | H | H | H | H | H | H | H |
| 6 | H | H | H | H | H | H | H | H | H | H |
| 7 | H | H | H | H | H | H | H | H | H | H |
| 8 | H | H | H | H | H | H | H | H | H | H |
| 9 | H | H | H | H | H | H | H | H | H | H |
| 10 | H | H | H | H | H | H | H | H | H | H |

### AP Matrix: Severity 7-8

| Occurrence → | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|--------------|---|---|---|---|---|---|---|---|---|-----|
| **Detection** |
| 1 | L | L | L | M | M | M | M | H | H | H |
| 2 | L | L | L | M | M | M | H | H | H | H |
| 3 | L | L | M | M | M | H | H | H | H | H |
| 4 | L | L | M | M | H | H | H | H | H | H |
| 5 | L | M | M | H | H | H | H | H | H | H |
| 6 | L | M | H | H | H | H | H | H | H | H |
| 7 | M | M | H | H | H | H | H | H | H | H |
| 8 | M | H | H | H | H | H | H | H | H | H |
| 9 | M | H | H | H | H | H | H | H | H | H |
| 10 | H | H | H | H | H | H | H | H | H | H |

### AP Matrix: Severity 4-6

| Occurrence → | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|--------------|---|---|---|---|---|---|---|---|---|-----|
| **Detection** |
| 1-3 | L | L | L | L | L | M | M | M | M | H |
| 4-6 | L | L | L | L | M | M | M | H | H | H |
| 7-10 | L | L | L | M | M | M | H | H | H | H |

**AP Legend**:
- **H** = High Priority (immediate action required)
- **M** = Medium Priority (action should be planned)
- **L** = Low Priority (monitor, action optional)

## Common Failure Modes Catalog

### Electronic Hardware

| Component | Common Failure Modes | Typical Causes | Detection Methods |
|-----------|-------------------|---------------|------------------|
| Microcontroller | Stuck in reset; Watchdog timeout; Corrupted flash | ESD; Latchup; Power supply glitch | Self-test; External watchdog |
| ADC | Offset error; Gain error; Non-linearity | Reference drift; Temperature; Aging | Known voltage self-test |
| MOSFET | Short drain-source; Open drain; Gate oxide breakdown | Overcurrent; ESD; Thermal stress | In-circuit test; Functional test |
| Capacitor (electrolytic) | ESR increase; Capacitance loss; Open circuit | Temperature aging; Ripple current | ESR monitoring; Voltage ripple |
| Resistor | Resistance drift; Open circuit | Power dissipation; Moisture | Tolerance verification test |
| Crystal Oscillator | Frequency drift; No oscillation | Mechanical shock; Load capacitance | Frequency counter self-test |
| Connector | High contact resistance; Open circuit | Fretting corrosion; Vibration | Contact resistance monitoring |
| PCB Trace | Open circuit; Short circuit | Thermal stress; Mechanical flex | Boundary scan (JTAG) |

### Software

| Function | Common Failure Modes | Typical Causes | Detection Methods |
|----------|-------------------|---------------|------------------|
| Task Scheduling | Missed deadline; Task starvation | CPU overload; Priority inversion | Deadline monitoring; CPU load |
| Memory Management | Memory leak; Heap corruption; Stack overflow | Pointer errors; Recursion | Stack canary; Heap integrity check |
| Communication | Message timeout; Wrong data; Sequence error | Synchronization; Race condition | E2E protection; Timeout detection |
| Calculation | Overflow; Divide-by-zero; Precision loss | Boundary condition; Floating-point | Range checking; Unit tests |
| State Machine | Stuck in state; Invalid transition | Unhandled event; Race condition | State timeout; Watchdog |
| Calibration | Wrong parameters loaded; Data corruption | EEPROM error; CRC mismatch | CRC validation; Range check |

### Mechanical (EV Battery)

| Component | Common Failure Modes | Typical Causes | Detection Methods |
|-----------|-------------------|---------------|------------------|
| Cell | Internal short; Capacity fade; High impedance | Manufacturing defect; Cycling; Aging | Voltage monitoring; Impedance test |
| Busbar | High resistance joint; Fracture | Vibration; Thermal cycling | Resistance monitoring; Strain gauge |
| Cooling System | Coolant leak; Pump failure; Blocked flow | Corrosion; Bearing wear; Debris | Flow sensor; Temperature gradient |
| Contactor | Welded contacts; Coil open; Contact erosion | Overcurrent; Mechanical wear | Auxiliary contact; Voltage check |
| Current Sensor | Offset drift; Saturation; Open sense wire | Temperature; Magnetic interference | Self-test; Cross-check with multiple |
| Enclosure | Seal failure; Corrosion; Mechanical damage | Aging; Environmental; Impact | Leak test; Visual inspection |

## FMEA Worksheets

### DFMEA Template (Automotive)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ DESIGN FMEA (DFMEA) - Automotive                                           │
├────────────────────────────────────────────────────────────────────────────┤
│ System/Subsystem: _______________________  FMEA Number: _________________ │
│ Design Responsibility: ___________________  Page: _____ of _____ │
│ Model Year/Vehicle: _______________________  Key Date: __________________ │
│ Prepared By: ______________________________  FMEA Date (Orig): __________ │
│ Core Team: ________________________________  FMEA Date (Rev): ___________ │
└────────────────────────────────────────────────────────────────────────────┘

┌──────┬───────────┬──────────┬───┬──────────┬───┬──────────┬───┬─────┬────────────┬────────────┬────┬────┬────┬──────┐
│ Item │ Potential │ Potential│ S │ Potential│ O │ Current  │ D │ RPN │ Recommended│ Resp. &    │ S' │ O' │ D' │ RPN' │
│ or   │ Failure   │ Effect(s)│   │ Cause(s)/│   │ Design   │   │     │ Action(s)  │ Target     │    │    │    │      │
│ Func │ Mode      │ of       │   │ Mechanism│   │ Controls │   │     │            │ Completion │    │    │    │      │
│      │           │ Failure  │   │          │   │          │   │     │            │ Date       │    │    │    │      │
├──────┼───────────┼──────────┼───┼──────────┼───┼──────────┼───┼─────┼────────────┼────────────┼────┼────┼────┼──────┤
│      │           │          │   │          │   │ Prevent: │   │     │            │            │    │    │    │      │
│      │           │          │   │          │   │          │   │     │            │            │    │    │    │      │
│      │           │          │   │          │   │ Detect:  │   │     │            │            │    │    │    │      │
├──────┼───────────┼──────────┼───┼──────────┼───┼──────────┼───┼─────┼────────────┼────────────┼────┼────┼────┼──────┤
│      │           │          │   │          │   │          │   │     │ Actions    │            │    │    │    │      │
│      │           │          │   │          │   │          │   │     │ Taken:     │            │    │    │    │      │
└──────┴───────────┴──────────┴───┴──────────┴───┴──────────┴───┴─────┴────────────┴────────────┴────┴────┴────┴──────┘
```

### PFMEA Template (Manufacturing Process)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ PROCESS FMEA (PFMEA)                                                       │
├────────────────────────────────────────────────────────────────────────────┤
│ Process: ______________________________  FMEA Number: ___________________ │
│ Process Responsibility: ________________  Page: _____ of _____ │
│ Model Year/Product: ____________________  Key Date: ____________________ │
│ Prepared By: ___________________________  FMEA Date (Orig): _____________ │
│ Core Team: _____________________________  FMEA Date (Rev): ______________ │
└────────────────────────────────────────────────────────────────────────────┘

┌──────────┬──────────┬──────────┬───┬──────────┬───┬──────────┬───┬─────┬────────────┬────────────┬────┬────┬────┬──────┐
│ Process  │ Potential│ Potential│ S │ Potential│ O │ Current  │ D │ RPN │ Recommended│ Resp. &    │ S' │ O' │ D' │ RPN' │
│ Function/│ Failure  │ Effect(s)│   │ Cause(s)/│   │ Process  │   │     │ Action(s)  │ Target     │    │    │    │      │
│ Require- │ Mode     │ of       │   │ Mechanism│   │ Controls │   │     │            │ Completion │    │    │    │      │
│ ment     │          │ Failure  │   │          │   │          │   │     │            │ Date       │    │    │    │      │
├──────────┼──────────┼──────────┼───┼──────────┼───┼──────────┼───┼─────┼────────────┼────────────┼────┼────┼────┼──────┤
│          │          │          │   │          │   │ Prevent: │   │     │            │            │    │    │    │      │
│          │          │          │   │          │   │          │   │     │            │            │    │    │    │      │
│          │          │          │   │          │   │ Detect:  │   │     │            │            │    │    │    │      │
└──────────┴──────────┴──────────┴───┴──────────┴───┴──────────┴───┴─────┴────────────┴────────────┴────┴────┴────┴──────┘
```

## ISO 26262 ASIL Mapping to FMEA Severity

| FMEA Severity | ASIL Level | ISO 26262 Interpretation |
|--------------|-----------|-------------------------|
| S = 10 | ASIL D | Severe injuries, life-threatening, multiple fatalities |
| S = 9 | ASIL C-D | Severe injuries, life-threatening, single fatality |
| S = 8 | ASIL B-C | Moderate injuries, severe injuries (controllable) |
| S = 7 | ASIL A-B | Light injuries, moderate injuries (controllable) |
| S ≤ 6 | QM or ASIL A | No injuries or light injuries (easily controllable) |

**Note**: ASIL also considers Controllability (C) and Exposure (E), not just Severity.

## FMEA-to-DV Matrix

Map FMEA failure modes to Design Verification (DV) tests.

| FMEA Failure Mode | DV Test | Test Method | Pass/Fail Criteria | Status |
|------------------|---------|-------------|-------------------|--------|
| Cell overvoltage | DV-BMS-015 | Apply 4.3V to cell input, verify cutoff | BMS opens contactor within 100ms | Pass |
| CAN timeout | DV-COM-008 | Stop CAN messages, verify fault detection | DTC set within 500ms | Pass |
| Temperature sensor open | DV-SENSOR-003 | Disconnect sensor, verify fault mode | Default to safe temperature limit | Fail (re-test) |

## FMEA Lessons Learned Database

Track recurring failure modes across projects for proactive prevention.

| Failure Mode | Project | Root Cause | Prevention Strategy | Applicability |
|--------------|---------|-----------|-------------------|--------------|
| ADC reference drift | BMS Gen2 | Low-cost reference IC | Use precision reference with <50ppm drift | All ADC circuits |
| CAN transceiver latchup | Inverter V1 | Lack of TVS protection | Add bi-directional TVS on CANH/CANL | All CAN interfaces |
| Software race condition | ADAS V3 | Non-atomic flag access | Use mutex or atomic operations | Multi-threaded code |
| Solder joint crack | HV Pack 2019 | Thermal mismatch (Cu/Al) | Add stress relief or use flexible busbar | Mixed-metal joints |

## Action Tracking Template

```
┌────────────────────────────────────────────────────────────────┐
│ FMEA ACTION TRACKING                                           │
├────────────────────────────────────────────────────────────────┤
│ FMEA ID: DFMEA-BMS-001             Date Opened: 2026-03-15    │
│ Project: Battery Management System                            │
└────────────────────────────────────────────────────────────────┘

Action ID: FMEA-BMS-001-A01
Item/Function: Cell voltage sensing
Failure Mode: Incorrect voltage reading due to ADC drift
Current RPN: 240 (S=10, O=4, D=6)

Recommended Action: Implement runtime ADC self-test

Details:
- Add self-test routine comparing ADC reading of precision reference voltage
- Run self-test every 10 seconds during normal operation
- If error >1%, set DTC and enter safe mode (contactor open)
- Verify in DVT testing

Responsibility: John Smith (Firmware Lead)
Target Completion: 2026-04-30
Actual Completion: 2026-04-28

Verification:
- [ ] Design review completed (2026-04-10)
- [X] Code review completed (2026-04-20)
- [X] Unit testing completed (2026-04-22)
- [X] Integration testing completed (2026-04-25)
- [X] DVT validation completed (2026-04-28)

Revised Ratings:
- S' = 10 (unchanged)
- O' = 2 (drift detected before causing overvoltage)
- D' = 2 (automated detection with fail-safe)
- RPN' = 40 (83% reduction)

Status: CLOSED (2026-04-28)
Verified By: Sarah Johnson (Quality Engineer)
```

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: FMEA practitioners, quality engineers, design teams
