# Battery Management System - Quick Reference

## Cell Datasheet Parameters

### NMC (Nickel Manganese Cobalt) 811

| Parameter | Value | Notes |
|-----------|-------|-------|
| Nominal voltage | 3.7V | Average operating voltage |
| Charge cutoff | 4.2V | Max safe voltage |
| Discharge cutoff | 2.5V | Min safe voltage (2.7V recommended) |
| Nominal capacity | 3.0-5.0 Ah | Per 18650/21700 cell |
| Max cont. discharge | 2C-3C | Depends on cell design |
| Max pulse discharge | 5C-10C | <30 seconds |
| Max charge rate | 1C | Standard; 2C+ with precautions |
| Operating temp (charge) | 0-45°C | Derating above 35°C |
| Operating temp (discharge) | -20-60°C | Derating below 0°C |
| Cycle life (80% DOD) | 1000-2000 | At 25°C |
| Calendar life | 10-15 years | At 25°C, 50% SOC storage |
| Internal resistance | 15-30 mΩ | At 50% SOC, 25°C |
| Thermal runaway temp | ~200°C | Exothermic reaction onset |

### LFP (Lithium Iron Phosphate)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Nominal voltage | 3.2V | Flatter discharge curve |
| Charge cutoff | 3.65V | More forgiving than NMC |
| Discharge cutoff | 2.0V | Wide voltage range |
| Nominal capacity | 2.5-3.5 Ah | Lower than NMC |
| Max cont. discharge | 3C-5C | Better power capability |
| Max charge rate | 1C (3C capable) | Fast charge friendly |
| Operating temp (charge) | 0-55°C | |
| Operating temp (discharge) | -20-60°C | |
| Cycle life (80% DOD) | 3000-5000 | Superior cycle life |
| Calendar life | 15-20 years | Very stable |
| Internal resistance | 20-40 mΩ | Slightly higher than NMC |
| Thermal runaway temp | >270°C | Safer chemistry |

### NCA (Nickel Cobalt Aluminum)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Nominal voltage | 3.6V | |
| Charge cutoff | 4.2V | |
| Discharge cutoff | 2.5V | |
| Nominal capacity | 3.0-4.8 Ah | High energy density |
| Max cont. discharge | 2C | Power-limited vs NMC |
| Max charge rate | 0.7C | Conservative |
| Cycle life (80% DOD) | 500-1000 | Lower than NMC/LFP |
| Internal resistance | 20-35 mΩ | |
| Thermal runaway temp | ~180°C | Requires careful management |

## Typical Voltage Curves

### NMC Discharge Curve (1C rate, 25°C)

```
SOC%  |  OCV (V)  |  Notes
------|-----------|------------------
100   |   4.20    |  Fully charged
 90   |   4.05    |
 80   |   3.95    |
 70   |   3.88    |
 60   |   3.82    |  Knee region begins
 50   |   3.76    |
 40   |   3.70    |  Stable region
 30   |   3.64    |
 20   |   3.55    |
 10   |   3.40    |  Rapid voltage drop
  0   |   2.50    |  Fully discharged
```

### LFP Discharge Curve (1C rate, 25°C)

```
SOC%  |  OCV (V)  |  Notes
------|-----------|------------------
100   |   3.65    |  Fully charged
 90   |   3.35    |  Rapid drop
 80   |   3.28    |
 70   |   3.26    |  Very flat plateau
 60   |   3.25    |
 50   |   3.24    |  Difficult to estimate SOC here
 40   |   3.23    |
 30   |   3.21    |
 20   |   3.15    |  Plateau ends
 10   |   3.00    |
  0   |   2.00    |  Fully discharged
```

## Capacity Tables

### Temperature Derating (NMC)

| Temperature | Usable Capacity | Notes |
|-------------|-----------------|-------|
| -20°C | 70% | Severe derating, risk of lithium plating if charged |
| -10°C | 80% | Moderate derating |
| 0°C | 90% | Slight derating, no charging recommended below 0°C |
| 10°C | 95% | |
| 25°C | 100% | Reference temperature |
| 35°C | 98% | Slight capacity increase, faster aging |
| 45°C | 95% | Accelerated aging |
| 55°C | 90% | Severe aging risk |

