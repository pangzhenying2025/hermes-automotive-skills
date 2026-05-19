# ECU Diagnostics & Flash Programming Implementation

Implementation Agent #8 - Complete diagnostics and flashing toolkit

## Overview

Comprehensive ECU diagnostic and flash programming system supporting:
- **UDS ISO 14229** - Unified Diagnostic Services
- **OBD-II SAE J1979** - On-Board Diagnostics
- **DoIP ISO 13400** - Diagnostics over IP
- **KWP2000 ISO 14230** - Keyword Protocol 2000 (legacy)
- **ODX ISO 22901** - Open Diagnostic Data Exchange

## Directory Structure

```
automotive-claude-code-agents/
├── skills/diagnostics/
│   ├── ecu-flash.yaml         (20 flash programming skills)
│   ├── ecu-diagnose.yaml      (25 diagnostic services)
│   ├── odx-management.yaml    (15 ODX database skills)
│   ├── uds-services.yaml      (20 UDS service implementations)
│   ├── obd-ii.yaml            (15 OBD-II skills)
│   └── doip.yaml              (10 DoIP skills)
│
├── tools/adapters/diagnostics/
│   ├── vflash_adapter.py      (307 lines - Vector vFlash integration)
│   ├── python_uds_adapter.py  (256 lines - UDS protocol stack)
│   ├── obd_ii_adapter.py      (203 lines - OBD-II implementation)
│   └── odxtools_adapter.py    (228 lines - ODX parser)
│
├── agents/diagnostics/
│   ├── diagnostic-engineer.yaml
│   └── flash-specialist.yaml
│
└── commands/diagnostics/
    ├── ecu-flash.sh           (Flash programming CLI)
    ├── ecu-diagnose.sh        (Diagnostic operations CLI)
    ├── odx-parse.sh           (ODX database parser CLI)
    └── dtc-read.sh            (DTC reading convenience wrapper)
```

## Skill Files (85+ Total Skills)

### 1. ecu-flash.yaml (20 skills)
Flash programming operations:
- `init_flash_session` - Initialize programming session with security access
- `request_download` - UDS RequestDownload (0x34)
- `transfer_data_blocks` - Transfer flash blocks (0x36)
- `request_transfer_exit` - Finalize transfer (0x37)
- `ecu_reset_flash` - Reset ECU to activate new flash
- `verify_flash_integrity` - Post-flash verification
- `flash_multi_block` - Multi-region flash (bootloader, app, calibration)
- `security_access_seed_key` - Seed-key algorithm
- `handle_flash_errors` - Error recovery
- `kwp2000_flash_mode` - Legacy KWP2000 flash
- `compress_flash_data` - LZMA/ZLIB compression
- `encrypt_flash_data` - AES-256 encryption
- `flash_progress_monitoring` - Progress tracking
- `backup_existing_flash` - Backup before programming
- `restore_flash_backup` - Recovery from backup
- `flash_fingerprinting` - ECU compatibility check
- `flash_with_vector_vflash` - Vector vFlash integration
- `adaptive_flash_timing` - Dynamic timeout adjustment
- `flash_dependency_check` - Version compatibility
- `flash_rollback_protection` - Anti-downgrade

### 2. ecu-diagnose.yaml (25 skills)
Diagnostic operations:
- `read_dtc_information` - Read DTCs (0x19)
- `clear_diagnostic_information` - Clear DTCs (0x14)
- `read_data_by_identifier` - Read DIDs (0x22)
- `write_data_by_identifier` - Write DIDs (0x2E)
- `routine_control` - Execute routines (0x31)
- `input_output_control` - I/O control (0x2F)
- `read_memory_by_address` - Memory read (0x23)
- `write_memory_by_address` - Memory write (0x3D)
- `diagnostic_session_control` - Session management (0x10)
- `tester_present` - Keep-alive (0x3E)
- `communication_control` - Bus control (0x28)
- `control_dtc_setting` - DTC enable/disable (0x85)
- `link_control` - Baudrate control (0x87)
- `read_scaling_by_identifier` - Scaling data (0x24)
- `dynamically_define_did` - Custom DIDs (0x2C)
- `read_dtc_snapshot` - Freeze frames
- `read_dtc_extended_data` - Extended DTC data
- `access_timing_parameters` - Timing control (0x83)
- `secured_data_transmission` - Encrypted transmission (0x84)
- `response_on_event` - Event-based responses (0x86)
- `read_periodic_data` - Periodic DIDs (0x2A)
- `diagnostic_session_timeout` - Timeout management
- `multi_ecu_diagnostic` - Multi-ECU scan
- `diagnostic_log_export` - Export to CSV/JSON/MDF4
- `compare_diagnostic_sessions` - Delta analysis

