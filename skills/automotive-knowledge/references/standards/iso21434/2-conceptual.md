# ISO/SAE 21434 - Conceptual Framework

## TARA Methodology Deep Dive

Threat Analysis and Risk Assessment (TARA) is the core cybersecurity engineering activity in ISO 21434, analogous to HARA in ISO 26262.

### TARA Process Flow

```
┌──────────────────────────┐
│  Asset Identification    │
│  - Vehicle functions     │
│  - Data, SW, HW, keys    │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│  Damage Scenario Analysis│
│  - Safety, Financial,    │
│    Operational, Privacy  │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│  Threat Scenario         │
│  Identification          │
│  - STRIDE, Attack Trees  │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│  Impact Rating           │
│  - Severe, Major,        │
│    Moderate, Negligible  │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│  Attack Feasibility      │
│  - Elapsed time, Expert  │
│    knowledge, Equipment  │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│  Risk Value Determination│
│  - Risk = Impact ×       │
│    Feasibility           │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│  Risk Treatment Decision │
│  - Avoid, Reduce, Share, │
│    Retain                │
└──────────────────────────┘
```

## Asset Identification

### Asset Categories

**Road vehicle assets (RVAs)** include:

1. **Vehicle Functions**
   - Propulsion control
   - Braking control
   - Steering control
   - ADAS features
   - Infotainment services

2. **Data**
   - Personal data (driver profile, location history)
   - Operational data (speed, fuel consumption)
   - Diagnostic data (DTCs, sensor values)
   - Cryptographic keys and certificates

3. **Software**
   - ECU firmware
   - Operating systems
   - Applications
   - Bootloaders

4. **Hardware**
   - ECUs and processors
   - Sensors and actuators
   - Communication gateways
   - HSM (Hardware Security Module)

### Asset Dependencies

Assets are interconnected. Example dependency chain:

```
[Gateway ECU Firmware]
        ↓ protects
[CAN Bus Communication]
        ↓ enables
[Brake ECU Control]
        ↓ provides
[Vehicle Deceleration Function]
```

Compromise of gateway firmware can cascade to all dependent assets.

## Damage Scenarios

### Damage Scenario Structure

Each damage scenario defines:
- **Asset affected**: What is compromised
- **Damage type**: Safety, financial, operational, privacy
- **Damage description**: Specific harmful consequence
- **Impact rating**: Severity of damage

### Example Damage Scenarios

**Scenario 1: Unauthorized Vehicle Control**
- Asset: Steering ECU firmware
- Damage type: Safety
- Description: Attacker remotely controls steering, causing crash
- Impact: Severe (potential fatalities)

**Scenario 2: Theft of Personal Data**
- Asset: Infotainment user profile data
- Damage type: Privacy
- Description: Attacker extracts driver's contacts, location history
- Impact: Moderate (privacy violation, no physical harm)

**Scenario 3: Denial of Service**
- Asset: Telematics CAN gateway
- Damage type: Operational
- Description: Attacker floods CAN bus, disabling vehicle functions
- Impact: Major (vehicle inoperable)

### Impact Rating Scale

| Rating | Safety | Financial | Operational | Privacy |
|--------|--------|-----------|-------------|---------|
| Severe | Death/serious injury | >€1M loss | Complete failure | Mass data breach |
| Major | Light injury | €100K-€1M | Major degradation | Individual PII leak |
| Moderate | No injury | €10K-€100K | Minor degradation | Limited data exposure |
| Negligible | No safety impact | <€10K | No noticeable effect | No privacy impact |

## Threat Scenario Identification

### STRIDE Threat Model

STRIDE is a structured approach to identify threats:

| Threat Type | Description | Example |
|-------------|-------------|---------|
| **S**poofing | Impersonating user/component | Fake CAN message from non-existent ECU |
| **T**ampering | Modifying data/code | Reflashing ECU with malicious firmware |
| **R**epudiation | Denying action occurred | No audit trail of diagnostic access |
| **I**nformation disclosure | Exposing confidential data | Sniffing unencrypted CAN traffic |
| **D**enial of service | Disrupting availability | CAN bus flood attack |
| **E**levation of privilege | Gaining unauthorized access | Exploiting bootloader to run unsigned code |

### Attack Tree Example

Threat: "Attacker gains remote code execution on Gateway ECU"

```
                    [Remote Code Execution]
                            |
          +-----------------+-----------------+
          |                                   |
    [Exploit Vulnerability]          [Physical Access]
          |                                   |
    +-----+-----+                      +------+------+
    |           |                      |             |
[Buffer    [Injection]            [JTAG        [Firmware
Overflow]                          Debug]       Replace]
```

Attack paths can be analyzed for feasibility and combined impact.

### Attack Feasibility Rating

ISO 21434 uses a composite feasibility score based on:

1. **Elapsed Time**
   - ≤1 day: High (3 points)
   - ≤1 month: Medium (4 points)
   - ≤6 months: Low (7 points)
   - >6 months: Very Low (11 points)

