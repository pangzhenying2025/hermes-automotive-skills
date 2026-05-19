# MISRA C++:2023 Coding Standard Rules

MISRA C++:2023 extends MISRA principles to modern C++ for automotive safety-critical systems. It addresses C++17 features while maintaining deterministic, verifiable behavior required for functional safety.

## Purpose

- Provide safe subset of C++17 for automotive applications
- Address modern C++ features (auto, lambdas, smart pointers, constexpr)
- Eliminate undefined behavior and implementation-defined behavior
- Support AUTOSAR Adaptive Platform development
- Enable static analysis and certification to ISO 26262

## Applicability

MISRA C++:2023 applies to C++ code in automotive contexts:
- AUTOSAR Adaptive Platform services (C++17 mandatory)
- High-performance ECUs (multi-core, ADAS, infotainment)
- Non-real-time safety applications (ASIL A/B)
- Tool chains and build infrastructure

For ASIL C/D real-time control, prefer MISRA C:2012 unless C++ is mandated by architecture.

## Rule Categories

| Category | Count | Enforcement |
|----------|-------|-------------|
| Mandatory | 42 | No deviations allowed |
| Required | 127 | Deviations with justification |
| Advisory | 86 | Recommended, document if not followed |

## Key Mandatory Rules for Safety

### Rule 5-0-1 (Mandatory): No dynamic memory in safety-critical paths

```cpp
// VIOLATION: Dynamic allocation in safety code
class BrakeController {
    std::vector<float> pressure_history;  // Dynamic allocation
public:
    void update_pressure(float value) {
        pressure_history.push_back(value);  // May fail
    }
};

// COMPLIANT: Static allocation with compile-time bounds
class BrakeController {
    static constexpr size_t MAX_HISTORY = 100U;
    std::array<float, MAX_HISTORY> pressure_history{};
    size_t history_count = 0U;
public:
    void update_pressure(float value) {
        if (history_count < MAX_HISTORY) {
            pressure_history[history_count] = value;
            history_count++;
        }
    }
};
```

### Rule 15-5-1 (Mandatory): No exceptions in ASIL-D code

```cpp
// VIOLATION: Exception throwing in ASIL-D path
class SafetyMonitor {
public:
    void check_voltage(float voltage) {
        if (voltage > MAX_VOLTAGE) {
            throw std::runtime_error("Overvoltage");  // Not allowed ASIL-D
        }
    }
};

// COMPLIANT: Return error code or use error-handling pattern
class SafetyMonitor {
public:
    enum class Status { OK, OVERVOLTAGE, UNDERVOLTAGE };

    Status check_voltage(float voltage, bool& error_flag) noexcept {
        if (voltage > MAX_VOLTAGE) {
            error_flag = true;
            return Status::OVERVOLTAGE;
        }
        error_flag = false;
        return Status::OK;
    }
};
```

### Rule 7-1-1 (Mandatory): No variable-length arrays

```cpp
// VIOLATION: VLA (non-standard in C++)
void process_samples(size_t count) {
    float samples[count];  // Variable-length array
    // Process samples
}

// COMPLIANT: Use std::array or static allocation
void process_samples(size_t count) {
    constexpr size_t MAX_SAMPLES = 256U;
    std::array<float, MAX_SAMPLES> samples{};

    if (count <= MAX_SAMPLES) {
        // Process samples
    }
}
```

### Rule 18-0-1 (Mandatory): No NULL, use nullptr

```cpp
// VIOLATION: Using NULL macro
void* get_buffer() {
    return NULL;  // C-style null pointer
}

// COMPLIANT: Use nullptr
void* get_buffer() {
    return nullptr;
}

// Better: Use typed pointer
float* get_buffer() {
    return nullptr;
}
```

## Key Required Rules

### Rule 3-1-1 (Required): No unnecessary use of volatile

```cpp
// VIOLATION: Inappropriate volatile
class DataProcessor {
    volatile int counter;  // Not hardware register, not ISR-shared
public:
    void increment() {
        counter++;  // Volatile prevents optimization unnecessarily
    }
};

// COMPLIANT: Use volatile only for hardware or ISR access
class PeripheralDriver {
    volatile uint32_t& status_register;  // Hardware register
public:
    PeripheralDriver(volatile uint32_t& reg) : status_register(reg) {}

    bool is_ready() const {
        return (status_register & STATUS_READY_BIT) != 0U;
    }
};
```

### Rule 5-2-1 (Required): No implicit conversions that lose information

