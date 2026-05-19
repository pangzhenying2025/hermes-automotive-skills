# Automotive SPICE - Detailed Implementation Guide

## SWE.1: Software Requirements Analysis - Implementation

### BP1: Specify Software Requirements

**Objective**: Define complete, consistent, verifiable software requirements.

**Implementation Steps**:

1. **Collect Input**:
   - System requirements specification
   - Interface control documents
   - Safety requirements (ISO 26262)
   - Customer-specific requirements

2. **Categorize Requirements**:
   ```
   Functional Requirements:
   - What the software shall do
   - Example: "The software shall calculate wheel speed from sensor pulses"

   Non-Functional Requirements:
   - Performance: timing, throughput, resource usage
   - Safety: ASIL requirements, fail-safe behavior
   - Security: authentication, encryption
   - Reliability: MTBF, error handling
   - Maintainability: coding standards, modularity
   ```

3. **Apply Requirement Template**:
   ```
   Requirement ID: SWE-REQ-ESC-042
   Title: Wheel speed plausibility check
   Source: SYS-REQ-ESC-015
   Type: Functional
   Priority: High
   ASIL: D

   Description:
   The ESC software shall perform plausibility check on wheel speed
   sensor values by comparing with vehicle reference speed derived
   from non-driven axle.

   Acceptance Criteria:
   - Plausibility check executed every 20ms
   - Fault detected if deviation > 20% for > 200ms
   - DTC P0500 set upon fault detection
   - ESC function degraded to base ABS upon fault

   Verification Method: Software integration test with fault injection

   Rationale: ISO 26262 requires sensor diagnostics for ASIL D functions
   ```

4. **Ensure Quality Attributes**:
   - **Complete**: All aspects specified
   - **Consistent**: No contradictions
   - **Unambiguous**: Single interpretation
   - **Verifiable**: Can be tested
   - **Traceable**: Linked to source
   - **Feasible**: Technically achievable

### BP2: Analyze Software Requirements

**Objective**: Ensure requirements are correct, testable, and complete.

**Analysis Checklist**:

```
Completeness:
☐ All system requirements allocated to software or justified if not
☐ All interfaces specified (inputs, outputs, timing)
☐ Error handling specified for all functions
☐ Initialization and shutdown specified

Consistency:
☐ No contradictory requirements
☐ Terminology used consistently
☐ Units specified and consistent (km/h vs m/s)

Testability:
☐ Each requirement has verification method
☐ Quantitative criteria specified (not "fast" but "< 100ms")
☐ Acceptance criteria measurable

Correctness:
☐ Requirements reviewed by domain expert
☐ Requirements validated against system spec
☐ Safety requirements cross-checked with HARA
```

**Common Issues**:
- Ambiguous language ("shall handle errors appropriately")
- Missing quantification ("shall be fast")
- Combining multiple requirements ("shall read sensor and calculate speed")
- Untestable requirements ("shall be user-friendly")

### BP5: Bidirectional Traceability

**Implementation with Traceability Matrix**:

| System Req | Software Req | Architecture | Detailed Design | Test Case | Status |
|------------|--------------|--------------|-----------------|-----------|--------|
| SYS-042 | SWE-042 | COMP-ESC-DIAG | FUNC-CheckWheelSpeed | TC-SWE-042-01 | Verified |
| SYS-042 | SWE-042 | COMP-ESC-DIAG | FUNC-SetDTC | TC-SWE-042-02 | Verified |
| SYS-043 | SWE-043, SWE-044 | COMP-ESC-CTRL | FUNC-DeactivateESC | TC-SWE-043-01 | In progress |

**Tool Implementation**:
```yaml
# Requirements in YAML (for tools like Doorstop)
links:
  - SYS-042: SWE-042
  - SYS-043: SWE-043, SWE-044

requirements:
  - id: SWE-042
    parent: SYS-042
    text: "The ESC software shall perform plausibility check..."
    verification:
      - TC-SWE-042-01
      - TC-SWE-042-02
    implemented-in: COMP-ESC-DIAG
```

## SWE.2: Software Architectural Design - Implementation

### BP1: Develop Software Architectural Design

**Architectural Views**:

