# Dynamic Memory Management Rules for Embedded Automotive Systems

> Rules governing memory allocation, deallocation, and usage patterns
> in safety-critical embedded ECU software to prevent heap fragmentation,
> memory leaks, and non-deterministic behavior.

## Scope

These rules apply to all embedded automotive software running on
microcontrollers (Arm Cortex-M/R, Infineon AURIX, Renesas RH850) and
microprocessors (Arm Cortex-A) in safety-critical and quality-managed
applications.

---

## Fundamental Rules

### Rule 1: No Dynamic Allocation After Initialization

```c
/*
 * Three-phase memory lifecycle:
 *
 * Phase 1 - INIT:    Dynamic allocation allowed (startup, config parsing)
 * Phase 2 - RUNNING: No allocation or deallocation permitted
 * Phase 3 - SHUTDOWN: Controlled deallocation (if applicable)
 */

typedef enum {
    MEM_PHASE_INIT,
    MEM_PHASE_RUNNING,
    MEM_PHASE_SHUTDOWN
} MemPhase_t;

static volatile MemPhase_t s_mem_phase = MEM_PHASE_INIT;

/* Guard wrapper - traps allocation after init phase */
void* safe_malloc(size_t size) {
    if (s_mem_phase != MEM_PHASE_INIT) {
        /* FATAL: allocation attempted during runtime */
        safety_fault_handler(FAULT_DYNAMIC_ALLOC_RUNTIME,
                             __FILE__, __LINE__);
        return NULL;
    }
    void* ptr = malloc(size);
    if (ptr == NULL) {
        safety_fault_handler(FAULT_ALLOC_FAILED, __FILE__, __LINE__);
    }
    return ptr;
}

/* Called once after all initialization is complete */
void memory_phase_lock(void) {
    s_mem_phase = MEM_PHASE_RUNNING;
    /* Optional: poison the heap to detect violations */
    heap_write_guard_pattern();
}
```

**ASIL Applicability**:
- ASIL A/B: Dynamic allocation permitted during init phase only
- ASIL C/D: No dynamic allocation at all (fully static memory)

### Rule 2: Static Allocation is the Default

All memory must be statically allocated at compile time unless a justified
exception is documented in the safety case.

```c
/* GOOD: Static allocation - size known at compile time */
static CanFrame_t s_can_rx_buffer[CAN_RX_BUFFER_SIZE];
static SensorData_t s_sensor_data[MAX_SENSOR_COUNT];
static uint8_t s_diagnostic_log[DIAG_LOG_SIZE_BYTES];

/* BAD: Dynamic allocation - size unknown, fragmentation risk */
CanFrame_t* can_rx_buffer = malloc(config.buffer_size * sizeof(CanFrame_t));
```

### Rule 3: Memory Pool Allocation Pattern

When variable-size allocation is needed during initialization, use
memory pools with fixed-size blocks.

```c
/* Memory pool definition */
#define POOL_BLOCK_SIZE_BYTES    64U
#define POOL_BLOCK_COUNT         128U
#define POOL_TOTAL_SIZE_BYTES    (POOL_BLOCK_SIZE_BYTES * POOL_BLOCK_COUNT)

typedef struct {
    uint8_t storage[POOL_TOTAL_SIZE_BYTES];
    uint8_t usage_bitmap[POOL_BLOCK_COUNT / 8U + 1U];
    uint32_t allocated_count;
    uint32_t peak_allocated_count;
    uint32_t allocation_failures;
} MemoryPool_t;

static MemoryPool_t s_small_pool;   /* 64-byte blocks */
static MemoryPool_t s_medium_pool;  /* 256-byte blocks */
static MemoryPool_t s_large_pool;   /* 1024-byte blocks */

/* Allocate from pool - O(n) worst case but bounded */
void* pool_alloc(MemoryPool_t* pool) {
    for (uint32_t i = 0U; i < POOL_BLOCK_COUNT; i++) {
        if (!bitmap_test(pool->usage_bitmap, i)) {
            bitmap_set(pool->usage_bitmap, i);
            pool->allocated_count++;
            if (pool->allocated_count > pool->peak_allocated_count) {
                pool->peak_allocated_count = pool->allocated_count;
            }
            return &pool->storage[i * POOL_BLOCK_SIZE_BYTES];
        }
    }
    pool->allocation_failures++;
    return NULL;
}

/* Free back to pool - O(1) */
void pool_free(MemoryPool_t* pool, void* ptr) {
    const ptrdiff_t offset = (uint8_t*)ptr - pool->storage;
    if (offset < 0 || offset >= POOL_TOTAL_SIZE_BYTES) {
        safety_fault_handler(FAULT_POOL_FREE_INVALID_PTR,
                             __FILE__, __LINE__);
        return;
    }
    const uint32_t index = (uint32_t)offset / POOL_BLOCK_SIZE_BYTES;
    if (!bitmap_test(pool->usage_bitmap, index)) {
        safety_fault_handler(FAULT_POOL_DOUBLE_FREE,
                             __FILE__, __LINE__);
        return;
    }
    bitmap_clear(pool->usage_bitmap, index);
    pool->allocated_count--;
}
```

