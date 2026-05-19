# MISRA C/C++ - Detailed Implementation Guide

> **Target Audience**: Embedded C/C++ developers, code reviewers, static analysis engineers

## Critical MISRA C:2012 Rules with Examples

### Rule 1.3 (Required): No Undefined Behavior

There shall be no occurrence of undefined or critical unspecified behavior.

**Non-Compliant**:
```c
/* Signed integer overflow - undefined behavior */
int32_t add(int32_t a, int32_t b) {
    return a + b;  /* May overflow if a + b > INT32_MAX */
}

/* Null pointer dereference - undefined behavior */
void process(int32_t *ptr) {
    int32_t value = *ptr;  /* ptr may be NULL */
}

/* Division by zero - undefined behavior */
int32_t divide(int32_t num, int32_t den) {
    return num / den;  /* den may be zero */
}
```

**Compliant**:
```c
/* Check for overflow before operation */
int32_t add(int32_t a, int32_t b) {
    int32_t result;
    if ((b > 0) && (a > (INT32_MAX - b))) {
        result = INT32_MAX;  /* Saturate */
    } else if ((b < 0) && (a < (INT32_MIN - b))) {
        result = INT32_MIN;  /* Saturate */
    } else {
        result = a + b;
    }
    return result;
}

/* Validate pointer before use */
void process(int32_t *ptr) {
    if (ptr != NULL) {
        int32_t value = *ptr;
        /* use value */
    }
}

/* Check divisor before division */
int32_t divide(int32_t num, int32_t den) {
    int32_t result = 0;
    if (den != 0) {
        result = num / den;
    }
    return result;
}
```

### Rule 2.2 (Required): No Dead Code

There shall be no dead code (code that can never execute).

**Non-Compliant**:
```c
void function(uint32_t value) {
    if (value > 100u) {
        /* do something */
    }
    return;
    value = 0u;  /* Dead code: unreachable after return */
}

uint32_t check(uint32_t x) {
    if (x > 10u) {
        return 1u;
    } else {
        return 0u;
    }
    return 2u;  /* Dead code: unreachable */
}
```

**Compliant**:
```c
void function(uint32_t value) {
    if (value > 100u) {
        /* do something */
    }
    /* Dead code removed */
}

uint32_t check(uint32_t x) {
    uint32_t result;
    if (x > 10u) {
        result = 1u;
    } else {
        result = 0u;
    }
    return result;
}
```

### Rule 10.1 (Required): Appropriate Essential Type for Operands

Operands shall not be of an inappropriate essential type.

**Non-Compliant**:
```c
/* Boolean used in arithmetic */
_Bool flag = true;
uint32_t count = flag + 1u;  /* Non-compliant: Boolean in addition */

/* Enum used in arithmetic */
enum Color { RED, GREEN, BLUE };
enum Color c = RED;
uint32_t val = c + 1u;  /* Non-compliant: enum in addition */

/* Character used in arithmetic */
char ch = 'A';
uint32_t code = ch + 1u;  /* Non-compliant: char in addition */
```

**Compliant**:
```c
/* Use appropriate types for arithmetic */
_Bool flag = true;
uint32_t count = flag ? 2u : 1u;  /* Use conditional, not arithmetic */

/* Cast enum explicitly when needed */
enum Color { RED, GREEN, BLUE };
enum Color c = RED;
uint32_t val = (uint32_t)c + 1u;  /* Explicit cast documents intent */

/* Use unsigned for numeric operations */
uint8_t code_val = (uint8_t)'A';
uint32_t next_code = (uint32_t)code_val + 1u;
```

### Rule 10.3 (Required): No Narrowing Conversions

The value of an expression shall not be assigned to an object of a narrower essential type or of a different essential type category.

**Non-Compliant**:
```c
uint32_t wide = 1000u;
uint16_t narrow = wide;  /* Non-compliant: narrowing conversion */

int32_t signed_val = -5;
uint32_t unsigned_val = signed_val;  /* Non-compliant: sign change */

float f_val = 3.14f;
int32_t i_val = f_val;  /* Non-compliant: float to int */
```

**Compliant**:
```c
uint32_t wide = 1000u;
uint16_t narrow = (uint16_t)wide;  /* Explicit cast */

int32_t signed_val = -5;
uint32_t unsigned_val = (uint32_t)signed_val;  /* Explicit cast */

float f_val = 3.14f;
int32_t i_val = (int32_t)f_val;  /* Explicit cast */
```

### Rule 11.3 (Required): No Pointer-to-Object Type Casts

A cast shall not be performed between a pointer to object type and a pointer to a different object type.

