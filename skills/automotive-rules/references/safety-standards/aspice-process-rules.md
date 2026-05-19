# Automotive SPICE Process Rules

Automotive SPICE (Software Process Improvement and Capability dEtermination) is the de facto standard for assessing software development processes in the automotive industry. This guide focuses on developer-facing process requirements.

## ASPICE Overview

ASPICE evaluates process capability on a 6-level scale (0-5) across three process categories:
- Primary Life Cycle Processes (ACQ, SPL, SYS, SWE, MAN)
- Supporting Life Cycle Processes (SUP)
- Organizational Life Cycle Processes (ORG)

Target capability levels vary by OEM:
- Tier 1 suppliers: Capability Level 2 (Managed) or Level 3 (Established) typical
- Critical safety systems: Level 3 required
- Advanced projects: Level 4+ (Predictable/Optimizing)

## Capability Levels Explained

| Level | Name | Characteristics | Evidence Required |
|-------|------|----------------|-------------------|
| 0 | Incomplete | Process not implemented or fails | None |
| 1 | Performed | Achieves purpose, informal | Work products exist |
| 2 | Managed | Planned, tracked, controlled | Planning docs, reviews, tracking |
| 3 | Established | Uses defined standard process | Process descriptions, tailoring |
| 4 | Predictable | Operates within defined limits, measured | Metrics, quantitative analysis |
| 5 | Optimizing | Continuously improved, innovative | Improvement data, trend analysis |

### Level 1 (Performed) Requirements

```
Base Practices (BP):
- Process achieves its purpose
- Work products are produced

Evidence:
- Code exists and compiles
- Requirements are documented somewhere
- Tests are run (even if ad-hoc)
```

### Level 2 (Managed) Requirements

```
Generic Practices (GP):
GP 2.1 Identify objectives
  - Project planning document exists
  - Scope and goals defined

GP 2.2 Plan the process
  - Work breakdown structure
  - Resource allocation
  - Schedule with milestones

GP 2.3 Monitor and adjust
  - Progress tracking (e.g., Jira burndown)
  - Issue management
  - Corrective actions

GP 2.4 Control work products
  - Version control (Git)
  - Baseline management
  - Change control

GP 2.5 Identify and manage interfaces
  - Interface specifications documented
  - Communication plan with stakeholders
```

### Level 3 (Established) Requirements

```
Generic Practices (GP):
GP 3.1 Define standard process
  - Organization-wide process descriptions
  - Templates and checklists
  - Process tailoring guidelines

GP 3.2 Deploy standard process
  - Project adapts standard process
  - Tailoring decisions documented
  - Process training provided
```

## Key Process Areas for Developers

### SWE.1: Software Requirements Analysis

**Purpose**: Establish requirements for software elements.

#### Base Practices

BP1: Specify software requirements
```yaml
# Example: software_requirement.yaml
REQ-SWE-001:
  title: "Calculate brake pressure based on pedal position"
  description: |
    The software shall calculate brake pressure proportional to pedal
    position input with a scaling factor of 2.0 bar per 1% pedal travel.
  derived_from: SYS-REQ-BRK-005
  type: functional
  priority: high
  verification_method: unit_test
  acceptance_criteria:
    - "Pedal at 0% yields 0 bar pressure"
    - "Pedal at 100% yields 200 bar pressure"
    - "Linearity error < 2%"
```

BP2: Structure software requirements
```
Organize by architectural layers:
- Interface requirements (external inputs/outputs)
- Functional requirements (behavior)
- Non-functional requirements (performance, safety, security)
- Design constraints (hardware, standards)
```

BP3: Analyze software requirements
```markdown
# Requirements Review Checklist

Per Requirement:
- [ ] Unambiguous (single interpretation)
- [ ] Testable (verification method defined)
- [ ] Consistent (no conflicts with other requirements)
- [ ] Feasible (technically achievable)
- [ ] Traceable (linked to system requirement)

Example:
FAIL: "System shall respond quickly"  (not testable)
PASS: "System shall respond within 100ms to user input"
```

