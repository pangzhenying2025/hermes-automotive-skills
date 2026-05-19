# Concurrency Rules: Thread Safety and Lock-Free Patterns

> Rules for designing and implementing concurrent software in automotive
> ECUs, covering RTOS task synchronization, lock-free data structures,
> and deterministic multi-core communication.

## Scope

These rules apply to all multi-threaded and multi-core automotive software,
including AUTOSAR Classic/Adaptive OS tasks, POSIX threads on Linux-based
ECUs, and bare-metal multi-core microcontrollers.

---

## Core Principles

### 1. Shared Mutable State is the Root of All Concurrency Bugs

Every piece of data in the system must have exactly one of these ownership
models:

| Ownership Model | Description | Example |
|----------------|-------------|---------|
| **Thread-local** | Owned by one thread, never shared | Task-local state machine |
| **Read-only shared** | Multiple readers, no writers | Calibration tables |
| **Single-writer** | One producer, multiple consumers | Sensor data publication |
| **Mutex-protected** | Multiple readers and writers | Configuration updates |
| **Lock-free** | Atomic operations, no blocking | ISR-to-task communication |

**Rule**: Every shared data structure must have a documented ownership model
in its header comment.

```c
/* Ownership: SINGLE-WRITER (Motor Control Task)
 * Readers: Diagnostics Task, Communication Task
 * Protection: Double-buffer with atomic index swap
 * Update rate: 1 ms
 */
typedef struct {
    float torque_nm;
    float speed_rpm;
    float temperature_c;
    uint32_t timestamp_us;
} MotorState_t;
```

### 2. Prefer Lock-Free Over Locking

Lock-free data structures eliminate:
- Priority inversion
- Deadlocks
- Convoying
- Non-deterministic blocking time

Use locking only when lock-free alternatives are impractical.

### 3. No Shared State Between ASIL Partitions

Software components at different ASIL levels must not share mutable memory
directly. Use qualified communication mechanisms.

```
+------------------+         +------------------+
|   ASIL D Task    |         |   ASIL B Task    |
|  (Motor Control) |         |  (Diagnostics)   |
+--------+---------+         +--------+---------+
         |                            |
         v                            v
+--------------------------------------------------+
|     Qualified Communication Interface            |
|  (Double-buffered, CRC-protected, MPU-isolated)  |
+--------------------------------------------------+
```

---

## Lock-Free Patterns

### Pattern 1: Double Buffer (Single-Writer, Multiple-Reader)

```c
/* Double buffer for sharing data from one writer to many readers */
typedef struct {
    MotorState_t buffers[2];
    volatile uint32_t active_index;  /* 0 or 1 - updated atomically */
} DoubleBuffer_t;

static DoubleBuffer_t s_motor_state_db;

/* Writer (Motor Control Task - runs at 1 ms) */
void motor_state_publish(const MotorState_t* new_state) {
    /* Write to inactive buffer */
    const uint32_t write_index = 1U - s_motor_state_db.active_index;
    s_motor_state_db.buffers[write_index] = *new_state;

    /* Memory barrier: ensure data written before index update */
    __DMB();

    /* Atomically swap active index */
    s_motor_state_db.active_index = write_index;
}

/* Reader (any task) */
MotorState_t motor_state_read(void) {
    /* Read active index */
    const uint32_t read_index = s_motor_state_db.active_index;

    /* Memory barrier: ensure index read before data */
    __DMB();

    /* Copy from active buffer */
    return s_motor_state_db.buffers[read_index];
}
```

### Pattern 2: Lock-Free SPSC Ring Buffer

```c
/* Single-Producer Single-Consumer lock-free ring buffer
 * Used for ISR-to-task or task-to-task communication
 */
#define SPSC_BUFFER_SIZE  256U  /* Must be power of 2 */

typedef struct {
    volatile uint32_t head;  /* Modified only by producer */
    uint8_t _pad1[60];       /* Cache line padding */
    volatile uint32_t tail;  /* Modified only by consumer */
    uint8_t _pad2[60];       /* Cache line padding */
    uint8_t data[SPSC_BUFFER_SIZE];
} SpscRingBuffer_t;

bool spsc_enqueue(SpscRingBuffer_t* rb, uint8_t value) {
    const uint32_t head = rb->head;
    const uint32_t next_head = (head + 1U) & (SPSC_BUFFER_SIZE - 1U);

    if (next_head == rb->tail) {
        return false;  /* Full */
    }

    rb->data[head] = value;
    __DMB();  /* Ensure data written before head update */
    rb->head = next_head;
    return true;
}

bool spsc_dequeue(SpscRingBuffer_t* rb, uint8_t* value) {
    const uint32_t tail = rb->tail;

    if (tail == rb->head) {
        return false;  /* Empty */
    }

    *value = rb->data[tail];
    __DMB();  /* Ensure data read before tail update */
    rb->tail = (tail + 1U) & (SPSC_BUFFER_SIZE - 1U);
    return true;
}
```

