# ISO 26262 Functional Safety Compliance Rules

ISO 26262 is the automotive functional safety standard defining processes and technical requirements for safety-critical systems. This guide focuses on developer-facing requirements during software implementation.

## Standard Overview

ISO 26262 "Road vehicles - Functional safety" consists of 12 parts:
- Part 1: Vocabulary
- Part 2: Management of functional safety
- Part 3: Concept phase
- Part 4: Product development at system level
- Part 5: Product development at hardware level
- Part 6: Product development at software level (PRIMARY for developers)
- Part 7: Production and operation
- Part 8: Supporting processes
- Part 9: ASIL-oriented and safety-oriented analyses
- Part 10: Guideline on ISO 26262
- Part 11: Semiconductor guidelines
- Part 12: Motorcycles

## ASIL Levels Explained

Automotive Safety Integrity Level (ASIL) classifies safety requirements based on hazard severity, exposure, and controllability.

| ASIL | Risk Level | Example Systems |
|------|-----------|----------------|
| QM | Quality Management only | Infotainment, comfort features |
| A | Lowest safety | Rear lights, windshield wipers |
| B | Low safety | Brake lights, turn signals |
| C | Medium safety | Airbag deployment, cruise control |
| D | Highest safety | Steering control, anti-lock braking, autonomous emergency braking |

### ASIL Determination

```
Severity (S) × Exposure (E) × Controllability (C) = ASIL

Severity:
- S0: No injuries
- S1: Light and moderate injuries
- S2: Severe and life-threatening injuries
- S3: Life-threatening injuries (survival uncertain), fatal injuries

Exposure:
- E0: Incredible (less than once per system lifetime)
- E1: Very low (once per lifetime)
- E2: Low (once per year)
- E3: Medium (once per month)
- E4: High (daily occurrence)

Controllability:
- C0: Controllable in general
- C1: Simply controllable
- C2: Normally controllable
- C3: Difficult to control or uncontrollable
```

Example: Electronic Stability Control (ESC)
- Severity: S3 (life-threatening if fails)
- Exposure: E4 (used daily)
- Controllability: C3 (driver cannot easily compensate)
- Result: ASIL D

## Coding Requirements per ASIL

### ISO 26262-6 Table 1: Programming Language Selection

| Method | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|--------|--------|--------|--------|
| Use of language subset (MISRA) | + | ++ | ++ | ++ |
| Enforcement of strong typing | + | + | ++ | ++ |
| Use of defensive implementation | + | + | ++ | ++ |
| Use of established design principles | + | + | + | ++ |

Legend: ++ = Highly Recommended, + = Recommended

### ISO 26262-6 Table 6: Coding Guidelines

| Guideline | ASIL A | ASIL B | ASIL C | ASIL D |
|-----------|--------|--------|--------|--------|
| One entry/exit per function | + | + | ++ | ++ |
| No dynamic objects or variables (unless proven bounded) | + | ++ | ++ | ++ |
| No pointer arithmetic | + | + | ++ | ++ |
| No implicit type conversions | + | ++ | ++ | ++ |
| No hidden data flow or control flow | + | + | ++ | ++ |
| No unconditional jumps (goto) | + | ++ | ++ | ++ |
| No recursion | + | + | ++ | ++ |

### ASIL A/B Implementation

```c
// ASIL A/B: Recommended practices

// Single entry/exit recommended
int calculate_speed(int distance, int time) {
    int speed = 0;

    if (time > 0) {
        speed = distance / time;
    } else {
        // Handle error
        speed = -1;
    }

    return speed;  // Single exit point
}

// Bounded dynamic behavior acceptable
#define MAX_MESSAGES 50
static uint8_t message_count = 0;

void add_message(Message_t msg) {
    if (message_count < MAX_MESSAGES) {
        message_buffer[message_count] = msg;
        message_count++;
    }
}
```

### ASIL C/D Implementation

```c
// ASIL C/D: Highly recommended/mandatory practices

// No pointer arithmetic - use array indexing
void process_buffer(const uint8_t *data, uint16_t length) {
    // VIOLATION for ASIL D
    for (const uint8_t *p = data; p < data + length; p++) {
        process_byte(*p);
    }

    // COMPLIANT
    for (uint16_t i = 0U; i < length; i++) {
        process_byte(data[i]);
    }
}

// No recursion - use iteration
// VIOLATION
uint32_t factorial(uint32_t n) {
    return (n == 0U) ? 1U : n * factorial(n - 1U);
}

// COMPLIANT
uint32_t factorial(uint32_t n) {
    uint32_t result = 1U;
    for (uint32_t i = 2U; i <= n; i++) {
        result *= i;
    }
    return result;
}

// No unconditional jumps
// VIOLATION
void process_data(void) {
    if (!init_hardware()) {
        goto error_exit;
    }
    // ...
error_exit:
    shutdown_hardware();
}

// COMPLIANT - structured error handling
void process_data(void) {
    if (init_hardware()) {
        // Normal processing
    }
    shutdown_hardware();  // Always execute
}
```

