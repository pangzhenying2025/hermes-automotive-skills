---
name: automotive-hardware-safety
description: >
  Calculate and verify diagnostic coverage for safety mechanisms Covers 4 topics across hardware-safety domain. Includes 4 skill files covering .
tags: [asil, automotive, automotive-hardware-safety, diagnostic-coverage, fmeda, hardware-safety, hardware-software-interface, hsi, integration, iso-26262, lfm, pmhf, safety-mechanisms, spfm]
---

# Automotive Hardware Safety

4 skill files covering hardware-safety domain for automotive software engineering.


## Instructions

### Diagnostic Coverage Analysis

You are an expert in diagnostic coverage analysis per ISO 26262.

**What is Diagnostic Coverage (DC):**
DC is the ratio of detected faults to total faults for a given failure mode.

**Formula:**
DC = λ_detected / (λ_detected + λ_undetected)

Where:
- λ_detected: Failure rate detected by safety mechanism
- λ_undetected: Residual failure rate (not detected)

**Diagnostic Coverage Levels (ISO 26262-5 Table 6):**
- DC = 0%: None (no diagnostic)
- DC < 60%: Low
- 60% ≤ DC < 90%: Medium
- 90% ≤ DC < 99%: High
- DC ≥ 99%: Very High

**Sources of Diagnostic Coverage:**

**1. Hardware Diagnostics:**
- Plausibility checks (range, gradient, correlation)
- Redundancy and voting (dual sensors, triple modular redundancy)
- Self-tests (BIST, RAM/ROM tests)
- Watchdog timers
- Memory protection (ECC, parity, CRC)
- Voltage/temperature monitoring

**2. Software Diagnostics:**
- Control flow monitoring
- Data integrity checks (checksums, CRCs)
- Alive counters
- Sequence monitoring
- Logical execution time monitoring

**Diagnostic Coverage by Mechanism:**

| Safety Mechanism | Typical DC | ISO 26262 Reference |
|------------------|-----------|---------------------|
| Plausibility check (range) | 60-70% | Part 5, Annex D |
| Dual sensor with voting | 90-95% | Part 5, Annex D |
| Triple modular redundancy | 99%+ | Part 5, Annex D |
| Watchdog timer | 90-95% | Part 6, Annex B |
| ECC memory | 95-99% | Part 5, Annex D |
| CRC on communication | 99%+ | Part 6, Annex B |

**Calculating Overall DC:**

For multiple diagnostics on same element:
DC_total = 1 - Π(1 - DC_i) for independent diagnostics

Example:
- Plausibility check: DC1 = 70%
- Redundant sensor: DC2 = 90%
- DC_total = 1 - (1 - 0.7)(1 - 0.9) = 1 - (0.3)(0.1) = 1 - 0.03 = 97%

**Verification of DC:**

DC must be verified, not just claimed. Methods:
- Fault injection testing (software/hardware)
- Formal verification
- Analysis (for well-established mechanisms)

**Fault Injection:**
- Inject faults into hardware (voltage glitch, bit flip)
- Verify safety mechanism detects fault
- Calculate observed DC from test results

**Example:**
- Inject 100 faults into RAM
- ECC detects 97 faults
- Observed DC = 97/100 = 97%

**Impact on ASIL Metrics:**

High DC enables:
- Lower PMHF (fewer residual faults)
- Higher SPFM (more single-point faults detected)
- Possible ASIL decomposition (if DC ≥ 99%)

**DC in ASIL Decomposition:**

To decompose ASIL D(D) → ASIL B(D) + ASIL B(D):
- Safety mechanism must have DC ≥ 99%
- Both elements developed to ASIL B
- Dependent failure analysis (DFA) required

### HSI - Hardware-Software Interface Safety

You are an expert in Hardware-Software Interface (HSI) safety per ISO 26262.

**What is HSI:**
HSI is the boundary between hardware and software elements where they interact.
Critical for safety as errors at this interface can bypass both HW and SW safety mechanisms.

**ISO 26262 Requirements:**
- Part 4 (System): 7.4.7 - Interface specification
- Part 5 (Hardware): 7.4.7 - HSI requirements from hardware perspective
- Part 6 (Software): 7.4.7 - HSI requirements from software perspective

**Common HSI Elements:**

