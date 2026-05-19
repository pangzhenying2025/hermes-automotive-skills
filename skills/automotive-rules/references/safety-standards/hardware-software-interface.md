# Hardware-Software Interface (HSI) Specification Rules

> Rules for defining, documenting, and verifying the interface between
> hardware and software in automotive ECUs per ISO 26262 Part 6,
> ensuring consistent assumptions across disciplines.

## Scope

These rules apply to all ECU development where hardware and software
are designed by separate teams or organizations, covering microcontroller
peripherals, sensor interfaces, actuator drivers, communication interfaces,
and diagnostic access points.

---

## HSI Definition

The Hardware-Software Interface is the formal specification of:
- Hardware resources controlled or monitored by software
- Software assumptions about hardware behavior and timing
- Shared resources requiring coordinated access
- Safety-relevant hardware features used by software

### HSI Categories

| Category | Examples |
|----------|---------|
| **Processor** | Clock frequency, cache config, MPU regions, interrupt vectors |
| **Memory** | Flash layout, RAM sections, NVM emulation pages |
| **Peripherals** | ADC channels, PWM timers, GPIO pins, DMA channels |
| **Communication** | CAN controllers, SPI/I2C buses, Ethernet MAC |
| **Sensors** | ADC input ranges, filter characteristics, conversion formulas |
| **Actuators** | PWM duty cycle to physical output mapping, enable/disable logic |
| **Diagnostics** | Watchdog configuration, ECC capabilities, self-test modes |
| **Power** | Voltage supervisors, power modes, wakeup sources |
| **Safety** | Lockstep core config, ECC, memory protection, safe state GPIO |

---

## HSI Document Structure

### Master HSI Specification Template

```yaml
hsi_specification:
  document_id: HSI-ECU-BMS-001
  version: 3.2
  date: 2025-03-19
  hw_baseline: "BMS-HW-Rev-C Schematic Rev 3.1"
  sw_baseline: "BMS-SW v2.4.0"

  processor:
    part_number: "TC397XP"
    manufacturer: "Infineon"
    core_frequency_mhz: 300
    cores_used: [CPU0, CPU1, CPU2]
    lockstep: { enabled: true, core: CPU0 }
    fpu: { available: true, type: "single precision" }

  clock_configuration:
    system_clock_mhz: 300
    peripheral_clock_mhz: 100
    can_clock_mhz: 80
    rtc_clock_khz: 32.768
    clock_source: "External 20 MHz crystal"
    pll_configuration: "20 MHz * 15 = 300 MHz"

  memory_layout:
    flash:
      - region: "Bootloader"
        start: 0x80000000
        size_kb: 64
        access: "read-only after programming"
      - region: "Application"
        start: 0x80010000
        size_kb: 2048
        access: "read-only, executable"
      - region: "Calibration"
        start: 0x80210000
        size_kb: 128
        access: "read-only, SW-updatable"
      - region: "NVM Emulation"
        start: 0x80230000
        size_kb: 64
        access: "read-write via NVM driver"

    ram:
      - region: "Safety Critical Data"
        start: 0x70000000
        size_kb: 32
        access: "MPU restricted to safety tasks"
        ecc: true
      - region: "Application Data"
        start: 0x70008000
        size_kb: 192
        access: "read-write"
        ecc: true
      - region: "DMA Buffers"
        start: 0x70038000
        size_kb: 16
        access: "DMA + CPU read-write"
        ecc: false
```

### Peripheral Interface Specifications

