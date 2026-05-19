# Functional Programming Patterns in Safety-Critical Automotive Code

> Functional programming principles applied to ASIL-rated automotive software
> to maximize determinism, testability, and formal verifiability.

## Scope

These rules apply to all safety-critical automotive software components rated
ASIL A through ASIL D, including powertrain controllers, ADAS functions,
battery management systems, and vehicle dynamics controllers.

## Why FP in Automotive

Safety-critical automotive code demands:
- **Determinism**: Same inputs must always produce same outputs
- **Testability**: Functions must be testable in isolation
- **Formal verification**: Code must be amenable to static analysis
- **Traceability**: Every computation must be traceable to a requirement

Functional programming naturally satisfies these constraints through
immutability, pure functions, and explicit data flow.

---

## Core Principles

### 1. Pure Functions for All Safety-Critical Computations

Every function in an ASIL-rated module must be a pure function unless
explicitly justified in the safety case.

```cpp
// GOOD: Pure function - deterministic, no side effects
float calculate_brake_torque(float pedal_position, float vehicle_speed,
                              float brake_pressure) {
    const float base_torque = pedal_position * MAX_BRAKE_TORQUE_NM;
    const float speed_factor = compute_speed_derating(vehicle_speed);
    return base_torque * speed_factor * (brake_pressure / MAX_PRESSURE_BAR);
}

// BAD: Impure function - reads global state, non-deterministic
float calculate_brake_torque() {
    float pedal = g_sensor_data.pedal_position;  // Global state read
    float speed = get_current_speed();             // Hidden dependency
    log_computation(pedal, speed);                 // Side effect
    return pedal * g_config.max_torque * speed;    // More global state
}
```

**Rule**: A pure function:
- Takes all inputs as explicit parameters
- Returns results only through return values or output parameters
- Does not read or modify global/static mutable state
- Does not perform I/O operations
- Produces the same output for the same inputs every time

### 2. Immutability by Default

All variables must be declared `const` unless mutation is explicitly required
and justified.

```cpp
// GOOD: Immutable pipeline
const float raw_voltage_mv = adc_read_channel(ADC_CHANNEL_BATTERY);
const float filtered_voltage_mv = apply_lowpass_filter(raw_voltage_mv, &filter_state);
const float calibrated_voltage_v = apply_calibration(filtered_voltage_mv, &cal_table);
const BatteryState state = classify_battery_state(calibrated_voltage_v);

// BAD: Mutable accumulation
float voltage = adc_read_channel(ADC_CHANNEL_BATTERY);
voltage = apply_lowpass_filter(voltage, &filter_state);  // Same variable reused
voltage = apply_calibration(voltage, &cal_table);         // Lost intermediate values
BatteryState state = classify_battery_state(voltage);
```

**Rule**: In C/C++ safety-critical code:
- Use `const` for all local variables that do not need mutation
- Use `constexpr` for compile-time constants
- Mark function parameters `const` when they are not modified
- Use `const` references for input parameters to structs/classes

### 3. Data Transformation Pipelines

Structure computations as explicit data transformation pipelines where each
stage is a named, testable function.

```cpp
// Signal processing pipeline - each stage independently testable
struct SignalPipeline {
    static SensorReading acquire(const AdcConfig& config);
    static FilteredReading filter(const SensorReading& raw,
                                   const FilterCoefficients& coeffs);
    static CalibratedValue calibrate(const FilteredReading& filtered,
                                      const CalibrationTable& table);
    static DiagnosticResult diagnose(const CalibratedValue& value,
                                      const DiagnosticThresholds& thresholds);
};

// Execute pipeline
const auto raw = SignalPipeline::acquire(adc_config);
const auto filtered = SignalPipeline::filter(raw, filter_coeffs);
const auto calibrated = SignalPipeline::calibrate(filtered, cal_table);
const auto diagnosis = SignalPipeline::diagnose(calibrated, diag_thresholds);
```

### 4. Algebraic Data Types for State Machines

Use tagged unions (variants) to represent vehicle states explicitly.
Every state transition must be handled.