---

## Stack Management

### Stack Sizing Rules

```c
/* Stack size calculation methodology:
 *
 * 1. Analyze deepest call chain (static analysis tool or manual)
 * 2. Account for ISR stack usage (nested interrupts)
 * 3. Add 25% safety margin
 * 4. Round up to MPU alignment boundary
 *
 * Example for Motor Control Task:
 *   - Deepest call chain: 48 words (from static analysis)
 *   - Local variables max: 32 words
 *   - ISR nesting (2 levels): 24 words
 *   - Context save: 16 words
 *   - Subtotal: 120 words = 480 bytes
 *   - Safety margin (25%): 120 bytes
 *   - Total: 600 bytes -> round to 640 (MPU aligned)
 */
#define TASK_MOTOR_CONTROL_STACK_WORDS   160U  /* 640 bytes */
#define TASK_DIAGNOSTICS_STACK_WORDS     256U  /* 1024 bytes */
#define TASK_COMMUNICATION_STACK_WORDS   512U  /* 2048 bytes */

/* Stack overflow detection via MPU guard region */
#define STACK_GUARD_SIZE_BYTES   32U

/* Stack arrays placed in dedicated linker section */
static uint32_t __attribute__((section(".stack.motor_control")))
    s_motor_control_stack[TASK_MOTOR_CONTROL_STACK_WORDS];
```

### Stack Monitoring

```c
/* Paint stack with known pattern at startup */
void stack_paint(uint32_t* stack_base, uint32_t size_words) {
    for (uint32_t i = 0U; i < size_words; i++) {
        stack_base[i] = STACK_PAINT_PATTERN;
    }
}

/* Measure stack usage (call periodically from background task) */
uint32_t stack_get_usage_words(const uint32_t* stack_base,
                                uint32_t size_words) {
    uint32_t unused = 0U;
    for (uint32_t i = 0U; i < size_words; i++) {
        if (stack_base[i] != STACK_PAINT_PATTERN) {
            break;
        }
        unused++;
    }
    return size_words - unused;
}

/* Trigger alarm if stack usage exceeds 75% */
void stack_check_all_tasks(void) {
    for (uint32_t t = 0U; t < TASK_COUNT; t++) {
        const uint32_t usage = stack_get_usage_words(
            task_configs[t].stack_base,
            task_configs[t].stack_size_words);
        const uint32_t usage_percent =
            (usage * 100U) / task_configs[t].stack_size_words;
        if (usage_percent > 75U) {
            report_stack_warning(t, usage_percent);
        }
        if (usage_percent > 90U) {
            report_stack_critical(t, usage_percent);
        }
    }
}
```

---

## Buffer Management

### Bounded Buffers

```c
/* All buffers must have compile-time bounds */
#define CAN_MSG_BUFFER_SIZE    64U
#define UART_TX_BUFFER_SIZE   256U
#define DIAG_LOG_ENTRIES       100U

/* Bounds-checked buffer access */
typedef struct {
    uint8_t data[CAN_MSG_BUFFER_SIZE];
    uint32_t length;
    uint32_t capacity;
} BoundedBuffer_t;

bool buffer_write(BoundedBuffer_t* buf, const uint8_t* src, uint32_t len) {
    if (buf->length + len > buf->capacity) {
        return false;  /* Would overflow - reject */
    }
    memcpy(&buf->data[buf->length], src, len);
    buf->length += len;
    return true;
}

/* NEVER use unbounded string functions */
/* BAD:  strcpy(dest, src);            */
/* BAD:  sprintf(buf, "%s", input);    */
/* GOOD: strncpy(dest, src, sizeof(dest) - 1U); dest[sizeof(dest)-1] = '\0'; */
/* GOOD: snprintf(buf, sizeof(buf), "%s", input); */
```

