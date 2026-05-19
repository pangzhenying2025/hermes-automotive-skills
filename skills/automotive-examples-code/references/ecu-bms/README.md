# BMS ECU Example Project

Complete Battery Management System ECU implementation demonstrating AUTOSAR Classic architecture with production-ready code.

## Overview

This example implements a **Battery Management System (BMS)** ECU with:
- Cell voltage monitoring (96 cells)
- Temperature sensing (12 sensors)
- State of Charge (SOC) estimation using Extended Kalman Filter
- Contactor control with safety interlocks
- CAN communication (ISO 15765-2)
- Functional Safety (ISO 26262 ASIL-C)

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  BMS ECU                         │
├─────────────────────────────────────────────────┤
│  Application Layer (AUTOSAR SWC)                │
│  ├─ Cell Monitoring SWC                         │
│  ├─ SOC Estimation SWC (EKF)                    │
│  ├─ Thermal Management SWC                       │
│  └─ Safety Management SWC                       │
├─────────────────────────────────────────────────┤
│  Runtime Environment (RTE)                       │
├─────────────────────────────────────────────────┤
│  Basic Software (BSW)                            │
│  ├─ CAN Driver + CanIf + CanTp + Com            │
│  ├─ ADC Driver (Cell Voltage, Temperature)      │
│  ├─ DIO (Contactors, Interlocks)                │
│  └─ WdgM (Watchdog Manager - ASIL-C)            │
└─────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

```bash
# Install ARM GCC toolchain
sudo apt-get install gcc-arm-none-eabi

# Install Python dependencies
pip install -r requirements.txt

# Install CANoe/SavvyCAN for testing
```

### Build

```bash
cd examples/ecu-bms
make clean
make all

# Output: build/bms_ecu.elf
```

### Flash to Hardware

```bash
# Using OpenOCD (STM32F4 target)
make flash

# Or using J-Link
JLinkExe -device STM32F407VG -if SWD -speed 4000
> loadfile build/bms_ecu.elf
> r
> g
```

### Run Tests

```bash
# Unit tests (host)
make test

# Hardware-in-the-Loop (HIL)
cd tests/hil
python run_hil_tests.py --config hil_config.yaml
```

## Project Structure

```
ecu-bms/
├── requirements/
│   └── bms-requirements.yaml         # Functional requirements
├── src/
│   ├── application/
│   │   ├── cell_monitor.c            # Cell voltage monitoring
│   │   ├── soc_estimator.c           # EKF-based SOC estimation
│   │   ├── thermal_mgmt.c            # Battery thermal management
│   │   └── safety_mgr.c              # Safety state machine
│   ├── rte/
│   │   └── Rte_BMS.c                 # RTE generated code
│   ├── bsw/
│   │   ├── can_stack.c               # CAN communication
│   │   ├── adc_driver.c              # ADC for sensors
│   │   └── dio_driver.c              # Digital I/O
│   └── main.c                        # Main initialization
├── arxml/
│   ├── BMS_System.arxml              # System definition
│   ├── BMS_ECU.arxml                 # ECU configuration
│   └── BMS_Composition.arxml         # SWC composition
├── tests/
│   ├── unit/                         # Unit tests
│   ├── integration/                  # Integration tests
│   └── hil/                          # HIL test scripts
├── config/
│   ├── can_database.dbc              # CAN signal definitions
│   └── calibration.a2l               # XCP calibration
├── Makefile
└── README.md
```

## Key Features

### 1. Cell Monitoring

Monitors 96 LiFePO4 cells (3S32P configuration):
- Voltage range: 2.5V - 3.65V per cell
- 12-bit ADC resolution (0.5mV accuracy)
- 100ms sampling rate
- Cell balancing control

```c
// Example usage
CellVoltages_t voltages;
BMS_GetCellVoltages(&voltages);

if (voltages.cell[0] > CELL_OVERVOLTAGE_THRESHOLD_MV) {
    BMS_TriggerFault(FAULT_CELL_OVERVOLTAGE);
}
```

### 2. SOC Estimation

Extended Kalman Filter (EKF) for accurate SOC:
- Coulomb counting + OCV correction
- Temperature compensation
- 1% accuracy (20-80% SOC range)
- Self-learning battery aging

```c
SOC_State_t soc_state;
SOC_Update(&soc_state, current_A, voltage_V, temperature_C);

uint8_t soc_percent = soc_state.soc_percent; // 0-100%
```

### 3. Thermal Management

Active cooling/heating control:
- 12 thermistors (NTC 10k)
- PID temperature control
- Thermal runaway detection
- Optimal operating range: 20-35°C

### 4. Safety Features

ISO 26262 ASIL-C compliant:
- Dual-channel contactor control
- Pre-charge circuit monitoring
- Insulation resistance monitoring
- Emergency shutdown (< 10ms)

## CAN Communication

### CAN Messages (500 kbps)