```cpp
// VIOLATION: Implicit narrowing conversion
void set_speed(int32_t speed_mps) {
    uint8_t speed_kmh = speed_mps * 3.6;  // Implicit conversion
}

// COMPLIANT: Explicit conversion with range check
void set_speed(int32_t speed_mps) {
    int32_t speed_kmh = speed_mps * 36 / 10;  // Avoid floating point

    if ((speed_kmh >= 0) && (speed_kmh <= 255)) {
        uint8_t speed_display = static_cast<uint8_t>(speed_kmh);
        update_display(speed_display);
    }
}
```

### Rule 7-5-1 (Required): All functions shall have return type

```cpp
// VIOLATION: Constructor-like function without return type (deprecated syntax)
class VehicleState {
    VehicleState() {  // OK for constructor
    }
};

// All regular functions must have explicit return type
auto calculate_distance()  // VIOLATION: Missing trailing return type
{
    return 42.0;
}

// COMPLIANT: Explicit return type
auto calculate_distance() -> double {
    return 42.0;
}

// Or traditional syntax
double calculate_distance() {
    return 42.0;
}
```

### Rule 8-4-2 (Required): Function parameters shall be named

```cpp
// VIOLATION: Unnamed parameters
class CanInterface {
public:
    virtual void on_message(uint32_t, const uint8_t*, size_t) = 0;
};

// COMPLIANT: Named parameters for clarity
class CanInterface {
public:
    virtual void on_message(uint32_t can_id,
                           const uint8_t* payload,
                           size_t length) = 0;
};
```

### Rule 10-2-1 (Required): Use RAII for resource management

```cpp
// VIOLATION: Manual resource management
class SensorDriver {
    int fd;
public:
    SensorDriver(const char* device) {
        fd = open(device, O_RDWR);
    }

    void read_data() {
        // Use fd
    }

    // Missing destructor - resource leak
};

// COMPLIANT: RAII pattern
class SensorDriver {
    class FileDescriptor {
        int fd;
    public:
        explicit FileDescriptor(const char* device)
            : fd(open(device, O_RDWR)) {
            if (fd < 0) {
                // Handle error without exception in ASIL-D
            }
        }

        ~FileDescriptor() {
            if (fd >= 0) {
                close(fd);
            }
        }

        // Delete copy, allow move
        FileDescriptor(const FileDescriptor&) = delete;
        FileDescriptor& operator=(const FileDescriptor&) = delete;
        FileDescriptor(FileDescriptor&& other) noexcept : fd(other.fd) {
            other.fd = -1;
        }

        int get() const { return fd; }
    };

    FileDescriptor fd;

public:
    explicit SensorDriver(const char* device) : fd(device) {}

    void read_data() {
        if (fd.get() >= 0) {
            // Use fd.get()
        }
    }
    // Automatic cleanup via RAII
};
```

### Rule 12-1-1 (Required): Dynamic polymorphism shall use override

```cpp
// VIOLATION: Missing override specifier
class BaseController {
public:
    virtual void update() {}
    virtual ~BaseController() = default;
};

class MotorController : public BaseController {
public:
    void update() {}  // Missing override - easy to introduce bugs
};

// COMPLIANT: Use override keyword
class MotorController : public BaseController {
public:
    void update() override {}  // Compiler verifies override
};
```

### Rule 14-7-1 (Required): No goto statements

```cpp
// VIOLATION: Using goto
void process_data() {
    if (!initialize()) {
        goto error;
    }

    if (!process()) {
        goto error;
    }

    return;

error:
    cleanup();
}

// COMPLIANT: Structured error handling
void process_data() {
    if (!initialize()) {
        cleanup();
        return;
    }

    if (!process()) {
        cleanup();
        return;
    }
}

// Better: RAII
void process_data() {
    ResourceGuard guard(initialize, cleanup);
    if (!guard.is_valid()) {
        return;
    }

    process();
    // Automatic cleanup
}
```

## Key Advisory Rules

### Rule 0-1-1 (Advisory): Use modern C++ features appropriately

```cpp
// SUBOPTIMAL: C-style code in C++
void process_buffer(const char* buffer, int length) {
    for (int i = 0; i < length; i++) {
        process_byte(buffer[i]);
    }
}

// BETTER: Modern C++ with type safety
void process_buffer(std::span<const uint8_t> buffer) {
    for (const auto byte : buffer) {
        process_byte(byte);
    }
}
```

### Rule 2-10-1 (Advisory): Use constexpr for compile-time constants

