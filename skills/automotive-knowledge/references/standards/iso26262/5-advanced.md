# ISO 26262 - Advanced Topics

## ASIL Decomposition Strategies

### When to Apply Decomposition

**Valid Use Cases**:
- Reduce development costs by avoiding full ASIL D on all elements
- Leverage existing QM or lower ASIL components
- Enable supplier qualification at lower ASIL
- Address resource constraints (ASIL D expertise limited)

**Invalid Use Cases**:
- Circumvent proper safety analysis
- Reduce verification effort inappropriately
- Avoid addressing root causes of high ASIL

### Architectural Decomposition Patterns

#### Pattern 1: Redundant Monitoring

```
Safety Goal (ASIL D): Prevent unintended acceleration

Decomposition: D = B(D) + B(D)

Element A (ASIL B developed to D):
- Primary accelerator pedal sensor
- Primary throttle control
- Independent plausibility checks
- Safe state on fault detection

Element B (ASIL B developed to D):
- Secondary accelerator pedal sensor
- Independent throttle monitor
- Override capability
- Safe state on fault detection

Independence:
- Different sensors (physical separation)
- Different microcontroller cores
- Different software teams
- Independent verification
```

#### Pattern 2: Monitor-Actuator Split

```
Safety Goal (ASIL D): Maintain steering assistance

Decomposition: D = C(D) + A(D)

Element A (ASIL C developed to D):
- Electric power steering motor control
- Torque sensor processing
- Primary control algorithm
- 70% diagnostic coverage

Element B (ASIL A developed to D):
- Independent torque monitor
- Range and plausibility checks
- Emergency override
- 30% additional diagnostic coverage

Combined coverage: > 90% (meets ASIL D)
```

#### Pattern 3: Degradation Chain

```
Safety Goal (ASIL D): Prevent loss of braking

Full function: ASIL D
- ESC with full stability control
- ABS on all wheels
- Electronic brake distribution

Degraded mode: ASIL B(D)
- Base hydraulic braking
- Mechanical brake distribution
- Driver fully responsible

Independence achieved through:
- Hydraulic backup path
- Mechanical components (low common cause)
- Clear degradation boundary
```

### Decomposition Validation

**Requirements for Valid Decomposition**:
1. Sufficiently independent elements
2. Dependent Failure Analysis (DFA) performed
3. Freedom from interference demonstrated
4. Combined elements achieve parent ASIL

**DFA Focus Areas**:
- Shared power supply (use separate regulators)
- Shared ground (separate ground paths)
- Shared clock (independent oscillators)
- Shared communication (partitioning, time/space isolation)
- EMC coupling (physical separation, shielding)
- Common software (memory protection, RTOS partitioning)

## Dependent Failure Analysis (DFA)

### DFA Methodology

**Objective**: Identify and mitigate common cause failures that violate independence assumptions.

**Process**:
1. Identify redundant elements (sensors, channels, ECUs)
2. Classify coupling factors
3. Evaluate failure propagation
4. Implement countermeasures
5. Verify residual coupling

### Coupling Factor Categories

#### Design Coupling

**Common Specification Errors**:
- Same requirements document used by both channels
- Mitigation: Independent requirements development and review

**Common Software Errors**:
- Reused library with systematic fault
- Mitigation: Diverse implementation, diverse compilers

**Common Hardware Design**:
- Same schematic used for redundant channels
- Mitigation: Diverse design (different IC families, topologies)

#### Manufacturing Coupling

**Common Production Process**:
- Same assembly line, same solder profile
- Mitigation: Different production sites or batches

**Component Batch**:
- Same IC lot for all redundant sensors
- Mitigation: Specify different date codes or manufacturers

#### Environmental Coupling

**Electromagnetic Interference**:
- Crosstalk between redundant signal wires
- Mitigation: Separate harnesses, shielding, twisted pairs

**Temperature Stress**:
- Both sensors mounted on same hot surface
- Mitigation: Physical separation, thermal barriers

**Vibration/Mechanical**:
- Both sensors on same mounting bracket
- Mitigation: Different mounting locations

**Electrical Stress**:
- Shared power supply, ground bounce
- Mitigation: Separate regulators, low-impedance grounds

### DFA Documentation Template

```
DFA Analysis: Dual Wheel Speed Sensors
Parent Requirement: ASIL D wheel speed sensing

Coupling Factor: Electrical - Shared 5V Supply
Failure Mode: Supply regulator fails to 0V
Effect: Both sensors lose power simultaneously
Probability: Medium (single component failure)
Countermeasure: Add redundant 5V regulator with diode OR
Residual Risk: Low (requires dual regulator failure)
Verification: Fault injection test - remove one regulator
Status: Mitigated

Coupling Factor: Environmental - EMC
Failure Mode: RF interference corrupts both sensor signals
Effect: Simultaneous incorrect wheel speed readings
Probability: Low (requires strong RF source)
Countermeasure: Separate shielded cables, RC filters
Residual Risk: Very low
Verification: EMC testing per ISO 11452-2
Status: Mitigated
```