### 3. odx-management.yaml (15 skills)
ODX database operations:
- `parse_odx_database` - Load ODX/PDX files
- `resolve_dtc_descriptions` - DTC lookup
- `get_did_metadata` - DID information
- `encode_diagnostic_request` - Request encoding
- `decode_diagnostic_response` - Response parsing
- `apply_did_scaling` - Physical value conversion
- `validate_ecu_variant` - Variant matching
- `export_odx_subset` - Filtered export
- `compare_odx_versions` - Version diff
- `validate_odx_consistency` - Database validation
- `merge_odx_databases` - Multi-file merge
- `generate_odx_documentation` - HTML/PDF/Markdown docs
- `odx_to_autosar` - ARXML export
- `odx_cache_management` - Performance cache
- `odx_service_discovery` - Service enumeration

### 4. uds-services.yaml (20 skills)
UDS service implementations:
- `uds_service_0x10_session_control` - DiagnosticSessionControl
- `uds_service_0x11_ecu_reset` - ECUReset
- `uds_service_0x14_clear_dtc` - ClearDiagnosticInformation
- `uds_service_0x19_read_dtc` - ReadDTCInformation
- `uds_service_0x22_read_did` - ReadDataByIdentifier
- `uds_service_0x23_read_memory` - ReadMemoryByAddress
- `uds_service_0x27_security_access` - SecurityAccess
- `uds_service_0x28_communication_control` - CommunicationControl
- `uds_service_0x2e_write_did` - WriteDataByIdentifier
- `uds_service_0x2f_io_control` - InputOutputControlByIdentifier
- `uds_service_0x31_routine_control` - RoutineControl
- `uds_service_0x34_request_download` - RequestDownload
- `uds_service_0x35_request_upload` - RequestUpload
- `uds_service_0x36_transfer_data` - TransferData
- `uds_service_0x37_transfer_exit` - RequestTransferExit
- `uds_service_0x3d_write_memory` - WriteMemoryByAddress
- `uds_service_0x3e_tester_present` - TesterPresent
- `uds_service_0x85_dtc_control` - ControlDTCSettings
- `uds_negative_response_handling` - NRC handling
- `uds_timing_management` - P2/P2*/S3 timing

### 5. obd-ii.yaml (15 skills)
OBD-II operations:
- `read_obd_pids` - Mode 01 current data
- `read_emission_dtcs` - Mode 03 DTC read
- `clear_emission_dtcs` - Mode 04 clear DTCs
- `read_freeze_frame` - Mode 02 freeze frame
- `read_readiness_monitors` - Monitor status
- `read_vin_obd` - Mode 09 VIN
- `read_calibration_id` - ECU calibration info
- `read_o2_sensor_data` - O2 sensor monitoring
- `read_fuel_system_status` - Fuel trim
- `read_evap_system` - EVAP pressure
- `monitor_real_time_data` - Streaming data
- `perform_evap_leak_test` - EVAP test
- `read_supported_pids` - PID discovery
- `calculate_fuel_consumption` - L/100km calculation
- `obd_performance_tracking` - Mode 06 test results

### 6. doip.yaml (10 skills)
Diagnostics over IP:
- `doip_vehicle_discovery` - UDP broadcast discovery
- `doip_routing_activation` - TCP connection setup
- `doip_diagnostic_message` - UDS over DoIP
- `doip_alive_check` - Connection keep-alive
- `doip_entity_status` - Gateway status
- `doip_power_mode` - Power mode info
- `doip_connection_management` - Multi-ECU connections
- `doip_tls_security` - TLS encryption
- `doip_error_handling` - DoIP error codes
- `doip_vlan_configuration` - VLAN support

## Tool Adapters

### vflash_adapter.py (307 lines)
Vector vFlash COM API integration:
- Load vFlash projects (.vflash)
- Configure CAN/DoIP interfaces
- Execute flash jobs with progress monitoring
- Parse flash results and logs
- Simulation mode for testing without Vector hardware

