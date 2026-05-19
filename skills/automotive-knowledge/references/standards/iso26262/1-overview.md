# ISO 26262 - Functional Safety for Road Vehicles - Overview

## What is ISO 26262?

ISO 26262 is the international standard for functional safety of electrical and electronic (E/E) systems in production automobiles. Published in 2011 (updated 2018), it provides a comprehensive framework for developing safety-critical automotive systems throughout their lifecycle.

## Standard Structure

ISO 26262 consists of 12 parts:

| Part | Title | Focus |
|------|-------|-------|
| Part 1 | Vocabulary | Definitions and terminology |
| Part 2 | Management of Functional Safety | Organizational requirements |
| Part 3 | Concept Phase | Hazard analysis, safety goals |
| Part 4 | Product Development: System Level | System architecture, safety requirements |
| Part 5 | Product Development: Hardware Level | Hardware design, verification |
| Part 6 | Product Development: Software Level | Software development, testing |
| Part 7 | Production, Operation, Service, Decommissioning | Post-development lifecycle |
| Part 8 | Supporting Processes | Configuration management, change management |
| Part 9 | ASIL-Oriented and Safety-Oriented Analyses | Specific analysis methods |
| Part 10 | Guidelines | Recommendations and examples |
| Part 11 | Application of ISO 26262 to Semiconductors | Chip-level guidance |
| Part 12 | Adaptation of ISO 26262 for Motorcycles | Motorcycle-specific adaptations |

## ASIL Levels (Automotive Safety Integrity Levels)

ISO 26262 defines four ASIL levels representing risk severity:

| ASIL | Description | Example Systems |
|------|-------------|-----------------|
| **ASIL D** | Highest risk | Airbag control, brake-by-wire, steering |
| **ASIL C** | High risk | Anti-lock braking (ABS), stability control |
| **ASIL B** | Moderate risk | Rear lights, brake lights |
| **ASIL A** | Low risk | Head lights (basic functions) |
| **QM** | Quality Management only | Infotainment, HVAC controls |

## ASIL Determination

ASIL is determined through **Hazard Analysis and Risk Assessment (HARA)**:

### Risk Parameters

**S (Severity)**: Injury severity
- S0: No injuries
- S1: Light to moderate injuries
- S2: Severe to life-threatening injuries (survival probable)
- S3: Life-threatening to fatal injuries (survival uncertain/impossible)

**E (Exposure)**: Probability of operational situation
- E0: Incredible
- E1: Very low probability
- E2: Low probability
- E3: Medium probability
- E4: High probability

**C (Controllability)**: Ability to avoid harm
- C0: Controllable in general
- C1: Simply controllable
- C2: Normally controllable
- C3: Difficult to control or uncontrollable

### ASIL Matrix

```
Example: Emergency braking failure
- Severity: S3 (fatal)
- Exposure: E4 (driving is frequent)
- Controllability: C3 (difficult to control)
→ Result: ASIL D
```

## V-Model Development Process

```
Requirements → Design → Implementation → Integration → Verification
     ↓                                                        ↑
     └────────────────────→ Validation ←────────────────────┘

Concept Phase:
- Item Definition
- Hazard Analysis & Risk Assessment
- Functional Safety Concept

System Development:
- Technical Safety Requirements
- System Architecture Design
- Safety Analysis (FMEA, FTA)

Hardware Development:         Software Development:
- Hardware Safety Req.       - Software Safety Req.
- Hardware Design            - Software Architecture
- Hardware Implementation    - Software Unit Design
- Hardware Testing           - Software Unit Testing
                             - Integration Testing

Validation:
- Functional Safety Assessment
- Release for Production
```

## Key Safety Mechanisms

### Hardware Safety Mechanisms

**Redundancy**
- Dual-channel processing
- Lockstep cores
- Voting mechanisms

**Error Detection**
- ECC (Error Correction Code) memory
- CRC (Cyclic Redundancy Check)
- Plausibility checks

**Monitoring**
- Watchdog timers
- Clock monitoring
- Voltage monitoring

### Software Safety Mechanisms

**Control Flow Monitoring**
- Program sequence monitoring
- Timing supervision
- Logical sequence checks

**Data Integrity**
- RAM tests (March algorithm)
- ROM checksums
- Stack overflow detection

**Communication Protection**
- E2E (End-to-End) protection
- Timeout monitoring
- Alive counters