**Non-Compliant**:
```c
uint8_t buffer[4] = {0x01, 0x02, 0x03, 0x04};
uint32_t *p32 = (uint32_t *)buffer;  /* Non-compliant: type punning */
uint32_t value = *p32;  /* Also alignment issue */
```

**Compliant**:
```c
/* Use memcpy for type punning */
uint8_t buffer[4] = {0x01, 0x02, 0x03, 0x04};
uint32_t value;
(void)memcpy(&value, buffer, sizeof(value));  /* Compliant */

/* Or use bit shifting for explicit byte assembly */
uint32_t value2 = ((uint32_t)buffer[0] << 24u) |
                   ((uint32_t)buffer[1] << 16u) |
                   ((uint32_t)buffer[2] << 8u)  |
                   ((uint32_t)buffer[3]);
```

### Rule 12.2 (Required): Shift Operators Within Range

The right-hand operand of a shift operator shall be in the range [0, bit_width - 1].

**Non-Compliant**:
```c
uint32_t a = 1u;
uint32_t b = a << 32u;  /* Non-compliant: shift equals bit width */
uint32_t c = a << -1;   /* Non-compliant: negative shift */

uint32_t shift_amount = get_shift();
uint32_t d = a << shift_amount;  /* Non-compliant if unchecked */
```

**Compliant**:
```c
uint32_t a = 1u;
uint32_t b = a << 31u;  /* Compliant: within [0, 31] */

uint32_t shift_amount = get_shift();
if (shift_amount < 32u) {
    uint32_t d = a << shift_amount;  /* Compliant: range checked */
}
```

### Rule 14.3 (Required): No Always-True/False Controlling Expressions

A controlling expression shall not be invariant.

**Non-Compliant**:
```c
if (1 == 1) {  /* Non-compliant: always true */
    do_something();
}

uint32_t x = 10u;
if (x > 5u) {  /* Non-compliant if x is provably always 10 */
    do_something();
}

while (0) {  /* Non-compliant: never executes */
    unreachable_code();
}
```

**Compliant**:
```c
/* Use compile-time configuration instead */
#if (FEATURE_ENABLED == 1u)
    do_something();
#endif

uint32_t x = get_value();
if (x > 5u) {  /* Compliant: x has variable value */
    do_something();
}
```

### Rule 15.7 (Required): All If-Else-If Chains End with Else

All if ... else if constructs shall be terminated with an else statement.

**Non-Compliant**:
```c
if (state == STATE_INIT) {
    init();
} else if (state == STATE_RUN) {
    run();
} else if (state == STATE_STOP) {
    stop();
}
/* Non-compliant: no final else */
```

**Compliant**:
```c
if (state == STATE_INIT) {
    init();
} else if (state == STATE_RUN) {
    run();
} else if (state == STATE_STOP) {
    stop();
} else {
    /* Default handler - defensive programming */
    error_handler();
}
```

### Rule 16.4 (Required): Every Switch Has a Default

Every switch statement shall have a default label.

**Non-Compliant**:
```c
switch (command) {
    case CMD_START:
        start();
        break;
    case CMD_STOP:
        stop();
        break;
    /* Non-compliant: no default */
}
```

**Compliant**:
```c
switch (command) {
    case CMD_START:
        start();
        break;
    case CMD_STOP:
        stop();
        break;
    default:
        /* Defensive: handle unexpected values */
        error_handler();
        break;
}
```

### Rule 17.7 (Required): Return Values Shall Not Be Discarded

The value returned by a function having non-void return type shall be used.

**Non-Compliant**:
```c
memcpy(dest, src, len);  /* Non-compliant: return value ignored */
printf("Hello\n");       /* Non-compliant: return value ignored */
```

**Compliant**:
```c
(void)memcpy(dest, src, len);  /* Compliant: explicit void cast */
(void)printf("Hello\n");      /* Compliant: explicit void cast */

/* Or use the return value */
int ret = snprintf(buf, sizeof(buf), "value=%d", val);
if (ret < 0) {
    error_handler();
}
```

## Critical MISRA C++:2023 Rules with Examples

### Rule 0.1.2 (Required): No Undefined Behavior

A program shall not contain instances of undefined behavior.

Same principle as MISRA C Rule 1.3 but covers C++ specific undefined behavior:

**Non-Compliant**:
```cpp
/* Use after move - undefined behavior in C++ */
std::vector<int> data = {1, 2, 3};
std::vector<int> moved = std::move(data);
int size = data.size();  /* Non-compliant: data is in moved-from state */

/* Virtual function call in constructor */
class Base {
public:
    Base() { init(); }  /* Non-compliant: calls virtual in ctor */
    virtual void init() {}
};
```