Key features:
- Real-time progress callbacks (percentage, rate, ETA)
- Voltage monitoring
- Error handling with rollback
- Multi-block flash support

### python_uds_adapter.py (256 lines)
Opensource UDS protocol stack:
- CAN and DoIP transport layers
- All UDS services (0x10-0x87)
- Negative response code handling
- Security access implementation
- Session and timing management
- Simulation mode for testing

Key features:
- Multiple transport support (SocketCAN, DoIP)
- Comprehensive NRC handling
- Timing parameter tracking (P2, P2*, S3)
- Seed-key security access

### obd_ii_adapter.py (203 lines)
OBD-II SAE J1979 implementation:
- Mode 01-09 support
- PID database with formulas
- DTC reading and clearing
- Freeze frame data
- Readiness monitor status
- Real-time data streaming

Key features:
- Auto-detect serial port
- Multi-protocol support (CAN, KWP, ISO9141, J1850)
- PID discovery
- Simulation mode

### odxtools_adapter.py (228 lines)
ODX database parser:
- ODX-D and PDX file parsing
- DTC resolution with descriptions
- DID metadata extraction
- Scaling formula application
- Service information lookup
- ECU variant management

Key features:
- DTC string conversion (P0301 <-> 0x010301)
- Physical value scaling
- ODX caching for performance
- Simulation mode

## Command-Line Tools

### ecu-flash.sh
Flash programming CLI:
```bash
# Flash with UDS
ecu-flash -e 0x10 -i can -c can0 engine_sw_v2.3.4.hex

# Flash with Vector vFlash
ecu-flash -v flash_project.vflash -b -r app.vbf

# Simulation mode
ecu-flash --simulate --progress test_flash.bin
```

### ecu-diagnose.sh
Diagnostic operations CLI:
```bash
# Read DTCs
ecu-diagnose -e 0x10 dtc

# Read DID
ecu-diagnose -e 0x10 read-did 0xF190

# Comprehensive scan
ecu-diagnose --odx database.odx-d scan

# JSON output
ecu-diagnose -f json info
```

### odx-parse.sh
ODX database parser:
```bash
# List variants
odx-parse -d database.odx-d variants

# Get DTC info
odx-parse -d database.odx-d dtc P0301

# Get DID metadata
odx-parse -d database.odx-d did 0xF190

# Export subset
odx-parse -d database.odx-d -f json export ECU_ENGINE
```

### dtc-read.sh
DTC reading convenience wrapper:
```bash
# Read DTCs
dtc-read

# With ODX descriptions
dtc-read -e 0x10 -o database.odx-d

# OBD-II mode
dtc-read -i obd -c /dev/ttyUSB0

# JSON with snapshots
dtc-read -f json -s > dtc_report.json

# Scan all ECUs
dtc-read --all-ecus
```

## Agents

### diagnostic-engineer.yaml
Expert in ECU diagnostics:
- Comprehensive ECU diagnostic scans
- DTC analysis and troubleshooting
- Parameter reading and writing
- Diagnostic session management
- Multi-ECU diagnostics

Workflows:
- `comprehensive_diagnostic_scan` - Full ECU analysis
- `dtc_analysis` - Root cause analysis
- `parameter_adjustment` - Safe parameter updates

### flash-specialist.yaml
ECU flash programming expert:
- UDS and KWP2000 flash programming
- Vector vFlash project execution
- Flash verification and rollback
- Multi-ECU flash orchestration
- Error recovery

Workflows:
- `standard_flash_procedure` - Complete flash sequence
- `flash_with_vflash` - Vector vFlash automation
- `multi_ecu_flash` - Multi-ECU coordination
- `flash_recovery` - Recovery from failures

## Dependencies

### Python Libraries
```bash
# UDS protocol (opensource)
pip install python-uds

# OBD-II (opensource)
pip install obd

# ODX parsing (opensource)
pip install odxtools

# CAN interface (Linux)
pip install python-can

# Vector vFlash (Windows only, commercial)
# Requires Vector hardware and license
```

### System Requirements
- Linux: SocketCAN for CAN interfaces
- Windows: Vector vFlash COM API for flash programming
- Python 3.8+
- CAN hardware (PEAK, Kvaser, Vector) or OBD-II adapter