**Component View**:
```
ESC Software Architecture

┌─────────────────────────────────────────────────────┐
│  Application Layer                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ ESC Control  │  │ ABS Control  │  │ TCS Ctrl  │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │
└─────────┼──────────────────┼────────────────┼───────┘
          │                  │                │
┌─────────┼──────────────────┼────────────────┼───────┐
│         │   Service Layer  │                │       │
│  ┌──────▼───────┐  ┌───────▼──────┐  ┌──────▼────┐ │
│  │ Sensor Diag  │  │ Actuator Drv │  │ Vehicle   │ │
│  │              │  │              │  │ Dynamics  │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │
└─────────┼──────────────────┼────────────────┼───────┘
          │                  │                │
┌─────────┼──────────────────┼────────────────┼───────┐
│  BSW Layer (AUTOSAR)       │                │       │
│  ┌──────▼────┐  ┌──────────▼──┐  ┌──────────▼────┐ │
│  │ CAN Drv   │  │ PWM Driver  │  │  ADC Driver   │ │
│  └───────────┘  └─────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Deployment View**:
```
Physical ECU
├── CPU (ARM Cortex-R52)
│   ├── Core 0: ESC/ABS/TCS Control (ASIL D)
│   ├── Core 1: Diagnostics & Communication (ASIL B)
│   └── Watchdog: External WD monitoring Core 0
├── RAM (2 MB)
│   ├── Safety RAM: 1 MB (ECC protected)
│   └── Standard RAM: 1 MB
└── Flash (4 MB)
    ├── Bootloader: 256 KB
    ├── Application: 3 MB
    └── Calibration: 768 KB
```

### BP2: Allocate Requirements to Components

**Allocation Table**:

| Component | Allocated Requirements | ASIL | Dependencies |
|-----------|------------------------|------|--------------|
| ESC-CTRL | SWE-042, SWE-043, SWE-044 | D | SENSOR-DIAG, VEH-DYN, ACT-DRV |
| SENSOR-DIAG | SWE-050, SWE-051, SWE-052 | D | CAN-DRV, ADC-DRV |
| ACT-DRV | SWE-060, SWE-061 | D | PWM-DRV |
| VEH-DYN | SWE-070, SWE-071 | B | SENSOR-DIAG |

### BP3: Define Interfaces

**Interface Specification Template**:

```c
/**
 * Interface: I_SensorDiag
 * Provider: Component SENSOR-DIAG
 * Consumer: Component ESC-CTRL
 * ASIL: D
 */

typedef struct {
    float wheelSpeed_FL_mps;  // Front-left wheel speed [m/s]
    float wheelSpeed_FR_mps;  // Front-right wheel speed [m/s]
    float wheelSpeed_RL_mps;  // Rear-left wheel speed [m/s]
    float wheelSpeed_RR_mps;  // Rear-right wheel speed [m/s]
    uint8_t validityFlags;    // Bit field: 0=valid, 1=invalid
    uint8_t diagnosticStatus; // 0=OK, 1=degraded, 2=failed
} WheelSpeedData_t;

/**
 * Function: GetWheelSpeedData
 * Description: Retrieve current wheel speed values with diagnostic status
 * Timing: Called every 10ms (100Hz)
 * Return: Pointer to wheel speed data structure
 * Safety: Returns last valid data if current data invalid
 */
const WheelSpeedData_t* GetWheelSpeedData(void);
```

### BP4: Describe Dynamic Behavior

**Sequence Diagram**:
```
Time     ESC_CTRL    SENSOR_DIAG    ACT_DRV      HW
  |         |            |            |           |
10ms       GetWheelSpeed()           |           |
  |         |----------->|            |           |
  |         |<-----------|            |           |
  |         |      WheelSpeedData     |           |
  |         |                         |           |
  |     CalculateSlip()               |           |
  |         |                         |           |
  |     IF slip > threshold           |           |
  |         |    SetBrakePressure()   |           |
  |         |------------------------>|           |
  |         |                         |--PWM----->|
20ms       GetWheelSpeed()           |           |
  |         |----------->|            |           |
```

**State Machine**:
```
ESC Control States

     [Power On]
          |
          v
    ┌─────────┐
    │  INIT   │──[Init failed]──> ERROR
    └────┬────┘
         │ [Init OK]
         v
    ┌─────────┐
    │ STANDBY │<──────────┐
    └────┬────┘           │
         │ [Speed > 5km/h]│
         v                │
    ┌─────────┐           │
    │ ACTIVE  │           │
    └────┬────┘           │
         │ [Speed < 3km/h]│
         └────────────────┘
         │ [Sensor fault]
         v
    ┌─────────┐
    │DEGRADED │
    └─────────┘
```

## SWE.3: Detailed Design and Unit Construction - Implementation

### BP1: Develop Detailed Design

**Detailed Design Document (per module)**:

```c
/**
 * Module: WheelSpeedPlausibility
 * Component: SENSOR-DIAG
 * Requirement: SWE-042
 * ASIL: D
 *
 * Description:
 * Performs plausibility checks on wheel speed sensor values by comparing
 * individual wheel speeds against vehicle reference speed.
 *
 * Algorithm:
 * 1. Calculate vehicle reference speed from non-driven axle
 *    (average of rear wheels for front-wheel-drive vehicle)
 * 2. For each wheel, calculate deviation:
 *    deviation = |wheel_speed - reference_speed| / reference_speed
 * 3. If deviation > 20% for > 200ms, flag sensor as implausible
 * 4. Set corresponding bit in validityFlags
 * 5. If any sensor invalid, set diagnosticStatus = DEGRADED
 *
 * Timing: Executed every 20ms
 * Stack usage: 128 bytes
 * CPU usage: 15 µs (measured on ARM Cortex-R52 @300MHz)
 */

