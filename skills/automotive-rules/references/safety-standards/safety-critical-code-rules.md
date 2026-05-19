# Safety-Critical Code Rules for ASIL C/D

Strict coding rules for ASIL C and ASIL D safety-critical automotive software per ISO 26262.

## Purpose

- Ensure deterministic, predictable execution in safety-critical contexts
- Eliminate undefined behavior and runtime failures
- Enable static analysis and formal verification
- Support safety case argumentation

## No Dynamic Memory Allocation

### Rationale
Dynamic memory allocation (malloc/calloc/realloc/free) introduces non-determinism, fragmentation, and potential out-of-memory failures.

### Rule
Dynamic memory allocation is prohibited in ASIL C/D code.

```c
// VIOLATION
void process_data(uint16_t size) {
    uint8_t *buffer = (uint8_t *)malloc(size);
    if (buffer != NULL) {
        // Process
        free(buffer);
    }
}

// COMPLIANT
#define MAX_BUFFER_SIZE 256U
static uint8_t buffer[MAX_BUFFER_SIZE];

void process_data(uint16_t size) {
    if (size <= MAX_BUFFER_SIZE) {
        // Process using static buffer
    }
}
```

## No Recursion

### Rationale
Recursion makes stack usage unpredictable and can cause stack overflow.

### Rule
Recursive functions are prohibited in ASIL C/D code.

```c
// VIOLATION
uint32_t factorial(uint32_t n) {
    if (n <= 1U) return 1U;
    return n * factorial(n - 1U);  // Recursion
}

// COMPLIANT
uint32_t factorial(uint32_t n) {
    uint32_t result = 1U;
    for (uint32_t i = 2U; i <= n; i++) {
        result *= i;
    }
    return result;
}
```

## Bounded Loops

### Rationale
Unbounded loops can hang the system. All loops must have provable termination.

### Rule
All loops must have a fixed maximum iteration count.

```c
// VIOLATION
while (data_available()) {  // Unbounded
    process_data();
}

// COMPLIANT
#define MAX_ITERATIONS 1000U
uint16_t count = 0U;
while (data_available() && (count < MAX_ITERATIONS)) {
    process_data();
    count++;
}
```

## Defensive Programming

### Range Checks

```c
// Always check inputs
void set_motor_speed(uint8_t speed_percent) {
    if (speed_percent <= 100U) {
        motor_pwm = (uint16_t)(speed_percent * 10U);
    } else {
        // Handle error
        set_dtc(DTC_INVALID_PARAMETER);
    }
}
```

### Plausibility Checks

```c
// Redundant sensor comparison
void read_temperature(void) {
    int16_t temp1 = read_sensor1();
    int16_t temp2 = read_sensor2();
    
    if (abs(temp1 - temp2) < PLAUSIBILITY_THRESHOLD) {
        temperature = (temp1 + temp2) / 2;
    } else {
        // Sensor mismatch fault
        set_dtc(DTC_SENSOR_PLAUSIBILITY);
    }
}
```

## Fail-Safe Design

### Safe State Transitions

```c
void enter_safe_state(void) {
    disable_motors();
    apply_brakes();
    cut_power_to_actuators();
    set_dtc(DTC_SAFE_STATE_ENTERED);
}
```

## References

- ISO 26262-6:2018 Annex B (Software safety analysis)
- ISO 26262-6:2018 Table 1 (Software architectural design)
- MISRA C:2012 (Coding standard for safety-critical systems)
