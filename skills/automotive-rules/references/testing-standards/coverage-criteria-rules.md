# Structural and Requirement Coverage Criteria Rules

> Rules for achieving and measuring test coverage in automotive software
> per ISO 26262 Part 6, covering structural coverage metrics (statement,
> branch, MC/DC) and requirements coverage traceability.

## Scope

These rules apply to all safety-critical automotive software where
coverage evidence is required for ISO 26262 compliance, from ASIL A
through ASIL D, across unit, integration, and system test levels.

---

## Coverage Metrics Hierarchy

### Structural Coverage Levels

```
MC/DC (Modified Condition/Decision Coverage)
  |
  +-- Subsumes: Decision/Branch Coverage
        |
        +-- Subsumes: Statement Coverage
              |
              +-- Subsumes: Function/Entry Point Coverage
```

### ASIL Requirements Matrix

| Metric | ASIL A | ASIL B | ASIL C | ASIL D | Target |
|--------|--------|--------|--------|--------|--------|
| Statement | ++ | ++ | ++ | ++ | >= 95% |
| Branch/Decision | + | ++ | ++ | ++ | >= 90% |
| MC/DC | o | + | ++ | ++ | >= 85% |
| Function | ++ | ++ | ++ | ++ | 100% |
| Call coverage | + | + | ++ | ++ | >= 95% |

Legend: ++ = highly recommended, + = recommended, o = optional

---

## Statement Coverage

### Definition

Every executable statement in the source code must be executed by at
least one test case.

```c
/* Example: Statement coverage analysis */
float compute_soc(float voltage_v, float current_a, float dt_s,
                   float previous_soc) {
    float soc = previous_soc;                    /* S1: covered */

    /* Coulomb counting */
    float delta_soc = (current_a * dt_s) / BATTERY_CAPACITY_AH;  /* S2 */
    soc += delta_soc;                            /* S3: covered */

    /* Voltage-based correction at rest */
    if (fabsf(current_a) < REST_CURRENT_THRESHOLD_A) {  /* S4 */
        float voltage_soc = lookup_ocv_table(voltage_v);  /* S5: need test */
        soc = (soc * 0.9f) + (voltage_soc * 0.1f);        /* S6: need test */
    }

    /* Clamp to valid range */
    if (soc > 100.0f) {                          /* S7 */
        soc = 100.0f;                            /* S8: need test */
    } else if (soc < 0.0f) {                     /* S9 */
        soc = 0.0f;                              /* S10: need test */
    }

    return soc;                                  /* S11: covered */
}
```

### Required Tests for Full Statement Coverage

```cpp
TEST(ComputeSoc, NormalCharging) {
    // Covers: S1, S2, S3, S4(false), S7(false), S9(false), S11
    float soc = compute_soc(3.7f, 10.0f, 1.0f, 50.0f);
    EXPECT_NEAR(soc, 50.1f, 0.01f);
}

TEST(ComputeSoc, AtRest_AppliesVoltageCorrection) {
    // Covers: S4(true), S5, S6
    float soc = compute_soc(3.85f, 0.01f, 1.0f, 50.0f);
    EXPECT_NEAR(soc, 50.5f, 1.0f);  // Corrected toward OCV
}

TEST(ComputeSoc, ClampsAbove100) {
    // Covers: S7(true), S8
    float soc = compute_soc(4.2f, 100.0f, 100.0f, 99.0f);
    EXPECT_FLOAT_EQ(soc, 100.0f);
}

TEST(ComputeSoc, ClampsBelow0) {
    // Covers: S9(true), S10
    float soc = compute_soc(2.5f, -100.0f, 100.0f, 1.0f);
    EXPECT_FLOAT_EQ(soc, 0.0f);
}
```

---

## Branch/Decision Coverage

### Definition

Every decision point (if/else, switch, loop condition, ternary) must
evaluate to both TRUE and FALSE at least once.

```c
/* Branch analysis example */
SafeState_t determine_safe_state(
    float cell_voltage_v,
    float pack_current_a,
    float temperature_c) {

    /* Branch B1: Over-voltage check */
    if (cell_voltage_v > MAX_CELL_VOLTAGE_V) {          /* B1 */
        return SAFE_STATE_DISCONNECT;                     /* B1-true */
    }

    /* Branch B2: Under-voltage check */
    if (cell_voltage_v < MIN_CELL_VOLTAGE_V) {           /* B2 */
        return SAFE_STATE_DISCONNECT;                     /* B2-true */
    }

    /* Branch B3: Overcurrent AND over-temperature (compound) */
    if (pack_current_a > MAX_CURRENT_A &&                /* B3 */
        temperature_c > MAX_TEMPERATURE_C) {
        return SAFE_STATE_REDUCE_POWER;                   /* B3-true */
    }

    /* Branch B4: Temperature warning */
    if (temperature_c > WARNING_TEMPERATURE_C) {         /* B4 */
        return SAFE_STATE_DERATE;                         /* B4-true */
    }

    return SAFE_STATE_NORMAL;                             /* B1-4 all false */
}
```

### Branch Coverage Test Matrix