### Quantitative DFA

**Beta Factor Method**:
```
β = λ_CCF / λ_total

where:
λ_CCF = Common cause failure rate
λ_total = Total failure rate
β = Beta factor (typically 0.01 to 0.10)

For redundant system:
λ_system = λ_CCF + λ_independent^2 × T_repair
         ≈ β × λ_total + (1-β)^2 × λ_total^2 × T_repair

For small β and λT_repair << 1:
λ_system ≈ β × λ_total
```

**Example**:
```
Dual sensor system:
λ_sensor = 100 FIT
β = 0.05 (5% common cause)
T_repair = 1 hour (diagnostic interval)

λ_independent = (1 - 0.05) × 100 = 95 FIT
λ_CCF = 0.05 × 100 = 5 FIT

λ_dual = 5 + (95 × 10^-9)^2 × 3600
       ≈ 5 FIT (CCF dominates)

Conclusion: Even with redundancy, CCF limits reliability
```

## Freedom from Interference

### Spatial Interference

**Memory Corruption**:
- Buffer overflow from low ASIL task corrupting high ASIL data
- Mitigation: Memory Protection Unit (MPU), separate address spaces

**Stack Overflow**:
- Low ASIL task exhausts stack, overwrites high ASIL stack
- Mitigation: Stack guards, separate stacks, stack monitoring

**DMA Interference**:
- Peripheral DMA writes to wrong memory region
- Mitigation: IOMMU, DMA range checking

### Temporal Interference

**CPU Starvation**:
- Low ASIL task prevents high ASIL task execution
- Mitigation: Priority-based scheduling, budget enforcement

**Interrupt Latency**:
- Interrupt storm delays high ASIL response
- Mitigation: Interrupt prioritization, interrupt rate limiting

**Bus Contention**:
- Low ASIL peripheral blocks high ASIL bus access
- Mitigation: Bus arbitration, quality of service (QoS)

### Communication Interference

**CAN Bus**:
- Low ASIL message delays high ASIL message
- Mitigation: Message priority (CAN ID allocation), separate buses

**Shared Memory**:
- Low ASIL process corrupts high ASIL shared data
- Mitigation: Semaphores, read-only mapping, CRC protection

**Network**:
- Low ASIL Ethernet traffic congests safety channel
- Mitigation: VLAN segregation, AVB/TSN scheduling

### Implementation Techniques

#### AUTOSAR Classic Platform

```c
/* Spatial isolation via OS protection */
OS_APPLICATION(SafetyApp) {
    TRUSTED = FALSE;
    MEMORY_REGION = SafetyRAM;
    STACK_SIZE = 4096;
}

OS_APPLICATION(QM_App) {
    TRUSTED = FALSE;
    MEMORY_REGION = QM_RAM;
    STACK_SIZE = 2048;
}

/* Temporal isolation via timing protection */
SCHEDULETABLE(SafetySchedule) {
    REPEATING = TRUE;
    DURATION = 10ms;
    EXPIRY_POINT(0ms) {
        TASK = SafetyTask_10ms;
        MAX_EXECUTION_TIME = 2ms;
    }
}
```

#### Linux with Hypervisor

```
Physical ECU
├── Hypervisor (Xen, KVM)
│   ├── Safety VM (ASIL D)
│   │   ├── Real-time Linux (PREEMPT_RT)
│   │   ├── Safety application
│   │   ├── Dedicated CPU cores (0-1)
│   │   └── Dedicated memory (0x0-0x40000000)
│   └── QM VM
│       ├── Standard Linux
│       ├── Infotainment, telemetry
│       ├── Dedicated CPU cores (2-3)
│       └── Dedicated memory (0x40000000-0x80000000)
```

#### Hardware Partitioning

**ARM TrustZone**:
- Secure world: ASIL D safety monitor
- Normal world: ASIL B primary control
- Secure interrupts: Cannot be masked by normal world

**Separate Cores**:
- Core 0: ASIL D safety application (lock-step mode)
- Core 1: ASIL B application
- Core 2-3: QM applications
- Memory firewall: Block cross-core access

## ML Component Qualification

### Machine Learning Safety Challenges

**Non-Determinism**:
- Neural network output varies with training data
- No explicit failure modes (degrades gracefully)

**Verification Gap**:
- Cannot test all possible inputs
- Corner cases difficult to identify
- No formal proof of correctness

**Perception Limitations**:
- Adversarial examples (intentional misclassification)
- Out-of-distribution inputs (never seen in training)

### SOTIF Integration (ISO 21448)

**Combined ISO 26262 + ISO 21448 Approach**:

```
ISO 26262 Scope:
- Random hardware failures (sensor malfunction)
- Systematic software failures (software bugs)
- Safety mechanisms (diagnostics, degradation)

ISO 21448 Scope:
- Performance limitations (poor weather, edge cases)
- Insufficiencies in specification
- Validation of intended functionality
```