```yaml
  adc_interfaces:
    - id: ADC-001
      peripheral: "VADC Group 0"
      channel: 0
      signal_name: "CELL_VOLTAGE_1"
      pin: "AN0 (P40.0)"
      input_range_v: { min: 0.0, max: 5.0 }
      resolution_bits: 12
      conversion_time_us: 2.5
      reference_voltage_v: 5.0
      physical_range: { min: 0.0, max: 4.5, unit: "V" }
      transfer_function: "V_cell = (ADC_raw / 4095) * 5.0 * R_divider_ratio"
      r_divider_ratio: 0.9
      accuracy_lsb: 2
      sampling_rate_hz: 1000
      anti_alias_filter: { type: "RC", cutoff_hz: 500 }
      safety_relevant: true
      asil: C
      failure_modes:
        - "Stuck-at-zero: Open sense wire"
        - "Stuck-at-max: Short to VREF"
        - "Drift: Temperature coefficient of divider resistors"

    - id: ADC-002
      peripheral: "VADC Group 0"
      channel: 1
      signal_name: "PACK_CURRENT"
      pin: "AN1 (P40.1)"
      input_range_v: { min: 0.0, max: 5.0 }
      resolution_bits: 12
      transfer_function: "I_pack = ((ADC_raw / 4095) * 5.0 - 2.5) / 0.005"
      # Bipolar: 2.5V = 0A, 0V = -500A, 5V = +500A
      physical_range: { min: -500.0, max: 500.0, unit: "A" }
      accuracy_percent: 1.0
      sampling_rate_hz: 10000
      safety_relevant: true
      asil: D
```

### GPIO Interface Specifications

```yaml
  gpio_interfaces:
    - id: GPIO-001
      pin: "P33.0"
      signal_name: "MAIN_CONTACTOR_ENABLE"
      direction: output
      active_level: high
      default_state: low  # Contactor open at reset
      drive_strength_ma: 20
      external_circuit: "N-MOSFET gate driver to contactor coil"
      timing:
        max_propagation_delay_us: 50
        min_pulse_width_us: 1000  # Debounce on receiving end
      safety_relevant: true
      asil: D
      safe_state_value: low  # Open contactor
      failure_modes:
        - "Stuck-at-high: Contactor remains closed (HW watchdog backup)"
        - "Stuck-at-low: Contactor cannot close (availability impact)"

    - id: GPIO-002
      pin: "P33.1"
      signal_name: "PRECHARGE_RELAY_ENABLE"
      direction: output
      active_level: high
      default_state: low
      timing:
        max_on_duration_ms: 5000  # Timeout protection
      safety_relevant: true
      asil: C
```

### Communication Interface Specifications

```yaml
  can_interfaces:
    - id: CAN-001
      peripheral: "MCAN0"
      pins: { tx: "P20.8", rx: "P20.7" }
      baudrate_kbps: 500
      protocol: "CAN 2.0B"
      bus_name: "BMS_INTERNAL_CAN"
      termination: "120 ohm on-board"
      messages:
        tx:
          - msg_id: 0x100
            name: "BMS_Status"
            dlc: 8
            cycle_time_ms: 100
            signals:
              - name: "PackVoltage"
                start_bit: 0
                length: 16
                factor: 0.1
                offset: 0
                unit: "V"
                range: { min: 0, max: 600 }
              - name: "PackCurrent"
                start_bit: 16
                length: 16
                factor: 0.1
                offset: -3200
                unit: "A"
                range: { min: -500, max: 500 }
        rx:
          - msg_id: 0x200
            name: "Charger_Command"
            dlc: 8
            timeout_ms: 500
            timeout_action: "Set charger current request to 0"

    - id: CAN-002
      peripheral: "MCAN1"
      baudrate_kbps: 500
      bus_name: "VEHICLE_CAN"
      protocol: "CAN FD"
      max_payload_bytes: 64
```

### Watchdog Specification

```yaml
  watchdog:
    type: "Internal + External"
    internal:
      peripheral: "SCU Watchdog"
      timeout_ms: 50
      window_start_ms: 25  # Must not trigger before 25 ms
      password_protected: true
      safety_relevant: true
      asil: D
      sw_responsibility: >
        Software must service watchdog in main loop.
        Missed service triggers MCU reset.

    external:
      part_number: "TPS3851"
      timeout_ms: 100
      wdi_pin: "P33.5"
      wdo_connection: "MCU PORST (Power-On Reset)"
      safety_relevant: true
      asil: D
      sw_responsibility: >
        Software must toggle WDI pin at least every 100 ms.
        Failure triggers full ECU reset.
```

---

## HSI Verification Rules

### Verification Methods

| HSI Element | Verification Method | Tool |
|-------------|-------------------|------|
| Memory layout | Linker map file analysis | Custom script |
| ADC accuracy | Calibrated voltage source test | HIL bench |
| GPIO timing | Oscilloscope measurement | HIL bench |
| CAN signals | Bus analyzer capture | CANalyzer |
| Watchdog timing | Triggered reset observation | HIL + scope |
| Interrupt latency | Timestamp measurement | Trace tool |
| Clock accuracy | Frequency counter | Lab equipment |
| Power modes | Current consumption measurement | Bench supply |

