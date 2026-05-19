# Embedded C Best Practices for Automotive ECUs

Best practices for writing robust, maintainable embedded C code for automotive ECUs.

## Register Access

### Memory-Mapped Peripherals

```c
// Define register addresses
#define CAN_BASE_ADDR       ((uint32_t)0x40006400U)
#define CAN_MCR             (*((volatile uint32_t *)(CAN_BASE_ADDR + 0x00U)))
#define CAN_MSR             (*((volatile uint32_t *)(CAN_BASE_ADDR + 0x04U)))

// Access with volatile qualifier
void can_init(void) {
    CAN_MCR = 0x00000001U;  // Set INRQ bit
    while ((CAN_MSR & 0x01U) == 0U) {
        // Wait for INAK
    }
}
```

### Bit Manipulation

```c
// Use bit masks and shifts
#define CAN_MCR_INRQ_Pos    (0U)
#define CAN_MCR_INRQ_Msk    (0x1UL << CAN_MCR_INRQ_Pos)
#define CAN_MCR_SLEEP_Pos   (1U)
#define CAN_MCR_SLEEP_Msk   (0x1UL << CAN_MCR_SLEEP_Pos)

void can_request_init(void) {
    CAN_MCR |= CAN_MCR_INRQ_Msk;
}

void can_clear_sleep(void) {
    CAN_MCR &= ~CAN_MCR_SLEEP_Msk;
}
```

## Volatile Usage

### When to Use volatile

```c
// Hardware registers (always)
volatile uint32_t *GPIO_IDR = (volatile uint32_t *)0x40020010;

// Variables modified by interrupts
volatile uint32_t g_system_tick_ms;

// Variables shared between tasks (with mutex)
volatile bool g_data_ready;
```

## Interrupt Service Routines (ISR)

### ISR Design

```c
// Keep ISR short and fast
void CAN_RX_IRQHandler(void) {
    // Read CAN data
    uint32_t data = CAN_RDT0R;
    
    // Set flag for main loop processing
    g_can_message_pending = true;
    
    // Clear interrupt flag
    CAN_RF0R |= CAN_RF0R_RFOM0;
}

// Process in main loop
void main_loop(void) {
    if (g_can_message_pending) {
        process_can_message();
        g_can_message_pending = false;
    }
}
```

## Stack Sizing

### Static Analysis

```c
// Document maximum stack usage
// Stack usage: 512 bytes (measured with -fstack-usage)
void deep_call_chain(void) {
    uint8_t buffer[256];  // 256 bytes
    nested_function(buffer);  // +128 bytes
}
```

## Watchdog Handling

### Watchdog Refresh

```c
#define WATCHDOG_TIMEOUT_MS     100U

void watchdog_task(void) {
    static uint32_t last_refresh_ms = 0U;
    
    uint32_t now_ms = get_system_tick_ms();
    if ((now_ms - last_refresh_ms) >= (WATCHDOG_TIMEOUT_MS / 2U)) {
        refresh_watchdog();
        last_refresh_ms = now_ms;
    }
}
```

## References

- MISRA C:2012 (Embedded systems coding standard)
- AUTOSAR C++ Coding Guidelines (Embedded patterns)
- Jack Ganssle's Embedded Systems Best Practices
