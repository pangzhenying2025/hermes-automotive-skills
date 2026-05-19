# DLT (Diagnostic Log and Trace) Adapter

Complete AUTOSAR DLT protocol implementation for automotive logging systems.

## Overview

The DLT adapter provides production-ready logging infrastructure for distributed automotive systems, implementing the AUTOSAR DLT protocol for diagnostic logging and tracing across multiple ECUs.

### Features

- **Full DLT Protocol Support**: AUTOSAR-compliant message format
- **Flexible Transport**: Network (TCP) and file-based logging
- **Verbose/Non-Verbose Modes**: Optimized for development and production
- **Multi-ECU Support**: Unique ECU IDs for distributed systems
- **Context Management**: Multiple contexts per application
- **Python Integration**: Standard logging.Handler interface
- **Parsing & Filtering**: Comprehensive log analysis tools
- **Export Capabilities**: CSV and JSON export formats

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  Application    │────▶│ DLT Adapter  │────▶│ DLT Daemon  │
│  (App/Context)  │     │              │     │ (Network)   │
└─────────────────┘     └──────────────┘     └─────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │  DLT File    │
                        │  (Storage)   │
                        └──────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │ DLT Viewer   │
                        │  (Analysis)  │
                        └──────────────┘
```

## Installation

```bash
# No external dependencies required for basic functionality
# Optional: Install DLT daemon for network logging
sudo apt-get install dlt-daemon

# Optional: Install DLT Viewer for visualization
# Download from: https://github.com/COVESA/dlt-viewer
```

## Quick Start

### Basic Usage

```python
from tools.adapters.logging import DLTAdapter

# Initialize DLT adapter
dlt = DLTAdapter(
    app_id="ADAS",      # Application ID (max 4 chars)
    context_id="CTRL",  # Context ID (max 4 chars)
    ecu_id="ECU1",      # ECU identifier
    log_file="/var/log/dlt/adas_ctrl.dlt"
)

# Send log messages
dlt.log_info("System initialized")
dlt.log_error("Sensor timeout", sensor_id=5, error_code=0x1234)
dlt.log_debug("Processing frame", frame_id=1234, duration_ms=12.3)

# Close connection
dlt.close()
```

### Context Manager

```python
with DLTAdapter(app_id="TEST", context_id="UNIT") as dlt:
    dlt.log_info("Test message")
    # Automatically closed
```

### Log Levels

```python
dlt.log_fatal("Critical system failure")   # Highest severity
dlt.log_error("Sensor communication lost")
dlt.log_warn("Degraded performance mode")
dlt.log_info("Vehicle speed: 65 km/h")
dlt.log_debug("Processing cycle completed")
dlt.log_verbose("Raw sensor data")         # Lowest severity
```

### Structured Logging

```python
# Add context as keyword arguments
dlt.log_info(
    "Vehicle telemetry",
    speed_kmh=65.5,
    rpm=2400,
    throttle_percent=45.2,
    brake_pressure_bar=0.0,
    steering_angle_deg=-5.2
)
```

## Advanced Usage

### Python Logging Integration

```python
import logging
from tools.adapters.logging import DLTLoggingHandler

# Setup Python logger with DLT handler
logger = logging.getLogger("adas_controller")
dlt_handler = DLTLoggingHandler(
    app_id="ADAS",
    context_id="CTRL",
    log_file="/var/log/dlt/adas.dlt"
)

logger.addHandler(dlt_handler)
logger.setLevel(logging.INFO)

# Use standard Python logging
logger.info("System started")
logger.error("Sensor failure", exc_info=True)
```

### Multiple Contexts

```python
# Different contexts for different subsystems
main_logger = DLTAdapter(app_id="ADAS", context_id="MAIN")
sensor_logger = DLTAdapter(app_id="ADAS", context_id="SENS")
control_logger = DLTAdapter(app_id="ADAS", context_id="CTRL")

main_logger.log_info("Application started")
sensor_logger.log_debug("Camera frame received")
control_logger.log_info("Control loop started")
```

### Multi-ECU Logging

```python
# Gateway ECU
gateway = DLTAdapter(
    app_id="GATE",
    context_id="ROUT",
    ecu_id="GW01",
    daemon_host="192.168.1.100"
)

# ADAS ECU
adas = DLTAdapter(
    app_id="ADAS",
    context_id="CTRL",
    ecu_id="ECU1",
    daemon_host="192.168.1.100"
)