### C-Rate Capacity Impact

| Discharge Rate | Available Capacity | Voltage Sag |
|----------------|-------------------|-------------|
| 0.2C | 105% | Minimal |
| 0.5C | 102% | Low |
| 1C | 100% | Reference |
| 2C | 95% | Moderate |
| 3C | 90% | High |
| 5C | 80% | Severe (avoid sustained) |

## Communication Protocols

### CAN BMS Messages (J1939 Format)

```c
// Battery Status Message (10 Hz)
#define CAN_ID_BMS_STATUS 0x18FF50E5
struct BMS_Status {
    uint8_t SOC_percent;           // 0-100%
    uint8_t SOH_percent;           // 0-100%
    uint16_t pack_voltage_dV;      // Voltage in 0.1V (e.g., 3600 = 360.0V)
    int16_t pack_current_dA;       // Current in 0.1A (signed, + = discharge)
    int8_t max_temp_degC;          // Max cell temperature
    int8_t min_temp_degC;          // Min cell temperature
};

// Power Limits Message (100 Hz)
#define CAN_ID_BMS_LIMITS 0x18FF51E5
struct BMS_Limits {
    uint16_t max_charge_power_kW;       // 0-6553.5 kW (0.1 kW resolution)
    uint16_t max_discharge_power_kW;
    uint16_t max_charge_current_dA;     // 0-655.35 A (0.01 A resolution)
    uint16_t max_discharge_current_dA;
    uint16_t reserved;
};

// Fault Status Message (Event-driven, 10 Hz when fault present)
#define CAN_ID_BMS_FAULTS 0x18FF52E5
struct BMS_Faults {
    uint8_t fault_flags_1;  // Bit 0: Overvoltage, Bit 1: Undervoltage, etc.
    uint8_t fault_flags_2;
    uint8_t warning_flags_1;
    uint8_t warning_flags_2;
    uint16_t fault_cell_id;  // Cell ID if cell-level fault
    uint8_t fault_severity;  // 0: Info, 1: Warning, 2: Error, 3: Critical
    uint8_t reserved;
};
```

### I2C/SPI Cell Monitoring

```c
// Example: LTC6811 (Linear Technology)
// SPI Commands
#define CMD_WRCFG   0x0001  // Write Configuration Register Group
#define CMD_RDCFG   0x0002  // Read Configuration Register Group
#define CMD_RDCVA   0x0004  // Read Cell Voltage Register Group A
#define CMD_RDCVB   0x0006  // Read Cell Voltage Register Group B
#define CMD_RDAUX   0x000C  // Read Auxiliary Register Group
#define CMD_RDSTAT  0x0010  // Read Status Register Group
#define CMD_ADCV    0x0260  // Start Cell Voltage ADC Conversion
#define CMD_ADAX    0x0460  // Start Aux ADC Conversion

// Voltage reading: 16-bit value in 100μV units
// Example: 0x9C40 = 40000 → 4.0000V

// Temperature reading (via NTC on aux input):
// V_aux → R_NTC via voltage divider → lookup table → Temperature
```

## Safety Limits and Fault Thresholds

### Protection Limits (NMC Example)

| Parameter | Warning | Error | Critical | Action |
|-----------|---------|-------|----------|--------|
| Cell voltage high | 4.15V | 4.25V | 4.30V | Reduce charge / Open contactors |
| Cell voltage low | 2.8V | 2.6V | 2.4V | Reduce discharge / Open contactors |
| Cell temp high | 50°C | 55°C | 60°C | Derate / Open contactors |
| Cell temp low | -15°C | -20°C | -25°C | Derate discharge |
| Pack current high (charge) | 150A | 180A | 200A | Limit current |
| Pack current high (discharge) | 300A | 350A | 400A | Limit current |
| Cell voltage imbalance | 100mV | 200mV | 300mV | Enable balancing / Fault |
| Insulation resistance | 500kΩ | 100kΩ | 50kΩ | Warning / Error / Open HV |

### Fault Response Times

