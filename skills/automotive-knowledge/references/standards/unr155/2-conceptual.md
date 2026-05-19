# UN R155 - CSMS Requirements

## Cybersecurity Management System (CSMS) Framework

The CSMS is the organizational backbone for UN R155 compliance. It defines how cybersecurity is managed across the vehicle lifecycle.

### CSMS Structure

```
┌──────────────────────────────────────────────────────┐
│           CSMS Governance Layer                      │
│  ┌────────────────┐  ┌────────────────┐            │
│  │ Executive      │  │ Cybersecurity  │            │
│  │ Oversight      │  │ Steering       │            │
│  │ Board          │  │ Committee      │            │
│  └────────────────┘  └────────────────┘            │
└──────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────┐
│           CSMS Process Layer                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Risk     │ │Vulnerability│ │ Incident │          │
│  │Management│ │ Management │ │ Response │          │
│  └──────────┘ └──────────┘ └──────────┘            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Supply   │ │ Testing & │ │ Training │           │
│  │ Chain    │ │Validation │ │          │           │
│  └──────────┘ └──────────┘ └──────────┘            │
└──────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────┐
│           CSMS Operational Layer                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Threat   │ │ Security │ │ Patch    │            │
│  │ Intel    │ │ Testing  │ │ Deployment│           │
│  └──────────┘ └──────────┘ └──────────┘            │
└──────────────────────────────────────────────────────┘
```

## CSMS Core Requirements (Paragraph 7.2)

UN R155 Paragraph 7.2 outlines mandatory CSMS processes:

### 7.2.1: Processes for Risk Management

**Requirement**: Identify, categorize, and treat cybersecurity risks.

**Implementation**:
- Conduct TARA using ISO 21434 methodology
- Assess all Annex 5 threats
- Document risk treatment decisions
- Maintain risk register

**Evidence Required**:
- Threat assessment reports
- Risk treatment plans
- Design specifications showing mitigations

**Example Risk Register Entry**:
```yaml
threat_id: T-2.2.1-001
description: "Attacker spoofs V2X messages to cause false emergency brake"
annex5_category: 2.2.1 (Wireless communication attack)
impact:
  safety: Severe (potential collision)
  financial: Major (accident costs)
likelihood: Medium (requires V2X equipment, proximity)
risk_level: High
treatment: Reduce
mitigations:
  - V2X message authentication (IEEE 1609.2)
  - Plausibility checks on external sensor data
  - Multi-sensor fusion to detect inconsistencies
verification:
  - V2X security test report dated 2024-05-15
  - Sensor fusion validation results
status: Implemented and verified
```

### 7.2.2: Testing for Vulnerabilities

**Requirement**: Test vehicles and systems for security weaknesses.

**Testing Scope**:
1. **Static Analysis**: Source code and binary analysis
2. **Dynamic Analysis**: Runtime testing and fuzzing
3. **Penetration Testing**: Simulated attacks by security experts
4. **Vulnerability Scanning**: Automated tool-based assessment

**Test Coverage Matrix**:
| Attack Vector | Test Method | Frequency |
|---------------|-------------|-----------|
| CAN bus injection | Penetration test | Per vehicle type |
| Diagnostic exploit | Fuzzing + pentest | Per ECU |
| OTA MITM attack | Penetration test | Per OTA system update |
| Ethernet attack | Port scan + exploit | Per network architecture |
| V2X spoofing | Protocol analysis | Per V2X implementation |

**Evidence Required**:
- Penetration test reports from accredited labs
- Vulnerability assessment results
- Remediation plans for findings
- Retest results after fixes

### 7.2.3: Detection and Monitoring

**Requirement**: Monitor for cybersecurity incidents and attacks.

**Monitoring Levels**:

**Level 1: Vehicle-Based IDS**
- ECU-level anomaly detection
- CAN bus traffic monitoring
- Diagnostic port access logging

**Level 2: Fleet Telemetry**
- TCU reports suspicious events to backend
- Aggregated security metrics (failed auth attempts, anomalies)

**Level 3: VSOC (Vehicle Security Operations Center)**
- Centralized threat monitoring
- Cross-fleet correlation
- Proactive threat hunting

**Monitoring Metrics**:
```python
# Example VSOC dashboard metrics
metrics = {
    'failed_diagnostic_auth': 127,  # Last 24h
    'unknown_can_ids_detected': 3,
    'firmware_integrity_failures': 0,
    'ota_signature_failures': 2,
    'ids_alerts_triggered': 45,
    'vehicles_with_active_incidents': 12,
    'mean_time_to_detect': '2.3 hours',
    'mean_time_to_respond': '5.7 hours'
}
```

