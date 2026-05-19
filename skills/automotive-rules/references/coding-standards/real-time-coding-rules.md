# Real-Time Coding Rules for Deterministic Automotive Systems

> Rules for writing deterministic, timing-predictable code in hard real-time
> automotive systems including powertrain, chassis, and ADAS controllers.

## Scope

These rules apply to all software executing on real-time operating systems
(RTOS) or bare-metal platforms in automotive ECUs where timing deadlines
must be met every cycle without exception.

## Definitions

| Term | Definition |
|------|-----------|
| WCET | Worst-Case Execution Time - maximum time a code path can take |
| Jitter | Variation in execution time between cycles |
| Deadline | Absolute time by which a computation must complete |
| Period | Fixed interval between task activations |
| Slack | Time remaining between task completion and deadline |
| Priority Inversion | Lower-priority task blocking higher-priority task |

---

## Task Architecture

### Task Classification

All real-time tasks must be classified and documented:

```
+------------------+----------+-----------+------------------+
| Task Class       | Period   | Deadline  | Example          |
+------------------+----------+-----------+------------------+
| Fast Cyclic      | 1-5 ms   | = Period  | Motor control    |
| Medium Cyclic    | 10-20 ms | = Period  | Torque request   |
| Slow Cyclic      | 50-100ms | = Period  | Diagnostics      |
| Event-Driven     | Aperiodic| 10-50 ms  | CAN message Rx   |
| Background       | N/A      | None      | Logging, NVM     |
+------------------+----------+-----------+------------------+
```

### Task Structure Template

```c
/* Task: Motor Control Loop
 * Period: 1 ms
 * WCET Budget: 400 us
 * ASIL: D
 * Priority: HIGHEST (configurable in OS config)
 */
void Task_MotorControl_1ms(void) {
    /* Phase 1: Input Acquisition (Budget: 50 us) */
    const SensorData_t sensors = acquire_sensor_data();

    /* Phase 2: Computation (Budget: 250 us) */
    const ControlOutput_t output = compute_motor_control(
        &sensors, &g_motor_state);

    /* Phase 3: Output Application (Budget: 50 us) */
    apply_motor_output(&output);

    /* Phase 4: Monitoring (Budget: 50 us) */
    update_timing_monitor(TASK_MOTOR_CONTROL);
}
```

**Rule**: Every task function must:
- Document its period, WCET budget, ASIL rating, and priority
- Be structured into named phases with individual budgets
- Complete within its WCET budget in all execution paths
- Call the timing monitor at the end of each cycle

---

## Timing Rules

### WCET Analysis Requirements

| ASIL Level | WCET Method Required | Tool Support |
|------------|---------------------|--------------|
| ASIL A | Measurement-based | Trace tools |
| ASIL B | Measurement + static analysis | Trace + aiT/Bound-T |
| ASIL C | Static analysis required | aiT/Bound-T/Chronos |
| ASIL D | Static analysis + formal proof | aiT + manual review |

### Execution Time Budgets

```c
/* WCET budget allocation - must sum to less than period */
#define TASK_PERIOD_US              1000U    /* 1 ms */
#define BUDGET_INPUT_ACQUIRE_US      100U
#define BUDGET_COMPUTATION_US        500U
#define BUDGET_OUTPUT_APPLY_US       100U
#define BUDGET_MONITORING_US          50U
#define BUDGET_OS_OVERHEAD_US        100U
#define BUDGET_MARGIN_US             150U    /* 15% safety margin */

/* Static assertion: budgets must not exceed period */
_Static_assert(
    (BUDGET_INPUT_ACQUIRE_US + BUDGET_COMPUTATION_US +
     BUDGET_OUTPUT_APPLY_US + BUDGET_MONITORING_US +
     BUDGET_OS_OVERHEAD_US + BUDGET_MARGIN_US) <= TASK_PERIOD_US,
    "WCET budget exceeds task period");
```

**Rule**: WCET budgets must:
- Be documented for every task and sub-phase
- Include OS overhead (context switch, ISR latency)
- Include a minimum 15% safety margin for ASIL C/D
- Be verified by measurement or static analysis before release
- Be checked by static assertion at compile time

### Prohibited Time-Unbounded Operations

The following operations are prohibited in real-time tasks:

| Operation | Reason | Alternative |
|-----------|--------|-------------|
| `malloc` / `free` | Unbounded fragmentation | Static allocation |
| `printf` / `sprintf` | Unbounded string formatting | Fixed-format logging |
| Recursive functions | Unbounded stack growth | Iterative with bounds |
| Unbounded loops | WCET cannot be determined | Bounded loop with max |
| Mutex with unbounded wait | Priority inversion | Priority ceiling protocol |
| Dynamic dispatch (vtable) | Cache-dependent timing | Static dispatch |
| Floating-point (no FPU) | Software emulation time | Fixed-point arithmetic |
| Exception handling (C++) | Unwinding time unbounded | Error codes / Result types |
| `std::string` operations | Dynamic allocation | Fixed char arrays |
| STL containers | Allocator-dependent | Static arrays, ring buffers |

