# UN R155 - Overview

## What is UN R155?

UN Regulation No. 155 "Uniform provisions concerning the approval of vehicles with regards to cyber security and cyber security management system" is a legally binding type-approval regulation for cybersecurity in the automotive industry. It applies to vehicles sold in the European Union, Japan, South Korea, and other UNECE member states.

## Key Characteristics

- **Mandatory compliance**: Required for type approval since July 2024
- **CSMS-focused**: Emphasizes organizational processes over technical details
- **Lifecycle approach**: Covers development through end-of-life
- **Certificate-based**: Manufacturers receive CSMS certificate from approval authority

## Regulatory Timeline

| Date | Milestone | Impact |
|------|-----------|--------|
| **January 22, 2021** | UN R155 enters into force | Available for voluntary adoption |
| **July 2022** | Mandatory for new vehicle types | New models must comply |
| **July 2024** | Mandatory for all new vehicles | All production must comply |
| **Ongoing** | Annual surveillance audits | CSMS certificate renewal |

## Scope and Applicability

### In-Scope Vehicles

UN R155 applies to:
- **Category M**: Passenger vehicles (cars, buses)
- **Category N**: Goods vehicles (trucks, vans)
- **Category O**: Trailers (when equipped with electronic systems)

### Connected Vehicle Criteria

A vehicle is subject to UN R155 if it has one or more of:
- External data connections (cellular, WiFi, Bluetooth)
- Over-the-air (OTA) software update capability
- Diagnostic interfaces (OBD-II, OBD-C)
- Vehicle-to-X (V2X) communication

**Exemption**: Vehicles with no external connectivity are exempt.

## UN R155 vs ISO 21434

UN R155 references but does not mandate ISO/SAE 21434.

| Aspect | UN R155 | ISO/SAE 21434 |
|--------|---------|---------------|
| **Type** | Legal regulation | Technical standard |
| **Scope** | CSMS organizational processes | Detailed engineering guidance |
| **Enforcement** | Type approval authorities | Voluntary (de facto required) |
| **Specificity** | High-level requirements | Detailed technical methods (TARA, etc.) |
| **Applicability** | EU, Japan, South Korea, etc. | Global automotive industry |
| **Deliverable** | CSMS certificate | Technical documentation |

**Practical relationship**: ISO 21434 compliance demonstrates UN R155 compliance.

## Core Requirements

UN R155 mandates manufacturers demonstrate:

### 1. Cybersecurity Management System (CSMS)

Organizational framework to manage cybersecurity throughout vehicle lifecycle.

**CSMS must include**:
- Cybersecurity governance structure
- Risk assessment processes
- Vulnerability management procedures
- Incident response capabilities
- Supply chain security requirements

### 2. Risk Assessment (Annex 5 Threat Catalog)

Systematic evaluation of threats from UN R155 Annex 5, covering:
- Back-end servers
- Update procedures
- Communication channels (wireless, wired)
- External connectivity interfaces
- Data and code integrity

### 3. Mitigation Measures

Appropriate technical and organizational controls to address identified risks.

Examples:
- Secure boot for ECU firmware
- Authenticated diagnostic access
- Encrypted over-the-air updates
- Intrusion detection systems

### 4. Testing and Validation

Evidence that security measures are effective:
- Penetration testing results
- Vulnerability assessments
- Security test reports

### 5. Monitoring and Response

Ongoing activities post-production:
- Threat intelligence monitoring
- Vulnerability disclosure handling
- Security incident response
- Timely security updates (patches)

## CSMS Certificate

Issued by national type approval authority after successful audit.

### Certificate Contents

- Manufacturer name and facility locations
- Vehicle types covered (may be multiple models)
- CSMS version and effective date
- Validity period (typically 3 years)
- Surveillance audit schedule

### Audit Process

```
┌────────────────────────────┐
│ Initial Application        │
│ - Submit CSMS documentation│
└────────────┬───────────────┘
             ↓
┌────────────────────────────┐
│ Document Review            │
│ - Approval authority checks│
└────────────┬───────────────┘
             ↓
┌────────────────────────────┐
│ On-Site Audit              │
│ - Interview staff          │
│ - Review processes         │
│ - Examine evidence         │
└────────────┬───────────────┘
             ↓
┌────────────────────────────┐
│ Findings and Corrective    │
│ Actions (if needed)        │
└────────────┬───────────────┘
             ↓
┌────────────────────────────┐
│ Certificate Issued         │
│ - Valid for 3 years        │
└────────────┬───────────────┘
             ↓
┌────────────────────────────┐
│ Annual Surveillance Audits │
│ - Verify continued         │
│   compliance               │
└────────────────────────────┘
```

## UN R155 Annex 5 Threat Catalog

