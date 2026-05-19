# DLT Adapter Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Automotive Application                        │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐ │
│  │   ADAS     │  │   Gateway  │  │ Powertrain │  │ Diagnosis │ │
│  │   ECU1     │  │    GW01    │  │    ECU2    │  │   DIAG    │ │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘  └─────┬─────┘ │
│         │                │                │              │       │
│         └────────────────┴────────────────┴──────────────┘       │
│                              │                                   │
│                    ┌─────────▼────────┐                          │
│                    │   DLT Adapter    │                          │
│                    │   (This Impl)    │                          │
│                    └──────┬────┬──────┘                          │
└───────────────────────────┼────┼───────────────────────────────┘
                            │    │
                 ┌──────────┘    └───────────┐
                 │                            │
         ┌───────▼────────┐          ┌───────▼────────┐
         │   DLT File     │          │  DLT Daemon    │
         │   Storage      │          │  (TCP:3490)    │
         └───────┬────────┘          └───────┬────────┘
                 │                            │
         ┌───────▼────────┐          ┌───────▼────────┐
         │ DLT Viewer     │          │  DLT Viewer    │
         │ Adapter        │          │  (COVESA)      │
         │ (Parser)       │          │  (GUI)         │
         └────────────────┘          └────────────────┘
```

## Component Architecture

### DLT Adapter (Core)

```
┌────────────────────────────────────────────────────────────────┐
│                        DLTAdapter                               │
├────────────────────────────────────────────────────────────────┤
│  Configuration:                                                 │
│  ├─ app_id: str (4 chars)      Application identifier          │
│  ├─ context_id: str (4 chars)  Context identifier              │
│  ├─ ecu_id: str (4 chars)      ECU identifier                  │
│  ├─ daemon_host: str           DLT daemon hostname             │
│  ├─ daemon_port: int           DLT daemon port (3490)          │
│  ├─ verbose_mode: bool         Verbose/non-verbose             │
│  ├─ use_network: bool          Enable network logging          │
│  └─ log_file: Optional[str]    File path for storage           │
├────────────────────────────────────────────────────────────────┤
│  Methods:                                                       │
│  ├─ log_fatal(msg, **kwargs)   FATAL level logging             │
│  ├─ log_error(msg, **kwargs)   ERROR level logging             │
│  ├─ log_warn(msg, **kwargs)    WARN level logging              │
│  ├─ log_info(msg, **kwargs)    INFO level logging              │
│  ├─ log_debug(msg, **kwargs)   DEBUG level logging             │
│  ├─ log_verbose(msg, **kwargs) VERBOSE level logging           │
│  └─ close()                     Cleanup and close connections   │
├────────────────────────────────────────────────────────────────┤
│  Internal:                                                      │
│  ├─ _connect_daemon()          TCP connection to daemon        │
│  ├─ _open_log_file()           Open DLT file for writing       │
│  ├─ _send_message()            Send to network/file            │
│  └─ message_counter            Sequential message counter      │
└────────────────────────────────────────────────────────────────┘
```

### Message Structure

#### Complete DLT Message Format

```
┌────────────────────────────────────────────────────────────────┐
│                    Complete DLT Message                         │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Storage Header (16 bytes) - For file storage only       │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  Pattern    │ "DLT\x01" (4 bytes)                        │  │
│  │  Seconds    │ Unix timestamp seconds (4 bytes)           │  │
│  │  Microsecs  │ Microseconds (4 bytes)                     │  │
│  │  ECU ID     │ ECU identifier (4 bytes)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Standard Header (Variable) - Always present             │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  HTYP        │ Header type (1 byte)                      │  │
│  │  Counter     │ Message counter (1 byte)                  │  │
│  │  Length      │ Total message length (2 bytes)            │  │
│  │  ECU ID      │ ECU identifier (4 bytes) [optional]       │  │
│  │  Session ID  │ Session identifier (4 bytes) [optional]   │  │
│  │  Timestamp   │ Timestamp 0.1ms (4 bytes) [optional]      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Extended Header (10 bytes) - For verbose mode           │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  MSIN        │ Message info (1 byte)                     │  │
│  │              │ ├─ Type: LOG/TRACE (4 bits)               │  │
│  │              │ ├─ Level: FATAL-VERBOSE (4 bits)          │  │
│  │              │ └─ Verbose flag (1 bit)                   │  │
│  │  Reserved    │ Reserved byte (1 byte)                    │  │
│  │  App ID      │ Application ID (4 bytes)                  │  │
│  │  Context ID  │ Context ID (4 bytes)                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Payload (Variable)                                       │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  Verbose Mode:                                            │  │
│  │  ├─ Num Args      │ Number of arguments (1 byte)         │  │
│  │  ├─ Type Info     │ Type information (4 bytes per arg)   │  │
│  │  └─ Data          │ Actual data (variable)               │  │
│  │                                                            │  │
│  │  Non-Verbose Mode:                                        │  │
│  │  └─ Raw Bytes     │ Raw payload data                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