```cpp
// SUBOPTIMAL: Runtime constant
const uint32_t MAX_SPEED_KMH = 250;

// BETTER: Compile-time constant
constexpr uint32_t MAX_SPEED_KMH = 250U;

// Even better: Typed constant
enum class SpeedLimit : uint32_t {
    MAX_SPEED_KMH = 250U
};
```

### Rule 7-1-2 (Advisory): Use auto where type is obvious

```cpp
// SUBOPTIMAL: Verbose type repetition
std::shared_ptr<BatteryManagementSystem> bms =
    std::make_shared<BatteryManagementSystem>();

// BETTER: Use auto
auto bms = std::make_shared<BatteryManagementSystem>();

// But avoid when type is not obvious
auto value = get_sensor_value();  // What type is this?

// Better: Explicit when clarity needed
float temperature_celsius = get_sensor_value();
```

## Modern C++ Patterns for Automotive

### Smart Pointers (ASIL A/B only)

```cpp
// Use unique_ptr for exclusive ownership
class VehicleController {
    std::unique_ptr<BrakeSystem> brake_system;

public:
    VehicleController()
        : brake_system(std::make_unique<BrakeSystem>()) {}

    // Move-only semantics
    VehicleController(VehicleController&&) = default;
    VehicleController& operator=(VehicleController&&) = default;

    // No copy
    VehicleController(const VehicleController&) = delete;
    VehicleController& operator=(const VehicleController&) = delete;
};

// Use shared_ptr sparingly, prefer composition
// AVOID in ASIL-D (non-deterministic reference counting)
```

### Lambda Functions

```cpp
// COMPLIANT: Stateless lambda for algorithm
std::array<int32_t, 100> sensor_values{};

auto max_value = std::max_element(
    sensor_values.begin(),
    sensor_values.end(),
    [](int32_t a, int32_t b) { return a < b; }
);

// COMPLIANT: Capture by value for small data
void process_with_threshold(const std::array<float, 10>& data) {
    constexpr float threshold = 50.0F;

    std::for_each(data.begin(), data.end(),
        [threshold](float value) {
            if (value > threshold) {
                trigger_alarm();
            }
        });
}

// AVOID: Capturing 'this' in safety-critical callbacks
// AVOID: Mutable lambdas in concurrent contexts
```

### Constexpr Functions

```cpp
// Compile-time calculation for lookup tables
constexpr uint32_t calculate_crc_table_entry(uint8_t index) {
    uint32_t crc = index;
    for (uint8_t i = 0; i < 8U; i++) {
        crc = (crc & 1U) ? (crc >> 1U) ^ 0xEDB88320U : (crc >> 1U);
    }
    return crc;
}

// Generate CRC table at compile time
constexpr auto generate_crc_table() {
    std::array<uint32_t, 256> table{};
    for (size_t i = 0; i < 256U; i++) {
        table[i] = calculate_crc_table_entry(static_cast<uint8_t>(i));
    }
    return table;
}

constexpr auto CRC32_TABLE = generate_crc_table();
```

### Type-Safe Enumerations

```cpp
// VIOLATION: Unscoped enum
enum State {
    IDLE,
    RUNNING,
    ERROR
};

// COMPLIANT: Scoped enum class
enum class VehicleState : uint8_t {
    IDLE = 0U,
    RUNNING = 1U,
    ERROR = 2U
};

// Usage
VehicleState state = VehicleState::IDLE;

// Explicit conversion when needed
uint8_t state_value = static_cast<uint8_t>(state);
```

## Common Violations and Fixes

### Implicit Bool Conversion

```cpp
// VIOLATION
void* ptr = get_pointer();
if (ptr) {  // Implicit conversion
    use(ptr);
}

// COMPLIANT
void* ptr = get_pointer();
if (ptr != nullptr) {
    use(ptr);
}
```

### Uninitialized Variables

```cpp
// VIOLATION
void calculate() {
    float result;
    if (condition) {
        result = compute();
    }
    send_result(result);  // May be uninitialized
}

// COMPLIANT
void calculate() {
    float result = 0.0F;  // Initialize
    if (condition) {
        result = compute();
    }
    send_result(result);
}
```

### Signed/Unsigned Comparison

```cpp
// VIOLATION
int32_t find_index(const std::vector<int>& vec, int value) {
    for (int i = 0; i < vec.size(); i++) {  // Signed/unsigned compare
        if (vec[i] == value) {
            return i;
        }
    }
    return -1;
}

// COMPLIANT
int32_t find_index(const std::vector<int>& vec, int value) {
    for (size_t i = 0U; i < vec.size(); i++) {
        if (vec[i] == value) {
            return static_cast<int32_t>(i);
        }
    }
    return -1;
}
```

