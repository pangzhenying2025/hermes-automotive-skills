# Test Automation Standards for Automotive Software

> Rules for building and maintaining automated test suites across
> the automotive V-model, from unit tests through system validation,
> ensuring reproducible, reliable, and efficient test execution.

## Scope

These rules apply to all automated testing in automotive software
development including unit tests, integration tests, HIL tests,
regression suites, and continuous testing in CI/CD pipelines.

---

## Test Automation Pyramid

```
           /\
          /  \       Vehicle Tests (Manual + Automated)
         /    \      5% of total tests
        /------\
       /        \    System/HIL Tests
      /          \   15% of total tests
     /------------\
    /              \  Integration Tests
   /                \ 30% of total tests
  /------------------\
 /                    \ Unit Tests
/______________________\ 50% of total tests
```

### Level Definitions

| Level | Scope | Execution Time | Environment | Frequency |
|-------|-------|---------------|-------------|-----------|
| Unit | Single function/class | < 1 ms each | Host PC | Every commit |
| Integration | Multiple modules | < 1 s each | Host/SIL | Every PR |
| System/HIL | Complete ECU SW | < 60 s each | HIL bench | Nightly |
| Vehicle | Complete vehicle | Minutes-hours | Vehicle | Release gate |

---

## Test Code Quality

### Test Naming Convention

```cpp
// Pattern: test_<Unit>_<Scenario>_<ExpectedBehavior>

// GoogleTest (C++)
TEST(CellVoltageMonitor, WhenVoltageExceedsMaximum_TriggersOvervoltageAlarm) {
    // ...
}

TEST(CellVoltageMonitor, WhenAdcReturnsZero_ReportsOpenWireFault) {
    // ...
}

TEST(BrakeTorqueCalculator, WithZeroPedalPosition_ReturnsZeroTorque) {
    // ...
}

// pytest (Python)
def test_cell_voltage_monitor_when_voltage_exceeds_max_triggers_alarm():
    pass

def test_brake_torque_with_zero_pedal_returns_zero():
    pass
```

### Test Structure (AAA Pattern)

```cpp
TEST(OvercurrentProtection, WhenCurrentExceeds500A_OpensContactorWithin100ms) {
    // ARRANGE: Set up preconditions
    BmsController bms;
    bms.initialize(default_config());
    bms.set_contactor_state(CONTACTOR_CLOSED);
    MockAdcDriver mock_adc;
    mock_adc.set_channel_value(ADC_PACK_CURRENT, current_to_adc(520.0f));

    // ACT: Execute the behavior under test
    bms.process_cycle();  // 1ms cycle

    // ASSERT: Verify outcomes
    EXPECT_EQ(bms.get_fault_state(), FAULT_OVERCURRENT);
    EXPECT_EQ(bms.get_contactor_command(), CONTACTOR_OPEN);
    EXPECT_LE(bms.get_fault_reaction_time_ms(), 100U);
}
```

### Test Independence

```cpp
// GOOD: Each test is self-contained
class CellBalancerTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Fresh instance for every test
        balancer = std::make_unique<CellBalancer>(test_config);
        mock_hardware = std::make_unique<MockBalancerHardware>();
        balancer->set_hardware(mock_hardware.get());
    }

    void TearDown() override {
        // Explicit cleanup
        balancer.reset();
        mock_hardware.reset();
    }

    std::unique_ptr<CellBalancer> balancer;
    std::unique_ptr<MockBalancerHardware> mock_hardware;
    static constexpr BalancerConfig test_config = {
        .threshold_mv = 10U,
        .max_balance_current_ma = 100U,
        .cell_count = 12U
    };
};

// BAD: Tests depend on execution order
static BmsController* shared_bms;  // Shared mutable state
TEST(Sequential, Step1_Initialize) { shared_bms->init(); }
TEST(Sequential, Step2_StartCharging) { shared_bms->start_charge(); }
TEST(Sequential, Step3_StopCharging) { shared_bms->stop_charge(); }
```