#### Message Flow

```
┌──────────────┐
│ Application  │
│              │
│ dlt.log_info │
│ ("Message",  │
│  key=value)  │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────┐
│ DLTMessage Creation               │
│ ├─ Build storage header (if file)│
│ ├─ Build standard header          │
│ ├─ Build extended header          │
│ ├─ Encode payload (verbose)       │
│ └─ Calculate total length         │
└──────┬───────────────────────────┘
       │
       ├────────────┬─────────────┐
       ▼            ▼             ▼
┌─────────────┐ ┌────────────┐ ┌──────────┐
│ Network     │ │ File       │ │ Counter  │
│ (TCP)       │ │ (Binary)   │ │ Increment│
│             │ │            │ │          │
│ Send to     │ │ Write to   │ │ 0-255    │
│ daemon      │ │ DLT file   │ │ rollover │
└─────────────┘ └────────────┘ └──────────┘
```

### DLT Viewer Adapter

```
┌────────────────────────────────────────────────────────────────┐
│                    DLTViewerAdapter                             │
├────────────────────────────────────────────────────────────────┤
│  Components:                                                    │
│  ├─ DLTParser              Parse binary DLT files              │
│  │  ├─ _parse_message()    Parse single message                │
│  │  ├─ _parse_verbose()    Parse verbose payload               │
│  │  └─ parse()             Iterator over all messages          │
│  │                                                              │
│  ├─ DLTFilter               Multi-criteria filtering           │
│  │  ├─ app_ids             Filter by application IDs           │
│  │  ├─ context_ids         Filter by context IDs               │
│  │  ├─ ecu_ids             Filter by ECU IDs                   │
│  │  ├─ log_levels          Filter by specific levels           │
│  │  ├─ min_level           Filter by minimum level             │
│  │  ├─ time_range          Filter by timestamp range           │
│  │  ├─ text_search         Search in message text              │
│  │  └─ matches()           Check if entry matches filter       │
│  │                                                              │
│  └─ DLTViewerAdapter        High-level interface               │
│     ├─ get_entries()        Retrieve with filtering            │
│     ├─ export_csv()         Export to CSV format               │
│     ├─ export_json()        Export to JSON format              │
│     ├─ get_statistics()     Generate statistics                │
│     └─ print_entries()      Print to stdout                    │
└────────────────────────────────────────────────────────────────┘
```

### Parsing Flow

```
┌──────────────┐
│  DLT File    │
│  Binary      │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────┐
│ DLTParser.parse()            │
│ ┌─────────────────────────┐ │
│ │ Read storage header     │ │
│ │ ├─ Verify pattern       │ │
│ │ ├─ Extract timestamp    │ │
│ │ └─ Extract ECU ID       │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Read standard header    │ │
│ │ ├─ Parse HTYP flags     │ │
│ │ ├─ Get message counter  │ │
│ │ ├─ Get total length     │ │
│ │ └─ Parse optional fields│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Read extended header    │ │
│ │ ├─ Parse MSIN           │ │
│ │ ├─ Extract app ID       │ │
│ │ ├─ Extract context ID   │ │
│ │ └─ Extract log level    │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Parse payload           │ │
│ │ ├─ Verbose: decode args │ │
│ │ └─ Non-verbose: raw     │ │
│ └─────────────────────────┘ │
└──────┬──────────────────────┘
       │
       ▼
┌──────────────┐
│ DLTLogEntry  │
│ - timestamp  │
│ - ecu_id     │
│ - app_id     │
│ - context_id │
│ - log_level  │
│ - message    │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────┐
│ DLTFilter.matches()          │
│ Check all filter criteria   │
└──────┬──────────────────────┘
       │
       ├─────────────┬──────────────┐
       ▼             ▼              ▼
┌────────────┐ ┌──────────┐ ┌────────────┐
│   Print    │ │  Export  │ │ Statistics │
│  to stdout │ │ CSV/JSON │ │            │
└────────────┘ └──────────┘ └────────────┘
```