### Pattern 3: Sequence Lock (Readers Favored)

```c
/* Sequence lock for data that is read frequently, written rarely.
 * Writers are mutually exclusive (single writer assumed here).
 * Readers retry if they detect a concurrent write.
 */
typedef struct {
    volatile uint32_t sequence;  /* Odd = write in progress */
    VehicleState_t data;
} SeqLock_t;

static SeqLock_t s_vehicle_state;

/* Writer (single writer only) */
void vehicle_state_write(const VehicleState_t* new_state) {
    s_vehicle_state.sequence++;     /* Odd: write started */
    __DMB();
    s_vehicle_state.data = *new_state;
    __DMB();
    s_vehicle_state.sequence++;     /* Even: write complete */
}

/* Reader (multiple readers, lock-free, wait-free) */
VehicleState_t vehicle_state_read(void) {
    VehicleState_t result;
    uint32_t seq1, seq2;

    do {
        seq1 = s_vehicle_state.sequence;
        __DMB();
        result = s_vehicle_state.data;
        __DMB();
        seq2 = s_vehicle_state.sequence;
    } while ((seq1 != seq2) || (seq1 & 1U));
    /* Retry if sequence changed or write was in progress */

    return result;
}
```

### Pattern 4: Atomic Flag for One-Shot Signaling

```c
/* Atomic flag for simple event signaling between ISR and task */
typedef struct {
    volatile uint32_t flag;
} AtomicFlag_t;

static AtomicFlag_t s_can_rx_ready = { .flag = 0U };

/* ISR: Set flag */
void CAN_RX_ISR(void) {
    /* Process hardware, copy data to buffer */
    copy_can_frame_from_hardware(&s_can_rx_buffer);

    __DMB();
    s_can_rx_ready.flag = 1U;
}

/* Task: Test and clear flag */
bool check_can_rx_ready(void) {
    if (s_can_rx_ready.flag != 0U) {
        s_can_rx_ready.flag = 0U;
        __DMB();
        return true;
    }
    return false;
}
```

---

## Locking Rules (When Locks Are Required)

### Priority Ceiling Protocol

```c
/* Mutex with immediate priority ceiling
 * Prevents priority inversion by raising task priority on acquisition
 */
typedef struct {
    volatile uint8_t locked;
    uint8_t ceiling_priority;  /* Highest priority of any user */
    uint8_t owner_original_priority;
    TaskId_t owner;
} CeilingMutex_t;

#define CEILING_MUTEX_INIT(ceiling) \
    { .locked = 0U, .ceiling_priority = (ceiling), \
      .owner_original_priority = 0U, .owner = INVALID_TASK }

/* Acquire with priority boost */
void ceiling_mutex_lock(CeilingMutex_t* mtx) {
    const TaskId_t self = os_get_current_task();
    const uint8_t orig_prio = os_get_task_priority(self);

    os_disable_preemption();
    /* Raise priority to ceiling */
    os_set_task_priority(self, mtx->ceiling_priority);
    mtx->locked = 1U;
    mtx->owner = self;
    mtx->owner_original_priority = orig_prio;
    os_enable_preemption();
}

/* Release with priority restore */
void ceiling_mutex_unlock(CeilingMutex_t* mtx) {
    os_disable_preemption();
    const uint8_t orig_prio = mtx->owner_original_priority;
    mtx->locked = 0U;
    mtx->owner = INVALID_TASK;
    os_set_task_priority(os_get_current_task(), orig_prio);
    os_enable_preemption();
}
```

### Locking Discipline

**Rule**: All mutex usage must follow these rules:

1. **Lock ordering**: Define a global lock ordering to prevent deadlocks.
   Always acquire locks in ascending order by lock ID.

```c
/* Global lock ordering - acquire in ascending order only */
typedef enum {
    LOCK_SENSOR_DATA    = 1,  /* Lowest priority */
    LOCK_MOTOR_STATE    = 2,
    LOCK_SAFETY_PARAMS  = 3,
    LOCK_NVM_ACCESS     = 4,
    LOCK_COMM_BUFFER    = 5,  /* Highest priority */
} LockOrder_t;
```

2. **Bounded hold time**: Document maximum lock hold time for each mutex.
   WCET analysis must include lock hold time.

3. **No nested locks across ASIL boundaries**: A lock in an ASIL D module
   must never be held while acquiring a lock in an ASIL B module.

4. **No locks in ISRs**: Interrupt handlers must never acquire mutexes.
   Use lock-free structures for ISR communication.

---

## Multi-Core Rules

### Core Assignment

```
+------------------+------------------+------------------+
|     Core 0       |     Core 1       |     Core 2       |
+------------------+------------------+------------------+
| Motor Control    | Battery Mgmt     | Communication    |
| Torque Coord.    | Thermal Mgmt     | Diagnostics      |
| Safety Monitor   | Cell Balancing   | HMI Updates      |
+------------------+------------------+------------------+
| ASIL D           | ASIL C           | ASIL A / QM      |
+------------------+------------------+------------------+
```

**Rule**: Core assignment must consider:
- ASIL isolation (higher ASIL on dedicated core)
- Communication affinity (minimize cross-core traffic)
- WCET isolation (prevent interference on shared resources)

### Cross-Core Communication

```c
/* Cross-core mailbox with hardware notification */
typedef struct {
    volatile uint32_t magic;       /* MAILBOX_MAGIC for integrity */
    volatile uint32_t sequence;    /* Monotonic sequence number */
    uint8_t payload[MAILBOX_PAYLOAD_SIZE];
    volatile uint32_t crc;         /* CRC32 of magic+sequence+payload */
    volatile uint32_t ready_flag;  /* Set by sender, cleared by receiver */
} CrossCoreMailbox_t;

/* Place in shared non-cached memory region */
static CrossCoreMailbox_t __attribute__((section(".shared_ram")))
    s_mailbox_core0_to_core1;

/* Send from Core 0 */
bool mailbox_send(CrossCoreMailbox_t* mb, const void* data, uint32_t len) {
    if (mb->ready_flag != 0U) {
        return false;  /* Previous message not consumed */
    }
    mb->magic = MAILBOX_MAGIC;
    mb->sequence++;
    memcpy((void*)mb->payload, data, len);
    mb->crc = crc32_compute((const uint8_t*)mb,
                             offsetof(CrossCoreMailbox_t, crc));
    __DSB();  /* Data synchronization barrier */
    mb->ready_flag = 1U;
    __SEV();  /* Send event to wake other core */
    return true;
}

/* Receive on Core 1 */
bool mailbox_receive(CrossCoreMailbox_t* mb, void* data, uint32_t len) {
    if (mb->ready_flag == 0U) {
        return false;  /* No message */
    }
    __DMB();
    /* Verify integrity */
    if (mb->magic != MAILBOX_MAGIC) {
        report_mailbox_corruption(mb);
        mb->ready_flag = 0U;
        return false;
    }
    const uint32_t expected_crc = crc32_compute(
        (const uint8_t*)mb, offsetof(CrossCoreMailbox_t, crc));
    if (mb->crc != expected_crc) {
        report_mailbox_corruption(mb);
        mb->ready_flag = 0U;
        return false;
    }
    memcpy(data, (const void*)mb->payload, len);
    __DMB();
    mb->ready_flag = 0U;  /* Acknowledge receipt */
    return true;
}
```

### Shared Resource Arbitration