gateway.log_info("CAN message routed", can_id=0x123)
adas.log_info("Message received", can_id=0x123)
```

## Log Analysis

### Parse DLT Files

```python
from tools.adapters.logging import DLTViewerAdapter

viewer = DLTViewerAdapter("/var/log/dlt/adas.dlt")

# Get all entries
entries = viewer.get_entries(limit=100)
for entry in entries:
    print(entry)
```

### Filter Logs

```python
from tools.adapters.logging import DLTFilter, DLTLogLevel

# Filter by log level
error_filter = DLTFilter(min_level=DLTLogLevel.ERROR)
errors = viewer.get_entries(error_filter)

# Filter by app/context
adas_filter = DLTFilter(
    app_ids=["ADAS"],
    context_ids=["CTRL", "SENS"]
)
adas_logs = viewer.get_entries(adas_filter)

# Text search
timeout_filter = DLTFilter(text_search="timeout")
timeouts = viewer.get_entries(timeout_filter)

# Combined filters
combined = DLTFilter(
    app_ids=["ADAS"],
    min_level=DLTLogLevel.WARN,
    text_search="sensor"
)
filtered = viewer.get_entries(combined)
```

### Export Logs

```python
# Export to CSV
viewer.export_csv("/tmp/logs.csv")
viewer.export_csv("/tmp/errors.csv", error_filter)

# Export to JSON
viewer.export_json("/tmp/logs.json", pretty=True)
```

### Statistics

```python
stats = viewer.get_statistics()
print(f"Total entries: {stats['total_entries']}")
print(f"Time range: {stats['time_range']}")
print(f"Applications: {stats['app_ids']}")
print(f"Log levels: {stats['log_levels']}")
```

## Command Line Interface

```bash
# Initialize DLT adapter
dlt-log.sh init ADAS CTRL

# Send log message
dlt-log.sh send info "System started"
dlt-log.sh send error "Sensor timeout" sensor_id=5 error_code=0x1234

# Parse DLT file
dlt-log.sh parse /var/log/dlt/adas.dlt

# Filter logs
dlt-log.sh filter /var/log/dlt/adas.dlt --min-level error --text timeout

# Export logs
dlt-log.sh export /var/log/dlt/adas.dlt csv /tmp/logs.csv

# Show statistics
dlt-log.sh stats /var/log/dlt/adas.dlt

# Monitor in real-time
dlt-log.sh monitor /var/log/dlt/adas.dlt

# Control DLT daemon
dlt-log.sh daemon start
dlt-log.sh daemon status
dlt-log.sh daemon stop
```

## DLT Message Format

### Storage Header (16 bytes)

```
┌─────────┬──────────┬─────────────┬────────┐
│ Pattern │ Seconds  │ Microsecs   │ ECU ID │
│ (4B)    │ (4B)     │ (4B)        │ (4B)   │
└─────────┴──────────┴─────────────┴────────┘
Pattern: "DLT\x01"
```

### Standard Header (Variable)

```
┌──────┬─────────┬────────┬────────┬────────────┬───────────┐
│ HTYP │ Counter │ Length │ ECU ID │ Session ID │ Timestamp │
│ (1B) │ (1B)    │ (2B)   │ (4B)   │ (4B)       │ (4B)      │
└──────┴─────────┴────────┴────────┴────────────┴───────────┘
Optional fields based on HTYP flags
```

### Extended Header (10 bytes)

```
┌──────┬──────────┬────────┬────────────┐
│ MSIN │ Reserved │ App ID │ Context ID │
│ (1B) │ (1B)     │ (4B)   │ (4B)       │
└──────┴──────────┴────────┴────────────┘
MSIN: Message Info (type, level, verbose flag)
```

### Payload (Variable)

Verbose mode:
```
┌──────────┬───────────┬──────────┐
│ Num Args │ Type Info │ Data ... │
│ (1B)     │ (4B each) │          │
└──────────┴───────────┴──────────┘
```

Non-verbose mode: Raw bytes

## Configuration

### Application ID Naming

Choose meaningful 4-character identifiers:

- `ADAS` - Advanced Driver Assistance Systems
- `CTRL` - Control systems
- `DIAG` - Diagnostics
- `GATE` - Gateway
- `SENS` - Sensors
- `COMM` - Communication
- `PWTR` - Powertrain

### Context ID Naming

Subsystems within application:

- `MAIN` - Main application
- `INIT` - Initialization
- `SENS` - Sensor processing
- `CTRL` - Control logic
- `COMM` - Communication
- `DIAG` - Diagnostics
- `SAFE` - Safety functions

### ECU ID Naming

Unique per ECU in system:

- `GW01` - Gateway ECU
- `ECU1` - ADAS ECU
- `ECU2` - Powertrain ECU
- `DISP` - Display ECU

## Performance Considerations

### Production Optimization

```python
# Use non-verbose mode for lower overhead
dlt = DLTAdapter(
    app_id="PROD",
    context_id="CTRL",
    verbose_mode=False  # Non-verbose mode
)