BP4: Analyze impact on operating environment
```c
/**
 * Requirement: REQ-SWE-001
 * Impact Analysis:
 *
 * Hardware: Requires ADC input from pedal sensor (ADC1, Channel 3)
 * Software: Depends on sensor driver module (SensorDrv_ReadPedalPosition)
 * Timing: Executes in 10ms task, WCET < 2ms
 * Memory: 128 bytes stack, 64 bytes static data
 * Power: Continuous execution, contributes to base load
 * Safety: ASIL-D, requires input plausibility check
 */
```

BP5: Develop verification criteria
```c
// Unit test specification derived from requirement
TEST(BrakePressure, REQ_SWE_001_ProportionalCalculation) {
    // Test Case 1: Minimum input
    EXPECT_EQ(CalculateBrakePressure(0), 0);

    // Test Case 2: Maximum input
    EXPECT_EQ(CalculateBrakePressure(100), 200);

    // Test Case 3: Mid-range
    EXPECT_EQ(CalculateBrakePressure(50), 100);

    // Test Case 4: Linearity
    EXPECT_NEAR(CalculateBrakePressure(25), 50, 1);  // ±1 bar tolerance
}
```

BP6: Establish bidirectional traceability
```yaml
# Traceability matrix
SYS-REQ-BRK-005:
  allocated_to:
    - REQ-SWE-001: "Calculate brake pressure"
    - REQ-SWE-002: "Validate pedal input range"
  verified_by:
    - TC-SWE-001: "Unit test: Proportional calculation"
    - TC-INT-005: "Integration test: End-to-end brake control"

REQ-SWE-001:
  parent: SYS-REQ-BRK-005
  implemented_in: "src/brake_control.c::CalculateBrakePressure"
  tested_by:
    - "test/test_brake_control.cpp::REQ_SWE_001_ProportionalCalculation"
```

#### Work Products

| Work Product | Description | Template Location |
|--------------|-------------|-------------------|
| 13-04 | Software Requirements Specification (SRS) | `/docs/templates/SRS_Template.md` |
| 13-22 | Traceability Record | `/tools/traceability_matrix.xlsx` |
| 13-50 | Verification Criteria | Embedded in SRS and test specs |

### SWE.2: Software Architectural Design

**Purpose**: Establish architectural design describing software elements and their interactions.

#### Base Practices

BP1: Develop software architectural design
```
┌─────────────────────────────────────────────────────┐
│              Application Layer                       │
│  ┌──────────────┐  ┌──────────────┐                │
│  │ Brake Manager │  │ Diagnostics  │                │
│  └──────────────┘  └──────────────┘                │
├─────────────────────────────────────────────────────┤
│            Service Layer (AUTOSAR RTE)               │
├─────────────────────────────────────────────────────┤
│              Basic Software Layer                    │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐           │
│  │  CAN  │  │  ADC  │  │  PWM  │  │  NVM  │           │
│  └──────┘  └──────┘  └──────┘  └──────┘           │
├─────────────────────────────────────────────────────┤
│              Hardware Abstraction Layer              │
└─────────────────────────────────────────────────────┘

Architecture Document: docs/architecture/SWA_BrakeECU.md
```

BP2: Allocate software requirements to elements
```yaml
# Architecture allocation
BrakeManager_Component:
  allocated_requirements:
    - REQ-SWE-001: "Calculate brake pressure"
    - REQ-SWE-003: "Monitor brake temperature"
  interfaces:
    requires:
      - "SensorInterface::ReadPedalPosition"
      - "ActuatorInterface::SetPressure"
    provides:
      - "DiagnosticInterface::GetBrakeStatus"
  resources:
    cpu_usage_percent: 15
    ram_bytes: 2048
    rom_bytes: 8192
```

BP3: Define interfaces
```c
/**
 * Interface: SensorInterface
 * Description: Abstract interface for sensor data acquisition
 * Architecture: Service layer interface
 */
typedef struct {
    /**
     * Read pedal position
     * @return Pedal position in percent (0-100)
     * @error E_NOT_OK if sensor fault detected
     */
    Std_ReturnType (*ReadPedalPosition)(uint8* position);

    /**
     * Get sensor diagnostic status
     * @return Sensor status flags
     */
    uint8 (*GetDiagnosticStatus)(void);
} SensorInterface_t;
```

