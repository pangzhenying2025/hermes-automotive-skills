# ISO 26262 - Quick Reference

## ASIL Determination Matrix

```
Severity ↓  |  Controllability → C0/C1    C2       C2       C3       C3
Exposure →  |                    E1       E2       E3       E4       E4
------------|----------------------------------------------------------
S3          |                    QM(a)    A        B        C        D
S2          |                    QM(a)    QM(a)    A        B        C
S1          |                    QM(a)    QM(a)    QM(a)    A        B
S0          |                    QM       QM       QM       QM       QM
```

(a) Quality Management required per ISO 9001

### Parameter Classification Quick Guide

**Severity (S)**:
- S0: No injuries
- S1: Light to moderate injuries (bruises, minor whiplash)
- S2: Severe injuries (broken bones, severe whiplash)
- S3: Life-threatening or fatal injuries

**Exposure (E)**:
- E0: Incredible (< 0.001% of operating time)
- E1: Very low (< 1%)
- E2: Low (1-5%)
- E3: Medium (5-50%)
- E4: High (> 50%)

**Controllability (C)**:
- C0: Controllable in general (> 99% drivers avoid harm)
- C1: Simply controllable (> 90% drivers avoid harm)
- C2: Normally controllable (> 60% drivers avoid harm)
- C3: Difficult to control (< 60% drivers avoid harm)

## ASIL Decomposition Rules

### Valid Decomposition Schemes

| Parent ASIL | Decomposition Options |
|-------------|----------------------|
| D | D = B(D) + B(D) |
| D | D = C(D) + A(D) |
| C | C = B(C) + A(C) |
| C | C = A(C) + A(C) |
| B | B = A(B) + A(B) |
| A | Cannot be decomposed |

**Notation**: B(D) means "ASIL B component developed to achieve ASIL D"

### Independence Requirements

For valid decomposition:
- Sufficiently independent development (design, verification, validation)
- No cascading failures between elements
- No common cause failures
- Dependent failure analysis (DFA) required

## Hardware Metrics Target Values

### Single Point Fault Metric (SPFM)

| ASIL | Target |
|------|--------|
| QM   | N/A    |
| A    | ≥ 90%  |
| B    | ≥ 90%  |
| C    | ≥ 97%  |
| D    | ≥ 99%  |

**Formula**: SPFM = 1 - (Σλ_SPF / Σλ)

### Latent Fault Metric (LFM)

| ASIL | Target |
|------|--------|
| QM   | N/A    |
| A    | ≥ 60%  |
| B    | ≥ 60%  |
| C    | ≥ 80%  |
| D    | ≥ 90%  |

**Formula**: LFM = 1 - (Σλ_latent / Σλ_multi-point)

### Probabilistic Metric for Hardware Failures (PMHF)

| ASIL | Target (per hour) | Target (FIT) |
|------|-------------------|--------------|
| QM   | N/A               | N/A          |
| A    | < 10^-7           | < 100        |
| B    | < 10^-7           | < 100        |
| C    | < 10^-8           | < 10         |
| D    | < 10^-8           | < 10         |

FIT = Failures In Time (failures per 10^9 hours)

## Software Development Methods (ISO 26262-6)

### Coding Guidelines (Table 1)

| ASIL | Requirements |
|------|--------------|
| A    | One method from Table 1 |
| B    | One method from Table 1 |
| C    | One method from Table 1, one method from Table 2 |
| D    | One method from Table 1, one method from Table 2 |

**Table 1 Methods** (highly recommended):
- MISRA C/C++ compliance
- Enforcement of low complexity (cyclomatic < 15)
- Enforcement of low coupling
- No dynamic objects (or justification)
- No recursion (or justification)

**Table 2 Methods** (recommended):
- Static code analysis
- Semantic code analysis
- Defensive programming
- Control flow analysis
- Data flow analysis

### Code Coverage Requirements (Table 13)

