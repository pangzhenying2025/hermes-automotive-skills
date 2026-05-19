# MISRA C:2012 Coding Standard Rules

MISRA C:2012 is the automotive industry's de facto standard for safe and reliable C code. These rules eliminate undefined behavior, reduce complexity, and improve maintainability in safety-critical systems.

## Purpose

- Eliminate undefined and unspecified behavior in C code
- Enforce predictable, deterministic execution
- Improve code portability across compilers and platforms
- Facilitate static analysis and formal verification
- Support ISO 26262 functional safety compliance

## Applicability

MISRA C:2012 applies to all C code in automotive projects:
- ASIL-A/B: Advisory rules recommended, Required rules mandatory
- ASIL-C/D: All Required and Mandatory rules enforced
- QM (non-safety): Subset of rules applied for quality

## Rule Categories

| Category | Enforcement | Deviation Allowed |
|----------|-------------|-------------------|
| Mandatory | Must comply | Formal deviation only, rare |
| Required | Must comply | Deviation with justification |
| Advisory | Should comply | Deviation permitted, document recommended |

## Key Mandatory Rules

### Rule 1.3 (Mandatory): No undefined or critical unspecified behavior

```c
// VIOLATION: Signed integer overflow (undefined behavior)
int16_t add(int16_t a, int16_t b) {
    return a + b;  // May overflow
}

// COMPLIANT: Check for overflow before operation
int16_t add_safe(int16_t a, int16_t b, bool *overflow) {
    if ((b > 0) && (a > (INT16_MAX - b))) {
        *overflow = true;
        return INT16_MAX;
    }
    if ((b < 0) && (a < (INT16_MIN - b))) {
        *overflow = true;
        return INT16_MIN;
    }
    *overflow = false;
    return a + b;
}
```

### Rule 2.2 (Mandatory): No dead code

```c
// VIOLATION: Unreachable code
void process_data(uint8_t value) {
    if (value > 100U) {
        return;
        value = 100U;  // Dead code - never executed
    }
}

// COMPLIANT: Remove dead code
void process_data(uint8_t value) {
    if (value > 100U) {
        return;
    }
    // Continue processing
}
```

### Rule 9.1 (Mandatory): Variables shall be initialized

```c
// VIOLATION: Uninitialized variable
void calculate_speed(void) {
    uint16_t speed;
    if (condition) {
        speed = get_speed();
    }
    send_can_message(speed);  // May use uninitialized value
}

// COMPLIANT: Initialize before use
void calculate_speed(void) {
    uint16_t speed = 0U;
    if (condition) {
        speed = get_speed();
    }
    send_can_message(speed);
}
```

## Key Required Rules

### Rule 8.4 (Required): Compatible declarations

```c
// VIOLATION: Inconsistent function declarations
// header.h
extern int32_t calculate(int16_t x);

// source.c
int32_t calculate(uint16_t x) {  // Type mismatch
    return (int32_t)x * 2;
}

// COMPLIANT: Matching declarations
// header.h
extern int32_t calculate(int16_t x);

// source.c
int32_t calculate(int16_t x) {
    return (int32_t)x * 2;
}
```

### Rule 10.3 (Required): Value preserving assignment

```c
// VIOLATION: Implicit narrowing conversion
uint16_t speed_kmh = 0U;
uint8_t speed_display;

void update_display(void) {
    speed_display = speed_kmh;  // May lose data
}

// COMPLIANT: Explicit conversion with range check
void update_display(void) {
    if (speed_kmh <= 255U) {
        speed_display = (uint8_t)speed_kmh;
    } else {
        speed_display = 255U;  // Saturate
    }
}
```

### Rule 11.8 (Required): No cast removing const/volatile

```c
// VIOLATION: Casting away const
void modify_config(const uint32_t *config) {
    uint32_t *p = (uint32_t *)config;  // Removes const
    *p = 0x12345678U;  // Undefined behavior
}

// COMPLIANT: Don't modify const data
void read_config(const uint32_t *config) {
    uint32_t local_copy = *config;
    // Work with local copy
}
```

### Rule 13.5 (Required): No side effects in right operand of &&, ||

```c
// VIOLATION: Side effect in logical operator
if ((status == READY) && (increment_counter() > 0)) {
    // increment_counter() may not execute if status != READY
}

// COMPLIANT: Separate side effects
increment_counter();
if ((status == READY) && (counter > 0)) {
    // Predictable execution
}
```

### Rule 14.4 (Required): Controlling expression shall be Boolean

```c
// VIOLATION: Non-Boolean controlling expression
uint8_t value = get_sensor_value();
if (value) {  // Implicit comparison to 0
    process();
}

// COMPLIANT: Explicit Boolean expression
uint8_t value = get_sensor_value();
if (value != 0U) {
    process();
}
```

### Rule 17.7 (Required): Return value shall be used