BP4: Describe dynamic behavior
```
State Machine: Brake Control

States:
- IDLE: Waiting for pedal input
- ACTIVE: Applying brake pressure
- FAULT: Sensor or actuator failure detected

Transitions:
IDLE → ACTIVE: pedal_position > 5%
ACTIVE → IDLE: pedal_position == 0%
* → FAULT: diagnostic_error == TRUE
FAULT → IDLE: error_cleared AND system_reset

Sequence Diagram: docs/architecture/sequences/brake_apply_sequence.puml
```

BP5: Define resource consumption
```c
/**
 * Component: BrakeManager
 * Resource Budget:
 *
 * Timing:
 *   - Task period: 10ms
 *   - WCET: 2.5ms (25% CPU utilization on 100MHz ARM Cortex-M4)
 *
 * Memory:
 *   - ROM: 8192 bytes (code + constants)
 *   - RAM: 2048 bytes (512 stack + 1536 data)
 *   - NVM: 128 bytes (calibration parameters)
 *
 * Interfaces:
 *   - CAN: 1 transmitted message (ID 0x200, 10ms cycle)
 *            2 received messages (ID 0x100, 0x101)
 *   - ADC: 1 channel (12-bit, 1ms sample time)
 */
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 13-01 | Software Architectural Design |
| 13-02 | Interface Specification |
| 13-04-01 | Software Requirements allocated to elements |
| 13-22 | Traceability Record (Requirements to Architecture) |

### SWE.3: Software Detailed Design

**Purpose**: Provide design for software units that implements software requirements.

#### Base Practices

BP1: Develop detailed design for units
```c
/**
 * Unit: BrakePressureCalculator
 * File: brake_pressure_calc.c
 *
 * Design Pattern: Defensive programming with saturation
 *
 * Inputs:
 *   - pedal_position: uint8 (0-100%)
 *   - vehicle_speed: uint16 (0-300 km/h)
 *
 * Outputs:
 *   - brake_pressure: uint16 (0-200 bar)
 *
 * Algorithm:
 *   1. Validate pedal_position range (0-100)
 *   2. Apply scaling factor: pressure = pedal_position * 2.0
 *   3. Apply speed-dependent limiting (prevent wheel lock at high speed)
 *   4. Saturate output to hardware limit (200 bar)
 *
 * Complexity: Cyclomatic complexity = 4 (within limit of 10)
 * MISRA compliance: 100% (no deviations)
 */

uint16 CalculateBrakePressure(uint8 pedal_position, uint16 vehicle_speed) {
    uint16 pressure;

    // Input validation (defensive programming)
    if (pedal_position > 100U) {
        DEM_ReportError(DTC_INVALID_PEDAL_POSITION);
        pedal_position = 100U;  // Saturate
    }

    // Base calculation
    pressure = (uint16)pedal_position * 2U;

    // Speed-dependent limiting (prevents wheel lock)
    if (vehicle_speed > 80U) {  // Above 80 km/h
        uint16 max_pressure = CalculateMaxPressureForSpeed(vehicle_speed);
        if (pressure > max_pressure) {
            pressure = max_pressure;
        }
    }

    return pressure;
}
```

BP2: Define interfaces of software units
```c
/**
 * Module: brake_pressure_calc
 * Public Interface (declared in brake_pressure_calc.h):
 */

// Public API
extern uint16 CalculateBrakePressure(uint8 pedal_position, uint16 vehicle_speed);
extern void BrakePressureCalc_Init(void);

/**
 * Module: brake_pressure_calc
 * Private Interface (static functions in .c file):
 */

// Private helper functions
static uint16 CalculateMaxPressureForSpeed(uint16 vehicle_speed);
static bool ValidatePedalPlausibility(uint8 pedal_position, uint16 vehicle_speed);
```

BP3: Describe dynamic behavior
```c
/**
 * Function: BrakeControlStateMachine
 * Implements: REQ-SWE-010 (Brake control state management)
 *
 * States: IDLE, APPLYING, HOLDING, RELEASING, FAULT
 *
 * Flowchart: See docs/detailed_design/brake_state_machine.png
 */

typedef enum {
    BRAKE_STATE_IDLE,
    BRAKE_STATE_APPLYING,
    BRAKE_STATE_HOLDING,
    BRAKE_STATE_RELEASING,
    BRAKE_STATE_FAULT
} BrakeState_t;