```
+------+-------------------+-------------------+---------+
| Test | B1 | B2 | B3 | B4 | Inputs | Expected |
+------+----+----+----+----+--------+----------+
| T1   | T  | -  | -  | -  | V=4.5, I=0, T=25 | DISCONNECT |
| T2   | F  | T  | -  | -  | V=2.0, I=0, T=25 | DISCONNECT |
| T3   | F  | F  | T  | -  | V=3.7, I=600, T=60 | REDUCE_POWER |
| T4   | F  | F  | F  | T  | V=3.7, I=100, T=50 | DERATE |
| T5   | F  | F  | F  | F  | V=3.7, I=100, T=25 | NORMAL |
+------+----+----+----+----+--------+----------+
```

---

## MC/DC Coverage

### Definition

Modified Condition/Decision Coverage requires that:
1. Every entry and exit point is invoked
2. Every decision takes every possible outcome
3. Each condition in a decision independently affects the outcome

### MC/DC Analysis Process

```c
/* Decision: if (A && B || C) */
/* Conditions: A, B, C */
/* Need to show each condition independently affects outcome */

/*
 * Independence pairs:
 *
 * Condition A:
 *   Show A change flips outcome while B,C fixed
 *   Pair: (A=T,B=T,C=F -> T) vs (A=F,B=T,C=F -> F)
 *
 * Condition B:
 *   Show B change flips outcome while A,C fixed
 *   Pair: (A=T,B=T,C=F -> T) vs (A=T,B=F,C=F -> F)
 *
 * Condition C:
 *   Show C change flips outcome while A,B fixed
 *   Pair: (A=F,B=F,C=T -> T) vs (A=F,B=F,C=F -> F)
 *
 * Minimum test vectors for MC/DC: 4
 *   T1: A=T, B=T, C=F -> True  (pairs with T2 for A, T3 for B)
 *   T2: A=F, B=T, C=F -> False (pairs with T1 for A)
 *   T3: A=T, B=F, C=F -> False (pairs with T1 for B)
 *   T4: A=F, B=F, C=T -> True  (pairs with T5 for C)
 *   T5: A=F, B=F, C=F -> False (pairs with T4 for C)
 */
```

### MC/DC for Compound Decisions

```c
/* Real automotive example: Emergency stop condition */
bool should_emergency_stop(
    bool collision_imminent,     /* A */
    bool brake_failure,          /* B */
    bool driver_unresponsive,    /* C */
    bool system_critical_fault)  /* D */
{
    /* Decision: (A && !B) || (C && D) */
    return (collision_imminent && !brake_failure) ||
           (driver_unresponsive && system_critical_fault);
}

/*
 * MC/DC test vectors:
 *
 * | Test | A | B | C | D | Result | Shows independence of |
 * |------|---|---|---|---|--------|----------------------|
 * | T1   | T | F | F | F | T      | A: pair with T2      |
 * | T2   | F | F | F | F | F      | A: pair with T1      |
 * | T3   | T | T | F | F | F      | B: pair with T1      |
 * | T4   | F | F | T | T | T      | C: pair with T5      |
 * | T5   | F | F | F | T | F      | C: pair with T4      |
 * | T6   | F | F | T | F | F      | D: pair with T4      |
 *
 * Minimum vectors: 6 for 4 conditions
 */
```

### MC/DC Implementation Tests

```cpp
TEST(EmergencyStop, CollisionImminent_BrakesWorking_Stops) {
    // T1: A=T, B=F, C=F, D=F -> True
    EXPECT_TRUE(should_emergency_stop(true, false, false, false));
}

TEST(EmergencyStop, NoCollision_NoBrakeFail_NoStop) {
    // T2: A=F, B=F, C=F, D=F -> False
    EXPECT_FALSE(should_emergency_stop(false, false, false, false));
}

TEST(EmergencyStop, CollisionImminent_BrakeFailed_NoStop) {
    // T3: A=T, B=T, C=F, D=F -> False
    EXPECT_FALSE(should_emergency_stop(true, true, false, false));
}

TEST(EmergencyStop, DriverUnresponsive_CriticalFault_Stops) {
    // T4: A=F, B=F, C=T, D=T -> True
    EXPECT_TRUE(should_emergency_stop(false, false, true, true));
}

TEST(EmergencyStop, NoDriver_NoCritFault_NoStop) {
    // T5: A=F, B=F, C=F, D=T -> False
    EXPECT_FALSE(should_emergency_stop(false, false, false, true));
}

TEST(EmergencyStop, DriverUnresponsive_NoCritFault_NoStop) {
    // T6: A=F, B=F, C=T, D=F -> False
    EXPECT_FALSE(should_emergency_stop(false, false, true, false));
}
```

---

## Requirements Coverage

### Requirements Traceability Matrix

