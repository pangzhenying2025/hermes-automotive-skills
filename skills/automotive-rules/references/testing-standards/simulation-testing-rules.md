# SIL/HIL/MIL Simulation Testing Rules

> Rules for Model-in-the-Loop, Software-in-the-Loop, Processor-in-the-Loop,
> and Hardware-in-the-Loop testing in automotive development, ensuring
> consistent test quality across simulation environments.

## Scope

These rules apply to all simulation-based testing in automotive software
development, from early algorithm validation through production ECU testing.

---

## Simulation Test Levels

### X-in-the-Loop Hierarchy

```
+-------------------------------------------------------------------+
|  MIL: Model-in-the-Loop                                          |
|  Environment: Simulink/Stateflow + Plant Model                    |
|  Purpose: Algorithm validation, early design verification          |
|  Fidelity: Functional behavior, ideal timing                      |
+-------------------------------------------------------------------+
         |
         v
+-------------------------------------------------------------------+
|  SIL: Software-in-the-Loop                                       |
|  Environment: Generated/Hand-coded C on Host PC + Plant Model     |
|  Purpose: Code verification, back-to-back with model              |
|  Fidelity: Functional + numerical precision, host timing          |
+-------------------------------------------------------------------+
         |
         v
+-------------------------------------------------------------------+
|  PIL: Processor-in-the-Loop                                       |
|  Environment: C code on Target MCU + Plant Model on Host          |
|  Purpose: Target compiler verification, fixed-point accuracy       |
|  Fidelity: Target arithmetic, approximate timing                   |
+-------------------------------------------------------------------+
         |
         v
+-------------------------------------------------------------------+
|  HIL: Hardware-in-the-Loop                                        |
|  Environment: Production ECU + Real-time Plant Simulator           |
|  Purpose: System validation, fault injection, timing verification  |
|  Fidelity: Full production behavior, real-time timing              |
+-------------------------------------------------------------------+
```

### When to Use Each Level

| Level | Stage | Cost | Speed | Fidelity | Repeatability |
|-------|-------|------|-------|----------|---------------|
| MIL | Concept/Design | Low | Very Fast | Low | High |
| SIL | SW Development | Low | Fast | Medium | High |
| PIL | SW Integration | Medium | Medium | High | High |
| HIL | System Test | High | Real-time | Very High | High |
| Vehicle | Validation | Very High | Real-time | Highest | Low |

---

## Model-in-the-Loop (MIL)

### MIL Test Rules

```yaml
mil_testing:
  purpose: "Validate algorithms against requirements before coding"

  plant_model_requirements:
    - "Document model accuracy and valid operating range"
    - "Model must include sensor noise characteristics"
    - "Model must include actuator dynamics and delays"
    - "Model must be version-controlled alongside algorithm model"
    - "Model parameters must match target vehicle configuration"

  test_requirements:
    - "Cover all operating modes and transitions"
    - "Cover boundary conditions of all inputs"
    - "Cover timing requirements (using simulated time)"
    - "Regression suite must run in under 30 minutes"

  output_artifacts:
    - "Test results with requirement traceability"
    - "Model coverage report"
    - "Signal plots for visual inspection"
    - "Golden reference outputs for SIL back-to-back"
```

### MIL Test Example

```matlab
% MATLAB/Simulink test script for BMS SOC estimation
function results = test_soc_estimation_mil()
    % Load model
    model = 'bms_soc_estimator';
    load_system(model);

    % Configure simulation
    set_param(model, 'StopTime', '3600');  % 1 hour
    set_param(model, 'FixedStep', '0.001'); % 1 ms step

    % Test Case 1: Constant current discharge
    simIn = Simulink.SimulationInput(model);
    simIn = simIn.setVariable('current_profile', ...
        timeseries(ones(3600000,1) * -50, (0:3599999)'/1000));
    simIn = simIn.setVariable('initial_soc', 100.0);
    simIn = simIn.setVariable('temperature_c', 25.0);

    simOut = sim(simIn);

    % Verify SOC decreases monotonically
    soc_signal = simOut.soc_percent.Data;
    assert(all(diff(soc_signal) <= 0), 'SOC must decrease during discharge');

    % Verify final SOC within expected range
    expected_final_soc = 100 - (50 * 1) / BATTERY_CAPACITY_AH * 100;
    assert(abs(soc_signal(end) - expected_final_soc) < 2.0, ...
        'Final SOC within 2% of coulomb counting estimate');

    results.test1_passed = true;
    results.final_soc = soc_signal(end);
end
```

---

## Software-in-the-Loop (SIL)

### SIL Environment Setup