# Disable debug/verbose in production
# Set minimum level at INFO or WARN
```

### High-Frequency Logging

- Avoid logging in time-critical paths (<1ms)
- Use DEBUG/VERBOSE levels that can be disabled
- Buffer logs and write in batches
- Consider message counter for sequence verification

### Memory Usage

- DLT messages are ~100-500 bytes each
- File rotation recommended for long-running systems
- Monitor disk space usage

## Examples

See `examples.py` for comprehensive examples:

```bash
python3 examples.py
```

Includes:
1. Basic logging
2. Structured logging
3. Multi-context logging
4. Python logging integration
5. Parse and filter
6. Performance logging
7. Diagnostic trace
8. Error recovery

## Integration with Tools

### DLT Viewer (COVESA)

1. Install DLT Viewer from https://github.com/COVESA/dlt-viewer
2. Open DLT file: File → Open
3. Configure filters: Filter → Add Filter
4. Export: File → Export

### DLT Daemon

```bash
# Start daemon
sudo systemctl start dlt-daemon

# Configure adapter for network
dlt = DLTAdapter(
    app_id="ADAS",
    context_id="CTRL",
    daemon_host="localhost",
    daemon_port=3490,
    use_network=True
)
```

### Systemd Journal Integration

```python
# DLT logs can be correlated with journal
import subprocess
journal = subprocess.run(
    ["journalctl", "-u", "adas-service", "--since", "1 hour ago"],
    capture_output=True
)
```

## Troubleshooting

### Cannot connect to DLT daemon

```bash
# Check if daemon is running
systemctl status dlt-daemon

# Check port
netstat -an | grep 3490

# Use file-only logging
dlt = DLTAdapter(app_id="TEST", context_id="UNIT", use_network=False)
```

### Log file not created

- Verify directory exists and has write permissions
- Check disk space: `df -h`
- Use absolute path

### Messages not in DLT Viewer

- Check app ID and context ID filters in viewer
- Verify log level filter
- Refresh viewer after new logs written

### High logging overhead

- Reduce log level
- Use non-verbose mode
- Move logging out of hot paths
- Consider conditional logging

## Best Practices

### Log Level Selection

- **FATAL**: System cannot continue, immediate action required
- **ERROR**: Functionality impaired, automatic recovery attempted
- **WARN**: Degraded operation, no immediate impact
- **INFO**: Important state changes, normal operation
- **DEBUG**: Detailed execution flow, development only
- **VERBOSE**: Raw data, high-frequency events

### Context Organization

```
App: ADAS
├── MAIN  - Main application lifecycle
├── INIT  - Initialization and configuration
├── SENS  - Sensor data processing
├── CTRL  - Control algorithms
├── COMM  - Communication interfaces
└── SAFE  - Safety monitoring
```

### Error Logging

```python
# Log error with full context
dlt.log_error(
    "Sensor timeout",
    sensor_type="LIDAR",
    sensor_id=3,
    timeout_ms=500,
    last_message_age_ms=1250,
    error_code=0x1234,
    recovery_attempted=True
)
```

### Performance Logging

```python
# Include timing and resource usage
dlt.log_debug(
    "Frame processed",
    frame_id=1234,
    duration_ms=12.3,
    cpu_percent=45.2,
    memory_mb=234
)
```

## References

- [AUTOSAR DLT Protocol Specification](https://www.autosar.org)
- [COVESA DLT Viewer](https://github.com/COVESA/dlt-viewer)
- [COVESA DLT Daemon](https://github.com/COVESA/dlt-daemon)
- [Skills: dlt-logging.yaml](../../../skills/logging/dlt-logging.yaml)
- [Agent: dlt-specialist.yaml](../../../agents/logging/dlt-specialist.yaml)

## License

MIT License - See project LICENSE file
