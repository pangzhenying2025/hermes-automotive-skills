# ISO/SAE 21434 - Overview

## What is ISO/SAE 21434?

ISO/SAE 21434 "Road vehicles - Cybersecurity engineering" is the international standard for cybersecurity in automotive systems. Published in August 2021, it establishes a comprehensive framework for managing cybersecurity risks throughout the vehicle lifecycle.

## Key Characteristics

- **Risk-based approach**: Focus on threat analysis and risk assessment (TARA)
- **Lifecycle coverage**: Concept phase through decommissioning
- **Supply chain integration**: Requirements for suppliers and OEMs
- **Continuous monitoring**: Ongoing threat intelligence and incident response

## Relationship to Other Standards

```
┌─────────────────────────────────────────┐
│   ISO 26262 (Functional Safety)         │
│   - Safety HARA                         │
│   - Safety requirements                 │
└─────────────────────────────────────────┘
           ↕ Interfaces
┌─────────────────────────────────────────┐
│   ISO 21434 (Cybersecurity)             │
│   - TARA (Threat Analysis)              │
│   - Security requirements               │
└─────────────────────────────────────────┘
           ↕ Interfaces
┌─────────────────────────────────────────┐
│   ISO 21448 (SOTIF)                     │
│   - Behavioral safety                   │
└─────────────────────────────────────────┘
```

## Scope

ISO 21434 applies to:
- Electrical and electronic (E/E) systems in road vehicles
- External connectivity (V2X, telematics, infotainment)
- Vehicle-to-cloud communication
- Software update mechanisms (OTA)
- Diagnostic interfaces

## Cybersecurity Lifecycle Phases

### Concept Phase
Define cybersecurity goals, identify assets, perform initial TARA

### Product Development
- Design cybersecurity architecture
- Implement security controls
- Verify and validate security requirements

### Production
- Secure manufacturing processes
- Post-production TARA monitoring

### Operations and Maintenance
- Incident response
- Security updates and patches
- Vulnerability management

### Decommissioning
- Secure data deletion
- Key material destruction

## Key Concepts

### Asset Identification
Identify elements requiring protection:
- Vehicle data (personal, operational, diagnostic)
- Software components (ECU firmware, applications)
- Cryptographic keys
- Communication channels

### Damage Scenarios
Cybersecurity-related harm including:
- Safety impact (loss of vehicle control)
- Financial impact (theft, fraud)
- Operational impact (denial of service)
- Privacy impact (data breach)

### Cybersecurity Claims
Statements about cybersecurity properties of items or components

### Cybersecurity Goals
High-level security objectives derived from damage scenarios

### Cybersecurity Requirements
Technical and organizational requirements to achieve goals

## Organizational Requirements

### Cybersecurity Management System
- Cybersecurity policy
- Risk management framework
- Competence management
- Evidence management

### Cybersecurity Culture
- Awareness training
- Incident reporting mechanisms
- Continuous improvement

## Compliance Timeline

| Milestone | Date | Impact |
|-----------|------|--------|
| Publication | August 2021 | Standard available |
| UN R155 reference | January 2021 | EU type approval requirement |
| UN R156 reference | January 2022 | OTA update type approval |
| Full enforcement | July 2024 | All new vehicle types |

## UN R155 Type Approval

ISO 21434 supports compliance with UN R155:
- Cybersecurity Management System (CSMS) required
- Covers vehicles with Level 3+ connectivity
- Mandatory for EU, Japan, South Korea

## Use Cases

ISO 21434 is essential for:
- Connected vehicles with telematics
- Vehicles with OTA update capability
- Advanced driver assistance systems (ADAS)
- V2X-enabled vehicles
- Electric vehicles with smart charging

## Getting Started

To implement ISO 21434:

1. **Establish CSMS**: Define processes, roles, responsibilities
2. **Perform TARA**: Identify threats, assess risks
3. **Define requirements**: Security controls based on TARA
4. **Implement controls**: Technical and organizational measures
5. **Monitor and respond**: Continuous vulnerability management

## Comparison: Safety vs Security

| Aspect | ISO 26262 (Safety) | ISO 21434 (Security) |
|--------|-------------------|---------------------|
| Focus | Random/systematic faults | Intentional attacks |
| Hazard source | Internal failures | External threats |
| Analysis | HARA, FMEA, FTA | TARA, attack trees |
| Mitigation | Redundancy, diagnostics | Encryption, authentication |
| Lifecycle | Development-centric | Continuous monitoring |

## Cybersecurity Assurance Levels

ISO 21434 does not define CAL levels like ASIL in ISO 26262. Instead:
- Risk-based approach determines security controls
- Controls selected based on threat severity and feasibility
- No predefined levels (CAL1-4) unlike earlier drafts

## Next Steps

- **Level 2**: Conceptual understanding of TARA methodology
- **Level 3**: Detailed implementation guide for security controls
- **Level 4**: Quick reference tables and checklists
- **Level 5**: Advanced topics including VSOC and incident response

## References

- ISO/SAE 21434:2021 Road vehicles - Cybersecurity engineering
- UN Regulation No. 155 - Cyber security and cyber security management system
- UN Regulation No. 156 - Software update and software updates management system
- SAE J3061 Cybersecurity Guidebook for Cyber-Physical Vehicle Systems

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Automotive cybersecurity engineers, compliance managers, system architects
