# ASIL Decomposition and Dependent Failure Analysis Rules

> Rules for decomposing safety requirements across redundant elements and
> ensuring independence through dependent failure analysis (DFA) per
> ISO 26262 Part 9.

## Scope

These rules apply to all automotive software and hardware design decisions
involving ASIL decomposition, where a higher-ASIL safety requirement is
allocated to two or more redundant elements of lower ASIL classification,
and to the dependent failure analysis that must accompany such decomposition.

---

## ASIL Decomposition Fundamentals

### Decomposition Principle

A safety requirement at ASIL X can be decomposed into two redundant
elements provided:
1. Each element independently fulfills the safety requirement
2. The elements are sufficiently independent
3. Dependent failure analysis confirms freedom from common cause failures

### Valid Decomposition Schemes

```
Original ASIL -> Element 1 + Element 2
================================================
ASIL D         -> ASIL D(D)  + ASIL D(D)    [No benefit]
ASIL D         -> ASIL C(D)  + ASIL A(D)    [Valid]
ASIL D         -> ASIL B(D)  + ASIL B(D)    [Valid]
ASIL C         -> ASIL B(C)  + ASIL A(C)    [Valid]
ASIL C         -> ASIL A(C)  + ASIL A(C)    [NOT valid - insufficient]
ASIL B         -> ASIL A(B)  + ASIL A(B)    [Valid]
ASIL B         -> ASIL QM(B) + ASIL QM(B)   [NOT valid]
ASIL A         -> ASIL QM(A) + ASIL QM(A)   [NOT valid]
```

**Rule**: The sum of decomposed ASILs must equal or exceed the original:
- D = D+D, C+A, B+B
- C = C+C, B+A
- B = B+B, A+A
- A = A+A (not decomposable to QM)

The notation ASIL X(Y) means "developed to ASIL X, contributing to ASIL Y
decomposition."

### Three-Way Decomposition

```
ASIL D -> ASIL B(D) + ASIL A(D) + ASIL A(D)  [Valid if all independent]
ASIL D -> ASIL A(D) + ASIL A(D) + ASIL A(D)  [NOT valid]
```

---

## Decomposition Documentation Requirements

### Safety Requirement Decomposition Record

```yaml
decomposition_record:
  id: DEC-BMS-001
  original_requirement:
    id: SR-BMS-042
    text: "The BMS shall disconnect the battery within 100ms upon detection
           of overcurrent exceeding 500A"
    asil: D

  decomposition:
    scheme: "ASIL B(D) + ASIL B(D)"
    rationale: >
      Overcurrent protection is implemented by two independent paths:
      a software-based monitoring function and a hardware current limiter.
      Neither path alone requires ASIL D rigor if both are demonstrably
      independent.

    element_1:
      id: DEC-BMS-001-SW
      description: "Software overcurrent monitor in BMS application"
      asil: "B(D)"
      implementation: "Current measurement via ADC, threshold comparison,
                       contactor open command via CAN"
      processor: "Main MCU (Cortex-R5)"

    element_2:
      id: DEC-BMS-001-HW
      description: "Hardware current limiter with independent sensor"
      asil: "B(D)"
      implementation: "Analog comparator with shunt resistor, direct
                       contactor drive via dedicated GPIO"
      processor: "Safety MCU (independent IC)"

  independence_argument:
    - "Different sensors (ADC vs. analog comparator with separate shunt)"
    - "Different processors (Main MCU vs. Safety MCU)"
    - "Different communication paths (CAN vs. dedicated GPIO)"
    - "No shared software or libraries"
    - "Independent power supplies with separate regulators"

  dfa_reference: "DFA-BMS-001"
```

---

## Dependent Failure Analysis (DFA)

### DFA Process

```
Step 1: Identify decomposed elements and their interfaces
Step 2: Analyze common cause failures (CCF)
Step 3: Analyze cascading failures (CF)
Step 4: Determine independence measures
Step 5: Verify residual dependent failure risk is acceptable
Step 6: Document in DFA report
```

### Common Cause Failure Categories

| Category | Description | Example |
|----------|-------------|---------|
| **Hardware CCF** | Shared physical components | Same power supply, same PCB |
| **Software CCF** | Shared code or libraries | Same RTOS, same compiler |
| **Environmental CCF** | Shared environment | Same temperature zone, EMI |
| **Process CCF** | Same development process | Same team, same tools |
| **Systematic CCF** | Same design methodology | Same algorithm approach |

### DFA Analysis Template