// Constants
#define PLAUS_DEVIATION_THRESHOLD_PCT  (20.0f)  // 20%
#define PLAUS_DEBOUNCE_COUNT           (10u)    // 10 cycles × 20ms = 200ms
#define WHEEL_FL (0u)
#define WHEEL_FR (1u)
#define WHEEL_RL (2u)
#define WHEEL_RR (3u)

// Static variables
static uint8_t faultCounters[4] = {0, 0, 0, 0};

/**
 * Function: CheckWheelSpeedPlausibility
 * Input: rawWheelSpeeds[4] - Raw wheel speed values [m/s]
 * Output: validityFlags - Bit field (bit 0 = FL, bit 1 = FR, etc.)
 * Returns: true if all sensors plausible, false otherwise
 */
bool CheckWheelSpeedPlausibility(const float rawWheelSpeeds[4],
                                  uint8_t* validityFlags);
```

### BP6: Construct Software Units

**Implementation**:

```c
#include "WheelSpeedPlausibility.h"
#include <math.h>
#include <stdbool.h>

bool CheckWheelSpeedPlausibility(const float rawWheelSpeeds[4],
                                  uint8_t* validityFlags)
{
    // Calculate reference speed (average of rear wheels for FWD)
    float referenceSpeed = (rawWheelSpeeds[WHEEL_RL] +
                            rawWheelSpeeds[WHEEL_RR]) / 2.0f;

    // Handle low-speed case (division by zero protection)
    if (referenceSpeed < 0.1f) {
        *validityFlags = 0x00; // All valid at low speed
        return true;
    }

    bool allPlausible = true;
    *validityFlags = 0x00;

    // Check each wheel
    for (uint8_t wheel = 0; wheel < 4u; wheel++) {
        float deviation = fabsf(rawWheelSpeeds[wheel] - referenceSpeed) /
                          referenceSpeed * 100.0f;

        if (deviation > PLAUS_DEVIATION_THRESHOLD_PCT) {
            faultCounters[wheel]++;
            if (faultCounters[wheel] >= PLAUS_DEBOUNCE_COUNT) {
                *validityFlags |= (1u << wheel); // Set invalid bit
                allPlausible = false;
                faultCounters[wheel] = PLAUS_DEBOUNCE_COUNT; // Clamp
            }
        } else {
            // Decrement counter with hysteresis
            if (faultCounters[wheel] > 0u) {
                faultCounters[wheel]--;
            }
        }
    }

    return allPlausible;
}
```

### BP7: Ensure Consistency with Design

**Consistency Checklist**:
- ☑ Function signature matches header
- ☑ Algorithm matches detailed design description
- ☑ Constants match specification
- ☑ Resource usage within budget (stack, CPU)
- ☑ MISRA C compliance verified
- ☑ Safety annotations present (ASIL tag)

## SWE.4: Software Unit Verification - Implementation

### BP2: Develop Unit Test Specification

**Test Case Template**:

```
Test Case ID: TC-SWE-042-UT-01
Test Objective: Verify plausibility check detects excessive deviation
Requirement: SWE-042 BP1 (deviation > 20%)
Test Level: Unit test
ASIL: D (requires MC/DC coverage)

Preconditions:
- faultCounters[] initialized to zero
- validityFlags initialized to 0x00

Test Data:
Input:
  rawWheelSpeeds[WHEEL_FL] = 15.0 m/s
  rawWheelSpeeds[WHEEL_FR] = 14.8 m/s
  rawWheelSpeeds[WHEEL_RL] = 10.0 m/s (reference)
  rawWheelSpeeds[WHEEL_RR] = 10.0 m/s (reference)

Expected Output:
  validityFlags = 0x03 (bits 0 and 1 set after debounce)
  Return value = false (after 10 cycles)

Test Steps:
1. Call CheckWheelSpeedPlausibility() with test data
2. Repeat 9 times (debounce = 10 cycles)
3. On 10th call, verify validityFlags = 0x03
4. Verify return value = false

Pass Criteria:
- FL and FR flagged as invalid after 200ms (10 cycles × 20ms)
- RL and RR remain valid
```

### BP3: Test Software Units

**Unit Test Implementation (Google Test)**:

```cpp
#include <gtest/gtest.h>
extern "C" {
#include "WheelSpeedPlausibility.h"
}

class WheelSpeedPlausTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Reset static state
        ResetPlausibilityModule();
    }
};

