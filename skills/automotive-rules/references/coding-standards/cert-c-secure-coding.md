# CERT C Secure Coding Standard Rules

CERT C Secure Coding Standard provides rules to eliminate undefined behavior, prevent common vulnerabilities, and improve security in C code.

## Purpose

- Prevent buffer overflows, integer overflows, and format string vulnerabilities
- Eliminate undefined behavior that can be exploited
- Improve code security and robustness
- Complement MISRA C with security-focused rules

## Buffer Overflow Prevention

### ARR30-C: Do not form out-of-bounds pointers

```c
// VIOLATION
char buffer[10];
char *ptr = buffer + 15;  // Out of bounds pointer

// COMPLIANT
char buffer[10];
if (index < 10) {
    char *ptr = buffer + index;
}
```

### ARR38-C: Ensure array indices are within bounds

```c
// VIOLATION
void set_value(uint8_t *array, uint8_t index, uint8_t value) {
    array[index] = value;  // No bounds check
}

// COMPLIANT
void set_value(uint8_t *array, uint8_t length, uint8_t index, uint8_t value) {
    if (index < length) {
        array[index] = value;
    }
}
```

## Integer Overflow Prevention

### INT30-C: Ensure unsigned integer operations do not wrap

```c
// VIOLATION
uint16_t add(uint16_t a, uint16_t b) {
    return a + b;  // May overflow
}

// COMPLIANT
bool add_safe(uint16_t a, uint16_t b, uint16_t *result) {
    if (a > (UINT16_MAX - b)) {
        return false;  // Overflow would occur
    }
    *result = a + b;
    return true;
}
```

### INT32-C: Ensure operations on signed integers do not overflow

```c
// VIOLATION
int16_t multiply(int16_t a, int16_t b) {
    return a * b;  // Undefined behavior on overflow
}

// COMPLIANT
bool multiply_safe(int16_t a, int16_t b, int16_t *result) {
    if (a > 0) {
        if (b > 0 && a > (INT16_MAX / b)) return false;
        if (b < 0 && a > (INT16_MIN / b)) return false;
    } else {
        if (b > 0 && a < (INT16_MIN / b)) return false;
        if (b < 0 && a < (INT16_MAX / b)) return false;
    }
    *result = a * b;
    return true;
}
```

## Format String Vulnerabilities

### FIO30-C: Exclude user input from format strings

```c
// VIOLATION
void log_message(const char *user_input) {
    printf(user_input);  // Format string vulnerability
}

// COMPLIANT
void log_message(const char *user_input) {
    printf("%s", user_input);
}
```

## Memory Management

### MEM30-C: Do not access freed memory

```c
// VIOLATION
uint8_t *buffer = malloc(100);
free(buffer);
buffer[0] = 0xFF;  // Use after free

// COMPLIANT (avoid dynamic memory in automotive safety code)
uint8_t buffer[100];
buffer[0] = 0xFF;
```

### MEM34-C: Only free memory allocated dynamically

```c
// VIOLATION
uint8_t buffer[100];
free(buffer);  // Freeing stack memory

// COMPLIANT
uint8_t *buffer = malloc(100);
if (buffer != NULL) {
    free(buffer);
}
```

## References

- SEI CERT C Coding Standard
- CWE (Common Weakness Enumeration)