```c
// VIOLATION: Ignoring return value
void write_eeprom(void) {
    eeprom_write(0x100U, data);  // Ignores error code
}

// COMPLIANT: Check return value
void write_eeprom(void) {
    if (eeprom_write(0x100U, data) != E_OK) {
        // Handle error
        set_dtc(DTC_EEPROM_WRITE_FAILED);
    }
}
```

### Rule 21.3 (Required): No malloc/calloc/realloc/free in safety code

```c
// VIOLATION: Dynamic memory allocation
void process_buffer(uint16_t size) {
    uint8_t *buffer = (uint8_t *)malloc(size);  // Non-deterministic
    if (buffer != NULL) {
        // Process
        free(buffer);
    }
}

// COMPLIANT: Static allocation
#define MAX_BUFFER_SIZE 256U
static uint8_t buffer[MAX_BUFFER_SIZE];

void process_buffer(uint16_t size) {
    if (size <= MAX_BUFFER_SIZE) {
        // Process using static buffer
    }
}
```

## Key Advisory Rules

### Rule 2.7 (Advisory): No unused function parameters

```c
// VIOLATION: Unused parameter
void can_rx_callback(uint32_t id, uint8_t *data, uint8_t length) {
    // 'length' parameter never used
    process_can_frame(id, data);
}

// COMPLIANT: Mark unused parameter or remove it
void can_rx_callback(uint32_t id, uint8_t *data, uint8_t length) {
    (void)length;  // Explicitly mark as unused if required by interface
    process_can_frame(id, data);
}
```

### Rule 8.13 (Advisory): Pointer should be const if not modified

```c
// VIOLATION: Missing const qualifier
uint32_t calculate_checksum(uint8_t *data, uint16_t length) {
    uint32_t checksum = 0U;
    for (uint16_t i = 0U; i < length; i++) {
        checksum += data[i];
    }
    return checksum;
}

// COMPLIANT: Add const to read-only parameter
uint32_t calculate_checksum(const uint8_t *data, uint16_t length) {
    uint32_t checksum = 0U;
    for (uint16_t i = 0U; i < length; i++) {
        checksum += data[i];
    }
    return checksum;
}
```

## Common Violations and Fixes

### Integer Division Before Widening

```c
// VIOLATION
uint32_t percent = (value / total) * 100U;  // Loses precision

// COMPLIANT
uint32_t percent = ((uint32_t)value * 100U) / total;
```

### Array Index Out of Bounds

```c
// VIOLATION
#define ARRAY_SIZE 10U
uint16_t data[ARRAY_SIZE];

void set_value(uint8_t index, uint16_t value) {
    data[index] = value;  // No bounds check
}

// COMPLIANT
void set_value(uint8_t index, uint16_t value) {
    if (index < ARRAY_SIZE) {
        data[index] = value;
    } else {
        // Handle error
    }
}
```

### Bitwise Operations on Signed Types

```c
// VIOLATION
int16_t flags = 0;
flags = flags | 0x8000;  // May cause implementation-defined behavior

// COMPLIANT
uint16_t flags = 0U;
flags = flags | 0x8000U;
```

### Switch Without Default

```c
// VIOLATION
switch (state) {
    case STATE_IDLE:
        handle_idle();
        break;
    case STATE_ACTIVE:
        handle_active();
        break;
    // No default case
}

// COMPLIANT
switch (state) {
    case STATE_IDLE:
        handle_idle();
        break;
    case STATE_ACTIVE:
        handle_active();
        break;
    default:
        // Handle unexpected state
        set_error(ERR_INVALID_STATE);
        break;
}
```

## Tool Support

### Cppcheck

```bash
# Basic MISRA C:2012 check
cppcheck --addon=misra.json --enable=all --error-exitcode=1 src/

# With custom rule configuration
cppcheck --addon=misra.json --suppressions-list=misra_suppressions.txt src/
```

Example `misra.json`:
```json
{
  "script": "misra.py",
  "args": ["--rule-texts=misra_2012_rules.txt"]
}
```

### PC-Lint Plus

```bash
# Run PC-Lint with MISRA C:2012 configuration
pclp64 -v -width(120) au-misra3.lnt src/*.c
```

Configuration file `au-misra3.lnt`:
```
// Enable MISRA C:2012 checks
+misra(2012)

// Set ASIL level (affects required rules)
-asil(D)

// Deviation file
-deviations(misra_deviations.txt)
```

### Polyspace Bug Finder

```matlab
% MATLAB script for Polyspace MISRA checking
opts = pslinkoptions();
opts.CodingRulesCodeMetrics = 'MISRA C:2012';
opts.MisraC3Strictness = 'Required';
results = polyspace('BugFinder', 'sources', {'src/*.c'}, opts);
```

### QAC (PRQA)