---

## Memory Rules for Real-Time

### Stack Sizing

```c
/* Stack size calculation for each task */
#define MOTOR_CONTROL_STACK_WORDS   512U   /* Verified by stack analysis */
#define MOTOR_CONTROL_STACK_GUARD    64U   /* Guard region (painted) */

/* Stack painting pattern for runtime monitoring */
#define STACK_PAINT_PATTERN  0xDEADBEEFU

/* Runtime stack usage check */
uint32_t get_stack_usage_percent(TaskHandle_t task) {
    const uint32_t high_water = uxTaskGetStackHighWaterMark(task);
    const uint32_t total = get_task_stack_size(task);
    return ((total - high_water) * 100U) / total;
}
```

**Rule**: Stack must be:
- Statically sized based on worst-case call depth analysis
- Painted with a known pattern for runtime monitoring
- Monitored every cycle with alarm at 80% usage
- Sized with 25% margin above measured worst case

### Static Memory Allocation

```c
/* All buffers statically allocated at file scope */
static SensorData_t s_sensor_buffer[SENSOR_BUFFER_SIZE];
static uint32_t s_sensor_write_index;
static uint32_t s_sensor_read_index;

/* Ring buffer with compile-time size validation */
_Static_assert(SENSOR_BUFFER_SIZE > 0U, "Buffer size must be positive");
_Static_assert((SENSOR_BUFFER_SIZE & (SENSOR_BUFFER_SIZE - 1U)) == 0U,
               "Buffer size must be power of 2 for efficient modulo");
```

---

## Interrupt Handling

### ISR Rules

```c
/* ISR: CAN Receive Interrupt
 * Max Duration: 10 us
 * Nesting: Disabled
 */
ISR(CAN0_RX_IRQHandler) {
    /* Rule: ISRs must be minimal - copy data and defer processing */
    const CanFrame_t frame = CAN0_read_hardware_buffer();

    /* Use lock-free ring buffer for ISR-to-task communication */
    const bool enqueued = ringbuf_try_enqueue(&g_can_rx_buffer, &frame);
    if (!enqueued) {
        increment_atomic(&g_can_rx_overflow_count);
    }

    /* Signal the processing task */
    os_event_set(EVENT_CAN_RX_READY);
}
```

**Rule**: Interrupt service routines must:
- Complete within documented maximum duration
- Never call blocking OS functions
- Use only lock-free data structures for communication
- Defer all processing to task context
- Never disable interrupts for more than the documented budget
- Be documented with maximum duration and nesting policy

### Interrupt Latency Budget

```
+-------------------------------------------+
| Interrupt Response Time Budget            |
+-------------------------------------------+
| Hardware latency:        0.5 us           |
| Vector fetch + pipeline: 1.0 us           |
| ISR prologue:            0.5 us           |
| ISR body (max):          5.0 us           |
| ISR epilogue:            0.5 us           |
| Context switch (worst):  3.0 us           |
+-------------------------------------------+
| Total budget:           10.5 us           |
+-------------------------------------------+
```

---

## Synchronization Patterns

### Lock-Free Communication (Preferred)

```c
/* Lock-free single-producer single-consumer ring buffer */
typedef struct {
    volatile uint32_t write_index;  /* Only modified by producer */
    volatile uint32_t read_index;   /* Only modified by consumer */
    uint8_t buffer[RING_BUFFER_SIZE];
    uint32_t element_size;
} LockFreeRingBuffer_t;

bool ringbuf_try_enqueue(LockFreeRingBuffer_t* rb, const void* data) {
    const uint32_t next = (rb->write_index + 1U) & (RING_BUFFER_SIZE - 1U);
    if (next == rb->read_index) {
        return false;  /* Buffer full - never block */
    }
    memcpy(&rb->buffer[rb->write_index * rb->element_size],
           data, rb->element_size);
    __DMB();  /* Data memory barrier before publishing index */
    rb->write_index = next;
    return true;
}
```

### Priority Ceiling Protocol (When Locking Required)

```c
/* Mutex with priority ceiling - prevents priority inversion */
#define MOTOR_DATA_MUTEX_CEILING  PRIORITY_MOTOR_CONTROL

os_mutex_t g_motor_data_mutex = OS_MUTEX_INIT(MOTOR_DATA_MUTEX_CEILING);

void update_motor_data(const MotorData_t* new_data) {
    /* Ceiling protocol: task priority raised to ceiling on acquire */
    os_mutex_lock(&g_motor_data_mutex);  /* Bounded wait time */
    g_motor_data = *new_data;
    os_mutex_unlock(&g_motor_data_mutex);
}
```