**1. Memory-Mapped I/O:**
- Peripheral registers (GPIO, CAN, ADC, PWM)
- Configuration registers
- Status/control registers

**2. Interrupts:**
- Interrupt vectors
- Interrupt priorities
- Interrupt service routines (ISRs)

**3. Direct Memory Access (DMA):**
- DMA descriptors
- Memory regions accessible by DMA
- DMA priorities

**4. Timers and Watchdogs:**
- Timer configurations
- Watchdog timeout settings
- Time base synchronization

**HSI Safety Hazards:**

**Incorrect Register Configuration:**
- Wrong peripheral mode (input vs output)
- Incorrect clock divider → wrong timing
- Disabled safety-critical interrupt

**Memory Corruption:**
- DMA overwrites safety-critical data
- Stack overflow into peripheral registers
- Wild pointer access to hardware

**Timing Violations:**
- Missed real-time deadlines
- Interrupt latency too high
- Watchdog timeout misconfigured

**HSI Safety Mechanisms:**

**1. Register Protection:**
- Write-once registers (configuration locked after init)
- Protected registers (password/sequence to unlock)
- Read-back verification after write

**2. Memory Protection:**
- MPU (Memory Protection Unit) to isolate HW registers
- DMA access control lists
- Stack guard regions

**3. Initialization Verification:**
- CRC over configuration data
- Read-back and compare after init
- Self-tests during startup

**4. Runtime Monitoring:**
- Plausibility checks on sensor values
- Watchdog monitoring
- Interrupt counter (detect missed interrupts)

**HSI Design Guidelines (ISO 26262-6 Annex D):**

**DO:**
- Document all register accesses
- Use hardware abstraction layer (HAL)
- Verify register writes with read-back
- Protect critical registers with MPU
- Use compile-time constants for addresses

**DON'T:**
- Use magic numbers for register values
- Access registers without volatile qualifier
- Modify registers from multiple contexts without mutex
- Assume reset values are correct
- Disable interrupts for long periods

**Example HSI Safety Requirement:**

"The software shall verify that the ADC configuration register (ADCCON)
is set to 0x1234 after initialization. If verification fails, the system
shall enter safe state."

**Code Example (C):**
```c
// Hardware abstraction - safe register write
bool SafeRegisterWrite(volatile uint32_t* reg, uint32_t value) {
    *reg = value;
    __DSB();  // Data Synchronization Barrier
    uint32_t readback = *reg;
    return (readback == value);  // Verify write successful
}

// Initialize ADC with verification
bool InitADC(void) {
    if (!SafeRegisterWrite(&ADC->CON, ADC_CONFIG_VALUE)) {
        // Verification failed - enter safe state
        EnterSafeState();
        return false;
    }
    return true;
}
```

**HSI Testing:**
- Fault injection (corrupt registers, flip bits)
- Timing analysis (WCET, interrupt latency)
- Memory protection tests (illegal access attempts)

### PMHF - Probabilistic Metric for Hardware Failures

You are an expert in PMHF (Probabilistic Metric for Hardware Failures) per ISO 26262-5.

**What is PMHF:**
PMHF is the average probability per hour that a hardware random fault leads to
violation of a safety goal. Required metric for ISO 26262-5:8.

**PMHF Targets (ISO 26262-5 Table 4):**
- ASIL A: Not specified (use good engineering practice)
- ASIL B: < 100 FIT
- ASIL C: < 100 FIT
- ASIL D: < 10 FIT

**FIT = Failures In Time (failures per 10^9 hours)**

**PMHF Calculation Formula:**

For each failure mode:
- λ = failure rate (FIT)
- K_MPF,RF = Multi-Point Failure factor
- K_IF = Inter-connection Failure factor

PMHF = Σ (λ_SM × K_MPF,RF) + Σ (λ_RF × K_IF)

Where:
- λ_SM: Single-point failure rate
- λ_RF: Residual failure rate (undetected)
- K_MPF,RF ≤ 1 (typically 0.01 to 0.1)
- K_IF ≤ 1

**Simplified PMHF (single element):**

PMHF_SM = λ_SM × (1 - DC)
PMHF_RF = λ_RF

Total PMHF = PMHF_SM + PMHF_RF

Where DC = Diagnostic Coverage

**Example Calculation:**

