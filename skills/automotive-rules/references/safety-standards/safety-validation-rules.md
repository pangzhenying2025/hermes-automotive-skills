# Safety Validation and Testing Rules

> Rules for validating safety requirements through structured testing
> at unit, integration, and system levels per ISO 26262 Part 4 (Product
> Development at the System Level) and Part 6 (Software Level).

## Scope

These rules apply to all verification and validation activities for
safety-critical automotive software, from unit test through system
validation, including requirements-based testing, fault injection testing,
and back-to-back testing.

---

## Test Levels and Objectives

### V-Model Test Mapping

```
Requirements Phase          Validation Phase
==================          ================

Vehicle Requirements  <-->  Vehicle Validation Tests
        |                           |
System Requirements   <-->  System Integration Tests
        |                           |
SW Architecture       <-->  SW Integration Tests
        |                           |
SW Detailed Design    <-->  SW Unit Tests
        |                           |
   Implementation              Code
```

### Test Level Definitions

| Level | Objective | Environment | ASIL Req |
|-------|-----------|------------|----------|
| Unit Test | Verify individual functions/modules | Host PC (SIL) | All |
| SW Integration | Verify SW component interactions | SIL / PIL | ASIL A+ |
| HW/SW Integration | Verify SW on target hardware | HIL | ASIL B+ |
| System Integration | Verify complete system behavior | HIL / Vehicle | ASIL B+ |
| Vehicle Validation | Validate safety goals in vehicle | Vehicle | All |

---

## Requirements-Based Testing

### Test Case Derivation

Every safety requirement must be covered by at least one test case
derived using the following methods:

| Method | Description | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|-------------|--------|--------|--------|--------|
| Equivalence classes | Partition inputs into classes | ++ | ++ | ++ | ++ |
| Boundary value analysis | Test at partition boundaries | + | ++ | ++ | ++ |
| Error guessing | Test likely failure scenarios | + | + | ++ | ++ |
| Requirements-based | Direct from requirements text | ++ | ++ | ++ | ++ |
| Interface testing | Test component interfaces | + | + | ++ | ++ |
| Fault injection | Inject faults, verify reaction | o | + | ++ | ++ |
| Back-to-back testing | Compare model vs code | o | o | + | ++ |
| Resource usage testing | Stack, CPU, memory limits | + | + | ++ | ++ |

Legend: ++ = highly recommended, + = recommended, o = optional

### Test Case Template

```yaml
test_case:
  id: TC-BMS-SW-042
  title: "Overcurrent protection triggers contactor open within FTTI"
  requirement_ref: SSR-BMS-012
  safety_goal_ref: SG-BMS-001
  asil: D
  test_level: SW_Integration
  priority: critical

  preconditions:
    - "BMS software running in normal operating mode"
    - "Main contactor closed"
    - "Pack current reading valid and within normal range"

  test_steps:
    - step: 1
      action: "Inject pack current reading of 520A (above 500A threshold)"
      expected: "Overcurrent fault detected within 10 ms"
      verification: "Check fault flag OC_DETECTED is set"

    - step: 2
      action: "Wait for fault reaction time"
      expected: "Contactor open command issued within 50 ms of detection"
      verification: "Check GPIO MAIN_CONTACTOR_ENABLE goes LOW"

    - step: 3
      action: "Verify fault logging"
      expected: "DTC 0xBMS042 stored with freeze frame data"
      verification: "Read DTC memory via diagnostic interface"

  pass_criteria:
    - "Total reaction time from overcurrent to contactor open < 100 ms"
    - "Fault correctly classified as severity CRITICAL"
    - "Safe state maintained until explicit reset"

  test_environment: HIL
  automation_status: automated
  execution_frequency: every_release
```

---

## Fault Injection Testing

### Fault Injection Strategy

```yaml
fault_injection_strategy:
  purpose: >
    Verify that safety mechanisms detect faults and transition to
    safe state within the fault tolerant time interval (FTTI).

  fault_categories:
    hardware_faults:
      - "ADC stuck-at-zero"
      - "ADC stuck-at-max"
      - "ADC offset drift"
      - "CAN bus-off"
      - "CAN message loss"
      - "CAN message corruption"
      - "GPIO stuck-at (output)"
      - "Watchdog service failure"
      - "Clock drift / loss"
      - "Memory bit-flip (RAM)"
      - "Flash corruption (NVM)"

    software_faults:
      - "Task overrun (deadline miss)"
      - "Stack overflow"
      - "Null pointer dereference"
      - "Division by zero"
      - "Array index out of bounds"
      - "Infinite loop in computation"
      - "Data race condition"
      - "State machine invalid transition"

    communication_faults:
      - "Message timeout (no reception)"
      - "Message counter mismatch (stale)"
      - "CRC failure (corrupted)"
      - "Signal range violation"
      - "Bus-off condition"
```