### 7.2.4: Response to Incidents

**Requirement**: Respond to cybersecurity incidents affecting vehicles in operation.

**Incident Response Workflow**:
```
┌─────────────────┐
│ 1. Detection    │ ← IDS alert, user report, researcher disclosure
└────────┬────────┘
         ↓
┌─────────────────┐
│ 2. Triage       │ ← Severity assessment, impact analysis
└────────┬────────┘
         ↓
┌─────────────────┐
│ 3. Containment  │ ← Isolate affected vehicles, disable features
└────────┬────────┘
         ↓
┌─────────────────┐
│ 4. Eradication  │ ← Develop and test patch
└────────┬────────┘
         ↓
┌─────────────────┐
│ 5. Recovery     │ ← Deploy OTA update, verify fix
└────────┬────────┘
         ↓
┌─────────────────┐
│ 6. Lessons      │ ← Post-incident review, update defenses
│    Learned      │
└─────────────────┘
```

**Incident Severity Classification**:
| Severity | Response Time | Escalation | Examples |
|----------|---------------|------------|----------|
| **Critical** | 4 hours | CEO, Regulatory | Remote vehicle control exploit |
| **High** | 24 hours | VP Engineering | ECU firmware vulnerability |
| **Medium** | 7 days | CSMS Manager | Infotainment privacy leak |
| **Low** | 30 days | Security Team | Minor information disclosure |

**Evidence Required**:
- Incident response procedures
- Incident logs and timelines
- Root cause analysis reports
- Corrective action records

### 7.2.5: Software Updates

**Requirement**: Provide security updates to address vulnerabilities.

**Update Channels**:
1. **Over-the-Air (OTA)**: Primary method for connected vehicles
2. **Dealer Service**: For safety-critical updates or non-connected vehicles
3. **USB/Diagnostic Tool**: Fallback method

**Update Process Flow**:
```
┌────────────────────────────────────────┐
│ 1. Vulnerability Identified            │
│    - CVE assigned                      │
│    - Impact assessed                   │
└─────────────────┬──────────────────────┘
                  ↓
┌────────────────────────────────────────┐
│ 2. Patch Developed                     │
│    - Code fix + test                   │
│    - Safety impact analysis            │
└─────────────────┬──────────────────────┘
                  ↓
┌────────────────────────────────────────┐
│ 3. Update Package Built                │
│    - Firmware signed                   │
│    - Release notes generated           │
└─────────────────┬──────────────────────┘
                  ↓
┌────────────────────────────────────────┐
│ 4. Pilot Deployment                    │
│    - Small fleet (1-5% vehicles)       │
│    - Monitor for issues                │
└─────────────────┬──────────────────────┘
                  ↓
┌────────────────────────────────────────┐
│ 5. Full Fleet Rollout                  │
│    - Phased by region/model            │
│    - Campaign management               │
└─────────────────┬──────────────────────┘
                  ↓
┌────────────────────────────────────────┐
│ 6. Verification                        │
│    - Confirm installation success      │
│    - Validate vulnerability resolved   │
└────────────────────────────────────────┘
```

**Update SLA Targets**:
| Vulnerability Severity | Patch Development | Deployment Start | Full Fleet |
|------------------------|-------------------|------------------|------------|
| Critical (CVSS 9-10) | 7 days | 14 days | 30 days |
| High (CVSS 7-8.9) | 30 days | 45 days | 90 days |
| Medium (CVSS 4-6.9) | 60 days | 90 days | 180 days |
| Low (CVSS 0.1-3.9) | Next release | Next release | Next release |

**Evidence Required**:
- Software update procedure
- Campaign management records
- Update success/failure statistics
- Version control logs

## Supply Chain Cybersecurity (Paragraph 7.2.6)

**Requirement**: Manage cybersecurity risks in the supply chain.

### Supplier Tiers

```
┌──────────────────────────────────────────┐
│           OEM (Vehicle Manufacturer)     │
│           - Overall CSMS responsibility  │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│      Tier 1 Suppliers (System)           │
│      - ADAS module, powertrain ECU       │
│      - Must have CSMS                    │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│      Tier 2 Suppliers (Component)        │
│      - Microcontroller, sensor           │
│      - Cybersecurity requirements flow   │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│      Tier 3+ Suppliers (Material/IP)     │
│      - Software libraries, silicon IP    │
│      - SBOM and CVE tracking             │
└──────────────────────────────────────────┘
```