## Safety Annotations in Code

Annotate safety-relevant code elements for traceability and analysis.

```c
/**
 * @safety_relevant: YES
 * @asil_level: ASIL_D
 * @safety_requirement: SR_BRK_001, SR_BRK_002
 * @brief: Calculate brake pressure based on pedal position
 *
 * Safety analysis:
 * - Input range validation prevents overflow
 * - Saturation logic prevents excessive pressure
 * - Plausibility check detects sensor fault
 *
 * @param pedal_position: Pedal position in percent (0-100)
 * @return: Brake pressure in bar (0-200)
 */
uint16_t calculate_brake_pressure(uint8_t pedal_position) {
    // Input validation (ISO 26262-6 defensive programming)
    if (pedal_position > 100U) {
        set_diagnostic_error(DTC_INVALID_PEDAL_POSITION);
        pedal_position = 100U;  // Saturate to safe value
    }

    // Linear mapping with saturation
    uint16_t pressure_bar = (uint16_t)pedal_position * 2U;

    // Safety limit enforcement
    if (pressure_bar > MAX_BRAKE_PRESSURE_BAR) {
        pressure_bar = MAX_BRAKE_PRESSURE_BAR;
    }

    return pressure_bar;
}

/**
 * @safety_relevant: NO
 * @asil_level: QM
 * @brief: Update infotainment display (non-safety)
 */
void update_infotainment_display(const char* message) {
    // No safety requirements
    display_write(message);
}
```

### Safety Annotation Tags

```c
// In header file or documentation
/**
 * Safety Classification Tags:
 *
 * @safety_relevant: YES/NO
 *   Indicates if function is part of safety-critical path
 *
 * @asil_level: QM/ASIL_A/ASIL_B/ASIL_C/ASIL_D
 *   ASIL decomposition result or QM for non-safety
 *
 * @safety_requirement: SR_XXX_NNN
 *   Comma-separated list of safety requirements implemented
 *
 * @safety_mechanism: ERROR_DETECTION/REDUNDANCY/PLAUSIBILITY_CHECK/etc
 *   Safety mechanisms implemented in function
 *
 * @fmea_coverage: FM_XXX_NNN
 *   Failure modes addressed by this implementation
 *
 * @verification_method: UNIT_TEST/INTEGRATION_TEST/STATIC_ANALYSIS/REVIEW
 *   Required verification activities
 */
```

## Required Work Products (ISO 26262-6)

### Software Safety Requirements Specification

```yaml
# Example: safety_requirements.yaml
SR_BRK_001:
  description: "System shall calculate brake pressure proportional to pedal input"
  asil: ASIL_D
  derived_from: SYS_REQ_005
  verification_method: ["Unit_Test", "Integration_Test"]
  implemented_in: ["brake_control.c::calculate_brake_pressure"]

SR_BRK_002:
  description: "System shall limit brake pressure to prevent wheel lock"
  asil: ASIL_D
  safety_mechanism: "Saturation with plausibility check"
  verification_method: ["Unit_Test", "HIL_Test"]
  implemented_in: ["brake_control.c::calculate_brake_pressure", "brake_control.c::apply_abs_logic"]
```

### Software Architecture Design

```
ECU_BrakeController/
├── safety_layer/              # ASIL-D components
│   ├── brake_control.c        # Primary brake logic
│   ├── sensor_plausibility.c  # Input validation
│   └── safety_monitor.c       # Watchdog and diagnostics
├── application_layer/         # ASIL-B components
│   ├── cruise_control.c
│   └── hill_hold_assist.c
└── qm_layer/                  # QM components
    └── user_interface.c
```

### Software Unit Design Specification

```c
/**
 * Unit: brake_control
 * ASIL: D
 * Design Pattern: Defensive programming with input validation
 *
 * Inputs:
 *   - pedal_position: uint8_t (0-100%)
 *   - vehicle_speed: uint16_t (0-300 km/h)
 *   - wheel_speeds: uint16_t[4] (0-300 km/h per wheel)
 *
 * Outputs:
 *   - brake_pressure: uint16_t (0-200 bar)
 *   - diagnostic_status: uint8_t bitmask
 *
 * Safety Mechanisms:
 *   1. Input range validation (plausibility check)
 *   2. Output saturation to safe limits
 *   3. Sensor cross-check (pedal vs. vehicle dynamics)
 *   4. Diagnostic error reporting
 *
 * Resource Usage:
 *   - Stack: 128 bytes
 *   - Execution time: < 2ms (WCET)
 *   - No dynamic memory allocation
 */
```