### Fault Injection Methods

| Method | Description | Applicable Level |
|--------|-------------|-----------------|
| **Software FI** | Modify variables in debugger/test harness | SIL, PIL |
| **Hardware FI** | Pin forcing, signal injection | HIL |
| **Model FI** | Inject faults in simulation models | MIL, SIL |
| **Code Mutation** | Insert code defects systematically | Unit test |
| **Protocol FI** | Inject malformed CAN/Ethernet frames | HIL, SIL |
| **EMC FI** | Electromagnetic interference | Vehicle lab |
| **Power FI** | Voltage spikes, dropouts, brown-out | HIL, vehicle |

### Fault Injection Test Template

```yaml
fault_injection_test:
  id: FI-BMS-001
  safety_mechanism_ref: SM-BMS-003
  fmea_ref: FMEA-BMS-SW-001

  fault_description: "ADC channel 0 (Cell Voltage 1) stuck at 0V"
  injection_method: "Force ADC register to 0x000 via debugger"
  injection_point: "VADC Group 0, Channel 0 result register"
  injection_timing: "During normal 1ms cyclic task execution"

  expected_detection:
    mechanism: "Range check (voltage below 2.5V minimum)"
    detection_time_ms: 10
    fault_code: "FC_CELL_VOLTAGE_LOW"

  expected_reaction:
    action: "Set cell 1 voltage to safe default, trigger warning"
    reaction_time_ms: 20
    safe_state: "Continued operation with degraded diagnostics"

  pass_criteria:
    - "Fault detected within 10 ms of injection"
    - "Correct fault code stored"
    - "Appropriate safe state entered within FTTI (100 ms)"
    - "No cascading failure to adjacent cells"

  actual_results:
    detection_time_ms: 4
    reaction_time_ms: 8
    fault_code_correct: true
    safe_state_entered: true
    verdict: PASS
```

---

## Back-to-Back Testing

### Purpose

Compare the behavior of the software implementation against the
reference model (Simulink/Stateflow) to detect implementation errors.

```
+-------------------+       +-------------------+
|   Reference       |       |   Implementation  |
|   Model           |       |   (C Code)        |
|   (Simulink)      |       |                   |
+--------+----------+       +--------+----------+
         |                           |
    Same inputs                 Same inputs
         |                           |
+--------v----------+       +--------v----------+
|   Model Output    |       |   Code Output     |
+--------+----------+       +--------+----------+
         |                           |
         +----------+  +------------+
                    |  |
              +-----v--v------+
              |   Comparator  |
              |   (tolerance  |
              |    check)     |
              +-------+-------+
                      |
              PASS / FAIL
```

### Back-to-Back Test Rules

```yaml
back_to_back_testing:
  required_for: [ASIL_C, ASIL_D]
  recommended_for: [ASIL_B]

  tolerance_criteria:
    floating_point: "Relative error < 1e-4 or absolute error < 1e-6"
    integer: "Exact match"
    boolean: "Exact match"
    timing: "Within one sample period"

  test_vectors:
    source: "Model test harness stimulus files"
    coverage: "Must cover all model operating modes and transitions"
    duration: "Minimum 10,000 simulation steps per test case"

  environment:
    model_execution: "Simulink Simulation (64-bit host)"
    code_execution: "SIL (compiled C on host) or PIL (C on target)"
    comparison_tool: "Automated regression script"
```

---

## Structural Coverage

### Coverage Targets by ASIL

| Coverage Metric | ASIL A | ASIL B | ASIL C | ASIL D |
|----------------|--------|--------|--------|--------|
| Statement coverage | ++ | ++ | ++ | ++ |
| Branch coverage | + | ++ | ++ | ++ |
| MC/DC coverage | o | + | ++ | ++ |
| Function coverage | ++ | ++ | ++ | ++ |
| Call coverage | + | + | ++ | ++ |

Legend: ++ = highly recommended, + = recommended, o = optional

### MC/DC (Modified Condition/Decision Coverage)

```c
/*
 * MC/DC requires that each condition in a decision independently
 * affects the outcome.
 *
 * Decision: if (A && B || C)
 *
 * MC/DC test vectors:
 * | Test | A | B | C | Result | Demonstrates |
 * |------|---|---|---|--------|-------------|
 * | T1   | T | T | F | T      | A=T: pair with T4 |
 * | T2   | T | F | F | F      | B=F: pair with T1 |
 * | T3   | F | T | T | T      | C=T: pair with T4 (approx) |
 * | T4   | F | T | F | F      | A=F: pair with T1 |
 * | T5   | T | T | T | T      | (optional, adds coverage) |
 */

/* For ASIL D: every condition in safety-critical decisions must have
 * MC/DC test vectors documented and automated */
```