```cpp
// Define vehicle states as an algebraic type
enum class VehicleMode : uint8_t {
    PARKED,
    READY,
    DRIVING,
    CHARGING,
    FAULT
};

struct ParkedState { uint32_t park_time_ms; };
struct ReadyState { float soc_percent; bool precharge_complete; };
struct DrivingState { float speed_kmh; float torque_nm; };
struct ChargingState { float charge_rate_kw; float target_soc; };
struct FaultState { uint16_t dtc_code; uint8_t severity; };

// State transition function - MUST handle all states (compiler-enforced)
VehicleMode handle_ignition_on(const VehicleMode current_mode) {
    switch (current_mode) {
        case VehicleMode::PARKED:    return VehicleMode::READY;
        case VehicleMode::READY:     return VehicleMode::READY;
        case VehicleMode::DRIVING:   return VehicleMode::DRIVING;
        case VehicleMode::CHARGING:  return VehicleMode::FAULT;
        case VehicleMode::FAULT:     return VehicleMode::FAULT;
    }
    // Unreachable - all cases handled
    return VehicleMode::FAULT;
}
```

**Rule**: All `switch` statements on enum types must:
- Handle every enumerator explicitly (no `default` catch-all)
- Be verified by `-Wswitch-enum` compiler warning
- Return a safe default if control reaches the end

### 5. Separation of Pure Logic and Side Effects

Organize code into two layers:
- **Pure core**: All business logic, calculations, state machines
- **Impure shell**: I/O, hardware access, communication

```
+------------------------------------------+
|           Impure Shell (thin)            |
|  - ADC reads, CAN transmit, GPIO write  |
|  - Timer callbacks, interrupt handlers   |
+------------------------------------------+
|           Pure Core (thick)              |
|  - Control algorithms                    |
|  - State machines                        |
|  - Fault detection logic                 |
|  - Diagnostic computations               |
+------------------------------------------+
```

**Rule**: The pure core must never:
- Call hardware abstraction functions directly
- Access shared memory or global variables
- Perform dynamic memory allocation
- Use system calls or OS primitives

---

## Function Composition Rules

### Compose Small Functions

```cpp
// Each function does ONE thing
float clamp(float value, float min, float max);
float scale(float value, float factor);
float offset(float value, float bias);

// Compose into a calibration pipeline
float apply_sensor_calibration(float raw_value,
                                const SensorCalibration& cal) {
    const float clamped = clamp(raw_value, cal.raw_min, cal.raw_max);
    const float scaled = scale(clamped, cal.gain);
    const float result = offset(scaled, cal.offset);
    return clamp(result, cal.output_min, cal.output_max);
}
```

### Result Types for Error Handling

Use result types instead of error codes or exceptions.

```cpp
template<typename T>
struct Result {
    bool is_ok;
    T value;
    uint16_t error_code;

    static Result ok(T val) { return {true, val, 0}; }
    static Result err(uint16_t code) { return {false, T{}, code}; }
};

// Usage in safety-critical code
Result<float> compute_cell_voltage(uint8_t cell_index,
                                    const AdcReadings& readings) {
    if (cell_index >= MAX_CELL_COUNT) {
        return Result<float>::err(ERR_CELL_INDEX_OUT_OF_RANGE);
    }
    const float raw = readings.channels[cell_index];
    if (raw < ADC_MIN_VALID_MV || raw > ADC_MAX_VALID_MV) {
        return Result<float>::err(ERR_ADC_READING_OUT_OF_RANGE);
    }
    return Result<float>::ok(raw * VOLTAGE_SCALE_FACTOR);
}
```

---

## Prohibited Patterns

| Pattern | Reason | Alternative |
|---------|--------|-------------|
| Global mutable state | Non-deterministic, untestable | Pass state as parameters |
| Static local variables | Hidden state between calls | Explicit state structs |
| Void functions with side effects | Untraceable data flow | Return results explicitly |
| In-place mutation of inputs | Aliasing bugs, hard to debug | Return new values |
| Function pointers without typedef | Unreadable, error-prone | Named function types |
| Recursive functions (ASIL C/D) | Stack overflow risk | Iterative with bounded loops |
| Dynamic dispatch (ASIL D) | WCET unpredictability | Static dispatch, templates |
| `goto` statements | Unstructured control flow | Structured loops and returns |
| Pointer arithmetic | Buffer overflow risk | Array indexing with bounds |
| Implicit type conversions | Precision loss | Explicit casts with checks |