## Tool Support

### Cppcheck with MISRA C++ addon

```bash
cppcheck --addon=misra.json \
         --addon=misracpp2023.json \
         --std=c++17 \
         --enable=all \
         --inconclusive \
         src/
```

### Clang-Tidy with MISRA checks

```yaml
# .clang-tidy configuration
Checks: >
  cert-*,
  cppcoreguidelines-*,
  modernize-*,
  readability-*,
  -modernize-use-trailing-return-type

CheckOptions:
  - key: cppcoreguidelines-avoid-magic-numbers.IgnoredIntegerValues
    value: '0;1;2;8;10;16;32;64;100;256;1000'
```

### LDRA TBvision

```bash
# MISRA C++:2023 analysis
ldra set_option -project automotive_ecu \
                -standard MISRA_CPP_2023 \
                -asil_level D

ldra analyze -project automotive_ecu -source src/
ldra report -project automotive_ecu -output misra_cpp_report.html
```

### PRQA QA-C++

```bash
qacpp -config MISRA_CPP_2023.xml \
      -asil D \
      -output misra_report.xml \
      src/**/*.cpp
```

## Deviation Process

### Deviation Categories

1. Language constructs (unavoidable C++ features)
2. Third-party libraries (AUTOSAR APIs)
3. Performance optimization (proven safe via analysis)
4. Tool limitations (false positives)

### Deviation Template

```cpp
/**
 * MISRA C++ Deviation
 *
 * Rule: 15-5-1 (Mandatory) - Exception throwing prohibited in ASIL-D
 * Justification: AUTOSAR ara::core API mandates std::exception for error handling.
 *                Component is ASIL-B, not ASIL-D. Exception caught at partition boundary.
 * Alternative Analysis: Error codes evaluated but incompatible with ara::com API.
 * Safety Impact: None - exceptions caught before safety-critical execution path.
 * Approval: Jane Doe (Safety Architect), 2024-02-20
 * Tracking: SAFE-5678
 */
namespace ara::com {
    void AdaptiveService::initialize() {
        try {
            FindService("ServiceName");
        } catch (const std::exception& e) {
            // Handle error - never propagate to ASIL-D code
            log_error(e.what());
        }
    }
}
```

## ASIL-Specific Restrictions

### ASIL D: Prohibited Features

- Dynamic memory allocation (new/delete, smart pointers)
- Exception handling (throw/try/catch)
- Runtime type information (dynamic_cast, typeid)
- Virtual functions (unless statically bound)
- STL containers (use static-size alternatives)

### ASIL C: Restricted Features

- Dynamic memory allowed if proven bounded
- Exceptions allowed in non-real-time paths
- RTTI allowed for diagnostics
- Virtual functions with analysis

### ASIL A/B: Modern C++ Allowed

- Full C++17 feature set
- Smart pointers recommended
- STL algorithms encouraged
- Exceptions for error handling

## Integration with AUTOSAR

MISRA C++:2023 complements AUTOSAR C++14 Guidelines:
- AUTOSAR focuses on architecture patterns
- MISRA focuses on language safety subset
- Both required for AUTOSAR Adaptive Platform

Common patterns:
```cpp
// AUTOSAR ara::core error handling
ara::core::Result<float> read_sensor() noexcept {
    if (sensor_available()) {
        return ara::core::Result<float>(sensor_value);
    } else {
        return ara::core::Result<float>::FromError(
            ara::core::ErrorCode(ErrorDomain::kSensor, 1U));
    }
}
```

## Enforcement in CI

```yaml
# .gitlab-ci.yml
misra_cpp_check:
  stage: static_analysis
  script:
    - cppcheck --addon=misracpp2023.json --xml --xml-version=2 src/ 2> misra.xml
    - python scripts/parse_misra_results.py misra.xml --fail-on-mandatory
  artifacts:
    reports:
      junit: misra_junit.xml
    paths:
      - misra.xml
  only:
    - merge_requests
    - develop
```

## References

- MISRA C++:2023 Guidelines for the use of C++17 in critical systems
- AUTOSAR C++14 Coding Guidelines (v21-11)
- ISO 26262-6:2018 Software development guidelines
- HIC++ High Integrity C++ Coding Standard
- JSF AV C++ Coding Standards (legacy reference)