### Coverage Analysis Workflow

```
1. Run all requirement-based test cases
2. Measure structural coverage
3. Analyze uncovered code:
   a. Dead code -> Remove or document justification
   b. Defensive code -> Add fault injection tests
   c. Missing test -> Add requirement-based test
4. Iterate until coverage targets met
5. Document any justified coverage gaps
```

---

## Resource Usage Testing

### Stack Usage Verification

```yaml
resource_test:
  id: RT-BMS-001
  type: stack_usage
  method: "Stack painting + watermark analysis"

  results:
    - task: "MotorControl_1ms"
      stack_size_words: 512
      measured_peak_words: 324
      usage_percent: 63.3
      margin_percent: 36.7
      verdict: PASS  # > 25% margin

    - task: "Diagnostics_100ms"
      stack_size_words: 256
      measured_peak_words: 218
      usage_percent: 85.2
      margin_percent: 14.8
      verdict: FAIL  # < 25% margin, needs stack increase
```

### WCET Verification

```yaml
resource_test:
  id: RT-BMS-002
  type: wcet
  method: "Runtime measurement via DWT cycle counter"

  results:
    - task: "CellVoltageMonitor"
      period_us: 1000
      budget_us: 400
      measured_wcet_us: 287
      utilization_percent: 28.7
      margin_percent: 28.3
      verdict: PASS

    - task: "ThermalManagement"
      period_us: 10000
      budget_us: 3000
      measured_wcet_us: 3150
      utilization_percent: 31.5
      margin_percent: -5.0
      verdict: FAIL  # Exceeds budget
```

---

## Test Environment Qualification

### Tool Qualification Requirements

| Tool Category | Example | Qualification Need |
|--------------|---------|-------------------|
| Test execution | VectorCAST, Tessy | TCL1 or TCL2 |
| Coverage analysis | gcov, BullseyeCoverage | TCL2 |
| Static analysis | Polyspace, QAC | TCL2 |
| Compiler | GCC, IAR | TCL2 for ASIL C/D |
| Simulation | Simulink, CarMaker | TCL1 |
| HIL system | dSPACE, ETAS | TCL1 |

### Tool Confidence Levels

| TCL | Validation Method |
|-----|------------------|
| TCL1 | Increased confidence from use (experience) |
| TCL2 | Evaluation of the tool development process |
| TCL3 | Validation of the software tool per ISO 26262-8 |
| TCL4 | Development per safety standard (highest rigor) |

---

## Test Reporting

### Test Summary Report Template

```yaml
test_summary:
  project: "BMS Software v2.4.0"
  date: 2025-03-19
  test_level: "SW Integration"
  asil: D

  statistics:
    total_test_cases: 847
    passed: 831
    failed: 12
    blocked: 4
    not_executed: 0
    pass_rate_percent: 98.1

  coverage:
    statement: 96.3
    branch: 93.7
    mcdc: 89.2
    function: 100.0

  failed_tests:
    - id: TC-BMS-SW-198
      failure_reason: "Timing exceeded by 2 ms under high load"
      severity: medium
      action: "Optimize computation path, retest"
      ticket: "ECUBE-4521"

  coverage_gaps:
    - file: "thermal_protection.c"
      uncovered_branches: 3
      justification: "Defensive code for hardware fault not injectable in SIL"
      action: "Cover in HIL fault injection campaign"

  conclusion: >
    12 failures identified, none safety-critical. All failures have
    corrective actions assigned. Coverage targets met for statement
    and branch. MC/DC gap of 0.8% justified by defensive code analysis.
    Recommendation: Conditional release pending failure resolution.
```

---

## Review Checklist

- [ ] Every safety requirement has at least one test case
- [ ] Test cases derived using methods appropriate for ASIL level
- [ ] Fault injection tests cover all identified safety mechanisms
- [ ] Back-to-back testing performed for ASIL C/D modules
- [ ] Structural coverage meets ASIL-appropriate targets
- [ ] Coverage gaps analyzed and justified
- [ ] Resource usage (stack, WCET, memory) verified with margin
- [ ] Test environment and tools qualified to required TCL
- [ ] Test summary report complete with pass/fail statistics
- [ ] All test failures have corrective action tickets
- [ ] Regression test suite automated and in CI pipeline
- [ ] Test results traceable to requirements and safety goals
