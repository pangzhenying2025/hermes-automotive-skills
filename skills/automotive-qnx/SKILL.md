---
name: automotive-qnx
description: >
  Advanced QNX Neutrino RTOS development patterns for automotive applications Covers 2 topics across qnx domain. Includes 2 skill files covering .
tags: [automotive, automotive-qnx, microkernel, neutrino, posix, qnx, rtos]
---

# Automotive Qnx

2 skill files covering qnx domain for automotive software engineering.


## Instructions

### qnx-advanced

## Advanced QNX Neutrino RTOS Development Guide

### Overview

QNX Neutrino is a POSIX-compliant, microkernel-based RTOS widely used in
safety-critical automotive systems (ADAS, digital cockpits, gateways). Its
microkernel architecture runs device drivers and file systems as user-space
processes, providing fault isolation that is essential for ISO 26262 compliance.
QNX is pre-certified to IEC 61508 SIL 3, making it suitable for ASIL-D
automotive applications.

### Microkernel Architecture

```
User Space:
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ App:ADAS │ │ App:Diag │ │ Driver:  │ │ Driver:  │ │  File    │
│ Control  │ │ Service  │ │ CAN      │ │ Ethernet │ │  System  │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │            │            │
═════╪════════════╪════════════╪════════════╪════════════╪════════
     │       Message Passing (MsgSend/MsgReceive/MsgReply)
═════╪════════════╪════════════╪════════════╪════════════╪════════
     │            │            │            │            │
┌────┴────────────┴────────────┴────────────┴────────────┴────┐
│                    QNX Neutrino Microkernel                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Threads  │ │ Signals  │ │ Timers   │ │ Interrupt│       │
│  │ Scheduling│ │ Sync     │ │ Clock    │ │ Dispatch │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### IPC Mechanisms

QNX provides several IPC mechanisms, each suited for different use cases:

| Mechanism | Latency | Data Size | Blocking | Use Case |
|-----------|---------|-----------|----------|----------|
| Messages | ~1-5 us | Arbitrary | Synchronous | Client-server communication |
| Pulses | ~0.5 us | 32-bit value | Asynchronous | Event notification, ISR to thread |
| Shared Memory | ~0 (direct) | Arbitrary | None (needs sync) | Large data (sensor, video) |
| Signals | ~1 us | Signal number | Asynchronous | Legacy POSIX compatibility |

### Message Passing Model

QNX message passing is synchronous and forms the basis of the entire OS:

```
Client                    Server
  │                         │
  │  MsgSend(coid, ...)     │
  ├────────────────────────►│ MsgReceive(chid, ...)
  │     (client BLOCKED)    │
  │                         │ Process request...
  │  MsgReply(rcvid, ...)   │
  │◄────────────────────────┤
  │  (client UNBLOCKED)     │
```

The three-phase send-receive-reply protocol ensures that:
1. The client knows the server received the message (no lost messages)
2. The server knows which client to reply to (rcvid)
3. Priority inheritance is automatic (server runs at client priority)

### Pulses for Asynchronous Notification

Pulses are lightweight (40-byte), non-blocking notifications ideal for:
- Interrupt service routines notifying handler threads
- Timer expiration events
- Asynchronous event signaling between processes

Pulse codes from `_PULSE_CODE_MINAVAIL` to `_PULSE_CODE_MAXAVAIL` are
available for application use. System pulses use codes below MINAVAIL.

### Resource Manager Framework

Resource managers are QNX's device driver framework. Any process can register
a pathname (e.g., `/dev/can0`) and handle POSIX I/O operations:

- `open()` -> `io_open` handler
- `read()` -> `io_read` handler
- `write()` -> `io_write` handler
- `devctl()` -> `io_devctl` handler (ioctl equivalent)
- `close()` -> `io_close` handler

This allows applications to interact with custom hardware using standard
POSIX file operations, simplifying application-level code.

### Thread Scheduling

QNX supports three POSIX scheduling policies:

| Policy | Behavior | Use Case |
|--------|----------|----------|
| SCHED_FIFO | Run until blocked or preempted by higher priority | Safety-critical real-time |
| SCHED_RR | Round-robin among same-priority threads | Fair sharing |
| SCHED_OTHER | System-defined (sporadic in QNX) | Non-real-time tasks |

Priority range: 1 (lowest) to 255 (highest). Priority 0 is the idle thread.
Typical automotive allocation:
- 200-255: Interrupt handler threads
- 100-199: Safety-critical control loops (ADAS, brake-by-wire)
- 50-99: Normal real-time tasks (CAN processing, diagnostics)
- 10-49: Non-critical tasks (logging, HMI updates)
- 1-9: Background tasks

### Interrupt Handling

QNX interrupt handling follows a two-level model:
1. **ISR (InterruptAttach)**: Runs at interrupt level, minimal work only
   (read status, clear interrupt, return event)
2. **Handler thread**: Receives pulse from ISR, does actual processing in
   user space with full OS services available

This model keeps interrupt latency low while allowing complex processing
in a safe, preemptible context.

### Shared Memory with Synchronization

For large data transfers (camera frames, LIDAR point clouds), shared memory
avoids copying. Always use synchronization:
- `pthread_mutex` with `PTHREAD_PROCESS_SHARED` attribute for cross-process
- Atomic operations (`atomic_add`, `atomic_cmpxchg`) for lock-free counters
- Condition variables for producer-consumer patterns

### Best Practices

- Prefer message passing over shared memory for control data (automatic priority inheritance)
- Use pulses for ISR-to-thread notification (never do heavy work in ISR context)
- Set explicit scheduling policy and priority for all real-time threads
- Use `ThreadCtl(_NTO_TCTL_RUNMASK, ...)` for CPU affinity on multi-core SoCs
- Always handle MsgReceive return codes: 0 = pulse, >0 = message, -1 = error
- Clean up channels and connections properly to avoid resource leaks
- Use `tracelogger` and `pidin` for debugging scheduling and timing issues
- Test interrupt latency with oscilloscope on real hardware

### QNX Neutrino RTOS Development

## QNX Neutrino RTOS Development Guide

### Overview

QNX Neutrino is a commercial, POSIX-compliant, microkernel RTOS used
extensively in automotive systems. Unlike monolithic kernels (Linux), QNX
runs all drivers, file systems, and protocol stacks as user-space processes
communicating via message passing. This architecture provides:
- **Fault containment**: A driver crash does not bring down the kernel
- **Deterministic timing**: Microkernel interrupt latency < 1 microsecond
- **Safety certification**: Pre-certified to IEC 61508 SIL 3
- **POSIX compliance**: Applications port easily from Linux

### QNX SDP (Software Development Platform)

The QNX SDP includes compilers, libraries, and tools for multiple targets:

```
QNX SDP 7.1/8.0
├── host/linux/x86_64/    Host tools (compilers, debuggers)
│   └── usr/bin/
│       ├── qcc           QNX C/C++ compiler driver
│       ├── ntox86_64-g++ Target-specific G++
│       └── ntoaarch64le-g++
├── target/qnx7/          Target sysroot
│   ├── x86_64/           x86-64 target libraries
│   ├── aarch64le/        ARM64 target libraries
│   └── armle-v7/         ARMv7 target libraries
└── usr/qde/eclipse/      Momentics IDE
```

### Cross-Compilation with qcc

```bash
# qcc is the compiler driver that selects the correct target toolchain
# Syntax: qcc -V<compiler>_nto<target> [flags] source.c