```bash
# Run QAC with MISRA C:2012 profile
qacli admin --qaf-project project.qaf --license-server license.company.com
qacli analyze --qaf-project project.qaf --config-path MISRA_C_2012
qacli report --qaf-project project.qaf --output misra_report.html
```

## Deviation Process

### When Deviations Are Acceptable

1. Physical impossibility (e.g., recursion in deeply embedded protocol stack)
2. Library interfaces beyond control (third-party HAL)
3. Language limitations (unavoidable cast for register access)
4. Performance critical code with proven safety (assembly-optimized CRC)

### Deviation Documentation Template

```c
/**
 * MISRA Deviation Record
 *
 * Rule: 11.4 (Advisory) - Cast between pointer to object and integer type
 * Justification: Memory-mapped peripheral register access requires pointer-to-integer conversion.
 *                Hardware abstraction layer pattern approved by safety architect.
 * Approval: John Smith (Safety Manager), 2024-01-15
 * Tracking: SAFE-1234
 */
#define UART_BASE_ADDR  ((uint32_t)0x40004000U)
#define UART_DATA_REG   (*((volatile uint32_t *)UART_BASE_ADDR))
```

### Deviation Approval Workflow

```
Developer identifies need --> Document justification --> Safety review
    |                              |                          |
    v                              v                          v
Create deviation request    Add to deviation file    Approve/Reject
    |                              |                          |
    v                              v                          v
Tag in code with ID        Update tool suppression   Track in issue system
```

## Enforcement in CI/CD

### Jenkins Pipeline Example

```groovy
stage('MISRA C:2012 Check') {
    steps {
        sh '''
            # Run cppcheck with MISRA addon
            cppcheck --addon=misra.json \
                     --enable=all \
                     --inconclusive \
                     --xml \
                     --xml-version=2 \
                     src/ 2> misra_results.xml

            # Parse results and fail if violations found
            python scripts/check_misra_violations.py misra_results.xml
        '''

        publishHTML(target: [
            reportDir: 'reports',
            reportFiles: 'misra_report.html',
            reportName: 'MISRA C:2012 Report'
        ])
    }
}
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running MISRA C:2012 checks..."

# Get list of C files being committed
C_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.c$')

if [ -z "$C_FILES" ]; then
    exit 0
fi

# Run cppcheck on staged files
cppcheck --addon=misra.json --enable=all --error-exitcode=1 $C_FILES

if [ $? -ne 0 ]; then
    echo "MISRA C:2012 violations found. Commit rejected."
    echo "Fix violations or request formal deviation."
    exit 1
fi

echo "MISRA C:2012 checks passed."
exit 0
```

## ASIL-Specific Requirements

### ASIL A/B

- Mandatory rules: Must comply
- Required rules: Must comply (deviations allowed)
- Advisory rules: Recommended

### ASIL C

- Mandatory rules: Must comply
- Required rules: Must comply (formal deviations only)
- Advisory rules: Should comply

### ASIL D

- Mandatory rules: Must comply (no deviations without safety case)
- Required rules: Must comply (formal deviations with safety architect approval)
- Advisory rules: Must comply unless proven inapplicable

## Integration with ISO 26262

MISRA C:2012 satisfies ISO 26262-6 Table 1 requirements:
- Use of language subsets (++)
- Enforcement of strong typing (++)
- Use of defensive implementation techniques (+)
- Use of established design principles (+)

Each MISRA rule maps to safety objectives:
- Freedom from interference
- Deterministic execution
- Error detection and handling
- Fault tolerance

## Metrics and Reporting

Track MISRA compliance metrics:
- Compliance percentage per module
- Deviation count by category
- Violation trend over time
- Rule coverage per ASIL level

Example compliance report:
```
MISRA C:2012 Compliance Report
================================
Project: ECU_Controller
ASIL Level: D
Scan Date: 2024-03-15

Rule Category          | Total | Pass | Fail | Deviation | Compliance
-----------------------|-------|------|------|-----------|------------
Mandatory              |   15  |  15  |   0  |     0     |   100.0%
Required               |  143  | 138  |   2  |     3     |    98.6%
Advisory               |   84  |  79  |   4  |     1     |    95.2%
-----------------------|-------|------|------|-----------|------------
Overall                |  242  | 232  |   6  |     4     |    97.5%

Critical Violations (Mandatory/Required):
- Rule 11.8: file.c:245 - Cast removes const qualifier
- Rule 17.7: module.c:112 - Return value not checked

All violations must be resolved before release.
```

## References

- MISRA C:2012 Guidelines for the Use of the C Language in Critical Systems (ISBN 978-1-906400-10-1)
- MISRA Compliance:2020 (ISBN 978-1-906400-27-9)
- ISO 26262-6:2018 Product development at the software level
- AUTOSAR C++14 Coding Guidelines (complementary for C++ projects)
