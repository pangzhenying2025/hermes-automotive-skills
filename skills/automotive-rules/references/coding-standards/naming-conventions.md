# Universal Naming Conventions for Automotive Software

Consistent naming conventions improve code readability, maintainability, and collaboration across multi-language automotive projects.

## Purpose

- Establish language-specific naming standards for C, C++, Python, Java, and YAML
- Ensure consistency across embedded, backend, and infrastructure code
- Facilitate code reviews and automated tooling
- Support MISRA, AUTOSAR, and CERT coding standards

## C/C++ Naming Conventions

### Files and Modules

```c
// Header files: lowercase with hyphen separator
battery-manager.h
can-driver.h
eeprom-hal.h

// Source files: match header name
battery-manager.c
can-driver.c
eeprom-hal.c

// AUTOSAR modules: PascalCase with underscore
Adc_Cfg.h
Can_GeneralTypes.h
```

### Functions

```c
// C: snake_case for application code
uint16_t calculate_battery_voltage(uint8_t cell_index);
void update_state_machine(void);

// AUTOSAR API: Module_Function notation
Std_ReturnType Can_Write(Can_HwHandleType Hth, const Can_PduType* PduInfo);
void Adc_StartGroupConversion(Adc_GroupType Group);
```

### Variables

```c
// Local variables: snake_case
uint16_t battery_voltage_mv;
uint8_t message_count;

// Global variables: g_ prefix + snake_case (discouraged, document if necessary)
uint32_t g_system_tick_count;
bool g_watchdog_enabled;

// Member variables (C++): m_ prefix + camelCase
class BatteryMonitor {
    uint16_t m_cellVoltages[12];
    bool m_balancingActive;
};

// Static variables: s_ prefix + snake_case
static uint16_t s_calibration_offset;
```

### Constants and Macros

```c
// Preprocessor defines: UPPER_SNAKE_CASE with units
#define MAX_BATTERY_VOLTAGE_MV      4200U
#define CAN_BAUDRATE_500K           500000U
#define WATCHDOG_TIMEOUT_MS         100U

// Enum values: UPPER_SNAKE_CASE with prefix
typedef enum {
    STATE_IDLE,
    STATE_CHARGING,
    STATE_DISCHARGING,
    STATE_ERROR
} BatteryState_t;

// const variables: lowercase with k prefix (C++)
const uint16_t kMaxCellCount = 96;
const float kVoltageThreshold = 3.2f;
```

### Types

```c
// Typedef: PascalCase with _t suffix
typedef uint16_t VoltageMillivolts_t;
typedef void (*CallbackFunction_t)(void);

// Struct: PascalCase with _t suffix
typedef struct {
    uint16_t voltage_mv;
    int16_t current_ma;
    uint8_t soc_percent;
} BatteryStatus_t;

// Enum: PascalCase with _t suffix
typedef enum {
    ERROR_NONE,
    ERROR_TIMEOUT,
    ERROR_CRC
} ErrorCode_t;
```

## Python Naming Conventions

### Files and Modules

```python
# Module files: snake_case
battery_manager.py
can_parser.py
test_battery_monitor.py
```

### Classes

```python
# Classes: PascalCase
class BatteryMonitor:
    pass

class CanMessageParser:
    pass

class TestBatteryMonitor(unittest.TestCase):
    pass
```

### Functions and Methods

```python
# Functions: snake_case
def calculate_state_of_charge(voltage, current):
    pass

def parse_can_message(frame_id, data):
    pass

# Private functions: leading underscore
def _internal_helper():
    pass
```

### Variables

```python
# Variables: snake_case
battery_voltage = 3.7
cell_count = 12

# Constants: UPPER_SNAKE_CASE
MAX_CELL_VOLTAGE = 4.2
MIN_CELL_VOLTAGE = 2.5
DEFAULT_TIMEOUT_SECONDS = 30

# Private attributes: leading underscore
class BatteryMonitor:
    def __init__(self):
        self._internal_state = {}
        self.public_data = []
```

## Java Naming Conventions

### Files and Packages

```java
// Package names: lowercase, reverse domain notation
package com.automotive.battery.management;
package com.oem.vehicle.telemetry;

// Class files: match class name (PascalCase)
BatteryManager.java
CanMessageParser.java
```

### Classes and Interfaces

```java
// Classes: PascalCase
public class BatteryMonitor {
}

public class CanBusController {
}

// Interfaces: PascalCase, often with I prefix or -able suffix
public interface IBatteryMonitor {
}

public interface Serializable {
}
```

### Methods

```java
// Methods: camelCase
public int calculateStateOfCharge() {
}

public void updateBatteryStatus(int voltage, int current) {
}

// Getters/Setters: standard JavaBean convention
public int getVoltage() {
}

public void setVoltage(int voltage) {
}

// Boolean getters: is/has prefix
public boolean isCharging() {
}

public boolean hasError() {
}
```