```yaml
traceability:
  - requirement:
      id: SSR-BMS-012
      text: "BMS shall detect overcurrent > 500A within 10ms"
      asil: D
    test_cases:
      - TC-BMS-042  # Normal overcurrent detection
      - TC-BMS-043  # Boundary: exactly 500A (no trigger)
      - TC-BMS-044  # Boundary: 500.1A (trigger)
      - TC-BMS-045  # Maximum current (1000A)
      - TC-BMS-046  # Timing: verify < 10ms response
    structural_coverage:
      statement: 100%
      branch: 100%
      mcdc: 100%
    status: FULLY_COVERED

  - requirement:
      id: SSR-BMS-013
      text: "BMS shall open contactor within 100ms of overcurrent detection"
      asil: D
    test_cases:
      - TC-BMS-047  # End-to-end timing measurement
      - FI-BMS-001  # Fault injection: primary path failure
      - FI-BMS-002  # Fault injection: secondary path failure
    structural_coverage:
      statement: 98%
      branch: 95%
      mcdc: 90%
    status: COVERED_WITH_JUSTIFICATION
    gap_justification: "2% uncovered code is error-handling for HW fault
                        not injectable in SIL; covered by HIL FI-BMS-003"
```

### Coverage Gap Analysis

```
Coverage Gap Categories:
========================

1. DEAD CODE
   - Code unreachable by any input
   - Action: Remove or justify as defensive coding
   - Example: Default case in fully-enumerated switch

2. DEFENSIVE CODE
   - Error handling for conditions hard to trigger in test
   - Action: Cover via fault injection or justify
   - Example: Memory allocation failure handler (static alloc system)

3. MISSING TEST
   - Code reachable but no test exercises it
   - Action: Add requirement-based or boundary test
   - Example: Untested else branch in configuration parsing

4. INFRASTRUCTURE CODE
   - Startup, shutdown, initialization
   - Action: Cover in integration test or justify
   - Example: OS startup hooks, interrupt vector setup

5. COMPILER-GENERATED CODE
   - Compiler inserts code not in source
   - Action: Document as not-applicable
   - Example: Stack canary checks, exception table
```

### Gap Justification Template

```yaml
coverage_gap:
  id: GAP-BMS-001
  file: "overcurrent_protection.c"
  line_range: "142-148"
  metric: "branch"
  uncovered_branch: "else branch at line 142"

  code_context: |
    if (hsm_verify_signature(data, sig)) {
        // Normal path - covered by tests
        process_key_update(data);
    } else {
        // Gap: HSM signature failure path
        report_security_event(SEC_EVT_SIG_FAILURE);
        return ERROR_AUTH_FAILED;
    }

  reason: "DEFENSIVE_CODE"
  explanation: >
    The HSM signature verification failure cannot be triggered in SIL
    environment because the HSM is mocked with a perfect implementation.
    This path is exercised in HIL fault injection test FI-SEC-005 where
    the HSM is configured to return verification failure.

  alternative_coverage: "FI-SEC-005 (HIL fault injection)"
  approved_by: "Safety Engineer"
  approval_date: "2025-03-15"
```

---

## Coverage Tooling

### Tool Configuration

```cmake
# CMake configuration for coverage measurement
if(COVERAGE_ENABLED)
    # GCC/Clang coverage flags
    target_compile_options(${TARGET} PRIVATE
        --coverage
        -fprofile-arcs
        -ftest-coverage
    )
    target_link_options(${TARGET} PRIVATE --coverage)

    # Generate coverage report after test execution
    add_custom_target(coverage
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/coverage
        COMMAND gcovr
            --root ${CMAKE_SOURCE_DIR}
            --filter ${CMAKE_SOURCE_DIR}/src/
            --exclude ${CMAKE_SOURCE_DIR}/test/
            --xml-pretty
            --output ${CMAKE_BINARY_DIR}/coverage/coverage.xml
            --html-details ${CMAKE_BINARY_DIR}/coverage/index.html
            --decisions  # Branch + MC/DC analysis
            --print-summary
            --fail-under-line 80
            --fail-under-branch 70
        DEPENDS ${TEST_TARGET}
        COMMENT "Generating coverage report"
    )
endif()
```

### Coverage Reporting in CI

```yaml
# Coverage gates in CI pipeline
coverage_gate:
  rules:
    - metric: statement
      threshold: 80
      fail_action: block_merge
    - metric: branch
      threshold: 70
      fail_action: block_merge
    - metric: mcdc
      threshold: 60
      fail_action: warn  # Warning for ASIL A/B
    - metric: function
      threshold: 100
      fail_action: block_merge

  exemptions:
    - path: "src/startup/*"
      reason: "Platform startup code - covered by integration tests"
    - path: "src/generated/*"
      reason: "Auto-generated code - covered by generator tests"
```

---

## Review Checklist

- [ ] Coverage metrics appropriate for ASIL level
- [ ] Statement coverage >= 95% for safety-critical modules
- [ ] Branch coverage >= 90% for ASIL B and above
- [ ] MC/DC coverage measured for ASIL C/D decisions
- [ ] Every safety requirement traced to test cases
- [ ] All coverage gaps analyzed and justified
- [ ] Defensive code gaps covered by fault injection
- [ ] Dead code identified and removed
- [ ] Coverage reports generated in CI pipeline
- [ ] Coverage gates enforce minimum thresholds
- [ ] Traceability matrix complete and reviewed
- [ ] Coverage tool qualified per ISO 26262 Part 8