```cmake
# SIL build configuration - compile production code for host PC
project(bms_sil_test)

# Production source files (same code that runs on target)
set(PRODUCTION_SOURCES
    src/soc_estimator.c
    src/cell_voltage_monitor.c
    src/thermal_management.c
    src/fault_detection.c
)

# SIL-specific: Hardware abstraction stubs
set(SIL_STUBS
    sil/stubs/adc_driver_stub.c
    sil/stubs/can_driver_stub.c
    sil/stubs/gpio_driver_stub.c
    sil/stubs/timer_driver_stub.c
)

# SIL-specific: Plant model interface
set(PLANT_MODEL
    sil/plant/battery_model.c
    sil/plant/thermal_model.c
    sil/plant/sensor_model.c
)

# Test framework
set(TEST_SOURCES
    sil/tests/test_soc_estimation.cpp
    sil/tests/test_fault_detection.cpp
    sil/tests/test_thermal_management.cpp
)

add_executable(bms_sil_tests
    ${PRODUCTION_SOURCES}
    ${SIL_STUBS}
    ${PLANT_MODEL}
    ${TEST_SOURCES}
)

# Compile with same warnings as production
target_compile_options(bms_sil_tests PRIVATE
    -Wall -Wextra -Werror -Wshadow
    -DSIL_ENVIRONMENT  # Flag for conditional compilation
)

target_link_libraries(bms_sil_tests GTest::gtest_main)
```

### SIL Back-to-Back Testing

```python
# Back-to-back comparison: Model output vs C code output
class BackToBackTest:
    def __init__(self, model_output_dir: str, sil_output_dir: str):
        self.model_dir = model_output_dir
        self.sil_dir = sil_output_dir

    def compare_signal(self, signal_name: str,
                        tolerance_abs: float = 1e-6,
                        tolerance_rel: float = 1e-4) -> dict:
        model_data = load_signal(self.model_dir, signal_name)
        sil_data = load_signal(self.sil_dir, signal_name)

        # Align time bases
        model_interp = interpolate_signal(model_data, sil_data.time)

        # Compute errors
        abs_error = np.abs(model_interp.values - sil_data.values)
        rel_error = abs_error / (np.abs(model_interp.values) + 1e-10)

        max_abs_error = np.max(abs_error)
        max_rel_error = np.max(rel_error)

        passed = (max_abs_error < tolerance_abs or
                  max_rel_error < tolerance_rel)

        return {
            "signal": signal_name,
            "max_abs_error": float(max_abs_error),
            "max_rel_error": float(max_rel_error),
            "passed": passed,
            "tolerance_abs": tolerance_abs,
            "tolerance_rel": tolerance_rel,
            "num_samples": len(sil_data.values)
        }

    def run_all_comparisons(self, signals: list) -> dict:
        results = {}
        for signal_config in signals:
            result = self.compare_signal(**signal_config)
            results[signal_config["signal_name"]] = result
        return results
```

---

## Hardware-in-the-Loop (HIL)

### HIL System Architecture

```
+-------------------------------------------------------+
|                    HIL Bench                           |
|                                                       |
|  +------------------+     +----------------------+    |
|  | Real-Time        |     | ECU Under Test       |    |
|  | Simulator        |     | (Production HW+SW)   |    |
|  |                  |     |                      |    |
|  | Plant Models     |<--->| CAN Bus (real)       |    |
|  | Sensor Models    |<--->| Analog I/O (real)    |    |
|  | Actuator Models  |<--->| Digital I/O (real)   |    |
|  | Environment Sim  |<--->| Ethernet (real)      |    |
|  |                  |     |                      |    |
|  | dSPACE / ETAS /  |     | Power Supply         |    |
|  | NI / Speedgoat   |     | (controllable)       |    |
|  +------------------+     +----------------------+    |
|         |                         |                   |
|         v                         v                   |
|  +------------------+     +----------------------+    |
|  | Test Automation  |     | Measurement          |    |
|  | (Robot Framework |     | (CAN trace, scope,   |    |
|  |  or Python)      |     |  power analyzer)     |    |
|  +------------------+     +----------------------+    |
+-------------------------------------------------------+
```

### HIL Test Automation

```robot
*** Settings ***
Library    HilLibrary    bench_config=bench01.yaml
Library    CanBusLibrary    interface=vector    channel=1
Suite Setup    Initialize HIL Bench
Suite Teardown    Shutdown HIL Bench

*** Test Cases ***
BMS Overcurrent Protection Triggers Within FTTI
    [Documentation]    SSR-BMS-012: Verify overcurrent detection < 100ms
    [Tags]    safety    asil_d    regression

    # Precondition: BMS running, contactor closed
    Set Plant Model State    normal_operation
    Wait Until Keyword Succeeds    5s    100ms
    ...    Verify CAN Signal    BMS_Status    Contactor_State    CLOSED

    # Inject overcurrent via plant model
    ${start_time}=    Get HIL Timestamp Ms
    Set Sensor Model Value    pack_current_a    520.0

    # Verify contactor opens within FTTI
    Wait Until Keyword Succeeds    100ms    1ms
    ...    Verify CAN Signal    BMS_Status    Contactor_State    OPEN
    ${end_time}=    Get HIL Timestamp Ms

    # Verify timing
    ${reaction_time}=    Evaluate    ${end_time} - ${start_time}
    Should Be True    ${reaction_time} < 100
    ...    Reaction time ${reaction_time}ms exceeds 100ms FTTI

    # Verify DTC stored
    Read DTC Via UDS    0xBMS042
    DTC Should Be Active    0xBMS042

BMS Recovers After Overcurrent Clears
    [Documentation]    SSR-BMS-015: System recovers when fault clears
    [Tags]    safety    asil_d

    # Start from overcurrent fault state
    Set Sensor Model Value    pack_current_a    520.0
    Sleep    200ms
    Verify CAN Signal    BMS_Status    Contactor_State    OPEN

    # Clear overcurrent condition
    Set Sensor Model Value    pack_current_a    100.0
    Sleep    500ms

    # Attempt recovery via diagnostic command
    Send UDS Command    0x31 0x01 0xFF 0x00    # Routine Control: Clear Faults
    Sleep    100ms

    # Verify recovery
    Verify CAN Signal    BMS_Status    Fault_Active    FALSE
```