### Variables

```java
// Local variables: camelCase
int batteryVoltage;
String messageName;

// Member variables: camelCase (no prefix)
public class BatteryMonitor {
    private int cellCount;
    private double[] voltages;
}

// Constants: UPPER_SNAKE_CASE
public static final int MAX_CELL_COUNT = 96;
public static final double VOLTAGE_THRESHOLD = 3.2;
```

## YAML Naming Conventions

### Files

```yaml
# Configuration files: kebab-case
battery-config.yaml
can-database.yaml
deployment-manifest.yaml
```

### Keys

```yaml
# Top-level keys: snake_case
battery_configuration:
  cell_count: 12
  max_voltage: 50.4

# Nested keys: snake_case
vehicle_parameters:
  battery_capacity_kwh: 75.0
  max_charging_power_kw: 150.0

# Kubernetes/Cloud resources: camelCase (follow ecosystem convention)
apiVersion: v1
kind: Pod
metadata:
  name: battery-monitor
spec:
  containers:
    - name: monitor
      image: battery-monitor:v1.2.3
```

## Cross-Language Best Practices

### Consistency Within Context

- Follow the dominant convention in each file or module
- When integrating multiple languages, maintain clear boundaries
- Document cross-language interfaces explicitly

### Abbreviations

```c
// Avoid ambiguous abbreviations
// BAD:
int tmp, cnt, val;

// GOOD:
int temporary_buffer;
int message_count;
int voltage_value;

// Well-known abbreviations acceptable:
CAN, LIN, FlexRay, UART, SPI, I2C
ECU, BMS, ADAS, OBD, VIN
ADC, PWM, DMA, GPIO
```

### Units in Names

Always include units for physical quantities:

```c
uint16_t battery_voltage_mv;        // millivolts
int16_t battery_current_ma;         // milliamperes
uint8_t battery_soc_percent;        // percentage (0-100)
uint32_t timeout_ms;                // milliseconds
float temperature_celsius;           // degrees Celsius
uint16_t speed_kmh;                 // kilometers per hour
```

### Boolean Naming

```c
// Use positive, descriptive names
bool is_charging;
bool has_error;
bool can_operate;

// Avoid negatives (harder to read when negated)
// BAD: if (!not_ready)
// GOOD: if (is_ready)
```

## Language-Specific Exceptions

### C AUTOSAR Compliance

When working with AUTOSAR Classic or Adaptive:

```c
// Follow AUTOSAR naming (Module_Function)
Std_ReturnType Adc_ReadGroup(Adc_GroupType Group, Adc_ValueGroupType* DataBufferPtr);

// Types use PascalCase without _t suffix
typedef uint8 Adc_ChannelType;
typedef uint16 Adc_ValueGroupType;
```

### C++ STL and Modern Patterns

```cpp
// STL-style for generic containers: snake_case
template<typename T>
class battery_vector {
public:
    using value_type = T;
    using iterator = T*;
};

// Application classes: PascalCase
class BatteryMonitor {
public:
    void updateVoltage(uint16_t voltage_mv);
private:
    uint16_t m_voltageMillivolts;
};
```

### Python Automotive Testing

```python
# Test functions: test_ prefix + descriptive snake_case
def test_battery_voltage_calculation_with_valid_input():
    pass

def test_can_message_parsing_handles_invalid_crc():
    pass

# Robot Framework keywords: Title Case With Spaces
*** Keywords ***
Verify Battery Voltage Is Within Range
    [Arguments]    ${expected_voltage}
    ${actual}=    Read Battery Voltage
    Should Be Equal    ${actual}    ${expected_voltage}
```

## Tooling and Enforcement

### clang-format (C/C++)

```yaml
# .clang-format
BasedOnStyle: Google
IndentWidth: 4
ColumnLimit: 100
AllowShortFunctionsOnASingleLine: Empty
PointerAlignment: Left
```

### pylint/black (Python)

```ini
# .pylintrc
[BASIC]
function-naming-style=snake_case
class-naming-style=PascalCase
const-naming-style=UPPER_CASE
```

### Checkstyle (Java)

```xml
<!-- checkstyle.xml -->
<module name="MethodName">
  <property name="format" value="^[a-z][a-zA-Z0-9]*$"/>
</module>
<module name="ConstantName">
  <property name="format" value="^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$"/>
</module>
```

## References

- MISRA C:2012 (Rule 5.1 - 5.9: Identifiers)
- AUTOSAR C++ Coding Guidelines (Rule A2-10-1: Identifiers)
- PEP 8 (Python Style Guide)
- Google Java Style Guide
- CERT C Coding Standard (DCL31-C: Declare identifiers in proper scope)