**Example: Camera-Based Lane Detection**

```
ISO 26262 Safety Requirements:
SR-1: Detect camera hardware failure (ASIL D)
SR-2: Detect invalid image data (ASIL D)
SR-3: Deactivate LKA on camera fault (ASIL D)

ISO 21448 SOTIF Requirements:
SOTIF-1: Verify lane detection in rain/snow/night
SOTIF-2: Identify scenarios causing false positives
SOTIF-3: Verify graceful degradation on low confidence
SOTIF-4: Validate with 10M km real-world data
```

### ML Safety Argumentation

**Argumentation Pattern**:
1. Training data representativeness
2. Model architecture justification
3. Validation dataset independence
4. Performance metrics thresholds
5. Runtime monitoring strategy
6. Degradation and fallback

**Example Safety Case for Object Detection**:

```
Claim: ML-based pedestrian detection achieves ASIL B integrity

Evidence:
E1: Training dataset covers 95% of operational domain
    - 1M labeled images
    - Day/night, weather, demographics
    - Verified no overlap with test set

E2: Model architecture proven in production
    - YOLOv8 with 98% recall on validation set
    - False positive rate < 0.1%
    - Inference time < 50ms on target HW

E3: Runtime plausibility checks (ASIL B)
    - Object size consistency check
    - Velocity plausibility check
    - Multi-frame tracking

E4: Fallback to radar-based detection (ASIL D)
    - Independent sensor modality
    - Camera fault triggers radar-only mode

E5: Continuous OTA monitoring
    - Log low-confidence detections
    - Retrain quarterly with field data
```

### ML Runtime Monitoring

**Confidence Thresholding**:
```python
def safe_prediction(model, input_image, threshold=0.95):
    prediction = model(input_image)
    confidence = prediction.confidence

    if confidence < threshold:
        # Low confidence - activate fallback
        return FALLBACK_MODE, None
    else:
        return NOMINAL_MODE, prediction.bbox
```

**Out-of-Distribution Detection**:
```python
def is_ood(input_image, training_statistics):
    # Mahalanobis distance to training distribution
    features = extract_features(input_image)
    distance = mahalanobis(features,
                           training_statistics.mean,
                           training_statistics.cov)

    if distance > OOD_THRESHOLD:
        log_ood_event(input_image)
        return True
    return False
```

## ISO 26262 Second Edition Changes

### Key Updates (2018 Edition)

**Semiconductors (Part 11)**:
- New part addressing semiconductor IP development
- Safety element out of context (SEooC)
- Evaluation of safety-related hardware elements

**Motorcycles (Part 12)**:
- Tailoring for two-wheeled vehicles
- Different HARA parameters for motorcycle dynamics

**Clarifications**:
- ASIL decomposition rules clarified
- Software tool qualification relaxed (tool confidence levels)
- Verification independence requirements refined

## Advanced Safety Patterns

### Monitor-Actuator Architecture

```
┌─────────────────────────────────────────┐
│  Application ECU (ASIL C)               │
│  - Control algorithm                    │
│  - Sensor fusion                        │
│  - Actuator commands                    │
└─────────────┬───────────────────────────┘
              │ Commands
              ↓
┌─────────────────────────────────────────┐
│  Safety Monitor ECU (ASIL A)            │
│  - Range/plausibility checks            │
│  - Monitor application ECU health       │
│  - Override/veto capability             │
└─────────────┬───────────────────────────┘
              │ Validated commands
              ↓
┌─────────────────────────────────────────┐
│  Actuator (QM)                          │
└─────────────────────────────────────────┘

Total safety: ASIL C (primary) + ASIL A (monitor) → ASIL D
```

### Dual-String Architecture

**Application**: High-availability fail-operational systems (steering, braking)

```
Sensor A1 ──┐
Sensor A2 ──┼─→ Channel A (ASIL D) ──┬──→ Voting ──→ Actuator
            │                         │     Logic
Sensor B1 ──┤                         │
Sensor B2 ──┴─→ Channel B (ASIL D) ──┘

Failure Tolerance:
- Any single sensor failure: System operational
- Any single channel failure: System operational
- Simultaneous A+B failure: System fails (acceptable if β sufficiently low)
```

## Next Steps

For practical application:
- Review ASIL decomposition in your architecture
- Perform DFA on all redundant elements
- Implement freedom from interference mechanisms
- For ML: Develop SOTIF validation strategy

## References

- ISO 26262-2:2018 Management (Clause 6: Confirmation measures)
- ISO 26262-9:2018 ASIL-oriented and safety-oriented analyses
- ISO 26262-11:2018 Semiconductors
- ISO/PAS 21448:2019 SOTIF
- SAE J3016 Levels of Driving Automation

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Senior safety engineers, architects, researchers