static BrakeState_t current_state = BRAKE_STATE_IDLE;

void BrakeControlStateMachine(void) {
    switch (current_state) {
        case BRAKE_STATE_IDLE:
            if (pedal_position > PEDAL_THRESHOLD) {
                current_state = BRAKE_STATE_APPLYING;
                StartPressureIncrease();
            }
            break;

        case BRAKE_STATE_APPLYING:
            if (measured_pressure >= target_pressure) {
                current_state = BRAKE_STATE_HOLDING;
            } else if (IsFaultDetected()) {
                current_state = BRAKE_STATE_FAULT;
            }
            break;

        // ... other states
    }
}
```

BP4: Define resource consumption
```c
/**
 * Function: CalculateBrakePressure
 *
 * Stack usage: 32 bytes
 *   - Local variables: 16 bytes
 *   - Function call depth: 2 levels × 8 bytes
 *
 * Execution time (100MHz ARM Cortex-M4):
 *   - Best case: 120 cycles (1.2 µs)
 *   - Worst case: 450 cycles (4.5 µs)
 *   - Average: 280 cycles (2.8 µs)
 *
 * Measured with: ARM Keil µVision profiler
 */
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 13-03 | Software Detailed Design Specification |
| 13-04-02 | Requirements allocated to software units |
| 13-22 | Traceability Record |

### SWE.4: Software Unit Verification

**Purpose**: Verify software units to ensure they meet design and requirements.

#### Base Practices

BP1: Develop unit verification strategy
```yaml
# test_strategy.yaml
unit_test_approach:
  framework: "Google Test + Google Mock"
  coverage_target: "100% statement coverage for ASIL-D code"
  automation: "Run on every commit (CI pipeline)"

test_types:
  - type: "Functional tests"
    description: "Verify correct behavior per requirements"
  - type: "Boundary tests"
    description: "Test edge cases and limits"
  - type: "Error handling tests"
    description: "Verify error detection and recovery"
  - type: "Resource tests"
    description: "Verify no memory leaks, stack overflow"
```

BP2: Develop unit tests
```cpp
/**
 * Test Suite: BrakePressureCalculator
 * Requirements Verified: REQ-SWE-001, REQ-SWE-002
 */

class BrakePressureTest : public ::testing::Test {
protected:
    void SetUp() override {
        BrakePressureCalc_Init();
    }
};

// Test: REQ-SWE-001 - Proportional calculation
TEST_F(BrakePressureTest, ProportionalCalculation) {
    EXPECT_EQ(CalculateBrakePressure(0, 50), 0);
    EXPECT_EQ(CalculateBrakePressure(50, 50), 100);
    EXPECT_EQ(CalculateBrakePressure(100, 50), 200);
}

// Test: REQ-SWE-002 - Input validation
TEST_F(BrakePressureTest, InputValidation_OutOfRange) {
    // Pedal position > 100 should saturate
    uint16 pressure = CalculateBrakePressure(150, 50);
    EXPECT_EQ(pressure, 200);  // Saturated to max
}

// Test: Boundary conditions
TEST_F(BrakePressureTest, BoundaryConditions) {
    EXPECT_EQ(CalculateBrakePressure(0, 0), 0);      // Min pedal, min speed
    EXPECT_EQ(CalculateBrakePressure(100, 300), 120); // Max pedal, max speed (limited)
}

// Test: Error injection
TEST_F(BrakePressureTest, SensorFaultHandling) {
    InjectSensorFault(FAULT_PEDAL_SENSOR);
    uint16 pressure = CalculateBrakePressure(50, 50);
    EXPECT_EQ(pressure, 0);  // Fail-safe to zero pressure
    EXPECT_TRUE(IsDiagnosticCodeSet(DTC_PEDAL_SENSOR_FAULT));
}
```

BP3: Test software units
```bash
#!/bin/bash
# run_unit_tests.sh - Execute unit tests with coverage

# Build tests
mkdir -p build/test
cd build/test
cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON ../..
make -j8

# Run tests
./brake_ecu_tests --gtest_output=xml:test_results.xml

# Generate coverage report
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '/usr/*' --output-file coverage.info  # Remove system files
lcov --list coverage.info  # Display summary

# Check coverage threshold (ASPICE Level 2 requirement)
coverage_percent=$(lcov --summary coverage.info | grep lines | awk '{print $2}' | tr -d '%')
if (( $(echo "$coverage_percent < 80" | bc -l) )); then
    echo "ERROR: Coverage $coverage_percent% below 80% threshold"
    exit 1
fi

echo "Unit tests passed with $coverage_percent% coverage"
```