| ASIL | Statement | Branch | MC/DC |
|------|-----------|--------|-------|
| A    | ++        | +      | o     |
| B    | ++        | ++     | o     |
| C    | ++        | ++     | +     |
| D    | ++        | ++     | ++    |

Legend:
- ++ Highly recommended
- + Recommended
- o For consideration

**MC/DC**: Modified Condition/Decision Coverage

### Software Architecture Methods (Table 5)

| Method | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|--------|--------|--------|--------|
| Hierarchical structure | ++ | ++ | ++ | ++ |
| Restricted size & complexity | + | ++ | ++ | ++ |
| Low coupling | + | + | ++ | ++ |
| Appropriate scheduling | + | ++ | ++ | ++ |
| Information hiding | + | + | ++ | ++ |
| Defensive programming | + | ++ | ++ | ++ |

## Safety Mechanism Catalog

### Detection Mechanisms

| Mechanism | Purpose | Diagnostic Coverage |
|-----------|---------|---------------------|
| Range check | Detect sensor out-of-range | 60-90% |
| Plausibility check | Cross-check redundant sensors | 70-95% |
| Watchdog | Detect software/CPU hang | 90-99% |
| CRC/Checksum | Detect data corruption | 90-99.9% |
| Dual-channel comparison | Detect computation error | 90-99% |
| Memory test (RAM) | Detect memory fault | 80-95% |
| Memory test (Flash) | Detect code corruption | 95-99% |

### Control Mechanisms

| Mechanism | Purpose | Implementation |
|-----------|---------|----------------|
| Voting (2oo3) | Mask single failure | 3 sensors, select median |
| Hot standby | Fail-operational | Redundant ECU with switchover |
| Watchdog + reset | Recover from transient fault | External watchdog triggers reset |
| Graceful degradation | Maintain partial function | Limp-home mode |
| Safe state | Prevent hazard | Controlled shutdown |

### Mitigation Mechanisms

| Mechanism | Purpose | Example |
|-----------|---------|---------|
| Torque limitation | Limit acceleration | Cap throttle to 30% on sensor fault |
| Speed limitation | Reduce risk exposure | Limit to 50 km/h in degraded mode |
| Warning to driver | Increase controllability | Visual/audible alert |
| Request driver intervention | Transfer control | "Take over immediately" message |
| Emergency stop | Ultimate safe state | Controlled deceleration to standstill |

## Diagnostic Coverage Estimation

### Fault Injection Coverage

**Formula**:
```
DC = (N_detected / N_injected) × 100%

where:
N_detected = Faults detected by safety mechanism
N_injected = Total faults injected
```

**Typical Coverage by Mechanism**:
- Watchdog timer: 90-95% (CPU/SW failures)
- Dual-channel comparison: 90-99% (computation errors)
- CRC on communication: 99.9% (bit errors)
- Range check: 60-90% (sensor failures)
- Plausibility check: 70-95% (sensor failures)

### Combined Coverage

For multiple mechanisms:
```
DC_total = 1 - Π(1 - DC_i)

Example:
DC_watchdog = 0.95
DC_range_check = 0.80
DC_total = 1 - (1 - 0.95) × (1 - 0.80) = 1 - 0.01 = 0.99 = 99%
```

## Common Safety Goals by System

### Powertrain

| System | Safety Goal | Typical ASIL |
|--------|-------------|--------------|
| Engine control | Prevent unintended acceleration | D |
| Engine control | Prevent unintended engine off | C |
| Transmission | Prevent unintended gear shift | C |
| Cruise control | Prevent unintended activation | B |

### Chassis

| System | Safety Goal | Typical ASIL |
|--------|-------------|--------------|
| ESC | Maintain stability control | D |
| ABS | Maintain braking capability | D |
| EPS | Maintain steering assistance | D |
| Brake-by-wire | Prevent unintended braking | D |

### ADAS