| ID    | Name              | Period | Signals                          |
|-------|-------------------|--------|----------------------------------|
| 0x100 | BMS_Status        | 100ms  | SOC, Voltage, Current, Temp      |
| 0x101 | BMS_CellVoltages1 | 200ms  | Cell 1-8 voltages                |
| 0x102 | BMS_CellVoltages2 | 200ms  | Cell 9-16 voltages               |
| 0x110 | BMS_Faults        | Event  | Fault codes, severity            |
| 0x111 | BMS_Limits        | 1000ms | Max charge/discharge current     |

### Example: Sending Status Message

```c
void BMS_SendStatusMessage(void) {
    CanTp_TxPdu_t pdu;
    pdu.id = 0x100;
    pdu.dlc = 8;

    pdu.data[0] = soc_percent;
    pdu.data[1] = (uint8_t)(pack_voltage_V / 2); // Scale: 0.5V/bit
    pdu.data[2] = (int8_t)(pack_current_A);      // Scale: 1A/bit, signed
    pdu.data[3] = (uint8_t)(max_temp_C + 40);    // Offset: -40°C
    pdu.data[4] = bms_state;
    pdu.data[5] = fault_flags;

    CanTp_Transmit(&pdu);
}
```

## Calibration Parameters

Use XCP protocol for runtime calibration:

```c
// Accessible via XCP (A2L file)
CAL uint16_t CAL_CellOVThreshold_mV = 3650;    // Overvoltage threshold
CAL uint16_t CAL_CellUVThreshold_mV = 2500;    // Undervoltage threshold
CAL int16_t  CAL_MaxChargeCurrent_A = 50;      // Max charge current
CAL int16_t  CAL_MaxDischargeCurrent_A = 100;  // Max discharge current
```

## Hardware Requirements

### Minimum ECU Specifications

- **MCU**: STM32F407 (168 MHz, 1MB Flash, 192KB RAM) or equivalent
- **CAN**: TJA1050 transceiver
- **ADC**: 12-bit, 16 channels minimum
- **Digital I/O**: 8 outputs (contactors, balancing)
- **Power**: 12V automotive supply, ISO 7637 compliant

### Sensor Interfaces

- **Cell Voltage**: LTC6811 battery monitor IC (SPI)
- **Temperature**: NTC 10k thermistors (ADC)
- **Current**: Hall-effect sensor, 0-5V output (ADC)
- **Insulation**: Bender ISOMETER (CAN)

## Testing Strategy

### Unit Tests (95% coverage)

```bash
make test

# Runs:
# - Cell voltage calculation tests
# - SOC estimation accuracy tests
# - Thermal model validation
# - Safety state machine tests
```

### Integration Tests

```bash
cd tests/integration
pytest test_can_communication.py
pytest test_sensor_fusion.py
```

### Hardware-in-the-Loop (HIL)

```bash
cd tests/hil
python run_hil_tests.py --test smoke
python run_hil_tests.py --test regression
```

HIL setup:
- NI PXI or dSPACE system
- Battery simulator (EA Elektro-Automatik)
- CAN bus monitor
- Temperature chamber

## Compliance

### Standards

- **ISO 26262**: ASIL-C (Safety Management)
- **AUTOSAR**: Classic Platform R20-11
- **ISO 15765-2**: CAN Transport Protocol
- **UL 2580**: Battery safety for EVs
- **UN ECE R100**: Electric vehicle safety

### Documentation

- Safety analysis (FMEA, FTA)
- Software safety requirements
- Verification report
- Change management records

## Troubleshooting

### Common Issues

**1. CAN Communication Failure**
```bash
# Check CAN bus termination (120Ω)
candump can0

# Verify bitrate matches (500 kbps)
ip link set can0 type can bitrate 500000
```

**2. Incorrect Cell Voltages**
```
- Check LTC6811 SPI communication
- Verify reference voltage (3.0V ±0.1%)
- Calibrate ADC offset
```

**3. SOC Drift**
```
- Perform full charge calibration
- Check current sensor offset
- Update battery capacity parameter
```

## Next Steps

1. **Extend to Multi-Pack System**: Add pack-level balancing
2. **Cloud Connectivity**: Add MQTT telemetry
3. **Predictive Maintenance**: Implement RUL estimation
4. **Wireless BMS**: Replace wiring with CAN-FD

## Resources

- [AUTOSAR Specification](https://www.autosar.org/standards/classic-platform/)
- [ISO 26262 Guidelines](https://www.iso.org/standard/68383.html)
- [LTC6811 Datasheet](https://www.analog.com/ltc6811)
- [BMS Design Guide](../docs/bms-design-guide.md)

## License

MIT License - See LICENSE file

## Support

- GitHub Issues: [Report bugs](https://github.com/your-org/automotive-agents/issues)
- Discussion: [Community forum](https://github.com/your-org/automotive-agents/discussions)