```yaml
dfa_report:
  id: DFA-BMS-001
  decomposition_ref: DEC-BMS-001
  date: 2025-03-19
  analyst: Safety Engineering Team

  elements_analyzed:
    - DEC-BMS-001-SW  # Software overcurrent monitor
    - DEC-BMS-001-HW  # Hardware current limiter

  common_cause_failures:
    - id: CCF-001
      category: hardware
      description: "Both elements share the same 12V power supply"
      probability: medium
      mitigation: "Add independent voltage regulator for Safety MCU with
                   separate input protection"
      residual_risk: low
      status: mitigated

    - id: CCF-002
      category: environmental
      description: "Both elements on same PCB - shared thermal environment"
      probability: low
      mitigation: "Thermal simulation confirms independent temperature
                   margins. Components rated to 125C, max operating 85C"
      residual_risk: negligible
      status: accepted

    - id: CCF-003
      category: software
      description: "Both MCUs programmed by same development team"
      probability: medium
      mitigation: "Different programming languages (C for main MCU,
                   VHDL-like for safety MCU config). Independent review."
      residual_risk: low
      status: mitigated

    - id: CCF-004
      category: systematic
      description: "EMC event could affect both processors simultaneously"
      probability: low
      mitigation: "EMC testing per CISPR 25 / ISO 11452. Independent
                   watchdogs on each processor."
      residual_risk: low
      status: mitigated

  cascading_failures:
    - id: CF-001
      description: "Software monitor false positive opens contactor,
                   hardware monitor sees current drop and remains inactive"
      probability: low
      impact: "Unnecessary disconnection (availability impact, not safety)"
      mitigation: "Debounce timer on software monitor. Hardware monitor
                   has independent activation threshold."
      status: accepted

    - id: CF-002
      description: "Main MCU crash corrupts CAN bus, preventing Safety MCU
                   from receiving heartbeat"
      probability: medium
      impact: "Safety MCU may enter independent safe state"
      mitigation: "Safety MCU monitors CAN bus health independently.
                   Heartbeat loss triggers safe state (contactor open)."
      status: mitigated

  independence_conclusion: >
    The two overcurrent protection elements are sufficiently independent
    for ASIL B(D) + ASIL B(D) decomposition. All identified common cause
    failures are mitigated to acceptable residual risk levels. Cascading
    failure paths lead to safe states (contactor open).
```

---

## Independence Measures

### Software Independence

```c
/*
 * Software independence requirements for ASIL decomposition:
 *
 * 1. No shared source code between decomposed elements
 * 2. No shared libraries (including RTOS, HAL, math libraries)
 * 3. Different compilers or compiler versions (recommended for ASIL D)
 * 4. Independent build pipelines
 * 5. No shared configuration files
 * 6. Independent calibration data
 */

/* Element 1: Main MCU Software Stack */
/* Compiler: GCC 12.3 for ARM Cortex-R5 */
/* RTOS: FreeRTOS 10.5.1 */
/* Math: Custom fixed-point library */

/* Element 2: Safety MCU Software Stack */
/* Compiler: IAR 9.30 for ARM Cortex-M4 */
/* RTOS: Bare-metal (no OS) */
/* Math: Lookup tables only */
```

### Hardware Independence

| Measure | Requirement | Verification |
|---------|------------|-------------|
| Separate processors | Different silicon | BOM review |
| Separate sensors | Different physical principle preferred | Schematic review |
| Separate power supplies | Independent regulators | Schematic + test |
| Separate communication | No shared bus for safety signals | Architecture review |
| Separate clock sources | Independent oscillators | Schematic review |
| Physical separation | Different PCB regions or boards | Layout review |

### Process Independence

| Measure | Requirement |
|---------|------------|
| Different development teams | Recommended for ASIL D decomposition |
| Independent reviews | Different reviewers for each element |
| Independent testing | Separate test campaigns and environments |
| Independent verification | Different V&V teams or approaches |
| Diverse algorithms | Different mathematical approaches (recommended) |

---

## Decomposition in Software Architecture

### Architectural Pattern: Redundant Monitor

```
+------------------+     +------------------+
|  Primary Path    |     |  Monitor Path    |
|  (ASIL B(D))     |     |  (ASIL B(D))     |
|                  |     |                  |
|  Sensor A ------>|     |  Sensor B ------>|
|  Algorithm 1 --->|     |  Algorithm 2 --->|
|  Output 1 ------>+--+--+<------ Output 2  |
+------------------+  |  +------------------+
                      |
                 Comparator
                      |
              +-------+-------+
              | Outputs agree? |
              +-------+-------+
                  |       |
                 YES      NO
                  |       |
              Execute   Safe State
              Command   (Fail-safe)
```