| System | Safety Goal | Typical ASIL |
|--------|-------------|--------------|
| AEB | Prevent collision or mitigate | D |
| LKA | Prevent unintended lane departure | C |
| ACC | Prevent unsafe acceleration | C |
| Parking assist | Prevent collision during parking | B |

## Verification Methods by Work Product

### Requirements Verification

| Work Product | Methods | ASIL Dependency |
|--------------|---------|-----------------|
| Safety goals | Review, HARA validation | All ASILs |
| FSC | Inspection, simulation | All ASILs |
| TSC | Inspection, prototyping | All ASILs |
| SW requirements | Review, traceability check | All ASILs |

### Design Verification

| Work Product | Methods | ASIL C/D Addition |
|--------------|---------|-------------------|
| System design | Simulation, FMEA | + DFA |
| HW design | FMEA, FTA | + Independent review |
| SW architecture | Review, metrics | + Semi-formal notation |
| SW detailed design | Review, static analysis | + Walkthrough |

### Implementation Verification

| Work Product | Methods | Coverage Required |
|--------------|---------|-------------------|
| SW unit (ASIL A/B) | Review + unit test | Statement + branch |
| SW unit (ASIL C/D) | Review + unit test | Statement + branch + MC/DC |
| HW implementation | Inspection + test | Per metrics |

## Typical ASIL Requirements by Phase

### Concept Phase

| ASIL | HARA | FSC Review | Documentation |
|------|------|------------|---------------|
| A    | Standard | Single reviewer | Standard |
| B    | Standard | Single reviewer | Standard |
| C    | + Sensitivity analysis | Two reviewers | + Assumptions |
| D    | + Sensitivity analysis | Two independent reviewers | + Assumptions + rationale |

### Software Development

| ASIL | Modeling | Coding | Review | Testing |
|------|----------|--------|--------|---------|
| A    | Optional | MISRA | Peer | Statement coverage |
| B    | Recommended | MISRA | Peer | Branch coverage |
| C    | Recommended | MISRA + static analysis | Independent | MC/DC |
| D    | Highly rec. | MISRA + static + defensive | Independent + walkthrough | MC/DC + robustness |

### Hardware Development

| ASIL | Analysis | Review | Metrics | Validation |
|------|----------|--------|---------|------------|
| A    | FMEA | Peer | SPFM ≥90%, LFM ≥60% | Functional test |
| B    | FMEA + FTA | Peer | SPFM ≥90%, LFM ≥60% | Functional + stress |
| C    | FMEA + FTA | Independent | SPFM ≥97%, LFM ≥80% | + Fault injection |
| D    | FMEA + FTA + DFA | Independent | SPFM ≥99%, LFM ≥90% | + Long-term |

## Work Product Checklist

### Safety Plan (ISO 26262-2)

- [ ] Scope of safety activities
- [ ] Tailoring of standard
- [ ] Safety lifecycle phases
- [ ] Responsibilities and roles
- [ ] Supporting process requirements
- [ ] Configuration management approach
- [ ] Verification and validation strategy

### Safety Case (ISO 26262-2)

- [ ] Safety goals with ASIL
- [ ] Evidence of compliance per phase
- [ ] Analysis results (HARA, FMEA, FTA, DFA)
- [ ] Verification and validation reports
- [ ] Known limitations and assumptions
- [ ] Assessment report

### HARA Document (ISO 26262-3)

- [ ] Item definition and boundaries
- [ ] Operational situations identified
- [ ] Hazardous events with S/E/C classification
- [ ] ASIL determination rationale
- [ ] Safety goals with safe states
- [ ] Traceability to system requirements

## References

- ISO 26262-1:2018 Vocabulary
- ISO 26262-2:2018 Management of functional safety
- ISO 26262-3:2018 Concept phase
- ISO 26262-4:2018 System level
- ISO 26262-5:2018 Hardware level
- ISO 26262-6:2018 Software level
- ISO 26262-9:2018 ASIL-oriented analysis

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All project team members
