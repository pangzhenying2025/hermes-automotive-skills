# FMEA - Failure Mode and Effects Analysis - Overview

## What is FMEA?

FMEA (Failure Mode and Effects Analysis) is a systematic, proactive method for identifying potential failure modes in a system, product, or process, and assessing their impact on system performance. In automotive development, FMEA is a critical tool for achieving quality and safety objectives.

## Types of FMEA

### Design FMEA (DFMEA)
Analyzes potential failures in product design before production.

**Focus**: Product components and subsystems
**Timing**: Concept and design phases
**Responsibility**: Design engineering team

**Example**: Battery management system voltage sensing circuit failure

### Process FMEA (PFMEA)
Analyzes potential failures in manufacturing and assembly processes.

**Focus**: Manufacturing steps and equipment
**Timing**: Production planning phase
**Responsibility**: Manufacturing engineering team

**Example**: Soldering temperature out of spec during ECU assembly

### System FMEA (SFMEA)
Analyzes potential failures at system level interactions.

**Focus**: System-level functions and interfaces
**Timing**: System architecture phase
**Responsibility**: Systems engineering team

**Example**: Vehicle network communication failure between ECUs

### Software FMEA (SW-FMEA)
Analyzes potential software failures and their effects.

**Focus**: Software modules and data flows
**Timing**: Software architecture phase
**Responsibility**: Software engineering team

**Example**: Division by zero in cruise control algorithm

## Key Concepts

### Failure Mode
The manner in which a component, subsystem, or system could potentially fail to meet design intent.

**Examples**:
- Sensor provides out-of-range reading
- Component fractures under load
- Software hangs in infinite loop
- Communication message lost

### Effect
The consequence of a failure mode on the system, customer, or regulations.

**Examples**:
- Vehicle unable to start
- Reduced braking performance
- Warning light illuminates
- Regulatory non-compliance

### Cause
The underlying reason for the failure mode occurrence.

**Examples**:
- Material fatigue
- Manufacturing defect
- Software bug
- Environmental stress

### Controls
Actions taken to prevent the cause or detect the failure.

**Prevention Controls**: Prevent cause from occurring
**Detection Controls**: Detect failure before it reaches customer

## Risk Priority Number (RPN)

RPN = Severity × Occurrence × Detection

### Severity (S)
Impact of the failure effect on the customer/system (1-10 scale).

| Rating | Description | Criteria |
|--------|-------------|----------|
| 10 | Hazardous without warning | Safety-critical, no warning |
| 9 | Hazardous with warning | Safety-critical, with warning |
| 8 | Very high | Vehicle inoperable |
| 7 | High | Vehicle operable with reduced performance |
| 6 | Moderate | Vehicle operable with discomfort |
| 5 | Low | Noticeable degradation |
| 4 | Very low | Minor degradation |
| 3 | Minor | Minor effect, most customers notice |
| 2 | Very minor | Minor effect, few customers notice |
| 1 | None | No effect |

### Occurrence (O)
Probability that the cause will occur (1-10 scale).

| Rating | Description | Probability | CPK |
|--------|-------------|-------------|-----|
| 10 | Very high | ≥ 1 in 2 | < 0.33 |
| 9 | Very high | 1 in 3 | ≥ 0.33 |
| 8 | High | 1 in 8 | ≥ 0.51 |
| 7 | High | 1 in 20 | ≥ 0.67 |
| 6 | Moderate | 1 in 80 | ≥ 0.83 |
| 5 | Moderate | 1 in 400 | ≥ 1.00 |
| 4 | Low | 1 in 2,000 | ≥ 1.17 |
| 3 | Low | 1 in 15,000 | ≥ 1.33 |
| 2 | Remote | 1 in 150,000 | ≥ 1.50 |
| 1 | Nearly impossible | < 1 in 1,500,000 | ≥ 1.67 |

### Detection (D)
Ability to detect the cause or failure mode (1-10 scale).

| Rating | Description | Criteria |
|--------|-------------|----------|
| 10 | Absolute uncertainty | No detection method |
| 9 | Very remote | Detection unlikely |
| 8 | Remote | Manual inspection |
| 7 | Very low | Manual inspection with high effort |
| 6 | Low | Statistical process control |
| 5 | Moderate | SPC with periodic checks |
| 4 | Moderately high | Automated detection after process |
| 3 | High | Automated detection in process |
| 2 | Very high | Error-proofing, 100% inspection |
| 1 | Almost certain | Automatic detection prevents defect |

### RPN Thresholds