TEST_F(WheelSpeedPlausTest, DetectExcessiveDeviation) {
    float wheelSpeeds[4] = {15.0f, 14.8f, 10.0f, 10.0f};
    uint8_t validityFlags;

    // First 9 cycles - fault counters increment but not yet flagged
    for (int i = 0; i < 9; i++) {
        bool result = CheckWheelSpeedPlausibility(wheelSpeeds, &validityFlags);
        EXPECT_TRUE(result); // Still plausible (debouncing)
        EXPECT_EQ(validityFlags, 0x00);
    }

    // 10th cycle - debounce expired, fault flagged
    bool result = CheckWheelSpeedPlausibility(wheelSpeeds, &validityFlags);
    EXPECT_FALSE(result);
    EXPECT_EQ(validityFlags, 0x03); // FL and FR invalid
}

TEST_F(WheelSpeedPlausTest, LowSpeedBypass) {
    float wheelSpeeds[4] = {0.05f, 0.04f, 0.05f, 0.05f};
    uint8_t validityFlags;

    bool result = CheckWheelSpeedPlausibility(wheelSpeeds, &validityFlags);
    EXPECT_TRUE(result);
    EXPECT_EQ(validityFlags, 0x00); // All valid at low speed
}

TEST_F(WheelSpeedPlausTest, Hysteresis) {
    float faultySpeeds[4] = {15.0f, 10.0f, 10.0f, 10.0f};
    float goodSpeeds[4] = {10.0f, 10.0f, 10.0f, 10.0f};
    uint8_t validityFlags;

    // Generate fault
    for (int i = 0; i < 10; i++) {
        CheckWheelSpeedPlausibility(faultySpeeds, &validityFlags);
    }
    EXPECT_EQ(validityFlags, 0x01); // FL invalid

    // Clear fault with good data
    for (int i = 0; i < 10; i++) {
        CheckWheelSpeedPlausibility(goodSpeeds, &validityFlags);
    }
    EXPECT_EQ(validityFlags, 0x00); // FL valid again
}
```

### Coverage Analysis

**MC/DC Coverage for ASIL D**:

```c
// Decision: if (deviation > PLAUS_DEVIATION_THRESHOLD_PCT)
// Conditions: deviation, PLAUS_DEVIATION_THRESHOLD_PCT

MC/DC Test Cases:
TC1: deviation = 25.0%, threshold = 20.0% → TRUE (deviation high)
TC2: deviation = 15.0%, threshold = 20.0% → FALSE (deviation low)

// Decision: if (faultCounters[wheel] >= PLAUS_DEBOUNCE_COUNT)
MC/DC Test Cases:
TC3: faultCounters[0] = 10, DEBOUNCE = 10 → TRUE (boundary)
TC4: faultCounters[0] = 9, DEBOUNCE = 10 → FALSE (below threshold)

// Combined decision in if-else
MC/DC Coverage: 100% (all conditions independently affect outcome)
```

## Traceability Implementation

### End-to-End Trace Example

```
Customer Requirement:
CR-ESC-001: "Vehicle stability control shall detect wheel slip"

System Requirement:
SYS-REQ-042: "ESC system shall detect wheel speed deviation > 20%"
  [Trace: CR-ESC-001]

Software Requirement:
SWE-REQ-042: "ESC software shall perform plausibility check on wheel speed"
  [Trace: SYS-REQ-042]

Software Architecture:
COMP-SENSOR-DIAG: Component responsible for sensor diagnostics
  [Allocates: SWE-REQ-042]

Detailed Design:
MODULE-WheelSpeedPlausibility: Detailed algorithm specification
  [Implements: SWE-REQ-042 via COMP-SENSOR-DIAG]

Implementation:
FILE: WheelSpeedPlausibility.c
FUNCTION: CheckWheelSpeedPlausibility()
  [Code lines: 45-78]

Unit Test:
TC-SWE-042-UT-01: Verify detection of deviation > 20%
TC-SWE-042-UT-02: Verify debounce timing (200ms)
TC-SWE-042-UT-03: Verify low-speed bypass
  [Verifies: SWE-REQ-042]

Integration Test:
TC-SWE-042-IT-01: Verify integration with ESC-CTRL component
  [Verifies: Interface I_SensorDiag]

System Test:
TC-SYS-042-ST-01: Verify ESC deactivation upon wheel speed fault
  [Verifies: SYS-REQ-042]
```

## Next Steps

- **Level 4**: Work product templates, checklists, assessment preparation
- **Level 5**: Achieving Level 3, organizational process assets, continuous improvement

## References

- Automotive SPICE PAM v3.1 SWE Process Group
- VDA Guideline: Software Requirements Specification
- Example work products from VDA QMC Working Group

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Software developers, test engineers, technical leads
