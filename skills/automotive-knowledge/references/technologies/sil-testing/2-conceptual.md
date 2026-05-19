# SIL Testing - Conceptual Architecture

## MIL vs. SIL vs. PIL Detailed Comparison

### Execution Flow Comparison

**MIL (Model-in-the-Loop)**:
```
MATLAB Workspace
    ↓
Simulink Model (.slx)
    ↓ Interpreted execution
MATLAB Engine
    ↓ Results
Test Script (MATLAB)
```

**SIL (Software-in-the-Loop)**:
```
MATLAB Workspace
    ↓
Simulink Model (.slx)
    ↓ Code generation (Embedded Coder)
C/C++ Code (.c, .h)
    ↓ Compile for PC (gcc x86)
Shared Library (.dll, .so)
    ↓ Load and execute
Test Harness (MATLAB, Python, C++)
    ↓ Results
Comparison with MIL
```

**PIL (Processor-in-the-Loop)**:
```
MATLAB Workspace
    ↓
Simulink Model (.slx)
    ↓ Code generation
C/C++ Code
    ↓ Cross-compile (arm-none-eabi-gcc)
Target Binary (.elf)
    ↓ Flash to MCU via JTAG
Target Microcontroller (ARM Cortex-M)
    ↓ Execute and return results
Test Harness (MATLAB)
```

### Fidelity vs. Speed Tradeoff

```
High Fidelity (Accurate)
    ↑
PIL │ Real HW, real compiler
    │ Slow (real-time execution)
    │
SIL │ Real code, PC compiler
    │ Fast (faster-than-real-time)
    │
MIL │ Model only (no code)
    │ Very fast
    ↓
Low Fidelity (Approximation)
```

## SIL Architecture Variants

### Variant 1: Simulink SIL (MATLAB-Based)

**Architecture**:
```
MATLAB Test Script
    ↓ sim() call
Simulink Model (SIL Mode)
    ├── C Code Block (compiled .dll)
    └── Plant Model (Simulink blocks)
    ↓ Results
MATLAB Workspace (assertions, plots)
```

**Use Case**: Model-based development, verify code generation

**Pros**:
- Integrated workflow (model → code → test in MATLAB)
- Automatic comparison with MIL

**Cons**:
- Requires MATLAB license
- Simulink overhead (slower than pure C++ test)

### Variant 2: Standalone SIL (Python/C++ Test Harness)

**Architecture**:
```
Python/C++ Test Framework
    ↓ Call via ctypes/DLL
C Code (compiled .so/.dll)
    ↓ Function calls
Plant Model (C++ library or Python)
    ↓ Assertions
Test Report (JUnit XML, HTML)
```

**Use Case**: CI/CD integration, non-Simulink projects

**Pros**:
- No MATLAB license required
- Fast execution (native C++)
- Easy CI/CD integration (Jenkins, GitLab)

**Cons**:
- Manual setup (build system, test harness)

### Variant 3: CANoe SIL (Bus Simulation)

**Architecture**:
```
CANoe Environment
    ├── Virtual ECU (C code .dll)
    ├── CAPL Scripts (test logic)
    ├── CAN Bus Simulation (virtual CAN database)
    └── Environment Models (other ECUs)
    ↓ Results
CANoe Test Report
```

**Use Case**: Network testing (CAN, LIN, Ethernet)

**Pros**:
- Realistic bus simulation
- Test CAN communication logic

**Cons**:
- Expensive (CANoe license)
- Automotive-specific (not general-purpose)

## Test Harness Design

### Components of Test Harness

**Stimulus Generation**:
- Input signals (sensor values, CAN messages)
- Scenarios (steady-state, ramps, steps)
- Fault injection (out-of-range, missing data)

**Software Under Test (SUT) Interface**:
- Function calls (call C functions from test)
- Data exchange (inputs → SUT → outputs)
- State management (reset between tests)

**Oracle (Expected Results)**:
- Golden data (reference outputs from MIL or manual calculation)
- Tolerance checking (floating-point comparison)
- Assertions (pass/fail criteria)

**Results Logging**:
- Test pass/fail status
- Actual vs. expected values
- Coverage metrics

### Test Harness Example (Google Test)

```cpp
// test_pid_controller.cpp
#include <gtest/gtest.h>
extern "C" {
    #include "pid_controller.h"
}

class PidControllerTest : public ::testing::Test {
protected:
    void SetUp() override {
        pid_init(1.0, 0.1, 0.01);  // Kp, Ki, Kd
    }
    
    void TearDown() override {
        pid_reset();
    }
};

TEST_F(PidControllerTest, StepResponse) {
    double setpoint = 100.0;
    double measurement = 0.0;
    double output;
    
    // Simulate 100 timesteps
    for (int i = 0; i < 100; i++) {
        output = pid_step(setpoint, measurement);
        measurement += output * 0.1;  // Simple plant model
    }
    
    // Check steady-state error < 1%
    EXPECT_NEAR(measurement, setpoint, 1.0);
}

TEST_F(PidControllerTest, OvershootLimit) {
    double setpoint = 100.0;
    double measurement = 0.0;
    double max_value = 0.0;
    
    for (int i = 0; i < 100; i++) {
        double output = pid_step(setpoint, measurement);
        measurement += output * 0.1;
        max_value = std::max(max_value, measurement);
    }
    
    // Check overshoot < 20%
    EXPECT_LT(max_value, setpoint * 1.20);
}
```