### Ring Buffers for Producer-Consumer

```c
/* Power-of-2 sized ring buffer for efficient modulo */
#define RING_BUFFER_SIZE  256U  /* Must be power of 2 */
_Static_assert((RING_BUFFER_SIZE & (RING_BUFFER_SIZE - 1U)) == 0U,
               "Ring buffer size must be power of 2");

typedef struct {
    uint8_t data[RING_BUFFER_SIZE];
    volatile uint32_t head;  /* Write position (producer only) */
    volatile uint32_t tail;  /* Read position (consumer only) */
} RingBuffer_t;

static inline uint32_t ring_count(const RingBuffer_t* rb) {
    return (rb->head - rb->tail) & (RING_BUFFER_SIZE - 1U);
}

static inline uint32_t ring_free(const RingBuffer_t* rb) {
    return (RING_BUFFER_SIZE - 1U) - ring_count(rb);
}

bool ring_enqueue(RingBuffer_t* rb, uint8_t byte) {
    if (ring_free(rb) == 0U) {
        return false;
    }
    rb->data[rb->head & (RING_BUFFER_SIZE - 1U)] = byte;
    __DMB();  /* Memory barrier before updating head */
    rb->head++;
    return true;
}

bool ring_dequeue(RingBuffer_t* rb, uint8_t* byte) {
    if (ring_count(rb) == 0U) {
        return false;
    }
    *byte = rb->data[rb->tail & (RING_BUFFER_SIZE - 1U)];
    __DMB();  /* Memory barrier before updating tail */
    rb->tail++;
    return true;
}
```

---

## Memory Protection

### MPU Configuration

```c
/* MPU region configuration for memory isolation */
typedef struct {
    uint32_t base_address;
    uint32_t size_bytes;
    uint32_t access_permissions;
    uint32_t attributes;
} MpuRegion_t;

/* Safety-critical data regions */
static const MpuRegion_t s_mpu_config[] = {
    /* Region 0: Flash (code) - Read/Execute only */
    { .base_address = FLASH_BASE,
      .size_bytes = FLASH_SIZE,
      .access_permissions = MPU_AP_RO,
      .attributes = MPU_ATTR_NORMAL_CACHED },

    /* Region 1: Safety RAM - Privileged R/W only */
    { .base_address = SAFETY_RAM_BASE,
      .size_bytes = SAFETY_RAM_SIZE,
      .access_permissions = MPU_AP_PRIV_RW,
      .attributes = MPU_ATTR_NORMAL_NON_CACHED },

    /* Region 2: Peripheral registers - Privileged R/W, device memory */
    { .base_address = PERIPH_BASE,
      .size_bytes = PERIPH_SIZE,
      .access_permissions = MPU_AP_PRIV_RW,
      .attributes = MPU_ATTR_DEVICE },

    /* Region 3: Stack guard - No access (trap on overflow) */
    { .base_address = STACK_GUARD_BASE,
      .size_bytes = STACK_GUARD_SIZE_BYTES,
      .access_permissions = MPU_AP_NONE,
      .attributes = MPU_ATTR_NORMAL_NON_CACHED },
};
```

### Memory Corruption Detection