ECU Microcontroller:
- λ_total = 50 FIT (from reliability database)
- Diagnostic Coverage (DC) = 90% = 0.9
- λ_SM (single-point) = λ_total × (1 - DC) = 50 × 0.1 = 5 FIT
- λ_RF (residual) = λ_total × DC × (1 - SPFM) = 50 × 0.9 × 0.05 = 2.25 FIT
- PMHF = 5 + 2.25 = 7.25 FIT

**Result**: 7.25 FIT < 10 FIT → **Meets ASIL D target** ✓

**PMHF Inputs:**
- Component failure rates (from IEC TR 62380, SN 29500, FIDES)
- Diagnostic coverage (from FMEDA)
- SPFM (Single-Point Fault Metric)
- LFM (Latent Fault Metric)

**Common Mistakes:**
- Using wrong failure rate database (automotive vs industrial)
- Not accounting for mission profile (temperature, vibration)
- Ignoring multi-point failures
- Incorrect DC estimation (must validate with fault injection)

**Tools:**
- Ansys Medini Analyze
- ReqSuite (SPICE)
- Excel spreadsheets

**ISO 26262-5 Requirements:**
- 8.4.2: Calculate PMHF for each safety goal
- 8.4.3: Verify PMHF < target
- 8.4.4: Document assumptions and justifications

### SPFM & LFM - Hardware Safety Metrics

You are an expert in SPFM and LFM hardware safety metrics per ISO 26262-5.

**SPFM - Single-Point Fault Metric**

SPFM measures the effectiveness of safety mechanisms in detecting single-point faults.

**Formula:**
SPFM = Σλ_S,detected / (Σλ_S,detected + Σλ_S,residual)

Where:
- λ_S,detected: Detected single-point fault rate
- λ_S,residual: Undetected single-point fault rate (residual)

**SPFM Targets (ISO 26262-5 Table 5):**
- ASIL A: Not specified
- ASIL B: ≥ 90%
- ASIL C: ≥ 97%
- ASIL D: ≥ 99%

**Example SPFM Calculation:**

Sensor:
- Total failure rate: 100 FIT
- Detected by plausibility check: 95 FIT
- Undetected (residual): 5 FIT

SPFM = 95 / (95 + 5) = 95 / 100 = 0.95 = **95%**

For ASIL C: 95% < 97% → **Does NOT meet target** ✗
Need additional diagnostic (e.g., redundant sensor)

---

**LFM - Latent Fault Metric**

LFM measures the effectiveness of safety mechanisms in detecting multi-point latent faults.

**Formula:**
LFM = Σλ_M,detected / (Σλ_M,detected + Σλ_M,residual)

Where:
- λ_M,detected: Detected multi-point latent fault rate
- λ_M,residual: Undetected multi-point latent fault rate

**LFM Targets (ISO 26262-5 Table 5):**
- ASIL A: Not specified
- ASIL B: ≥ 60%
- ASIL C: ≥ 80%
- ASIL D: ≥ 90%

**Latent Fault:**
A fault present in the system but not detected until a second independent fault occurs,
leading to a multi-point failure.

**Example LFM Calculation:**

Backup sensor (only used if primary fails):
- Total latent failure rate: 50 FIT
- Detected by periodic self-test: 40 FIT (every ignition cycle)
- Undetected: 10 FIT

LFM = 40 / (40 + 10) = 40 / 50 = 0.80 = **80%**

For ASIL C: 80% ≥ 80% → **Meets target** ✓

---

**Relationship: SPFM, LFM, PMHF**

All three metrics are derived from FMEDA (Failure Modes, Effects, and Diagnostic Analysis):
- FMEDA identifies failure modes and diagnostic coverage
- SPFM/LFM evaluate diagnostic effectiveness
- PMHF quantifies residual risk

**Improving SPFM:**
- Add plausibility checks (range, gradient, correlation)
- Redundant sensors (voting)
- Built-in self-test (BIST)
- Watchdog timers
- Memory protection (ECC, parity)

**Improving LFM:**
- Periodic self-tests (startup, shutdown, cyclic)
- Cross-checks between redundant elements
- Reduce fault detection interval
- Monitor quiescent current

**ISO 26262-5 Requirements:**
- 8.4.5: Calculate SPFM and LFM
- 8.4.6: Verify metrics meet targets
- 8.4.7: Document diagnostic coverage assumptions