## Usage Examples

### Flash ECU Software
```bash
# Flash with backup and verification
./commands/diagnostics/ecu-flash.sh \
  -e 0x10 \
  -i can \
  -c can0 \
  -b \
  -r \
  engine_app_v2.3.4.hex
```

### Read and Analyze DTCs
```bash
# Read DTCs with ODX descriptions
./commands/diagnostics/dtc-read.sh \
  -e 0x10 \
  -o /path/to/database.odx-d \
  -f json \
  -s > dtc_report.json
```

### Comprehensive Diagnostic Scan
```bash
# Scan all ECUs
./commands/diagnostics/ecu-diagnose.sh \
  --odx database.odx-d \
  -f json \
  scan > diagnostic_report.json
```

### OBD-II Emissions Check
```bash
# Read emission DTCs
./commands/diagnostics/dtc-read.sh \
  -i obd \
  -c /dev/ttyUSB0

# Clear DTCs after repairs
./commands/diagnostics/dtc-read.sh \
  -i obd \
  -c /dev/ttyUSB0 \
  --clear
```

## Architecture

### Layered Design
```
┌─────────────────────────────────────────────┐
│         Commands (CLI Scripts)              │
│  ecu-flash.sh  ecu-diagnose.sh  dtc-read.sh │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│        Agents (YAML Definitions)            │
│  diagnostic-engineer  flash-specialist      │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         Skills (YAML Task Specs)            │
│  ecu-flash  ecu-diagnose  odx-management    │
│  uds-services  obd-ii  doip                 │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│      Tool Adapters (Python Libraries)       │
│  vflash_adapter  python_uds_adapter         │
│  obd_ii_adapter  odxtools_adapter           │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│       Protocol Implementations              │
│  UDS  OBD-II  DoIP  KWP2000  ODX           │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│        Hardware Interfaces                  │
│  CAN (SocketCAN)  OBD-II  Ethernet (DoIP)  │
└─────────────────────────────────────────────┘
```

## Testing

All adapters include simulation modes for testing without hardware:

```python
# UDS simulation
adapter = PythonUdsAdapter(config, simulation_mode=True)

# vFlash simulation
adapter = VFlashAdapter(simulation_mode=True)

# OBD-II simulation
adapter = ObdIIAdapter(simulation_mode=True)

# ODX simulation
adapter = OdxToolsAdapter(odx_path, simulation_mode=True)
```

## Integration Points

### With Other Agent Systems
- **CAN Agent**: Transport layer for UDS diagnostics
- **Testing Agent**: Automated diagnostic test sequences
- **Data Logger**: DTC and diagnostic data collection
- **Fleet Manager**: Multi-vehicle diagnostic orchestration

### File Paths (Absolute)
```
/home/rpi/Opensource/automotive-claude-code-agents/
├── skills/diagnostics/ecu-flash.yaml
├── skills/diagnostics/ecu-diagnose.yaml
├── skills/diagnostics/odx-management.yaml
├── skills/diagnostics/uds-services.yaml
├── skills/diagnostics/obd-ii.yaml
├── skills/diagnostics/doip.yaml
├── tools/adapters/diagnostics/vflash_adapter.py
├── tools/adapters/diagnostics/python_uds_adapter.py
├── tools/adapters/diagnostics/obd_ii_adapter.py
├── tools/adapters/diagnostics/odxtools_adapter.py
├── agents/diagnostics/diagnostic-engineer.yaml
├── agents/diagnostics/flash-specialist.yaml
├── commands/diagnostics/ecu-flash.sh
├── commands/diagnostics/ecu-diagnose.sh
├── commands/diagnostics/odx-parse.sh
└── commands/diagnostics/dtc-read.sh
```

---

**Implementation Statistics:**
- **Total Skills**: 105 (20+25+15+20+15+10)
- **Tool Adapters**: 4 (994 total lines)
- **Agents**: 2
- **Commands**: 4
- **Protocols**: UDS, OBD-II, DoIP, KWP2000, ODX
- **Lines of Code**: ~1000+ (Python adapters) + ~500+ (Shell commands)

**Status**: ✅ COMPLETE - All diagnostic and flash programming components implemented and ready for use.