### Software Unit Implementation

Code with traceability comments:

```c
// Implements SR_BRK_001, SR_BRK_002
uint16_t calculate_brake_pressure(uint8_t pedal_position) {
    uint16_t pressure_bar;

    // SR_BRK_001: Input validation
    if (pedal_position > 100U) {
        set_dtc(DTC_PEDAL_IMPLAUSIBLE);
        pedal_position = 100U;
    }

    // SR_BRK_001: Proportional calculation
    pressure_bar = (uint16_t)pedal_position * 2U;

    // SR_BRK_002: Safety limit
    if (pressure_bar > MAX_BRAKE_PRESSURE_BAR) {
        pressure_bar = MAX_BRAKE_PRESSURE_BAR;
    }

    return pressure_bar;
}
```

## Verification Requirements

### ISO 26262-6 Table 12: Methods for Software Unit Testing

| Method | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|--------|--------|--------|--------|
| Requirements-based test | ++ | ++ | ++ | ++ |
| Interface testing | + | ++ | ++ | ++ |
| Fault injection testing | - | + | ++ | ++ |
| Resource usage testing | + | + | ++ | ++ |

### ISO 26262-6 Table 13: Structural Coverage Metrics

| Coverage Metric | ASIL A | ASIL B | ASIL C | ASIL D |
|----------------|--------|--------|--------|--------|
| Statement coverage | ++ | ++ | ++ | ++ |
| Branch coverage | + | ++ | ++ | ++ |
| MC/DC (Modified Condition/Decision Coverage) | - | + | ++ | ++ |

### ASIL D Testing Requirements

```c
// Example: MC/DC test cases for ASIL D function

/**
 * Function under test:
 * Condition: (pedal_position > 50) && (brake_enabled)
 */
bool should_apply_brake(uint8_t pedal_position, bool brake_enabled) {
    return (pedal_position > 50U) && brake_enabled;
}

// MC/DC Test Cases (each condition independently affects outcome)
TEST(BrakeLogic, MCDC_Coverage) {
    // Test 1: Both false -> false
    ASSERT_FALSE(should_apply_brake(30, false));

    // Test 2: First true, second false -> false (shows second matters)
    ASSERT_FALSE(should_apply_brake(60, false));

    // Test 3: First false, second true -> false (shows first matters)
    ASSERT_FALSE(should_apply_brake(30, true));

    // Test 4: Both true -> true
    ASSERT_TRUE(should_apply_brake(60, true));
}
```

### Coverage Enforcement in CI

```bash
#!/bin/bash
# verify_coverage.sh - Enforce ASIL-D coverage requirements

gcov -b src/safety_layer/*.c

# Extract coverage metrics
statement_cov=$(gcovr --print-summary | grep lines | awk '{print $2}' | tr -d '%')
branch_cov=$(gcovr --print-summary | grep branches | awk '{print $2}' | tr -d '%')

# ASIL D requirements: 100% statement, 100% branch (MC/DC via manual review)
if (( $(echo "$statement_cov < 100" | bc -l) )); then
    echo "ERROR: Statement coverage $statement_cov% < 100% required for ASIL D"
    exit 1
fi

if (( $(echo "$branch_cov < 100" | bc -l) )); then
    echo "ERROR: Branch coverage $branch_cov% < 100% required for ASIL D"
    exit 1
fi

echo "PASS: Coverage meets ASIL D requirements"
```

## Tool Qualification (ISO 26262-8)

### Tool Confidence Levels

| TCL | Criteria | Examples |
|-----|----------|----------|
| TCL1 | Low impact on safety, or high verification | Text editor, version control |
| TCL2 | Medium impact, medium verification | Compiler with extensive testing |
| TCL3 | High impact, low verification | Static analysis tool generating test cases |

### Tool Qualification Methods

```yaml
# tool_qualification.yaml
compiler:
  name: "GCC ARM Embedded 10.3"
  version: "10.3-2021.10"
  tcl: TCL2
  qualification_method: "Increased confidence from use (compiler test suite)"
  evidence:
    - "GCC test suite results (300k+ tests passed)"
    - "MISRA compliance validation report"
    - "Compiler qualification kit from ARM"

static_analyzer:
  name: "Polyspace Bug Finder"
  version: "R2024a"
  tcl: TCL3
  qualification_method: "Tool validation via back-to-back testing"
  evidence:
    - "Validation suite: 1000 test cases with known defects"
    - "Tool qualification report per ISO 26262-8"
    - "Annual recertification process"

test_framework:
  name: "Google Test + GCov"
  version: "1.14.0"
  tcl: TCL2
  qualification_method: "Proven in use + validation suite"
  evidence:
    - "Framework used in previous certified projects"
    - "Coverage tool validated against manual review"
```

## Configuration Management

### Baseline Requirements

Every software release must have:

1. Unique version identifier (semantic versioning)
2. Change history with safety impact analysis
3. Traceability to requirements
4. Build reproducibility (locked toolchain versions)

```bash
# build_info.h (auto-generated)
#define SW_VERSION_MAJOR 2
#define SW_VERSION_MINOR 1
#define SW_VERSION_PATCH 5
#define SW_BUILD_DATE "2024-03-15"
#define SW_GIT_COMMIT "a3f5d2c"
#define SW_COMPILER "GCC 10.3.1"
#define SW_ASIL_LEVEL "ASIL_D"
#define SW_SAFETY_MANUAL_VERSION "SM_v2.1"
```

### Change Impact Analysis

```markdown
# Change Request: CR-2024-042

## Modification
Function: calculate_brake_pressure()
File: brake_control.c
Lines changed: 45-52

## Safety Impact Analysis
- Safety requirements affected: SR_BRK_001 (unchanged), SR_BRK_002 (modified)
- ASIL level: ASIL D
- Impact: Algorithm optimization, no functional change
- Regression risk: LOW (output values identical, verified via unit tests)

## Verification Activities
- [x] Unit tests passed (100% coverage maintained)
- [x] Integration tests passed
- [x] Static analysis clean (no new defects)
- [x] Code review completed (2 reviewers)
- [x] Safety impact review approved

## Approval
- Developer: John Smith (2024-03-10)
- Safety Engineer: Jane Doe (2024-03-11)
- Project Manager: Bob Johnson (2024-03-12)
```

## Safety Manual Requirements

Every safety-relevant software component requires a safety manual documenting:

1. Safety concept and architecture
2. ASIL decomposition
3. Safety mechanisms
4. Assumptions of use
5. Integration requirements
6. Verification evidence

```markdown
# Software Safety Manual: Brake Control ECU

## 1. Safety Concept
The brake control ECU implements electronic brake distribution with ABS functionality,
classified as ASIL D for primary brake control functions.

## 2. ASIL Decomposition
- Brake pressure calculation: ASIL D
- ABS logic: ASIL D (redundant sensor processing)
- Hill hold assist: ASIL B (decomposed from ASIL D system requirement)
- User interface: QM

## 3. Safety Mechanisms
- Input plausibility checking (pedal position vs. vehicle dynamics)
- Output saturation (maximum pressure limit)
- Watchdog monitoring (2ms cycle time)
- Limp-home mode (degraded function if sensor fault)

## 4. Assumptions of Use
- Brake hydraulic system meets ISO 26262 ASIL D requirements
- Wheel speed sensors provide data at minimum 10Hz rate
- Power supply voltage remains within 9-16V range

## 5. Integration Requirements
- CAN bus timing: 1ms message cycle for critical signals
- Diagnostic interface: UDS protocol per ISO 14229
- Calibration parameters stored in secured EEPROM

## 6. Verification Evidence
- Unit test coverage: 100% statement, 100% branch (MC/DC documented)
- Integration test report: 250 test cases, 100% passed
- Static analysis: 0 critical defects, 0 high severity defects
- HIL test report: 5000 hours fault injection testing
```

## Freedom From Interference

For mixed-ASIL systems, demonstrate independence between safety elements:

```c
// Memory partitioning (MPU configuration)
const MPU_Region_t memory_partitions[] = {
    // ASIL D region - read-only code, protected RAM
    {
        .base_address = 0x08000000,
        .size = MPU_REGION_SIZE_64KB,
        .access_permission = MPU_READ_ONLY,
        .asil = ASIL_D
    },
    // ASIL B region - isolated RAM
    {
        .base_address = 0x20000000,
        .size = MPU_REGION_SIZE_32KB,
        .access_permission = MPU_READ_WRITE,
        .asil = ASIL_B
    },
    // QM region - separate partition
    {
        .base_address = 0x20008000,
        .size = MPU_REGION_SIZE_32KB,
        .access_permission = MPU_READ_WRITE,
        .asil = QM
    }
};

// Timing partitioning (RTOS task priorities)
void configure_tasks(void) {
    // Highest priority for ASIL D
    create_task(brake_control_task, PRIORITY_CRITICAL, STACK_SIZE_4K);

    // Medium priority for ASIL B
    create_task(cruise_control_task, PRIORITY_HIGH, STACK_SIZE_2K);

    // Low priority for QM
    create_task(infotainment_task, PRIORITY_LOW, STACK_SIZE_8K);
}
```

## References

- ISO 26262-6:2018 - Product development at the software level
- ISO 26262-8:2018 - Supporting processes (verification, configuration management, tool qualification)
- ISO 26262-9:2018 - ASIL-oriented and safety-oriented analyses
- MISRA C:2012 - Coding standard supporting ISO 26262 compliance
- AUTOSAR safety mechanisms specification