---

## Mocking and Stubbing

### Hardware Abstraction Mocking

```cpp
/* Interface for mockable hardware access */
class IAdcDriver {
public:
    virtual ~IAdcDriver() = default;
    virtual uint16_t read_channel(uint8_t channel) = 0;
    virtual bool start_conversion(uint8_t group) = 0;
    virtual bool is_conversion_complete(uint8_t group) = 0;
};

/* Production implementation */
class HwAdcDriver : public IAdcDriver {
public:
    uint16_t read_channel(uint8_t channel) override {
        return VADC_read_result(channel);  // Actual hardware register
    }
};

/* Test mock */
class MockAdcDriver : public IAdcDriver {
public:
    MOCK_METHOD(uint16_t, read_channel, (uint8_t), (override));
    MOCK_METHOD(bool, start_conversion, (uint8_t), (override));
    MOCK_METHOD(bool, is_conversion_complete, (uint8_t), (override));

    void set_channel_value(uint8_t channel, uint16_t value) {
        ON_CALL(*this, read_channel(channel))
            .WillByDefault(Return(value));
    }
};
```

### CAN Communication Mocking

```python
# Python mock for CAN bus testing
class MockCanBus:
    def __init__(self):
        self.sent_messages = []
        self.rx_queue = queue.Queue()
        self.filters = {}

    def send(self, msg_id: int, data: bytes) -> bool:
        self.sent_messages.append(CanMessage(msg_id, data))
        return True

    def inject_rx(self, msg_id: int, data: bytes):
        """Simulate receiving a CAN message."""
        self.rx_queue.put(CanMessage(msg_id, data))

    def get_sent_messages(self, msg_id: int = None) -> list:
        if msg_id is None:
            return self.sent_messages
        return [m for m in self.sent_messages if m.id == msg_id]

    def assert_message_sent(self, msg_id: int, expected_data: bytes,
                             timeout_ms: int = 100):
        matches = self.get_sent_messages(msg_id)
        assert len(matches) > 0, f"No message with ID 0x{msg_id:X} sent"
        assert matches[-1].data == expected_data
```

---

## CI/CD Integration

### Pipeline Test Stages

```yaml
# GitLab CI / GitHub Actions pipeline structure
stages:
  - build
  - unit_test
  - static_analysis
  - integration_test
  - hil_test
  - release_gate

unit_test:
  stage: unit_test
  script:
    - mkdir -p build && cd build
    - cmake .. -DBUILD_TESTS=ON -DCOVERAGE=ON
    - make -j$(nproc)
    - ctest --output-on-failure --parallel $(nproc)
    - gcovr --xml-pretty -o coverage.xml --fail-under-line 80
  artifacts:
    reports:
      junit: build/test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: build/coverage.xml
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "develop"'

integration_test:
  stage: integration_test
  script:
    - cmake .. -DBUILD_INTEGRATION_TESTS=ON
    - make -j$(nproc)
    - ctest --label-regex integration --output-on-failure
  needs: [unit_test]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

hil_test:
  stage: hil_test
  tags: [hil-bench-01]  # Run on specific HIL runner
  script:
    - flash_ecu --target $ECU_ID --binary build/firmware.bin
    - robot --outputdir results --variable ECU:$ECU_ID tests/hil/
  artifacts:
    reports:
      junit: results/output.xml
    paths:
      - results/
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'
      when: manual
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+/'
```

### Test Execution Rules

| Rule | Rationale |
|------|-----------|
| Unit tests run on every commit | Catch regressions immediately |
| Integration tests run on every PR | Verify component interactions |
| All tests must pass before merge | No broken code in main branch |
| Flaky tests quarantined within 24h | Flaky tests erode trust |
| Test timeout: 10x normal duration | Detect performance regressions |
| Parallel execution where possible | Reduce feedback time |
| Results stored as artifacts | Traceability and trend analysis |

---

## Test Data Management

### Test Vector Management