**Rule**: Synchronization hierarchy:
1. **Prefer**: Lock-free structures (ring buffers, double buffering)
2. **Acceptable**: Priority ceiling mutexes with bounded hold time
3. **Avoid**: Standard mutexes (priority inversion risk)
4. **Prohibited**: Spinlocks, unbounded waits, nested locks

---

## Fixed-Point Arithmetic

When hardware FPU is unavailable or for ASIL D determinism:

```c
/* Fixed-point type: Q16.16 format */
typedef int32_t fixed16_t;
#define FIXED16_SHIFT       16
#define FIXED16_ONE         (1 << FIXED16_SHIFT)
#define FIXED16_HALF        (1 << (FIXED16_SHIFT - 1))

/* Convert float to fixed (compile-time only) */
#define FLOAT_TO_FIXED16(f)  ((fixed16_t)((f) * FIXED16_ONE))

/* Multiply with overflow protection */
static inline fixed16_t fixed16_mul(fixed16_t a, fixed16_t b) {
    const int64_t result = (int64_t)a * (int64_t)b;
    return (fixed16_t)((result + FIXED16_HALF) >> FIXED16_SHIFT);
}

/* Division with zero check */
static inline fixed16_t fixed16_div(fixed16_t a, fixed16_t b) {
    if (b == 0) {
        return (a >= 0) ? INT32_MAX : INT32_MIN;  /* Saturate on div-by-zero */
    }
    const int64_t temp = ((int64_t)a << FIXED16_SHIFT) + (b >> 1);
    return (fixed16_t)(temp / b);
}
```

---

## Timing Monitoring

### Runtime Deadline Monitor

```c
typedef struct {
    uint32_t task_id;
    uint32_t period_us;
    uint32_t wcet_budget_us;
    uint32_t max_observed_us;
    uint32_t min_observed_us;
    uint32_t deadline_miss_count;
    uint32_t execution_count;
} TaskTimingStats_t;

static TaskTimingStats_t s_timing_stats[MAX_TASK_COUNT];

void timing_monitor_start(uint32_t task_id) {
    s_timing_stats[task_id].start_tick = hw_timer_get_ticks();
}

void timing_monitor_end(uint32_t task_id) {
    const uint32_t elapsed = hw_timer_elapsed_us(
        s_timing_stats[task_id].start_tick);
    TaskTimingStats_t* stats = &s_timing_stats[task_id];

    stats->execution_count++;
    if (elapsed > stats->max_observed_us) {
        stats->max_observed_us = elapsed;
    }
    if (elapsed < stats->min_observed_us || stats->min_observed_us == 0U) {
        stats->min_observed_us = elapsed;
    }
    if (elapsed > stats->wcet_budget_us) {
        stats->deadline_miss_count++;
        report_timing_violation(task_id, elapsed, stats->wcet_budget_us);
    }
}
```

---

## Scheduling Rules

### Rate Monotonic Scheduling

- Assign priorities based on period: shorter period = higher priority
- Verify schedulability: sum of (WCET/Period) for all tasks must be < ln(2) * n
- Document the complete task table in the safety manual

### Task Table Documentation

```
+-----+-------------------+--------+--------+------+-------+
| Pri | Task Name         | Period | WCET   | ASIL | CPU%  |
+-----+-------------------+--------+--------+------+-------+
|  1  | MotorControl      | 1 ms   | 400 us | D    | 40.0% |
|  2  | TorqueCoordinator | 5 ms   | 800 us | C    | 16.0% |
|  3  | VehicleDynamics   | 10 ms  | 2 ms   | B    | 20.0% |
|  4  | Diagnostics       | 100 ms | 5 ms   | A    | 5.0%  |
|  5  | Communication     | 10 ms  | 1 ms   | B    | 10.0% |
|  -  | Background/Idle   | N/A    | N/A    | QM   | 9.0%  |
+-----+-------------------+--------+--------+------+-------+
| Total CPU utilization:                           | 91.0% |
+-----+-------------------+--------+--------+------+-------+
```

**Rule**: Total CPU utilization must not exceed:
- 90% for ASIL A/B systems
- 80% for ASIL C/D systems
- Remaining capacity reserved for OS overhead and safety margin

---

## Review Checklist

- [ ] All tasks have documented period, WCET, ASIL, and priority
- [ ] WCET budgets verified by analysis or measurement
- [ ] No dynamic memory allocation in real-time tasks
- [ ] No unbounded loops or recursion
- [ ] All ISRs complete within documented budget
- [ ] Lock-free structures used for ISR-to-task communication
- [ ] Stack sizes verified with 25% margin
- [ ] CPU utilization within ASIL-appropriate limits
- [ ] Timing monitor active for all real-time tasks
- [ ] Fixed-point arithmetic used where FPU unavailable
- [ ] Priority ceiling protocol used for all shared resources
- [ ] Task table documented and reviewed in safety case