BP4: Achieve bidirectional traceability
```yaml
# Traceability: Test to Requirement
TC-SWE-001:
  description: "Unit test: Proportional calculation"
  verifies: REQ-SWE-001
  test_file: "test/test_brake_pressure.cpp"
  test_function: "BrakePressureTest.ProportionalCalculation"
  last_run: "2024-03-15 14:32:00"
  result: PASS

# Reverse traceability: Requirement to Test
REQ-SWE-001:
  verified_by:
    - TC-SWE-001: "Unit test: Proportional calculation"
    - TC-INT-010: "Integration test: Brake pedal to pressure"
  coverage: "100% statement, 100% branch"
```

BP5: Summarize and communicate results
```markdown
# Unit Test Report - Brake ECU
Date: 2024-03-15
Build: v2.3.0-rc1

## Summary
- Total test cases: 145
- Passed: 145
- Failed: 0
- Coverage: 94.2% statement, 91.8% branch

## Coverage by Module
| Module              | Statement | Branch | MC/DC |
|---------------------|-----------|--------|-------|
| brake_pressure_calc | 100%      | 100%   | 100%  |
| brake_state_mgr     | 98.5%     | 95.2%  | 93.1% |
| diagnostics         | 87.3%     | 85.6%  | N/A   |

## Action Items
- [ ] Increase branch coverage in brake_state_mgr to 100%
- [ ] Add MC/DC coverage measurement for diagnostics module
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 13-19 | Software Unit Test Specification |
| 13-20 | Software Unit Test Report |
| 13-22 | Traceability Record (Test to Requirement) |

### SWE.5: Software Integration and Integration Test

**Purpose**: Integrate software units and test the integrated software.

#### Base Practices

BP1: Develop integration strategy
```yaml
# integration_strategy.yaml
approach: "Bottom-up integration with continuous integration"

integration_stages:
  stage_1:
    name: "Driver layer integration"
    components: ["CAN_Driver", "ADC_Driver", "PWM_Driver"]
    test_environment: "Hardware-in-loop (HIL) testbench"

  stage_2:
    name: "Service layer integration"
    components: ["SensorInterface", "ActuatorInterface", "DiagnosticService"]
    dependencies: ["stage_1"]

  stage_3:
    name: "Application layer integration"
    components: ["BrakeManager", "DiagnosticManager"]
    dependencies: ["stage_2"]

  stage_4:
    name: "System integration"
    description: "Full ECU software with AUTOSAR RTE"
    dependencies: ["stage_1", "stage_2", "stage_3"]
```

BP2: Develop integration test cases
```cpp
/**
 * Integration Test: Pedal to Pressure End-to-End
 * Verifies: REQ-SWE-001, REQ-SWE-005, REQ-INT-010
 * Integration Scope: ADC_Driver → SensorInterface → BrakeManager → ActuatorInterface → PWM_Driver
 */

TEST(BrakeIntegration, PedalToPressureEndToEnd) {
    // Setup: Initialize all layers
    ADC_Init(&adc_config);
    SensorInterface_Init();
    BrakeManager_Init();
    ActuatorInterface_Init();
    PWM_Init(&pwm_config);

    // Stimulate: Simulate pedal input (50% position)
    SimulatePedalVoltage(2.5);  // 2.5V = 50% pedal

    // Wait for processing (worst-case timing)
    Delay_ms(20);

    // Verify: Check actuator output
    uint16 pwm_duty = PWM_GetDutyCycle(PWM_CHANNEL_BRAKE);
    EXPECT_NEAR(pwm_duty, 5000, 100);  // 50% duty ± 2%

    // Verify: Check CAN message transmission
    CanMessage_t tx_msg;
    ASSERT_TRUE(Can_GetTransmittedMessage(0x200, &tx_msg));
    uint16 reported_pressure = (tx_msg.data[0] << 8) | tx_msg.data[1];
    EXPECT_EQ(reported_pressure, 100);  // 50% pedal = 100 bar
}
```

BP3: Integrate software units
```c
/**
 * Integration Build Configuration
 * File: integration_build.cmake
 */