### Supplier Cybersecurity Agreement Template

**Key Clauses**:
1. **CSMS Certification**: Tier 1 must obtain UN R155 or equivalent
2. **TARA Delivery**: Supplier provides threat analysis for their components
3. **SBOM Provision**: Complete software bill of materials
4. **Vulnerability Notification**: Notify OEM within 48h of discovering CVE
5. **Patch Support**: Provide security updates for minimum 10 years
6. **Audit Rights**: OEM can audit supplier cybersecurity practices
7. **Incident Cooperation**: Support OEM incident response
8. **IP Protection**: No reverse engineering, secure development

**Example Contractual Language**:
```
"Supplier shall maintain a Cybersecurity Management System compliant with
ISO/SAE 21434 or equivalent. Supplier shall perform Threat Analysis and Risk
Assessment (TARA) for all delivered components and provide results to OEM
within 30 days of component delivery. Supplier shall notify OEM within 48
hours of discovering any vulnerability with CVSS score ≥7.0 affecting
delivered components."
```

## CSMS Maturity Model

Organizations progress through maturity levels:

| Level | Name | Characteristics | UN R155 Status |
|-------|------|-----------------|----------------|
| **1** | Ad-hoc | Reactive, no formal processes | Non-compliant |
| **2** | Managed | Basic CSMS, documented processes | Minimum compliance |
| **3** | Defined | Standardized across organization | Full compliance |
| **4** | Quantitatively Managed | Metrics-driven, continuous improvement | Industry leading |
| **5** | Optimizing | Predictive, adaptive defenses | State-of-the-art |

**Progression Path**:
- Most manufacturers start at Level 1-2
- UN R155 compliance requires Level 2 minimum
- Competitive advantage at Level 3+
- Autonomous vehicle leaders target Level 4-5

## Training and Competence

**Requirement** (implicit in UN R155): Personnel must be competent in cybersecurity.

### Training Program Structure

**Role-Based Training**:
| Role | Training Topics | Frequency |
|------|----------------|-----------|
| **All Engineers** | Cybersecurity awareness, secure coding basics | Annual |
| **Security Engineers** | TARA, penetration testing, cryptography | Bi-annual + certifications |
| **Architects** | Secure architecture patterns, threat modeling | Bi-annual |
| **Test Engineers** | Security testing tools, vulnerability assessment | Annual |
| **Management** | CSMS governance, regulatory compliance | Annual |

**Certification Recommendations**:
- CISSP (Certified Information Systems Security Professional)
- CEH (Certified Ethical Hacker)
- GIAC (Global Information Assurance Certification)
- Vendor-specific (e.g., AUTOSAR security certification)

## Continuous Improvement

CSMS is not static. UN R155 expects evolution based on:

### Threat Landscape Changes
- New attack vectors discovered (e.g., V2X vulnerabilities)
- Emerging technologies (quantum computing threat)
- Regulatory updates

### Incident Learnings
- Analyze security incidents (own and industry)
- Update threat models
- Enhance detection capabilities

### Technology Advances
- Adopt new security mechanisms (PQC, hardware security)
- Improve automation (AI-based threat detection)
- Expand monitoring coverage

### Audit Feedback
- Address findings from surveillance audits
- Implement auditor recommendations
- Benchmark against industry best practices

## Documentation Requirements

Comprehensive documentation is critical for audit success.

### Mandatory Documents

1. **CSMS Manual** (50-200 pages)
   - Governance structure
   - All CSMS processes
   - Roles and responsibilities

2. **Risk Assessment Report** (100-300 pages)
   - Annex 5 threat analysis
   - Risk treatment decisions
   - Verification evidence

3. **Supplier Management Plan** (20-50 pages)
   - Supplier requirements
   - Assessment criteria
   - Monitoring procedures

4. **Incident Response Plan** (30-80 pages)
   - Response procedures
   - Escalation matrix
   - Communication templates

5. **Testing and Validation Report** (50-150 pages)
   - Penetration test results
   - Vulnerability scan findings
   - Remediation verification

6. **Training Records** (database)
   - Personnel training matrix
   - Attendance records
   - Competency assessments

### Document Control

- Version control for all CSMS documents
- Change approval process
- Periodic review (annual minimum)
- Accessible to audit team

## Next Steps

- **Level 3**: Detailed compliance implementation guide
- **Level 4**: Quick reference checklists and Annex 5 threat catalog
- **Level 5**: Advanced multi-OEM CSMS and supply chain security

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: CSMS implementers, compliance managers, security architects