## Safety Requirements

### Technical Safety Requirements (TSR)

Example for emergency braking:

```
TSR-001: The system shall apply emergency braking within 100ms of hazard detection
  ASIL: D
  Verification: Integration test, HIL test
  Safety mechanism: Dual-channel processing with voting

TSR-002: The system shall detect sensor failures within 20ms
  ASIL: D
  Verification: Fault injection testing
  Safety mechanism: Plausibility check, redundant sensors

TSR-003: In case of failure, the system shall enter safe state within 200ms
  ASIL: D
  Verification: Failure mode testing
  Safety mechanism: Degradation strategy
```

## Metrics and Targets

### Hardware Metrics

**PMHF (Probabilistic Metric for Hardware Failures)**
- ASIL D: < 10 FIT (Failures In Time, per 10^9 hours)
- ASIL C: < 100 FIT
- ASIL B: < 100 FIT

**SPFM (Single-Point Fault Metric)**
- ASIL D: ≥ 99%
- ASIL C: ≥ 97%
- ASIL B: ≥ 90%

**LFM (Latent Fault Metric)**
- ASIL D: ≥ 90%
- ASIL C: ≥ 80%
- ASIL B: ≥ 60%

### Software Metrics

**Code Coverage**
- ASIL D: MC/DC (Modified Condition/Decision Coverage)
- ASIL C: Decision coverage
- ASIL B: Branch coverage
- ASIL A: Statement coverage

## ASIL Decomposition

Safety requirements can be decomposed to reduce development effort:

```
Original: ASIL D requirement

Decompose to:
- Element 1: ASIL B(D)  ← ASIL B developed to meet part of ASIL D
- Element 2: ASIL B(D)  ← Independent ASIL B element

Together, Elements 1 & 2 meet ASIL D requirement
```

**Rules**:
- At least two independent elements
- No common cause failures
- Proper freedom from interference

## Documentation Requirements

### Required Work Products

**Concept Phase**
- Item Definition
- Hazard Analysis and Risk Assessment
- Functional Safety Concept

**System Level**
- Technical Safety Concept
- System Design Specification
- Safety Analyses (FMEA, FTA, DFA)
- Integration Test Specification

**Software Level**
- Software Safety Requirements
- Software Architecture Design
- Software Unit Design
- Unit Test Reports
- Integration Test Reports
- Software Safety Analysis

**Verification & Validation**
- Verification Report
- Validation Report
- Functional Safety Assessment
- Safety Case

## Tool Classification

**Tool Confidence Level (TCL)** based on:
- TI (Tool Impact): TI1 (high) or TI2 (low)
- TD (Tool Error Detection): TD1, TD2, TD3
- TCL: TCL1, TCL2, TCL3

**Examples**:
- Compiler: TCL3 (requires qualification)
- Static analyzer: TCL2
- Version control: TCL1 (no qualification needed)

## Certification Process

1. **Safety Plan**: Define safety activities, responsibilities
2. **Development**: Follow V-model with safety activities
3. **Safety Analysis**: FMEA, FTA, FMEDA
4. **Verification**: Testing per ASIL level
5. **Validation**: Confirm safety goals met
6. **Assessment**: Independent safety audit
7. **Release**: Safety case approval

## Compliance Checklist (ASIL D)

- [ ] HARA completed with ASIL D classification
- [ ] Functional Safety Concept defined
- [ ] Technical Safety Concept with redundancy
- [ ] Software developed per ASIL D requirements
- [ ] MC/DC code coverage ≥ 100% for safety functions
- [ ] Hardware SPFM ≥ 99%
- [ ] Hardware PMHF < 10 FIT
- [ ] E2E protection implemented
- [ ] Freedom from interference demonstrated
- [ ] Independent safety assessment passed
- [ ] Safety case approved

## Next Steps

- **Level 2**: Conceptual understanding of safety lifecycle
- **Level 3**: Detailed requirements for each ASIL level
- **Level 4**: Complete work product templates and checklists
- **Level 5**: Advanced safety patterns and certification experience

## References

- ISO 26262:2018 Road Vehicles - Functional Safety
- ISO 26262-6:2018 Software Development
- IEC 61508 Functional Safety of E/E/PE Systems (basis for ISO 26262)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Safety engineers, automotive developers, project managers