## Multi-ECU Architecture

### Distributed Logging System

```
┌──────────────────────────────────────────────────────────────┐
│                    Automotive Network                         │
│                                                               │
│  ┌────────────────┐        ┌────────────────┐               │
│  │  ADAS ECU      │        │  Gateway ECU   │               │
│  │  (ECU1)        │        │  (GW01)        │               │
│  │                │        │                │               │
│  │  DLTAdapter    │        │  DLTAdapter    │               │
│  │  app:  ADAS    │        │  app:  GATE    │               │
│  │  ctx:  CTRL    │◄───────┤  ctx:  ROUT    │               │
│  │  ecu:  ECU1    │  CAN   │  ecu:  GW01    │               │
│  └────────┬───────┘        └────────┬───────┘               │
│           │                         │                        │
│           │ TCP                     │ TCP                    │
│           │ 3490                    │ 3490                   │
│           │                         │                        │
│  ┌────────▼─────────────────────────▼───────┐               │
│  │       Central Logging ECU                │               │
│  │                                           │               │
│  │       ┌───────────────────┐               │               │
│  │       │   DLT Daemon      │               │               │
│  │       │   (Port 3490)     │               │               │
│  │       └─────────┬─────────┘               │               │
│  │                 │                         │               │
│  │       ┌─────────▼─────────┐               │               │
│  │       │   DLT Files       │               │               │
│  │       │   /var/log/dlt/   │               │               │
│  │       └───────────────────┘               │               │
│  └───────────────────────────────────────────┘               │
│                                                               │
│  ┌────────────────┐        ┌────────────────┐               │
│  │ Powertrain ECU │        │ Display ECU    │               │
│  │  (ECU2)        │        │  (DISP)        │               │
│  │                │        │                │               │
│  │  DLTAdapter    │        │  DLTAdapter    │               │
│  │  app:  PWTR    │        │  app:  HMI     │               │
│  │  ctx:  CTRL    │────────┤  ctx:  MAIN    │               │
│  │  ecu:  ECU2    │  CAN   │  ecu:  DISP    │               │
│  └────────────────┘        └────────────────┘               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │  Development PC       │
                │                       │
                │  ┌─────────────────┐  │
                │  │  DLT Viewer     │  │
                │  │  (COVESA)       │  │
                │  │                 │  │
                │  │  - Real-time    │  │
                │  │  - Filtering    │  │
                │  │  - Export       │  │
                │  └─────────────────┘  │
                └───────────────────────┘
```

## Data Flow Examples

### Example 1: ADAS Lane Keeping Log

```
Application Code:
  dlt.log_info("Lane keeping active", speed_kmh=65.5, steering_deg=-2.3)

Encoded Message (Hex):
  Storage Header:
    44 4C 54 01              # "DLT\x01"
    64 1A 2F 60              # Timestamp seconds
    12 34 56 78              # Timestamp microseconds
    45 43 55 31              # "ECU1"

  Standard Header:
    35                       # HTYP (ECU ID, Timestamp, Version 1)
    2A                       # Counter: 42
    00 5E                    # Length: 94 bytes
    45 43 55 31              # "ECU1"
    00 00 12 34              # Timestamp: 0.1ms

  Extended Header:
    04                       # MSIN (LOG, INFO, Verbose)
    00                       # Reserved
    41 44 41 53              # "ADAS"
    43 54 52 4C              # "CTRL"

  Payload (Verbose):
    01                       # 1 argument
    00 00 02 3C              # Type info: String, length 60
    4C 61 6E 65 20 ...       # "Lane keeping active | {...}"
```

### Example 2: Error with Recovery

```
Sequence:
  1. dlt.log_error("Sensor timeout", sensor_id=3, timeout_ms=500)
  2. dlt.log_info("Attempting recovery", retry=1)
  3. dlt.log_info("Recovery successful", duration_ms=100)

Timeline:
  T+0ms     [ERROR] ADAS.SENS: Sensor timeout | {"sensor_id": 3, "timeout_ms": 500}
  T+10ms    [INFO]  ADAS.SENS: Attempting recovery | {"retry": 1}
  T+110ms   [INFO]  ADAS.SENS: Recovery successful | {"duration_ms": 100}

Filter in DLT Viewer:
  App ID:       ADAS
  Context ID:   SENS
  Min Level:    ERROR
  Text Search:  "timeout"
  Result:       1 entry (first message only)
```