```yaml
# Test vectors stored in version-controlled YAML files
test_vectors:
  module: cell_voltage_monitor
  revision: 3
  vectors:
    - id: TV-001
      description: "Normal operating range - mid SOC"
      inputs:
        adc_raw: 2048
        calibration_gain: 1.221
        calibration_offset: 0.0
      expected:
        cell_voltage_v: 2.500
        tolerance_v: 0.001
        fault_status: NO_FAULT

    - id: TV-002
      description: "Over-voltage condition"
      inputs:
        adc_raw: 3686
        calibration_gain: 1.221
        calibration_offset: 0.0
      expected:
        cell_voltage_v: 4.500
        tolerance_v: 0.001
        fault_status: OVERVOLTAGE
```

### Golden Reference Data

```python
# Generate and maintain golden reference outputs
class GoldenReferenceManager:
    """Manages approved reference outputs for regression testing."""

    def __init__(self, golden_dir: str):
        self.golden_dir = golden_dir

    def compare(self, test_id: str, actual_output: dict) -> bool:
        golden_path = os.path.join(self.golden_dir, f"{test_id}.json")
        with open(golden_path) as f:
            expected = json.load(f)

        for key, expected_val in expected.items():
            actual_val = actual_output[key]
            if isinstance(expected_val, float):
                if abs(actual_val - expected_val) > expected.get(
                    f"{key}_tolerance", 1e-6):
                    return False
            elif actual_val != expected_val:
                return False
        return True

    def update_golden(self, test_id: str, new_output: dict,
                       approver: str):
        """Requires explicit approval to update golden reference."""
        golden_path = os.path.join(self.golden_dir, f"{test_id}.json")
        new_output["_approved_by"] = approver
        new_output["_approved_date"] = datetime.utcnow().isoformat()
        with open(golden_path, 'w') as f:
            json.dump(new_output, f, indent=2)
```

---

## Test Reporting

### Standardized Report Format

```xml
<!-- JUnit XML format for CI integration -->
<testsuites>
  <testsuite name="CellVoltageMonitor" tests="42" failures="1"
             errors="0" time="0.234">
    <testcase name="WhenVoltageNormal_ReportsNoFault"
              classname="CellVoltageMonitorTest" time="0.003"/>
    <testcase name="WhenOvervoltage_TriggersAlarm"
              classname="CellVoltageMonitorTest" time="0.005">
      <failure message="Expected OVERVOLTAGE but got NO_FAULT">
        cell_voltage_monitor.cpp:142
        Expected: FAULT_OVERVOLTAGE
        Actual: FAULT_NONE
      </failure>
    </testcase>
  </testsuite>
</testsuites>
```

### Test Metrics Dashboard

```yaml
metrics:
  - name: "Test Pass Rate"
    formula: "passed / total * 100"
    target: ">= 99%"
    alert_threshold: "< 95%"

  - name: "Test Execution Time"
    formula: "total_duration"
    target: "< 15 minutes (unit + integration)"
    alert_threshold: "> 30 minutes"

  - name: "Flaky Test Rate"
    formula: "tests_with_inconsistent_results / total * 100"
    target: "< 1%"
    alert_threshold: "> 3%"

  - name: "Code Coverage (new code)"
    formula: "covered_lines_new / total_lines_new * 100"
    target: ">= 80%"
    alert_threshold: "< 70%"
```

---

## Review Checklist

- [ ] Test pyramid ratio maintained (50/30/15/5)
- [ ] All tests follow AAA pattern with clear naming
- [ ] Tests are independent with no shared mutable state
- [ ] Hardware dependencies mocked via interfaces
- [ ] CI pipeline runs unit tests on every commit
- [ ] Integration tests gate PR merges
- [ ] Test vectors version-controlled alongside code
- [ ] Flaky tests identified and quarantined
- [ ] Coverage reports generated and reviewed
- [ ] Test results stored as artifacts for traceability
- [ ] Golden reference data approved before updates
- [ ] Test execution time monitored and optimized