| Fault Type | Detection Time | Response Time | Total Latency |
|------------|----------------|---------------|---------------|
| Overvoltage | <10 ms | <5 ms | <15 ms |
| Overcurrent | <1 ms | <2 ms | <3 ms |
| Overtemperature | <100 ms | <50 ms | <150 ms |
| Insulation fault | <500 ms | <100 ms | <600 ms |
| Short circuit | <100 μs | <500 μs | <1 ms |

## BMS IC Selection Guide

| IC Family | Vendor | Cells per IC | Voltage Accuracy | Interface | Cost/Ch | Best For |
|-----------|--------|--------------|------------------|-----------|---------|----------|
| LTC681x | Analog Devices | 12-18 | ±1.2 mV | isoSPI | $2-3 | High-end EV |
| BQ76xx | Texas Instruments | 3-16 | ±5 mV | SPI | $1-2 | Consumer/ADAS |
| MC33771/2 | NXP | 14 | ±2 mV | TPL (transformer) | $2-3 | Automotive |
| ISL94xxx | Renesas | 3-16 | ±10 mV | I2C | $0.50-1 | Low-cost ESS |
| MAX17xxx | Maxim | 1-16 | ±3 mV | I2C/SPI | $1-2 | Industrial |

## Typical System Parameters

### Passenger EV (Tesla Model 3 LR equivalent)

```
Battery Pack:
- Capacity: 75 kWh (nominal)
- Voltage: 350-400V (nominal 360V)
- Configuration: ~4400 cells (21700 format)
- Topology: 96s46p (96 series groups, 46 parallel per group)
- Weight: ~480 kg
- Chemistry: NMC 811

BMS:
- Architecture: Distributed (6 slave modules + 1 master)
- Balancing: Passive (50-100 mA per cell)
- SOC accuracy: ±1-2%
- Update rate: 100 Hz (critical data), 10 Hz (telemetry)
- Communication: CAN FD (5 Mbps)
- Safety: ASIL-D compliance

Performance:
- Max charge power: 250 kW (Supercharger V3)
- Max discharge power: 350 kW (peak)
- 0-80% charge time: 30 minutes
- Range: 350 miles (EPA)
```

## Debugging Checklist

- [ ] Cell voltages balanced within 50mV
- [ ] SOC estimate matches OCV (after 2-hour rest)
- [ ] Current sensor calibrated (check zero offset)
- [ ] Temperature sensors reading reasonable values (15-35°C ambient)
- [ ] CAN messages transmitted at correct rate
- [ ] Contactor control logic tested (open on fault)
- [ ] Insulation monitoring functional (simulate fault)
- [ ] Balancing active when needed (top-of-charge)
- [ ] Protection limits tuned per cell datasheet
- [ ] EKF covariance not diverging (check P matrix)

## Performance Targets

| Metric | Target | Acceptable | Notes |
|--------|--------|------------|-------|
| SOC accuracy | ±1% | ±3% | After initial calibration |
| SOH accuracy | ±2% | ±5% | Requires periodic capacity test |
| Voltage measurement | ±2 mV | ±5 mV | Per cell |
| Current measurement | ±0.5% | ±1% | Full scale |
| Temperature measurement | ±1°C | ±2°C | NTC accuracy |
| Latency (fault detection) | <10 ms | <50 ms | Critical faults |
| Power consumption | <5W | <10W | BMS electronics only |
| MTBF | >15 years | >10 years | Target vehicle life |

## Next Steps

- **Level 5**: Neural network SOC estimation, digital twin BMS, fleet learning
- **Standards**: ISO 26262 (functional safety), ISO 6469 (EV safety)
- **Tools**: MATLAB/Simulink Battery Toolbox, AVL CRUISE for pack simulation

## References

- Cell datasheets: Panasonic NCR18650B, LG Chem INR21700 M50, CATL LFP
- J1939 Standard: SAE J1939 Digital Annex
- LTC6811 Datasheet: Analog Devices
- IEC 62619: Secondary cells and batteries containing alkaline or other non-acid electrolytes

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All BMS engineers (quick lookup during development and debugging)