```c
/* CRC-protected critical data structures */
typedef struct {
    float target_torque_nm;
    float max_current_a;
    float voltage_limit_v;
    uint16_t safety_flags;
    uint16_t _padding;
    uint32_t crc32;  /* CRC of all fields above */
} SafetyParams_t;

/* Verify data integrity before use */
bool safety_params_verify(const SafetyParams_t* params) {
    const uint32_t computed_crc = crc32_compute(
        (const uint8_t*)params,
        sizeof(SafetyParams_t) - sizeof(uint32_t));
    return computed_crc == params->crc32;
}

/* Update CRC after modifying safety parameters */
void safety_params_update_crc(SafetyParams_t* params) {
    params->crc32 = crc32_compute(
        (const uint8_t*)params,
        sizeof(SafetyParams_t) - sizeof(uint32_t));
}

/* Double storage for critical variables */
static SafetyParams_t s_safety_params_primary;
static SafetyParams_t s_safety_params_mirror;

bool safety_params_read(SafetyParams_t* out) {
    const bool primary_ok = safety_params_verify(&s_safety_params_primary);
    const bool mirror_ok = safety_params_verify(&s_safety_params_mirror);

    if (primary_ok && mirror_ok) {
        if (memcmp(&s_safety_params_primary, &s_safety_params_mirror,
                   sizeof(SafetyParams_t)) == 0) {
            *out = s_safety_params_primary;
            return true;
        }
    }
    if (primary_ok) {
        *out = s_safety_params_primary;
        s_safety_params_mirror = s_safety_params_primary;
        return true;
    }
    if (mirror_ok) {
        *out = s_safety_params_mirror;
        s_safety_params_primary = s_safety_params_mirror;
        return true;
    }
    /* Both corrupted - enter safe state */
    return false;
}
```

---

## Prohibited Patterns

| Pattern | Risk | MISRA Rule | Alternative |
|---------|------|-----------|-------------|
| `malloc`/`free` at runtime | Fragmentation | Rule 21.3 | Static alloc or pool |
| `realloc` | Non-deterministic | Rule 21.3 | Fixed-size buffers |
| VLA (variable-length arrays) | Stack overflow | Rule 18.8 | Fixed arrays |
| `alloca` | Stack overflow | N/A | Static buffers |
| `memcpy` without bounds | Buffer overflow | Rule 21.18 | Bounded copy |
| Cast `void*` without check | Type confusion | Rule 11.5 | Typed pools |
| Pointer arithmetic | Buffer overflow | Rules 18.1-4 | Array indexing |
| Uninitialized variables | Undefined behavior | Rule 9.1 | Initialize all |
| Union type punning | Undefined behavior | Rule 19.2 | `memcpy` or bitfields |
| Flexible array members | Unbounded size | Rule 18.7 | Fixed-size arrays |

---

## Memory Layout Documentation

Every project must document its memory layout:

```
+----------------------------------+ 0x0000_0000
|  Interrupt Vector Table (IVT)    | 1 KB
+----------------------------------+ 0x0000_0400
|  Bootloader (read-only)          | 32 KB
+----------------------------------+ 0x0000_8400
|  Application Code (Flash)        | 448 KB
+----------------------------------+ 0x0007_8400
|  Calibration Data (Flash)        | 16 KB
+----------------------------------+ 0x0007_C400
|  NVM Emulation (Flash)           | 16 KB
+----------------------------------+ 0x0008_0000
                                    End of Flash

+----------------------------------+ 0x2000_0000
|  Safety RAM (MPU protected)      | 8 KB
+----------------------------------+ 0x2000_2000
|  Application Data (.bss + .data) | 48 KB
+----------------------------------+ 0x2000_E000
|  Memory Pools                    | 16 KB
+----------------------------------+ 0x2001_2000
|  Task Stacks (painted)           | 8 KB
+----------------------------------+ 0x2001_4000
|  ISR Stack                       | 2 KB
+----------------------------------+ 0x2001_4800
|  Stack Guard (MPU: no access)    | 256 bytes
+----------------------------------+ 0x2001_4900
|  DMA Buffers (non-cached)        | 4 KB
+----------------------------------+ 0x2001_5900
|  Reserved                        | remaining
+----------------------------------+ 0x2002_0000
                                    End of RAM (128 KB)
```

---

## Review Checklist

- [ ] No dynamic allocation after initialization phase
- [ ] All buffers have compile-time bounds with static assertions
- [ ] Stack sizes determined by analysis with 25% margin
- [ ] Stack painting and monitoring active for all tasks
- [ ] Ring buffers use power-of-2 sizes
- [ ] Memory pools used instead of heap for variable-size blocks
- [ ] MPU configured to isolate safety-critical memory
- [ ] Critical data protected by CRC and double storage
- [ ] Memory layout documented with linker script validation
- [ ] All string operations use bounded variants
- [ ] No pointer arithmetic outside of approved patterns
- [ ] Memory usage report generated and reviewed each release