## Coverage Measurement Strategies

### Statement Coverage

**Definition**: Every line of code executed at least once.

**Example**:
```c
int abs(int x) {
    if (x < 0) {       // Line 1
        return -x;     // Line 2
    }
    return x;          // Line 3
}

// Test Case 1: abs(-5) → executes lines 1, 2
// Test Case 2: abs(5) → executes lines 1, 3
// Statement coverage: 100% (all lines executed)
```

**Target**: ISO 26262 ASIL A/B requires 100%

### Branch Coverage

**Definition**: Every decision (if/else) takes both true and false.

**Example**:
```c
int divide(int a, int b) {
    if (b == 0) {      // Branch 1
        return 0;      // Branch 1: True
    }
    return a / b;      // Branch 1: False
}

// Test Case 1: divide(10, 0) → Branch True
// Test Case 2: divide(10, 2) → Branch False
// Branch coverage: 100% (both true and false tested)
```

**Target**: ISO 26262 ASIL C/D requires 100%

### MC/DC Coverage (Modified Condition/Decision Coverage)

**Definition**: Each condition independently affects the decision outcome.

**Example**:
```c
bool safety_check(bool sensor1_ok, bool sensor2_ok) {
    if (sensor1_ok && sensor2_ok) {  // Decision with 2 conditions
        return true;
    }
    return false;
}

// MC/DC Test Cases:
// TC1: sensor1=F, sensor2=F → F (baseline)
// TC2: sensor1=T, sensor2=F → F (sensor1 changes, outcome same)
// TC3: sensor1=F, sensor2=T → F (sensor2 changes, outcome same)
// TC4: sensor1=T, sensor2=T → T (both change, outcome changes)

// Minimal MC/DC set (sensor1 independent effect):
// TC1: sensor1=F, sensor2=T → F
// TC4: sensor1=T, sensor2=T → T
// (Only sensor1 changed, outcome changed)

// Minimal MC/DC set (sensor2 independent effect):
// TC3: sensor1=T, sensor2=F → F
// TC4: sensor1=T, sensor2=T → T
// (Only sensor2 changed, outcome changed)
```

**Target**: ISO 26262 ASIL D requires 100% MC/DC

### Coverage Tool Integration

**gcov (Free)**:
```bash
# Compile with coverage flags
gcc -fprofile-arcs -ftest-coverage -o sut.o -c sut.c

# Link and run test
g++ -o test test.cpp sut.o -lgtest --coverage
./test

# Generate coverage report
gcov sut.c
cat sut.c.gcov  # View line-by-line coverage
```

**BullseyeCoverage (Commercial)**:
```bash
# Instrument code
cov01 -1
gcc -o sut.o -c sut.c
cov01 -0

# Run test
./test

# Generate report (HTML with MC/DC)
covhtml --file coverage.cov
```

## CI/CD Integration Patterns

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'make clean'
                sh 'make sil_test'
            }
        }
        stage('Test') {
            steps {
                sh './sil_test --gtest_output=xml:test_results.xml'
            }
        }
        stage('Coverage') {
            steps {
                sh 'gcov *.c'
                sh 'lcov --capture --directory . --output-file coverage.info'
                sh 'genhtml coverage.info --output-directory coverage'
            }
        }
        stage('Publish') {
            steps {
                junit 'test_results.xml'
                publishHTML(target: [
                    reportDir: 'coverage',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
    }
}
```

### GitLab CI Pipeline

```yaml
stages:
  - build
  - test
  - coverage

build_sil:
  stage: build
  script:
    - mkdir build && cd build
    - cmake .. -DCMAKE_BUILD_TYPE=Debug -DCOVERAGE=ON
    - make
  artifacts:
    paths:
      - build/

run_tests:
  stage: test
  dependencies:
    - build_sil
  script:
    - cd build
    - ./sil_test --gtest_output=xml:../test_results.xml
  artifacts:
    reports:
      junit: test_results.xml

generate_coverage:
  stage: coverage
  dependencies:
    - build_sil
    - run_tests
  script:
    - cd build
    - gcov CMakeFiles/sil_test.dir/*.gcda
    - lcov --capture --directory . --output-file coverage.info
    - genhtml coverage.info --output-directory ../coverage
  coverage: '/lines......: \d+\.\d+%/'
  artifacts:
    paths:
      - coverage/
```

## Next Steps

- **Level 3**: Detailed CANoe SIL setup, Python ctypes examples, Google Test
- **Level 4**: Test templates, coverage commands, CI/CD configs
- **Level 5**: Fuzzing, mutation testing, formal verification

## References

- ISO 26262-6:2018 Table 13 (Coverage metrics)
- Google Test Documentation
- gcov User Manual

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Test engineers, software architects