# Stage 3: Application layer integration
add_executable(brake_ecu_stage3
    # Application components
    src/brake_manager.c
    src/diagnostic_manager.c

    # Service layer (integrated in stage 2)
    src/sensor_interface.c
    src/actuator_interface.c
    src/diagnostic_service.c

    # Driver layer (integrated in stage 1)
    src/can_driver.c
    src/adc_driver.c
    src/pwm_driver.c

    # AUTOSAR RTE (generated)
    generated/Rte.c
)

# Link integration test framework
target_link_libraries(brake_ecu_stage3
    gtest
    gmock
    can_simulator
    hil_interface
)
```

BP4: Test integrated software units
```bash
#!/bin/bash
# run_integration_tests.sh

# Start HIL simulator
start_hil_simulator &
HIL_PID=$!

# Wait for simulator ready
sleep 2

# Run integration tests
./build/integration_tests \
    --hil-connection=tcp://localhost:5555 \
    --test-duration=600 \
    --output=integration_report.xml

# Stop simulator
kill $HIL_PID

# Parse results
python scripts/parse_integration_results.py integration_report.xml
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 13-06 | Software Integration Strategy |
| 13-21 | Software Integration Test Specification |
| 13-19 | Software Integration Test Report |
| 17-08 | Integrated Software |

### SWE.6: Software Qualification Test

**Purpose**: Test integrated software against software requirements.

#### Base Practices

BP1: Develop software qualification test strategy
```yaml
# qualification_test_strategy.yaml
purpose: "Verify integrated software meets all software requirements"

test_environment: "Production-equivalent ECU hardware with HIL system"

test_types:
  functional_tests:
    description: "Verify functional requirements"
    count: 250
    coverage_target: "100% of functional requirements"

  performance_tests:
    description: "Verify timing and resource requirements"
    metrics: ["Response time", "CPU utilization", "Memory usage"]

  robustness_tests:
    description: "Verify error handling and recovery"
    scenarios: ["Sensor faults", "Actuator faults", "Communication loss"]

  safety_tests:
    description: "Verify safety requirements (ASIL-D)"
    requirements: ["Plausibility checks", "Fail-safe behavior", "Diagnostics"]

acceptance_criteria:
  - "100% of safety requirements verified"
  - "95% of functional requirements passed"
  - "No critical or high severity defects open"
```

BP2: Develop qualification test cases
```yaml
# Test Case: Brake pressure control under normal conditions
TC-QUAL-001:
  title: "Brake pressure proportional to pedal under normal conditions"
  requirements: [REQ-SWE-001, REQ-SWE-002]
  preconditions:
    - "Vehicle speed: 50 km/h"
    - "All sensors functional"
    - "No diagnostic faults"
  test_steps:
    - step: "Apply 0% pedal position"
      expected: "Brake pressure = 0 bar ± 2 bar"
    - step: "Apply 25% pedal position"
      expected: "Brake pressure = 50 bar ± 2 bar"
    - step: "Apply 50% pedal position"
      expected: "Brake pressure = 100 bar ± 2 bar"
    - step: "Apply 100% pedal position"
      expected: "Brake pressure = 200 bar ± 2 bar"
  pass_criteria: "All steps pass with pressure within tolerance"
```

BP3: Test software against requirements
```python
# Automated qualification test execution
import hil_interface
import test_case_loader

def run_qualification_tests():
    hil = hil_interface.connect("tcp://hil-system:5555")
    test_suite = test_case_loader.load("qualification_test_suite.yaml")

    results = []
    for test_case in test_suite:
        # Setup preconditions
        hil.set_vehicle_speed(test_case.preconditions.vehicle_speed)
        hil.reset_faults()

        # Execute test steps
        for step in test_case.steps:
            hil.set_pedal_position(step.pedal_position)
            time.sleep(0.1)  # Allow system to stabilize

            actual_pressure = hil.read_brake_pressure()
            expected_pressure = step.expected_pressure
            tolerance = step.tolerance

            passed = abs(actual_pressure - expected_pressure) <= tolerance
            results.append({
                "test_case": test_case.id,
                "step": step.number,
                "expected": expected_pressure,
                "actual": actual_pressure,
                "passed": passed
            })

    generate_report(results)
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 13-09 | Software Qualification Test Specification |
| 13-23 | Software Qualification Test Report |
| 13-22 | Traceability Record (Requirements to Test) |

### SUP.8: Configuration Management

**Purpose**: Establish and maintain integrity of work products.

#### Base Practices

BP1: Develop configuration management strategy
```markdown
# Configuration Management Plan