# x86-64 target
qcc -Vgcc_ntox86_64 -o app_x86 main.c

# ARM64 target (i.MX8, R-Car H3)
qcc -Vgcc_ntoaarch64le -o app_arm64 main.c

# ARMv7 target (i.MX6)
qcc -Vgcc_ntoarmv7le -o app_armv7 main.c

# C++ with optimization
qcc -Vgcc_ntoaarch64le -std=c++14 -O2 -o app main.cpp -lstdc++
```

### Process Model

Every QNX process is a full POSIX process with:
- Its own virtual address space (MMU protection)
- One or more threads
- Channels for receiving messages
- Connections for sending messages to other processes

```
Process A (Client)              Process B (Server)
┌─────────────────┐            ┌─────────────────┐
│  Thread 1       │            │  Thread 1       │
│    │            │            │    │            │
│    ├─Connection──┼───────────┼──►Channel       │
│    │  (coid)     │  message  │    │ (chid)     │
│    │            │            │    │            │
└─────────────────┘            └─────────────────┘
```

### Pathname Space

QNX unifies all resources under a single pathname space managed by
process manager (procnto). Resource managers register pathnames:

```
/dev/can0        → CAN driver resource manager
/dev/ser1        → Serial driver
/dev/shmem/data  → Shared memory object
/proc/           → Process information pseudo-filesystem
/net/            → Network-transparent access to remote nodes
```

Applications use standard `open()`, `read()`, `write()`, `close()` to
interact with any resource manager, whether it is a hardware driver,
a file system, or a custom service.

### AUTOSAR Adaptive on QNX

QNX is a primary target for AUTOSAR Adaptive Platform deployments:
- ara::com (SOME/IP) maps to QNX message passing + vsomeip
- ara::exec uses QNX process manager for application lifecycle
- ara::log integrates with QNX slogger2 for system logging
- ara::per uses QNX filesystem services for persistence
- Thread scheduling maps directly to QNX SCHED_FIFO/SCHED_RR

### Debugging and Profiling

```bash
# Remote debugging via GDB
# On target: start pdebug (debug agent)
pdebug 8000 &

# On host: connect GDB
ntoaarch64le-gdb app_arm64
(gdb) target qnx <target_ip>:8000
(gdb) upload app_arm64 /tmp/app_arm64
(gdb) run

# System profiling with tracelogger
tracelogger -n 5 -f trace.kev    # Capture 5 buffers
traceprinter trace.kev            # Text output

# Process info
pidin                              # Process listing
pidin -f aAbBF                     # Detailed thread info
pidin mem                          # Memory usage
```

### Automotive Use Cases

| Domain | QNX Application | Key Feature |
|--------|----------------|-------------|
| Digital Cockpit | Instrument cluster, HMI | GPU composition, Screen Framework |
| ADAS | Sensor fusion, planning | Deterministic scheduling, hypervisor |
| Gateway | CAN-Ethernet bridge | Resource managers, high throughput |
| Telematics | OTA, connectivity | Networking stack, security |
| Hypervisor | Multi-OS (QNX + Linux) | QNX Hypervisor for type-1 isolation |

### Best Practices

- Use `qcc` compiler driver instead of calling target compilers directly
- Set `QNX_HOST` and `QNX_TARGET` environment variables before building
- Use resource managers for all hardware abstraction (not direct register access)
- Deploy with `on -f -p<priority>` to set process priority at launch
- Use slogger2 for structured logging (not printf to stdout)
- Profile with tracelogger to identify scheduling anomalies
- Test on both x86-64 (faster development cycle) and target architecture (ARM64)
- For AUTOSAR Adaptive, use C++14 standard as required by the specification
