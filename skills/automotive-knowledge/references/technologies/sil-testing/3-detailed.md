# SIL Testing - Detailed Implementation Guide

## CANoe SIL Setup

### Prerequisites

- Vector CANoe version 11+
- CANoe Option .NET (for C# scripting)
- Visual Studio (C++ compiler for building SIL DLL)

### Step 1: Prepare Software Under Test

**Compile as DLL**:
```c
// ecu_controller.c
#include "ecu_controller.h"

static double vehicle_speed_kph = 0.0;

void ECU_Initialize(void) {
    vehicle_speed_kph = 0.0;
}

void ECU_Step(const ECU_Inputs* inputs, ECU_Outputs* outputs) {
    // Simple cruise control logic
    double error = inputs->target_speed - vehicle_speed_kph;
    outputs->throttle_pct = error * 2.0;  // P controller
    
    // Clamp throttle
    if (outputs->throttle_pct < 0) outputs->throttle_pct = 0;
    if (outputs->throttle_pct > 100) outputs->throttle_pct = 100;
    
    // Update vehicle speed (simple integration)
    vehicle_speed_kph += outputs->throttle_pct * 0.01;
}
```

**Build Script** (MSVC):
```batch
REM build_sil_dll.bat
cl /LD /Feecu_controller.dll ecu_controller.c
```

### Step 2: Create CANoe Configuration

**CANoe Configuration (.cfg)**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<CANoeConfiguration>
  <Networks>
    <CAN name="PowertrainCAN" baudrate="500000" />
  </Networks>
  
  <Nodes>
    <Node name="ECU_SIL" type="SIL">
      <DLL>ecu_controller.dll</DLL>
      <InitFunction>ECU_Initialize</InitFunction>
      <StepFunction>ECU_Step</StepFunction>
      <CyclicTime>10ms</CyclicTime>
    </Node>
  </Nodes>
</CANoeConfiguration>
```

### Step 3: CAPL Test Script

```c
// test_cruise_control.can
includes {
  #include "ecu_controller.h"
}

variables {
  msTimer testTimer;
  double target_speed = 100.0;  // km/h
}

on start {
  write("Starting Cruise Control SIL Test");
  
  // Set target speed via CAN message
  message CruiseControlCommand msg;
  msg.TargetSpeed = target_speed;
  output(msg);
  
  // Start test timer (10 seconds)
  setTimer(testTimer, 10000);
}

on timer testTimer {
  // Check if speed reached target
  double current_speed = getValue("ECU_SIL", "vehicle_speed_kph");
  
  if (abs(current_speed - target_speed) < 2.0) {
    write("PASS: Speed reached target (%.1f km/h)", current_speed);
    testStepPass();
  } else {
    write("FAIL: Speed did not reach target (%.1f km/h, expected %.1f)", 
          current_speed, target_speed);
    testStepFail();
  }
  
  stop();
}
```

### Step 4: Run Test

```
CANoe GUI:
1. Open configuration: File → Open → cruise_control_sil.cfg
2. Start measurement: F9
3. View test results: Test Feature Set → Test Report
```

## Python ctypes SIL Testing

### Step 1: Compile C Code as Shared Library

```c
// pid_controller.c
typedef struct {
    double kp, ki, kd;
    double integral;
    double prev_error;
} PID_State;

static PID_State pid;

void pid_init(double kp, double ki, double kd) {
    pid.kp = kp;
    pid.ki = ki;
    pid.kd = kd;
    pid.integral = 0.0;
    pid.prev_error = 0.0;
}

double pid_step(double setpoint, double measurement) {
    double error = setpoint - measurement;
    pid.integral += error;
    double derivative = error - pid.prev_error;
    pid.prev_error = error;
    
    return pid.kp * error + pid.ki * pid.integral + pid.kd * derivative;
}
```

**Build**:
```bash
# Linux
gcc -shared -fPIC -o pid_controller.so pid_controller.c

# Windows (MinGW)
gcc -shared -o pid_controller.dll pid_controller.c
```

### Step 2: Python Test Script

```python
import ctypes
import numpy as np
import matplotlib.pyplot as plt

# Load shared library
lib = ctypes.CDLL('./pid_controller.so')

# Define function signatures
lib.pid_init.argtypes = [ctypes.c_double, ctypes.c_double, ctypes.c_double]
lib.pid_init.restype = None

lib.pid_step.argtypes = [ctypes.c_double, ctypes.c_double]
lib.pid_step.restype = ctypes.c_double

# Initialize PID
lib.pid_init(1.0, 0.1, 0.01)

# Test: Step response
setpoint = 100.0
measurement = 0.0
time_steps = 200
dt = 0.01

time_data = []
measurement_data = []
output_data = []

for i in range(time_steps):
    # Call PID controller
    output = lib.pid_step(setpoint, measurement)
    
    # Simple plant model: first-order system
    measurement += (output - measurement) * 0.1 * dt
    
    # Log data
    time_data.append(i * dt)
    measurement_data.append(measurement)
    output_data.append(output)

# Verify results
final_error = abs(measurement - setpoint)
assert final_error < 1.0, f"Final error {final_error} exceeds tolerance"

# Plot results
plt.figure()
plt.plot(time_data, measurement_data, label='Measurement')
plt.axhline(y=setpoint, color='r', linestyle='--', label='Setpoint')
plt.xlabel('Time (s)')
plt.ylabel('Value')
plt.title('PID Step Response')
plt.legend()
plt.grid()
plt.savefig('pid_response.png')
print("PASS: PID step response test")
```

## Google Test with Coverage

### Project Structure

```
sil_test_project/
├── src/
│   ├── cruise_control.c
│   └── cruise_control.h
├── test/
│   ├── test_cruise_control.cpp
│   └── CMakeLists.txt
├── CMakeLists.txt
└── README.md
```

### CMakeLists.txt (Root)

```cmake
cmake_minimum_required(VERSION 3.10)
project(SIL_Test)

set(CMAKE_CXX_STANDARD 11)

# Enable coverage
option(COVERAGE "Enable coverage reporting" OFF)
if(COVERAGE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif()

# Add source library
add_library(cruise_control STATIC src/cruise_control.c)
target_include_directories(cruise_control PUBLIC src)

# Add tests
enable_testing()
add_subdirectory(test)
```

### test/CMakeLists.txt

```cmake
# Download Google Test
include(FetchContent)
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/release-1.12.1.zip
)
FetchContent_MakeAvailable(googletest)

# Create test executable
add_executable(sil_test test_cruise_control.cpp)
target_link_libraries(sil_test cruise_control gtest_main)

# Register test
add_test(NAME SIL_Tests COMMAND sil_test)
```

### test/test_cruise_control.cpp

```cpp
#include <gtest/gtest.h>
extern "C" {
    #include "cruise_control.h"
}

class CruiseControlTest : public ::testing::Test {
protected:
    void SetUp() override {
        cc_init();
    }
};

TEST_F(CruiseControlTest, TargetSpeedReached) {
    cc_set_target_speed(100.0);
    
    double speed = 0.0;
    for (int i = 0; i < 500; i++) {
        double throttle = cc_step(speed);
        speed += throttle * 0.02;  // Simple plant
    }
    
    EXPECT_NEAR(speed, 100.0, 2.0);  // Within 2 km/h
}

TEST_F(CruiseControlTest, NoOvershoot) {
    cc_set_target_speed(100.0);
    
    double speed = 0.0;
    double max_speed = 0.0;
    
    for (int i = 0; i < 500; i++) {
        double throttle = cc_step(speed);
        speed += throttle * 0.02;
        max_speed = std::max(max_speed, speed);
    }
    
    EXPECT_LT(max_speed, 110.0);  // Max overshoot 10%
}

TEST_F(CruiseControlTest, ThrottleClamping) {
    cc_set_target_speed(200.0);  // Unrealistic high target
    
    double throttle = cc_step(0.0);
    EXPECT_GE(throttle, 0.0);
    EXPECT_LE(throttle, 100.0);
}
```

### Build and Run

```bash
# Configure with coverage
mkdir build && cd build
cmake .. -DCOVERAGE=ON

# Build
make

# Run tests
./test/sil_test

# Generate coverage report
gcov ../src/cruise_control.c
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html

# View report
firefox coverage_html/index.html
```

## vTESTstudio Test Automation

### Test Case in vTESTstudio

```
Test Case: TC_CC_001_StepResponse
Requirement: REQ-CC-042
ASIL: B

Preconditions:
  - SIL DLL loaded: cruise_control.dll
  - Initialization: cc_init() called

Test Steps:
  1. Set target speed to 100 km/h
     Command: cc_set_target_speed(100.0)
     Expected: Return value = 0 (success)

  2. Simulate 10 seconds (1000 cycles @ 10ms)
     Loop: 1000 iterations
       Command: throttle = cc_step(current_speed)
       Plant: current_speed += throttle * 0.02
       Log: time, speed, throttle

  3. Verify final speed
     Check: abs(current_speed - 100.0) < 2.0
     Expected: PASS

  4. Verify settling time
     Check: time_to_settle < 5.0 seconds
     Expected: PASS

Pass Criteria:
  - Final speed within ±2 km/h
  - Settling time < 5 seconds
  - No overshoot > 10%
```

### Python API (vTESTstudio)

```python
from vtestapi import VTestStudio

# Connect to vTESTstudio
vts = VTestStudio.connect()

# Load SIL configuration
vts.load_sil_dll("cruise_control.dll")

# Execute test case
result = vts.execute_test_case("TC_CC_001_StepResponse")

# Check result
if result.passed:
    print(f"PASS: {result.name}")
else:
    print(f"FAIL: {result.name} - {result.failure_reason}")

# Generate report
vts.generate_report("test_report.html")
```

## Next Steps

- **Level 4**: Test templates, coverage analysis, CI/CD examples
- **Level 5**: Fuzzing, mutation testing, formal verification

## References

- Vector CANoe User Manual (SIL Extension)
- Google Test Primer
- gcov Documentation

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Software test engineers, developers