**Compliant**:
```cpp
std::vector<int> data = {1, 2, 3};
std::vector<int> moved = std::move(data);
data.clear();  /* Reset to known state before use */
int size = data.size();  /* Compliant: data is in known state (empty) */

class Base {
public:
    Base() { Base::init(); }  /* Compliant: explicit non-virtual call */
    virtual void init() {}
};
```

### Rule 6.2.1 (Required): Use Fixed-Width Integer Types

Fixed-width integer types from `<cstdint>` shall be used instead of basic integer types.

**Non-Compliant**:
```cpp
int sensor_value;          /* Non-compliant: width unknown */
unsigned int counter;      /* Non-compliant: width unknown */
long timestamp;            /* Non-compliant: width varies */
```

**Compliant**:
```cpp
int32_t sensor_value;      /* Compliant: always 32-bit signed */
uint32_t counter;          /* Compliant: always 32-bit unsigned */
int64_t timestamp;         /* Compliant: always 64-bit signed */
```

### Rule 8.2.5 (Required): No Implicit Conversions That May Lose Data

**Non-Compliant**:
```cpp
int32_t wide = 100000;
int16_t narrow = wide;    /* Non-compliant: implicit narrowing */

double pi = 3.14159;
float f_pi = pi;          /* Non-compliant: implicit precision loss */
```

**Compliant**:
```cpp
int32_t wide = 100000;
int16_t narrow = static_cast<int16_t>(wide);  /* Explicit, reviewable */

double pi = 3.14159;
float f_pi = static_cast<float>(pi);          /* Explicit conversion */
```

### Rule 15.1.3 (Required): No Raw new/delete

Dynamic memory shall not be managed using raw new and delete.

**Non-Compliant**:
```cpp
int* data = new int[100];  /* Non-compliant: raw new */
/* ... */
delete[] data;             /* Risk of forgetting, double delete, etc. */

Widget* w = new Widget();  /* Non-compliant: raw new */
```

**Compliant**:
```cpp
auto data = std::make_unique<int[]>(100);  /* Compliant: RAII */

auto w = std::make_unique<Widget>();       /* Compliant: automatic cleanup */

/* Or for shared ownership */
auto shared_w = std::make_shared<Widget>();
```

### Rule 18.3.2 (Required): No reinterpret_cast Except for Specific Cases

**Non-Compliant**:
```cpp
float f = 3.14f;
uint32_t bits = *reinterpret_cast<uint32_t*>(&f);  /* Non-compliant */
```

**Compliant**:
```cpp
float f = 3.14f;
uint32_t bits;
std::memcpy(&bits, &f, sizeof(bits));  /* Compliant: well-defined */

/* C++20 alternative (if available) */
/* uint32_t bits = std::bit_cast<uint32_t>(f); */
```

## Directive Implementation Guide

### Directive 4.1 (Required): Run-Time Failures Minimized

Run-time failures shall be minimized through:
- Bound checking on array access
- Division by zero checks
- Pointer validity checks
- Overflow prevention

**Implementation Pattern**:
```c
/* Safe array access with bounds checking */
#define ARRAY_SIZE 100u
static int32_t data[ARRAY_SIZE];

int32_t safe_array_read(uint32_t index) {
    int32_t result = 0;
    if (index < ARRAY_SIZE) {
        result = data[index];
    } else {
        /* Log error, return safe default */
        report_error(ERR_ARRAY_BOUNDS);
    }
    return result;
}

/* Safe division */
int32_t safe_divide(int32_t num, int32_t den) {
    int32_t result = 0;
    if (den == 0) {
        report_error(ERR_DIV_ZERO);
    } else if ((num == INT32_MIN) && (den == -1)) {
        /* Overflow: INT32_MIN / -1 is undefined */
        report_error(ERR_OVERFLOW);
    } else {
        result = num / den;
    }
    return result;
}
```

### Directive 4.7 (Required): Error Information Shall Be Tested

If a function returns error information, that error information shall be tested.

**Non-Compliant**:
```c
FILE *fp = fopen("config.dat", "r");
/* Non-compliant: return value not tested */
fread(buffer, 1, sizeof(buffer), fp);
```

**Compliant**:
```c
FILE *fp = fopen("config.dat", "r");
if (fp == NULL) {
    report_error(ERR_FILE_OPEN);
} else {
    size_t bytes_read = fread(buffer, 1u, sizeof(buffer), fp);
    if (bytes_read != sizeof(buffer)) {
        report_error(ERR_FILE_READ);
    }
    (void)fclose(fp);
}
```