---

## Testing FP Automotive Code

### Property-Based Testing

Pure functions enable property-based testing:

```cpp
// Property: brake torque is always non-negative
TEST(BrakeTorque, AlwaysNonNegative) {
    for (int i = 0; i < 10000; ++i) {
        const float pedal = random_float(0.0f, 1.0f);
        const float speed = random_float(0.0f, 250.0f);
        const float pressure = random_float(0.0f, 200.0f);
        EXPECT_GE(calculate_brake_torque(pedal, speed, pressure), 0.0f);
    }
}

// Property: monotonicity - more pedal = more torque
TEST(BrakeTorque, MonotonicWithPedal) {
    const float speed = 100.0f;
    const float pressure = 150.0f;
    float prev_torque = 0.0f;
    for (float pedal = 0.0f; pedal <= 1.0f; pedal += 0.01f) {
        const float torque = calculate_brake_torque(pedal, speed, pressure);
        EXPECT_GE(torque, prev_torque);
        prev_torque = torque;
    }
}
```

### Equivalence Partition Testing

```cpp
// Test each partition boundary for pure function
TEST(CellVoltage, ValidRange) {
    const auto result = compute_cell_voltage(0, valid_readings);
    EXPECT_TRUE(result.is_ok);
    EXPECT_NEAR(result.value, EXPECTED_VOLTAGE_V, TOLERANCE_V);
}

TEST(CellVoltage, IndexOutOfRange) {
    const auto result = compute_cell_voltage(MAX_CELL_COUNT, valid_readings);
    EXPECT_FALSE(result.is_ok);
    EXPECT_EQ(result.error_code, ERR_CELL_INDEX_OUT_OF_RANGE);
}
```

---

## Compliance Matrix

| FP Rule | MISRA C:2012 | ISO 26262 | AUTOSAR C++14 |
|---------|-------------|-----------|---------------|
| Pure functions | Rule 8.13 | Part 6, Table 1 | A7-1-1 |
| Immutability | Rule 8.13 | Part 6, 8.4.4 | A7-1-1, A7-1-2 |
| No globals | Rule 8.9 | Part 6, Table 9 | A3-3-2 |
| No recursion | Rule 17.2 | Part 6, Table 8 | A7-5-2 |
| Bounded loops | Rule 15.4 | Part 6, 8.4.4 | M6-5-6 |
| Explicit types | Rule 10.1-10.8 | Part 6, Table 1 | A5-0-3 |
| No dynamic alloc | Rule 21.3 | Part 6, Table 4 | A18-5-1 |
| Result types | Rule 17.7 | Part 6, Table 9 | A0-1-2 |

---

## Language-Specific Guidelines

### C (ASIL C/D - MISRA Compliant)

- Use `const` qualifier on all non-mutated variables
- Use `static` for file-scope functions (encapsulation)
- Use structs for grouping related parameters
- No VLAs (variable-length arrays)
- All functions must have explicit return types

### C++ (ASIL A/B - AUTOSAR Compliant)

- Use `constexpr` for compile-time computations
- Use `std::array` instead of C arrays
- Use `enum class` instead of plain enums
- Templates allowed for generic pure functions
- No RTTI or dynamic_cast in safety paths

### Rust (Emerging - Pre-ASIL)

- Leverage ownership system for memory safety
- Use `Result<T, E>` for all fallible operations
- Use `#[must_use]` on all result-returning functions
- No `unsafe` blocks in safety-critical paths
- Use `const fn` for compile-time evaluation

---

## Review Checklist

- [ ] All safety-critical functions are pure (no side effects)
- [ ] All variables declared `const` unless mutation justified
- [ ] Data flows through explicit transformation pipelines
- [ ] State machines use algebraic types with exhaustive matching
- [ ] Pure core separated from impure shell
- [ ] No global mutable state in safety-critical modules
- [ ] Error handling uses result types, not exceptions
- [ ] All functions bounded (no recursion, bounded loops)
- [ ] Property-based tests cover critical invariants
- [ ] Compliance matrix entries verified against standards