### Automated HSI Verification

```python
# HSI verification script - runs as part of CI
def verify_memory_layout(linker_map_path: str, hsi_spec: dict) -> list:
    """Verify linker output matches HSI memory layout specification."""
    violations = []
    map_sections = parse_linker_map(linker_map_path)

    for region in hsi_spec["memory_layout"]["flash"]:
        section = map_sections.get(region["region"])
        if section is None:
            violations.append(
                f"Region '{region['region']}' not found in linker map")
            continue
        if section["start"] != region["start"]:
            violations.append(
                f"Region '{region['region']}' start mismatch: "
                f"expected {hex(region['start'])}, "
                f"got {hex(section['start'])}")
        if section["size"] > region["size_kb"] * 1024:
            violations.append(
                f"Region '{region['region']}' exceeds allocated size: "
                f"{section['size']} > {region['size_kb'] * 1024}")

    return violations
```

### HSI Consistency Checks

```yaml
consistency_checks:
  - check: "ADC channel assignments match schematic"
    method: "Cross-reference HSI ADC table with schematic net names"
    frequency: "Every HW revision"

  - check: "CAN message definitions match DBC file"
    method: "Automated DBC parser vs HSI CAN table"
    frequency: "Every SW build"

  - check: "GPIO default states match safe state requirements"
    method: "Review default_state vs safe_state_value"
    frequency: "Every HSI revision"

  - check: "Memory regions do not overlap"
    method: "Automated range overlap detection"
    frequency: "Every HSI revision"

  - check: "Interrupt priorities do not conflict"
    method: "Priority assignment table review"
    frequency: "Every SW release"
```

---

## Change Management

### HSI Change Process

```
1. Change request from HW or SW team
2. Impact analysis on both sides
3. HSI specification update (tracked in version control)
4. Review by HW lead, SW lead, and safety engineer
5. Update affected FMEA/FTA if safety-relevant
6. Update verification test cases
7. Re-verify changed interfaces
8. Release updated HSI with cross-reference to HW/SW versions
```

### HSI Compatibility Matrix

```
+----------+----------+----------+----------+
|          | HW Rev A | HW Rev B | HW Rev C |
+----------+----------+----------+----------+
| SW v1.0  |   OK     |  N/A     |  N/A     |
| SW v2.0  |   OK*    |   OK     |  N/A     |
| SW v2.4  |  INCOMPAT|   OK*    |   OK     |
| SW v3.0  |  INCOMPAT| INCOMPAT |   OK     |
+----------+----------+----------+----------+
* = Compatible with known limitations (see release notes)
```

---

## Common HSI Defects

| Defect Category | Example | Prevention |
|----------------|---------|------------|
| Missing interface | ADC channel used but not in HSI | HSI completeness review |
| Wrong polarity | Active-high in SW, active-low in HW | Schematic cross-check |
| Wrong units | HSI says mV, SW treats as V | Unit documentation + review |
| Timing mismatch | SW assumes 1us ADC, HW needs 10us | Timing specification review |
| Range mismatch | SW expects 0-5V, HW outputs 0-3.3V | Range verification |
| Missing pull-up/down | SW expects defined level, pin floating | Default state review |
| Clock misconfiguration | Peripheral clock different than assumed | Clock tree review |
| DMA conflict | Two peripherals sharing DMA channel | Resource allocation table |

---

## Review Checklist

- [ ] HSI specification covers all interface categories
- [ ] Every ADC channel has transfer function and accuracy specification
- [ ] Every GPIO has direction, default state, and safe state defined
- [ ] CAN messages match DBC file definitions
- [ ] Memory layout verified against linker map
- [ ] Watchdog configuration documented with SW responsibilities
- [ ] Interrupt priorities documented with no conflicts
- [ ] Clock configuration documented with all derived clocks
- [ ] Safety-relevant interfaces identified with ASIL rating
- [ ] HSI version tracked with HW/SW compatibility matrix
- [ ] Automated consistency checks in CI pipeline
- [ ] HSI changes follow formal change management process