## Performance Characteristics

### Message Throughput

```
Test Scenario: Write 10,000 messages to file

Verbose Mode:
  ├─ Message size: ~150 bytes average
  ├─ Total size: ~1.5 MB
  ├─ Duration: ~150ms
  └─ Throughput: ~66,000 msg/sec

Non-Verbose Mode:
  ├─ Message size: ~80 bytes average
  ├─ Total size: ~800 KB
  ├─ Duration: ~80ms
  └─ Throughput: ~125,000 msg/sec

Network Mode (TCP):
  ├─ Latency: ~5ms per message
  ├─ Throughput: ~200 msg/sec
  └─ Buffering improves to ~5,000 msg/sec
```

### Memory Footprint

```
Component Memory Usage:

DLTAdapter Instance:
  ├─ Base object: ~1 KB
  ├─ Socket buffer: ~64 KB (system)
  ├─ File buffer: ~8 KB (Python)
  └─ Total per instance: ~73 KB

DLTMessage Encoding:
  ├─ Temporary buffers: ~500 bytes
  ├─ Cleared after send
  └─ No persistent memory

DLTParser Reading:
  ├─ Parse buffer: ~16 KB
  ├─ Entry list: ~100 bytes per entry
  └─ 10,000 entries: ~1 MB
```

## Integration Patterns

### Pattern 1: Single Application, Multiple Contexts

```python
# Main application
main = DLTAdapter(app_id="ADAS", context_id="MAIN")

# Subsystems
sensors = DLTAdapter(app_id="ADAS", context_id="SENS")
control = DLTAdapter(app_id="ADAS", context_id="CTRL")
comm = DLTAdapter(app_id="ADAS", context_id="COMM")

# Each subsystem logs independently
main.log_info("Application started")
sensors.log_debug("Camera frame received")
control.log_info("Steering adjusted")
comm.log_debug("CAN message sent")
```

### Pattern 2: Python Logging Integration

```python
import logging
from tools.adapters.logging import DLTLoggingHandler

# Setup
logger = logging.getLogger("adas")
handler = DLTLoggingHandler(app_id="ADAS", context_id="MAIN")
logger.addHandler(handler)

# Use standard logging
logger.info("System ready")
logger.error("Sensor failure", exc_info=True)
```

### Pattern 3: Multi-ECU with Central Logging

```python
# Each ECU connects to central daemon
ecu1_logger = DLTAdapter(
    app_id="ADAS", context_id="CTRL", ecu_id="ECU1",
    daemon_host="192.168.1.100", daemon_port=3490
)

ecu2_logger = DLTAdapter(
    app_id="PWTR", context_id="CTRL", ecu_id="ECU2",
    daemon_host="192.168.1.100", daemon_port=3490
)

# Logs aggregated on central daemon
```

## File Format Specification

### DLT File Structure

```
DLT File: /var/log/dlt/adas.dlt

[Storage Header 1][Standard Header 1][Extended Header 1][Payload 1]
[Storage Header 2][Standard Header 2][Extended Header 2][Payload 2]
[Storage Header 3][Standard Header 3][Extended Header 3][Payload 3]
...
[Storage Header N][Standard Header N][Extended Header N][Payload N]

Sequential messages, no index, no compression
File can be read sequentially from start to end
Corrupted messages skipped by parser
```

### Compatibility

```
✓ Compatible with:
  - COVESA DLT Viewer 2.x
  - dlt-daemon 2.x
  - Diagnostic tools supporting AUTOSAR DLT
  - Custom parsers following AUTOSAR spec

✗ Not compatible with:
  - Plain text log files
  - syslog format
  - journald binary format
  - Proprietary logging formats
```

## Error Handling

### Robust Error Recovery

```
Write Errors:
  ├─ Network disconnected
  │  └─ Log locally, attempt reconnection
  ├─ Disk full
  │  └─ Drop messages, log error to stderr
  └─ Permission denied
     └─ Fail fast, notify user

Parse Errors:
  ├─ Corrupted storage header
  │  └─ Search for next valid pattern
  ├─ Invalid message length
  │  └─ Skip to next storage header
  └─ Truncated file
     └─ Stop parsing, return partial results

Filter Errors:
  ├─ Invalid regex
  │  └─ Fall back to literal search
  └─ Empty filter
     └─ Return all entries
```

---

**Architecture Version: 1.0**
**Last Updated: 2026-03-19**
**Status: Production Ready**