## Version Control
- Tool: Git + GitLab
- Branch strategy: GitFlow (main, develop, feature/*, release/*, hotfix/*)
- Commit message format: "<type>(<scope>): <description>"

## Baseline Management
- Baseline types: Requirements, Design, Code, Test
- Baseline frequency: End of each sprint, before release
- Baseline approval: Requires review + CI pass + PM approval

## Change Control
- Change request process: Via Jira tickets
- Impact analysis required for safety-critical changes
- CCB (Change Control Board) for ASIL C/D changes
```

BP2: Identify configuration items
```yaml
# Configuration items for Brake ECU project
configuration_items:
  requirements:
    - SRS_BrakeECU_v2.3.docx
    - requirements.yaml

  design:
    - SWA_BrakeECU_v2.3.md
    - detailed_design/*.puml

  source_code:
    - src/**/*.c
    - src/**/*.h
    - CMakeLists.txt

  configuration:
    - config/**/*.arxml
    - config/brake_ecu_config.yaml

  tests:
    - test/**/*.cpp
    - test_specs/**/*.yaml

  build_artifacts:
    - brake_ecu.elf
    - brake_ecu.hex
```

BP3: Establish baselines
```bash
# Create baseline (release tag)
git tag -a v2.3.0 -m "Release 2.3.0 - Baseline for SOP"
git push origin v2.3.0

# Baseline metadata
cat > baseline_v2.3.0.yaml <<EOF
baseline_id: BL-2024-003
version: v2.3.0
date: 2024-03-15
approved_by: John Smith (Project Manager)

included_items:
  requirements: REQ-SWE v2.3
  architecture: SWA-BRK v2.3
  source_code: commit a3f5d2c
  test_specs: TS-QUAL v2.3

verification_status:
  unit_tests: PASSED (145/145)
  integration_tests: PASSED (89/89)
  qualification_tests: PASSED (250/252, 2 deviations approved)
EOF
```

BP4: Control modifications
```yaml
# Change Request: CR-2024-042
change_id: CR-2024-042
title: "Update brake pressure scaling factor"
type: enhancement
priority: medium
affected_baseline: v2.3.0

impact_analysis:
  requirements: [REQ-SWE-001]  # Modified
  design: []                    # No change
  source_code: [src/brake_pressure_calc.c]
  tests: [TC-SWE-001, TC-QUAL-001]  # Updated

safety_impact: LOW (QM component, verified by test)

approval:
  - reviewer: Jane Doe (Technical Lead) - APPROVED
  - reviewer: Bob Johnson (Safety Engineer) - APPROVED
  - approver: John Smith (Project Manager) - APPROVED

implementation:
  branch: feature/CR-2024-042-update-brake-scaling
  commits: [e7a3b21, f9c4d33]
  merged_to_develop: 2024-03-16
  target_release: v2.4.0
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 15-01 | Configuration Management Strategy |
| 15-02 | Configuration Item List |
| 15-03 | Configuration Status Account (baselines, changes) |
| 15-04 | Configuration Audit Records |

### MAN.3: Project Management

**Purpose**: Identify, establish, and control activities to achieve project objectives.

#### Base Practices

BP1: Define scope of work
```yaml
# Project Charter: Brake ECU Software Development
project_name: "Advanced Brake Control ECU Software"
project_id: PROJ-2024-BRK-001
start_date: 2024-01-15
target_completion: 2024-09-30

scope:
  in_scope:
    - "Brake pressure calculation and control"
    - "ABS (Anti-lock Braking System) logic"
    - "Diagnostics and fault management"
    - "CAN communication interface"

  out_of_scope:
    - "Electronic Stability Control (ESC)" # Future phase
    - "Hill Hold Assist" # Separate project
    - "Hardware development" # Separate team

deliverables:
  - "Software Requirements Specification (SRS)"
  - "Software Architecture Document (SAD)"
  - "Source code (C, MISRA compliant)"
  - "Unit test suite (Google Test)"
  - "Integration test suite (HIL)"
  - "Qualification test report"
```

BP2: Define project life cycle
```
Phase 1: Requirements Analysis (6 weeks)
  - Analyze system requirements
  - Derive software requirements
  - Define verification criteria
  Deliverables: SRS v1.0

Phase 2: Architecture Design (4 weeks)
  - Design software architecture
  - Define interfaces
  - Allocate requirements
  Deliverables: SAD v1.0

Phase 3: Detailed Design & Implementation (12 weeks)
  - Detailed unit design
  - Code implementation
  - Unit testing (ongoing)
  Deliverables: Source code, Unit test report

Phase 4: Integration & Test (8 weeks)
  - Software integration
  - Integration testing
  - Qualification testing
  Deliverables: Integrated software, Test reports

Phase 5: Release & Deployment (2 weeks)
  - Final verification
  - Documentation completion
  - Software release
  Deliverables: Release package
```

BP3: Evaluate feasibility
```markdown
# Feasibility Assessment

## Technical Feasibility
- Technology: AUTOSAR Classic Platform R21-11 ✓
- Hardware: NXP S32K144 (ARM Cortex-M4) ✓
- Tools: Vector DaVinci Configurator, GCC ARM ✓
- Team skills: 3 AUTOSAR experts, 2 junior developers ✓

## Schedule Feasibility
- Duration: 32 weeks
- Critical path: Requirements → Design → Implementation → Integration
- Risk: Integration phase tight (mitigate with early integration)

## Resource Feasibility
- Team: 5 developers, 1 tester, 1 architect
- Budget: $500k (within allocation)
- Equipment: 2 HIL systems, 10 ECU prototypes (available)

## Recommendation: PROCEED with noted risks
```

#### Work Products

| Work Product | Description |
|--------------|-------------|
| 17-00 | Project Plan |
| 17-01 | Work Breakdown Structure (WBS) |
| 17-02 | Project Schedule (Gantt chart) |
| 17-06 | Risk Management Plan |
| 17-09 | Project Status Reports |

## Traceability Requirements

Bidirectional traceability required throughout lifecycle:

```
System Requirements
        ↓ ↑
Software Requirements (SWE.1)
        ↓ ↑
Architecture Elements (SWE.2)
        ↓ ↑
Software Units (SWE.3)
        ↓ ↑
Test Cases (SWE.4, SWE.5, SWE.6)
```

### Traceability Tools

```bash
# Generate traceability report
python tools/generate_traceability_matrix.py \
    --requirements requirements.yaml \
    --design architecture/*.yaml \
    --source src/**/*.c \
    --tests test/**/*.cpp \
    --output traceability_matrix.xlsx
```

## Work Product Naming Conventions

```
Format: <Project>_<WorkProduct>_<Version>.ext

Examples:
- BrakeECU_SRS_v2.3.docx                # Requirements
- BrakeECU_SWA_v2.3.md                  # Architecture
- BrakeECU_UnitTestReport_v2.3.pdf      # Test report
- BrakeECU_IntegrationTestSpec_v2.2.xlsx # Test spec
- BrakeECU_ProjectPlan_v1.0.mpp         # Project plan
```

## Review Requirements

| Work Product Type | Review Type | Participants | Exit Criteria |
|------------------|-------------|--------------|---------------|
| Requirements | Formal review | Architect, Safety engineer, Customer | All issues resolved or tracked |
| Architecture | Formal review | Technical lead, Senior developers | Architecture approved |
| Detailed design | Peer review | 2 developers | No critical issues |
| Code | Peer review | 1 developer | MISRA clean, review checklist complete |
| Test specs | Formal review | Test engineer, Requirements owner | Requirements coverage 100% |

## References

- Automotive SPICE Process Assessment Model (PAM) v3.1
- Automotive SPICE Process Reference Model (PRM) v3.1
- VDA Scope for Automotive SPICE v3.2
- ISO/IEC 33001-33099: Software process assessment standards