Mandatory threat scenarios to assess:

### Category 1: Back-end Servers
- 1.1.1 Back-end server attack
- 1.2.1 Update procedure attack
- 1.3.1 Communication channel attack

### Category 2: External Connectivity
- 2.1.1 External connectivity attack
- 2.2.1 Wireless communication attack (V2X, WiFi, Bluetooth)

### Category 3: Wired Connectivity
- 3.1.1 Wired communication attack (diagnostic port, Ethernet)

### Category 4: Data and Code
- 4.1.1 Vehicle data and code attack
- 4.2.1 Manipulation of vehicle data and code

### Category 5: Operation
- 5.1.1 Misuse of debug/diagnostic functions

Each threat must be assessed for:
- **Potential impact** on vehicle safety, privacy, financial, operational
- **Likelihood** of exploitation
- **Mitigation measures** implemented

## UN R156: Software Update Management

Companion regulation to UN R155, focuses on OTA updates.

### Key R156 Requirements

- Secure update mechanism (authentication, integrity)
- Version management and rollback capability
- User notification and consent (where required)
- No degradation of vehicle safety during update
- Audit trail of all updates performed

**Practical note**: UN R155 and R156 are often addressed together in CSMS.

## Industry Best Practices

### Preparation Checklist

To achieve UN R155 compliance:

1. **Establish CSMS governance**
   - Appoint cybersecurity officer
   - Define roles and responsibilities
   - Create cybersecurity policy

2. **Conduct Annex 5 threat assessment**
   - Use TARA methodology (ISO 21434)
   - Document risk treatment decisions

3. **Implement security controls**
   - Design and deploy mitigations
   - Verify effectiveness through testing

4. **Set up vulnerability management**
   - Monitor security advisories (Auto-ISAC, NVD)
   - Establish disclosure process
   - Plan patch deployment (OTA or dealer)

5. **Prepare for audit**
   - Compile evidence (test reports, process documentation)
   - Train staff on CSMS processes
   - Schedule pre-audit with authority

### Common Audit Findings

Based on early UN R155 audits, common issues include:

| Finding | Category | Remediation |
|---------|----------|-------------|
| Insufficient evidence of Annex 5 coverage | Documentation | Complete TARA for all threat categories |
| Unclear vulnerability response SLAs | Process | Define timelines (Critical: 7 days, High: 30 days) |
| No supplier cybersecurity requirements | Supply chain | Add security clauses to contracts |
| Lack of penetration test evidence | Technical | Commission independent security audit |
| Missing incident response procedures | Process | Document and test IR playbooks |

## Relationship to Other Regulations

### Complementary Regulations

- **UN R156**: Software updates (works alongside R155)
- **GDPR**: Privacy of personal vehicle data
- **ePrivacy Directive**: Electronic communications in vehicles
- **General Safety Regulation (GSR)**: EU vehicle safety standards

### Regional Variations

**China**: GB/T 40857-2021 similar requirements, enforced since 2023
**USA**: No federal equivalent yet; NHTSA issued best practices guidance
**India**: AIS-155 aligned with UN R155, phased implementation

## Benefits of Compliance

Beyond regulatory necessity, UN R155 compliance provides:

1. **Market access**: Required for sales in key markets
2. **Customer trust**: Demonstrates commitment to security
3. **Risk reduction**: Systematic approach prevents incidents
4. **Insurance benefits**: May reduce premiums
5. **Competitive advantage**: Security as differentiator

## Getting Started

For manufacturers new to UN R155:

### Step 1: Gap Analysis
Compare existing processes against UN R155 requirements. Identify missing elements.

### Step 2: Select Approval Authority
Choose authority in country of manufacture or primary market (e.g., KBA in Germany, VCA in UK).

### Step 3: Implement CSMS
Establish processes per ISO 21434 guidance. Document everything.

### Step 4: Prepare Application
Compile required documentation per authority's specific format.

### Step 5: Submit and Audit
Submit application, undergo document review and on-site audit.

### Step 6: Maintain Certificate
Conduct annual surveillance audits, update CSMS as vehicle evolves.

## Next Steps

- **Level 2**: Conceptual understanding of CSMS requirements
- **Level 3**: Detailed compliance implementation guide
- **Level 4**: Quick reference checklists and threat catalog
- **Level 5**: Advanced topics including multi-OEM CSMS and supply chain

## References

- UN Regulation No. 155 (E/ECE/TRANS/505/Rev.3/Add.154)
- UN Regulation No. 156 (Software Updates)
- ISO/SAE 21434:2021 Road vehicles - Cybersecurity engineering
- UNECE WP.29 documentation: https://unece.org/transport/vehicle-regulations

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Automotive compliance managers, CSMS leads, regulatory affairs