### HIL Fault Injection

```python
# HIL fault injection framework
class HilFaultInjector:
    def __init__(self, hil_interface):
        self.hil = hil_interface
        self.active_faults = []

    def inject_sensor_fault(self, sensor_name: str,
                             fault_type: str, **params):
        """Inject a sensor fault into the HIL plant model."""
        fault = {
            "sensor": sensor_name,
            "type": fault_type,
            "params": params,
            "start_time": self.hil.get_time_ms()
        }

        if fault_type == "stuck_at":
            self.hil.override_sensor(sensor_name, params["value"])
        elif fault_type == "offset":
            self.hil.add_sensor_offset(sensor_name, params["offset"])
        elif fault_type == "noise":
            self.hil.add_sensor_noise(sensor_name,
                                       params["amplitude"],
                                       params["frequency_hz"])
        elif fault_type == "open_circuit":
            self.hil.disconnect_sensor(sensor_name)
        elif fault_type == "short_circuit":
            self.hil.short_sensor(sensor_name, params["short_to"])

        self.active_faults.append(fault)

    def clear_all_faults(self):
        for fault in self.active_faults:
            self.hil.restore_sensor(fault["sensor"])
        self.active_faults.clear()
```

---

## Plant Model Quality

### Model Validation Requirements

```yaml
plant_model_validation:
  battery_model:
    validated_against: "Physical cell test data (25C, -10C, 45C)"
    voltage_accuracy: "<= 50 mV across SOC range"
    current_accuracy: "<= 1% of full scale"
    thermal_accuracy: "<= 2 degC"
    valid_soc_range: "5% - 100%"
    valid_current_range: "-500A to +500A"
    valid_temp_range: "-20C to 55C"
    review_frequency: "Annually or after cell chemistry change"

  sensor_model:
    includes:
      - "Transfer function (input to output)"
      - "Noise characteristics (Gaussian noise level)"
      - "Offset drift (temperature dependent)"
      - "Response time / bandwidth"
      - "Quantization (ADC resolution)"
    validated_against: "Sensor datasheet specifications"

  actuator_model:
    includes:
      - "Response dynamics (step response)"
      - "Dead time / transport delay"
      - "Saturation limits"
      - "Hysteresis"
    validated_against: "Component test bench measurements"
```

---

## Test Environment Configuration Management

### HIL Bench Configuration

```yaml
hil_bench_configuration:
  bench_id: "HIL-BENCH-01"
  simulator: "dSPACE SCALEXIO"
  real_time_os: "dSPACE RTLib"
  step_size_us: 10  # 100 kHz simulation rate

  connected_ecus:
    - ecu_id: "BMS-ECU-001"
      hw_revision: "Rev C"
      sw_version: "v2.4.0"
      connection:
        can_channels: [CAN1, CAN2]
        analog_inputs: [AI0-AI15]
        analog_outputs: [AO0-AO3]
        digital_io: [DIO0-DIO31]
        power_supply: "PS1 (6-16V, 10A)"

  plant_models:
    - name: "Battery Pack Model"
      version: "v3.1"
      fidelity: "96-cell equivalent circuit"
    - name: "Thermal Model"
      version: "v2.0"
      fidelity: "Lumped thermal network"

  calibration_date: "2025-03-01"
  next_calibration: "2025-09-01"
```

---

## Review Checklist

- [ ] MIL tests validate algorithm against requirements
- [ ] SIL tests use same production source code
- [ ] SIL back-to-back results within tolerance
- [ ] PIL tests verify target arithmetic correctness
- [ ] HIL tests cover all safety requirements
- [ ] HIL fault injection covers all safety mechanisms
- [ ] Plant models validated against physical test data
- [ ] Model accuracy documented with valid operating range
- [ ] HIL bench configuration version-controlled
- [ ] Test automation scripts repeatable and deterministic
- [ ] Simulation step size appropriate for system dynamics
- [ ] Coverage achieved at each test level documented