2. **Specialist Expertise**
   - Layman: High (0 points)
   - Proficient: Medium (3 points)
   - Expert: Low (6 points)
   - Multiple experts: Very Low (8 points)

3. **Knowledge of Item**
   - Public: High (0 points)
   - Restricted: Medium (3 points)
   - Confidential: Low (7 points)
   - Strictly confidential: Very Low (11 points)

4. **Window of Opportunity**
   - Unlimited: High (0 points)
   - Easy: Medium (1 point)
   - Moderate: Low (4 points)
   - Difficult: Very Low (10 points)

5. **Equipment**
   - Standard: High (0 points)
   - Specialized: Medium (4 points)
   - Bespoke: Low (7 points)
   - Multiple bespoke: Very Low (9 points)

**Total Feasibility Score**: Sum of all factors

| Total Score | Feasibility Rating |
|-------------|-------------------|
| 0-9 | Very High |
| 10-16 | High |
| 17-23 | Medium |
| 24-33 | Low |
| ≥34 | Very Low |

## Risk Determination

### Risk Matrix

Risk value combines impact and attack feasibility:

| Impact ↓ / Feasibility → | Very High | High | Medium | Low | Very Low |
|--------------------------|-----------|------|--------|-----|----------|
| **Severe** | Unacceptable | Unacceptable | High | Medium | Low |
| **Major** | Unacceptable | High | High | Medium | Low |
| **Moderate** | High | Medium | Medium | Low | Very Low |
| **Negligible** | Medium | Low | Low | Very Low | Very Low |

### Risk Treatment Options

**Avoid**: Eliminate the threat
- Remove vulnerable feature
- Disable unnecessary interfaces

**Reduce**: Implement security controls
- Authentication, encryption, input validation
- Most common treatment in automotive

**Share**: Transfer risk to third party
- Insurance, liability agreements
- Supplier responsibility clauses

**Retain**: Accept the risk
- Only for "Low" or "Very Low" risks
- Requires documented justification

## Cybersecurity Concept

### Cybersecurity Goals

High-level security objectives derived from damage scenarios:

**Example Goals**:
- "Prevent unauthorized modification of gateway firmware"
- "Ensure confidentiality of personal driver data"
- "Maintain availability of critical vehicle functions"

### Cybersecurity Requirements

Technical requirements to achieve goals:

**Functional Requirements**:
- "Gateway shall authenticate all firmware updates using RSA-2048"
- "Infotainment shall encrypt personal data using AES-256"
- "CAN gateway shall rate-limit messages to 1000/sec per ID"

**Non-functional Requirements**:
- "Authentication shall complete within 100ms"
- "Encryption overhead shall not exceed 5% CPU usage"

## Cybersecurity Architecture

### Defense in Depth

Layer security controls across architectural levels:

```
┌───────────────────────────────────────┐
│  Layer 7: Physical Security           │
│  - Tamper detection, secure facilities│
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│  Layer 6: Vehicle-Level Controls      │
│  - Secure gateway, IDS, firewall      │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│  Layer 5: Network Segmentation        │
│  - CAN isolation, Ethernet VLANs      │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│  Layer 4: Secure Communication        │
│  - TLS, SecOC, MACsec                 │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│  Layer 3: ECU Security                │
│  - Secure boot, runtime integrity     │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│  Layer 2: Application Security        │
│  - Input validation, least privilege  │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│  Layer 1: Cryptographic Foundation    │
│  - HSM, key management, RNG           │
└───────────────────────────────────────┘
```

### Security Zones

Partition vehicle architecture into zones with different trust levels:

- **Zone 1 (Critical)**: Powertrain, chassis, ADAS ECUs
- **Zone 2 (High)**: Gateway, TCU, diagnostics
- **Zone 3 (Medium)**: Body control, HVAC
- **Zone 4 (Low)**: Infotainment, rear-seat entertainment

Inter-zone communication requires authentication and authorization.

## Cybersecurity Validation

### Penetration Testing

Independent security testing using:
- Known vulnerability scanners
- Fuzzing tools
- Protocol analyzers
- Reverse engineering

### Vulnerability Scanning

Continuous scanning for:
- Software CVEs (Common Vulnerabilities and Exposures)
- Configuration weaknesses
- Cryptographic weaknesses
- Outdated libraries

### Security Testing Methods

| Method | Scope | Timing |
|--------|-------|--------|
| Static analysis | Source code | Development |
| Dynamic analysis | Running system | Integration |
| Penetration testing | Complete system | Pre-production |
| Red team exercise | Deployed vehicles | Post-production |

## Next Steps

- **Level 3**: Detailed implementation guide for security controls
- **Level 4**: Quick reference tables and compliance checklists
- **Level 5**: Advanced VSOC, incident response, supply chain security

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Cybersecurity architects, TARA practitioners, security engineers