**Critical**: RPN > 200 → Immediate action required
**High**: RPN 100-200 → Action required
**Moderate**: RPN 50-100 → Review and consider actions
**Low**: RPN < 50 → Monitor

## FMEA Process Flow

```
1. Define Scope
   ↓
2. Assemble Team
   ↓
3. Identify Functions
   ↓
4. Identify Failure Modes
   ↓
5. Identify Effects
   ↓
6. Assign Severity
   ↓
7. Identify Causes
   ↓
8. Assign Occurrence
   ↓
9. Identify Current Controls
   ↓
10. Assign Detection
    ↓
11. Calculate RPN
    ↓
12. Prioritize Actions
    ↓
13. Implement Actions
    ↓
14. Re-evaluate RPN
    ↓
15. Document & Review
```

## FMEA Worksheet Structure

| Component | Function | Failure Mode | Effect | S | Cause | O | Controls | D | RPN | Actions | Responsibility | Status |
|-----------|----------|--------------|--------|---|-------|---|----------|---|-----|---------|----------------|--------|
| Brake sensor | Measure brake pedal position | Sensor stuck at 0% | No braking | 10 | Mechanical jam | 3 | Redundant sensor | 2 | 60 | Add plausibility check | SW Team | Open |
| CAN bus | Transmit messages | Bus-off error | Loss of communication | 9 | EMI interference | 4 | CRC, timeout | 3 | 108 | Add shielding | HW Team | Closed |

## Relationship to Standards

### ISO 26262 (Functional Safety)
- FMEA used in Part 9: ASIL-oriented analyses
- Software FMEA for ASIL B and above
- Hardware FMEA for safety mechanism coverage

### ASPICE (Automotive SPICE)
- SUP.9: Problem Resolution Management
- SWE.4: Software Qualitative Analysis

### IATF 16949 (Quality Management)
- Section 8.3.5.1: Design and development outputs
- Section 8.5.1.1: Control plan

### AIAG-VDA FMEA Handbook
- Latest methodology (2019)
- 7-step approach
- Action Priority (AP) replaces RPN in newer versions

## Benefits

**Proactive Risk Management**
- Identify issues before production
- Reduce warranty costs
- Prevent safety incidents

**Knowledge Capture**
- Document design rationale
- Share lessons learned
- Support design reviews

**Regulatory Compliance**
- Satisfy ISO 26262 requirements
- Meet ASPICE expectations
- Support type approval

**Cost Savings**
- Fix issues early (cheaper)
- Reduce rework
- Prevent recalls

## Common Pitfalls

1. **Too late**: Starting FMEA after design is frozen
2. **Incomplete**: Missing failure modes or effects
3. **Subjective ratings**: Inconsistent severity/occurrence/detection
4. **No follow-up**: Actions not tracked or implemented
5. **Living document**: FMEA not updated with changes

## FMEA in Agile/Iterative Development

**Sprint Planning**: Identify critical failure modes
**During Sprint**: Implement mitigations
**Sprint Review**: Update FMEA with findings
**Continuous**: Living document, updated each iteration

## Software FMEA Example

| Software Module | Function | Failure Mode | Effect | S | Cause | O | Controls | D | RPN |
|-----------------|----------|--------------|--------|---|-------|---|----------|---|-----|
| CruiseControl::CalculateThrottle() | Calculate throttle position | Division by zero | ECU reset | 8 | Zero speed input | 5 | Input validation | 2 | 80 |
| CANReceive::ProcessMessage() | Parse CAN frame | Buffer overflow | Memory corruption | 9 | Oversized payload | 3 | Length check | 2 | 54 |
| Diagnostics::ReadDTC() | Retrieve DTCs | Infinite loop | Watchdog reset | 7 | Corrupted DTC list | 4 | Loop counter | 3 | 84 |

## Integration with Other Tools

**FMEA → FTA**: Failure modes become top events in Fault Tree Analysis
**FMEA → HAZOP**: Systematic analysis complements HAZOP
**FMEA → TARA**: Safety analysis informs security threat modeling
**FMEA → DVP&R**: Failure modes drive test planning

## Next Steps

- **Level 2**: Conceptual understanding of DFMEA vs PFMEA
- **Level 3**: Detailed step-by-step FMEA execution guide
- **Level 4**: Complete FMEA worksheet templates and examples
- **Level 5**: Advanced FMEA strategies for ASIL D compliance

## References

- AIAG-VDA FMEA Handbook (2019)
- ISO 26262-9:2018 ASIL-Oriented Analyses
- SAE J1739 Potential Failure Mode and Effects Analysis in Design
- IEC 60812 Failure Modes and Effects Analysis

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Quality engineers, design engineers, safety engineers