```c
/* Hardware spinlock for short critical sections on multi-core */
/* WARNING: Only use for sub-microsecond operations */
#define MAX_SPINLOCK_ITERATIONS  1000U  /* Bounded to prevent livelock */

typedef struct {
    volatile uint32_t lock;  /* 0 = free, core_id + 1 = locked */
} HwSpinLock_t;

bool spinlock_try_acquire(HwSpinLock_t* sl, uint32_t core_id) {
    for (uint32_t i = 0U; i < MAX_SPINLOCK_ITERATIONS; i++) {
        uint32_t expected = 0U;
        if (__atomic_compare_exchange_n(&sl->lock, &expected,
                                         core_id + 1U, false,
                                         __ATOMIC_ACQ_REL,
                                         __ATOMIC_ACQUIRE)) {
            return true;
        }
    }
    return false;  /* Failed after bounded attempts */
}

void spinlock_release(HwSpinLock_t* sl) {
    __atomic_store_n(&sl->lock, 0U, __ATOMIC_RELEASE);
}
```

---

## Memory Ordering and Barriers

### Barrier Types

| Barrier | Use | Platform |
|---------|-----|----------|
| `__DMB()` | Data Memory Barrier - ordering guarantee | ARM Cortex |
| `__DSB()` | Data Synchronization Barrier - completion guarantee | ARM Cortex |
| `__ISB()` | Instruction Synchronization Barrier - pipeline flush | ARM Cortex |
| `__atomic_thread_fence(__ATOMIC_SEQ_CST)` | Full sequential consistency | GCC/Clang |
| `__atomic_thread_fence(__ATOMIC_ACQUIRE)` | Acquire fence (loads) | GCC/Clang |
| `__atomic_thread_fence(__ATOMIC_RELEASE)` | Release fence (stores) | GCC/Clang |

**Rule**: Use the weakest barrier that satisfies the correctness requirement:
- Acquire barrier: After reading a flag that enables data access
- Release barrier: Before writing a flag that publishes data
- Full barrier: Only when sequential consistency is required

---

## Prohibited Patterns

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `volatile` for synchronization | No ordering guarantee | Atomic operations |
| Busy-wait without bound | CPU waste, livelock | Bounded retry + fallback |
| Recursive locks | Complexity, hidden bugs | Restructure code |
| Reader-writer locks (RTOS) | Writer starvation | Sequence locks |
| Nested locks (different order) | Deadlock | Enforce global lock order |
| `sleep()` for synchronization | Non-deterministic | Event/semaphore signaling |
| Double-checked locking | Broken on most platforms | Atomic once initialization |
| Signal handlers for IPC | Race conditions | OS events/semaphores |

---

## Testing Concurrency

### Thread Sanitizer (Development Builds)

```cmake
# Enable for Linux-hosted development builds only
if(CMAKE_BUILD_TYPE STREQUAL "Debug" AND NOT CROSS_COMPILING)
    target_compile_options(${TARGET} PRIVATE -fsanitize=thread)
    target_link_options(${TARGET} PRIVATE -fsanitize=thread)
endif()
```

### Stress Testing Pattern

```c
/* Concurrent stress test for lock-free buffer */
TEST(SpscRingBuffer, StressTest_1M_Messages) {
    SpscRingBuffer_t rb = {0};
    std::atomic<bool> done{false};
    std::atomic<uint32_t> produced{0};
    std::atomic<uint32_t> consumed{0};

    /* Producer thread */
    std::thread producer([&]() {
        for (uint32_t i = 0; i < 1000000U; i++) {
            while (!spsc_enqueue(&rb, (uint8_t)(i & 0xFFU))) {
                std::this_thread::yield();
            }
            produced++;
        }
        done = true;
    });

    /* Consumer thread */
    std::thread consumer([&]() {
        uint8_t value;
        while (!done || spsc_dequeue(&rb, &value)) {
            if (spsc_dequeue(&rb, &value)) {
                consumed++;
            }
        }
    });

    producer.join();
    consumer.join();
    EXPECT_EQ(produced.load(), consumed.load());
}
```

---

## Review Checklist

- [ ] Every shared data structure has documented ownership model
- [ ] Lock-free patterns used where possible
- [ ] All mutexes use priority ceiling protocol
- [ ] Global lock ordering defined and enforced
- [ ] No locks held across ASIL boundaries
- [ ] No locks acquired in ISR context
- [ ] Memory barriers placed correctly for all shared accesses
- [ ] Cross-core communication uses CRC-protected mailboxes
- [ ] Spinlock usage bounded with maximum iteration count
- [ ] Concurrent code stress-tested with thread sanitizer
- [ ] Multi-core task assignment documented with ASIL rationale
- [ ] No use of `volatile` as sole synchronization mechanism