### Implementation Pattern

```c
/* Redundant computation with comparison */
typedef struct {
    float primary_result;
    float monitor_result;
    bool agreement;
    float discrepancy;
} RedundantResult_t;

RedundantResult_t compute_with_redundancy(
    const SensorDataA_t* sensor_a,
    const SensorDataB_t* sensor_b) {

    RedundantResult_t result;

    /* Primary path computation */
    result.primary_result = primary_algorithm(sensor_a);

    /* Monitor path computation (diverse algorithm) */
    result.monitor_result = monitor_algorithm(sensor_b);

    /* Comparison with tolerance */
    result.discrepancy = fabsf(result.primary_result - result.monitor_result);
    result.agreement = (result.discrepancy < AGREEMENT_TOLERANCE);

    if (!result.agreement) {
        log_disagreement(result.primary_result, result.monitor_result,
                         result.discrepancy);
    }

    return result;
}

/* Use result only if agreement confirmed */
void apply_control_output(const RedundantResult_t* redundant) {
    if (redundant->agreement) {
        /* Use primary result */
        set_actuator_output(redundant->primary_result);
    } else {
        /* Enter safe state */
        enter_safe_state(SAFE_STATE_REASON_REDUNDANCY_MISMATCH);
    }
}
```

---

## Verification of Decomposition

### Fault Injection Testing

```yaml
fault_injection_tests:
  - id: FI-DEC-001
    decomposition: DEC-BMS-001
    target: Element 1 (Software monitor)
    fault_type: "Stuck-at output (always reports OK)"
    expected_behavior: "Element 2 (Hardware limiter) independently detects
                       overcurrent and opens contactor"
    pass_criteria: "Contactor opens within 100ms"
    result: PASS

  - id: FI-DEC-002
    decomposition: DEC-BMS-001
    target: Element 2 (Hardware limiter)
    fault_type: "Comparator stuck-at high (never trips)"
    expected_behavior: "Element 1 (Software monitor) independently detects
                       overcurrent and commands contactor open via CAN"
    pass_criteria: "Contactor opens within 100ms"
    result: PASS

  - id: FI-DEC-003
    decomposition: DEC-BMS-001
    target: Both elements simultaneously
    fault_type: "Common cause: power supply dropout"
    expected_behavior: "Contactor fails to safe state (normally open spring)
                       due to de-energized coil"
    pass_criteria: "Contactor opens within 50ms of power loss"
    result: PASS
```

### Independence Verification Matrix

```
+-------------------+--------+--------+--------+--------+--------+
| Independence      | HW     | SW     | Sensor | Comm   | Power  |
| Measure           | Indep. | Indep. | Indep. | Indep. | Indep. |
+-------------------+--------+--------+--------+--------+--------+
| DEC-BMS-001       | YES    | YES    | YES    | YES    | YES*   |
| DEC-INV-002       | YES    | PARTIAL| YES    | YES    | YES    |
| DEC-CHG-003       | YES    | YES    | N/A    | YES    | YES    |
+-------------------+--------+--------+--------+--------+--------+
* = Mitigated by independent regulator (see CCF-001)
```

---

## Prohibited Practices

| Practice | Reason |
|----------|--------|
| Decomposing without DFA | No evidence of independence |
| Shared RTOS between decomposed elements | Common cause failure |
| Same sensor for both elements | Single point of failure |
| Same compiler for ASIL D decomposition | Systematic CCF risk |
| Undocumented decomposition rationale | Audit non-compliance |
| Decomposing below ASIL A to QM | Not permitted by ISO 26262 |
| Ignoring cascading failure paths | Incomplete analysis |
| DFA without fault injection verification | Unvalidated claims |

---

## Review Checklist

- [ ] Decomposition scheme is valid per ISO 26262 Part 9
- [ ] Each element independently satisfies the safety requirement
- [ ] DFA report completed for every decomposition
- [ ] All common cause failure categories analyzed
- [ ] All cascading failure paths identified
- [ ] Independence measures implemented and verified
- [ ] Fault injection tests confirm independent operation
- [ ] Independence verification matrix complete
- [ ] Decomposition rationale documented and reviewed
- [ ] Residual risk for each CCF assessed as acceptable
- [ ] Process independence measures in place for ASIL D
- [ ] Decomposition approved by functional safety manager