### Directive 4.12 (Required): Dynamic Memory Allocation Shall Not Be Used

In many safety-critical systems, dynamic memory allocation after initialization is prohibited.

**Non-Compliant**:
```c
void process_message(uint32_t msg_len) {
    uint8_t *buffer = (uint8_t *)malloc(msg_len);  /* Non-compliant */
    if (buffer != NULL) {
        /* process */
        free(buffer);
    }
}
```

**Compliant**:
```c
#define MAX_MSG_LEN 256u
static uint8_t msg_buffer[MAX_MSG_LEN];

void process_message(uint32_t msg_len) {
    if (msg_len <= MAX_MSG_LEN) {
        /* Use static buffer */
        (void)memset(msg_buffer, 0, MAX_MSG_LEN);
        /* process using msg_buffer */
    } else {
        report_error(ERR_MSG_TOO_LARGE);
    }
}
```

## Common MISRA Violation Patterns and Fixes

### Pattern 1: Implicit Boolean Conversion

```c
/* Non-compliant: implicit conversion to boolean */
uint32_t flags = get_flags();
if (flags) {           /* Rule 14.4 violation */
    handle_flags();
}

/* Compliant: explicit comparison */
if (flags != 0u) {
    handle_flags();
}
```

### Pattern 2: Missing Braces in Control Structures

```c
/* Non-compliant: Rule 15.6 */
if (condition)
    do_something();

for (i = 0u; i < 10u; i++)
    process(i);

/* Compliant: always use braces */
if (condition) {
    do_something();
}

for (i = 0u; i < 10u; i++) {
    process(i);
}
```

### Pattern 3: Macro Usage

```c
/* Non-compliant: function-like macro without parentheses */
#define SQUARE(x)  x * x           /* Rule 20.7 */
uint32_t val = SQUARE(a + b);     /* Expands to: a + b * a + b */

/* Compliant: properly parenthesized, or use inline function */
#define SQUARE(x)  ((x) * (x))    /* If macro required */

static inline uint32_t square(uint32_t x) {  /* Preferred */
    return x * x;
}
```

### Pattern 4: Switch Fall-Through

```c
/* Non-compliant: Rule 16.3 - fall through */
switch (state) {
    case STATE_A:
        action_a();
        /* Falls through to STATE_B - non-compliant */
    case STATE_B:
        action_b();
        break;
    default:
        break;
}

/* Compliant: explicit break or documented intentional fall-through */
switch (state) {
    case STATE_A:
        action_a();
        break;  /* Explicit break */
    case STATE_B:
        action_b();
        break;
    default:
        break;
}
```

### Pattern 5: Pointer Arithmetic

```c
/* Non-compliant: Rule 18.4 - pointer arithmetic beyond array */
int32_t arr[10];
int32_t *p = &arr[0];
int32_t *q = p + 15;  /* Beyond array bounds */

/* Compliant: use array indexing with bounds check */
int32_t arr[10];
uint32_t index = get_index();
if (index < 10u) {
    int32_t value = arr[index];
}
```

## Static Analysis Tool Configuration

### QAC/Helix Configuration Example

```
# misra_c2012.rcf - QAC rule configuration
-rule_group misra_c_2012
-mandatory_rules enable_all
-required_rules enable_all
-advisory_rules enable_all

# Project-specific suppressions (with deviation records)
-suppress 11.3:hw_register.c  # DEV-MISRA-001
-suppress 20.5:legacy_api.h   # DEV-MISRA-002

# Warning level for advisory rules
-advisory_as_warning
```

### Polyspace Configuration Example

```matlab
% Polyspace Bug Finder configuration
-misra-c-2012-mandatory enable-all
-misra-c-2012-required enable-all
-misra-c-2012-advisory enable-all

% Specify target for implementation-defined behavior
-target x86_64
-compiler gcc
-D __GNUC__=9
```

## Next Steps

- **Level 4**: Quick reference lookup tables, rule-to-tool mapping, common violation fix patterns
- **Level 5**: Advanced CI/CD integration, tool qualification for ISO 26262, MISRA C++:2023 migration guide

## References

- MISRA C:2012 Guidelines (Rules 1-22 with rationale)
- MISRA C:2023 Guidelines (updated rules)
- MISRA C++:2023 Guidelines (C++17 rules)
- MISRA C:2012 Amendment 2 (additional rules)
- MISRA C:2012 Technical Corrigendum 2

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Embedded C/C++ developers, code reviewers, static analysis engineers
