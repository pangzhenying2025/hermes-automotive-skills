# UN R155 - Compliance Implementation

## CSMS Implementation Roadmap

This section provides step-by-step guidance for implementing a UN R155-compliant CSMS from scratch.

### Phase 1: Foundation (Months 1-3)

**Objective**: Establish governance and baseline processes.

#### Activities

**1.1 Define Organizational Structure**

Create CSMS governance model:
```yaml
csms_organization:
  executive_sponsor:
    role: Chief Technology Officer
    responsibilities:
      - CSMS strategy approval
      - Resource allocation
      - Regulatory liaison

  csms_manager:
    role: Head of Cybersecurity
    responsibilities:
      - CSMS implementation
      - Audit coordination
      - Continuous improvement
    reports_to: CTO

  security_architects:
    count: 3-5
    responsibilities:
      - Vehicle architecture security design
      - TARA execution
      - Technical standards

  security_engineers:
    count: 10-20
    responsibilities:
      - Security testing
      - Vulnerability assessment
      - Tool development

  security_operations:
    count: 5-10
    responsibilities:
      - Monitoring (VSOC)
      - Incident response
      - Patch deployment
```

**1.2 Develop CSMS Policy**

Template structure:
```markdown
# Cybersecurity Policy v1.0

## 1. Purpose
Define organizational commitment to vehicle cybersecurity per UN R155.

## 2. Scope
All vehicles with external connectivity developed, produced, or maintained
by [Company Name].

## 3. Principles
- Security by design
- Defense in depth
- Least privilege
- Continuous monitoring
- Rapid response

## 4. Responsibilities
[List roles and responsibilities per section 1.1]

## 5. CSMS Processes
[Reference to detailed process documents]

## 6. Risk Appetite
Maximum acceptable risk: Medium (per ISO 21434 risk scale)
All High/Unacceptable risks must be mitigated.

## 7. Incident Reporting
All suspected cybersecurity incidents must be reported within 2 hours
to security.operations@company.com

## 8. Compliance
This policy supports compliance with:
- UN R155 (CSMS type approval)
- UN R156 (Software updates)
- ISO/SAE 21434 (Cybersecurity engineering)

## 9. Review
Policy reviewed annually or upon major regulatory change.

Approved by: [CTO Signature]
Date: [YYYY-MM-DD]
```

**1.3 Conduct Gap Analysis**

Assessment template:
| UN R155 Requirement | Current State | Gap | Priority | Owner |
|---------------------|---------------|-----|----------|-------|
| 7.2.1 Risk management process | Informal FMEA only | Need formal TARA | High | Security Architect |
| 7.2.2 Security testing | No pentest program | Establish pentest | High | Security Engineer |
| 7.2.3 Monitoring | No fleet monitoring | Deploy VSOC | Medium | Security Ops |
| 7.2.4 Incident response | Generic IT IR plan | Vehicle-specific IR | High | CSMS Manager |
| 7.2.5 Security updates | Manual dealer updates | Deploy OTA | High | SW Engineering |
| 7.2.6 Supply chain | No security clauses | Update contracts | Medium | Procurement |

### Phase 2: Implementation (Months 4-12)

**Objective**: Deploy CSMS processes and technical controls.

#### 2.1 Execute Annex 5 TARA

**Threat Assessment Workflow**:
```python
# Annex 5 TARA automation script
import yaml

def assess_annex5_threat(threat_id, vehicle_architecture):
    """
    Assess a single Annex 5 threat against vehicle architecture.
    """
    threat = ANNEX5_CATALOG[threat_id]

    # Identify affected assets
    affected_assets = identify_assets(threat, vehicle_architecture)

    # Assess damage scenarios
    damages = []
    for asset in affected_assets:
        damage = {
            'asset': asset,
            'safety_impact': assess_safety_impact(asset, threat),
            'financial_impact': assess_financial_impact(asset, threat),
            'operational_impact': assess_operational_impact(asset, threat),
            'privacy_impact': assess_privacy_impact(asset, threat)
        }
        damages.append(damage)

    # Determine maximum impact
    max_impact = max([d['safety_impact'] for d in damages])

    # Assess attack feasibility
    feasibility = assess_feasibility(
        threat,
        vehicle_architecture,
        existing_controls=get_existing_controls(threat_id)
    )

    # Calculate risk
    risk_level = risk_matrix[max_impact][feasibility]

    # Identify required mitigations
    mitigations = []
    if risk_level in ['High', 'Unacceptable']:
        mitigations = select_mitigations(threat, damages)

    return {
        'threat_id': threat_id,
        'description': threat['description'],
        'affected_assets': affected_assets,
        'damages': damages,
        'max_impact': max_impact,
        'feasibility': feasibility,
        'risk_level': risk_level,
        'mitigations': mitigations
    }

# Execute TARA for all Annex 5 threats
vehicle_arch = load_vehicle_architecture('vehicle_model_2025.yaml')
tara_results = []

for threat_id in ANNEX5_CATALOG.keys():
    result = assess_annex5_threat(threat_id, vehicle_arch)
    tara_results.append(result)

# Generate TARA report
generate_tara_report(tara_results, output='tara_report_r155.pdf')
```

**TARA Output Format**:
```yaml
# Example TARA result for one threat
threat_assessment:
  threat_id: "2.1.1"
  annex5_category: "External connectivity attack"
  description: "Attacker exploits vulnerability in TCU to gain remote access"

  affected_assets:
    - name: "Telematics Control Unit (TCU)"
      location: "Central gateway domain"
    - name: "CAN gateway"
      location: "Central gateway domain"

  damage_scenarios:
    - scenario: "Attacker uses TCU as pivot to CAN bus"
      safety_impact: Severe
      rationale: "Could manipulate safety-critical ECUs (brake, steering)"

    - scenario: "Theft of personal data from TCU storage"
      privacy_impact: Major
      rationale: "Location history, contacts, voice recordings"

  attack_path:
    - step: "Exploit cellular modem buffer overflow (CVE-2024-XXXX)"
      feasibility: High (public exploit available)
    - step: "Escalate to root on TCU Linux"
      feasibility: Medium (requires kernel exploit)
    - step: "Access CAN gateway from TCU"
      feasibility: High (if no network segmentation)

  feasibility_score:
    elapsed_time: "≤1 week" (4 points)
    expertise: "Expert" (6 points)
    knowledge: "Public" (0 points)
    opportunity: "Unlimited" (0 points)
    equipment: "Standard" (0 points)
    total: 10 (High feasibility)

  risk_determination:
    impact: Severe
    feasibility: High
    risk_level: Unacceptable

  risk_treatment: Reduce (mandatory mitigation)

  mitigations:
    - control: "Patch cellular modem firmware (CVE-2024-XXXX)"
      effectiveness: Eliminates specific vulnerability
      status: Deployed via OTA 2024-06-01

    - control: "Deploy network firewall between TCU and CAN gateway"
      effectiveness: Prevents pivot even if TCU compromised
      status: Implemented in hardware revision 2.1

    - control: "Enable SELinux mandatory access control on TCU"
      effectiveness: Contains exploit, prevents escalation
      status: Enabled in production software v3.2

  verification:
    penetration_test: "Pentest Report PT-2024-15, dated 2024-07-20"
    result: "Attempted exploit failed due to mitigations"
    residual_risk: Low
```

#### 2.2 Implement Technical Controls

**Gateway Firewall Configuration**:
```c
// AUTOSAR Ethernet firewall configuration
typedef struct {
    uint32_t src_ip;
    uint32_t dest_ip;
    uint16_t src_port;
    uint16_t dest_port;
    uint8_t protocol; // TCP=6, UDP=17
    bool allow;
} FirewallRule_t;

const FirewallRule_t gateway_firewall[] = {
    // Allow TCU to Backend (HTTPS)
    {.src_ip = TCU_IP, .dest_ip = ANY_IP,
     .src_port = ANY_PORT, .dest_port = 443,
     .protocol = TCP, .allow = true},

    // Allow Diagnostic (DoIP from tester)
    {.src_ip = ANY_IP, .dest_ip = GATEWAY_IP,
     .src_port = ANY_PORT, .dest_port = 13400,
     .protocol = TCP, .allow = true},

    // Block TCU to CAN gateway (prevent pivot)
    {.src_ip = TCU_IP, .dest_ip = CAN_GATEWAY_IP,
     .src_port = ANY_PORT, .dest_port = ANY_PORT,
     .protocol = ANY, .allow = false},

    // Block all other traffic (default deny)
    {.src_ip = ANY_IP, .dest_ip = ANY_IP,
     .src_port = ANY_PORT, .dest_port = ANY_PORT,
     .protocol = ANY, .allow = false}
};
```

#### 2.3 Security Testing Program

**Annual Test Schedule**:
| Test Type | Frequency | Trigger | Vendor | Cost Estimate |
|-----------|-----------|---------|--------|---------------|
| **Penetration Testing** | Yearly | New vehicle type or major update | Accredited lab (NCC Group, IOActive) | €50K-€150K |
| **Vulnerability Scanning** | Quarterly | Each SW release | Automated (Nessus, Qualys) | €10K/year |
| **Fuzzing** | Continuous | Per ECU firmware build | In-house (AFL, Honggfuzz) | €20K/year (tools) |
| **Code Analysis** | Per commit | Git push | Automated (Coverity, Fortify) | €50K/year |
| **Red Team Exercise** | Every 2 years | Major platform launch | Specialized firm | €200K-€500K |

**Penetration Test Scope Document**:
```markdown
# Penetration Test Scope - Vehicle Model 2025

## Objectives
- Validate effectiveness of UN R155 Annex 5 mitigations
- Identify unknown vulnerabilities
- Assess exploitability of known risks

## In-Scope Systems
- Telematics Control Unit (TCU) firmware v3.2
- Central Gateway ECU firmware v2.5
- Infotainment head unit software v4.1
- OTA update mechanism
- Diagnostic interface (DoIP)
- V2X communication module (if equipped)

## Attack Vectors
1. Remote network attacks (cellular, WiFi, V2X)
2. Physical access attacks (OBD-II, Ethernet diagnostic)
3. Supply chain attacks (compromised update server simulation)
4. Social engineering (phishing for backend access)

## Out of Scope
- Destructive testing (no physical damage)
- Denial of service causing permanent damage
- Attacks on backend cloud infrastructure (separate pentest)

## Success Criteria
- At least 2 weeks of testing by certified penetration testers
- Detailed report with CVSS scores for findings
- Proof-of-concept code for critical/high findings
- Remediation recommendations

## Timeline
- Kickoff: 2024-08-01
- Testing window: 2024-08-05 to 2024-08-19
- Draft report: 2024-08-30
- Final report: 2024-09-15

## Budget: €80,000
```

#### 2.4 Vulnerability Management Process

**Vulnerability Lifecycle**:
```
┌──────────────────┐
│ 1. Discovery     │ ← Pentest, researcher, Auto-ISAC, CVE DB
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 2. Triage        │ ← Assess CVSS score, exploitability, impact
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 3. Patch Dev     │ ← Develop fix, test for safety regression
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 4. Validation    │ ← Verify patch resolves vulnerability
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 5. Deployment    │ ← OTA or dealer campaign
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 6. Verification  │ ← Confirm installed, vulnerability gone
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 7. Disclosure    │ ← Public disclosure (if researcher-found)
└──────────────────┘
```

**SLA Enforcement Script**:
```python
import datetime

def check_vulnerability_sla(vulnerability):
    """Monitor SLA compliance for vulnerability patching."""
    cvss_score = vulnerability['cvss_score']
    discovery_date = vulnerability['discovery_date']
    today = datetime.date.today()
    age_days = (today - discovery_date).days

    # Determine SLA based on CVSS
    if cvss_score >= 9.0:
        sla_days = 7
        severity = "Critical"
    elif cvss_score >= 7.0:
        sla_days = 30
        severity = "High"
    elif cvss_score >= 4.0:
        sla_days = 90
        severity = "Medium"
    else:
        sla_days = 180
        severity = "Low"

    days_remaining = sla_days - age_days

    if days_remaining < 0:
        alert = f"SLA BREACH: {vulnerability['cve_id']} is {-days_remaining} days overdue!"
        escalate_to_management(alert)
        return {"status": "breached", "days_overdue": -days_remaining}
    elif days_remaining <= 3:
        alert = f"SLA WARNING: {vulnerability['cve_id']} has {days_remaining} days remaining"
        notify_security_team(alert)
        return {"status": "at_risk", "days_remaining": days_remaining}
    else:
        return {"status": "on_track", "days_remaining": days_remaining}
```

### Phase 3: Audit Preparation (Months 13-15)

**Objective**: Compile evidence and prepare for type approval audit.

#### 3.1 Evidence Collection

**Required Documents Checklist**:
- [ ] CSMS Manual (version-controlled, signed by CTO)
- [ ] Organizational chart showing cybersecurity roles
- [ ] TARA report covering all Annex 5 threats
- [ ] Risk treatment plan with verification evidence
- [ ] Architectural design specifications showing security controls
- [ ] Penetration test reports (at least one per vehicle type)
- [ ] Vulnerability management procedure and CVE log
- [ ] Incident response procedure and incident log (anonymized if none)
- [ ] Security update procedure and deployment statistics
- [ ] Supplier cybersecurity requirements (contracts, questionnaires)
- [ ] Training records (attendance, competency assessments)
- [ ] Management review meeting minutes

#### 3.2 Mock Audit

Conduct internal audit 3 months before real audit:
- External consultant as auditor
- Full 3-day audit simulation
- Identify gaps and remediate
- Practice staff interviews

#### 3.3 Submit Application

**Application Package Contents**:
1. **Cover Letter** - Introducing manufacturer and vehicle types
2. **CSMS Certificate Application Form** - Per approval authority template
3. **CSMS Manual** - Core documentation (50-200 pages)
4. **Annex 5 Assessment** - TARA results (100-300 pages)
5. **Supporting Evidence** - Test reports, procedures, logs
6. **Audit Readiness Statement** - Confirm readiness for on-site audit

Submit to chosen approval authority (e.g., KBA, VCA, UTAC) 6 months before desired certificate date.

### Phase 4: Audit Execution (Month 16)

**Objective**: Successfully pass UN R155 audit.

#### Audit Day 1: Document Review

**Auditor Activities**:
- Review CSMS manual for completeness
- Verify Annex 5 threat coverage
- Check process definitions match requirements

**OEM Preparation**:
- Assign subject matter expert (SME) to each auditor
- Have all documents organized and accessible
- Prepare presentation on CSMS overview

**Common Questions**:
- "How do you ensure all Annex 5 threats are covered?"
- "What is your process for selecting security controls?"
- "How often do you review and update TARA?"

#### Audit Day 2: Process Evaluation

**Auditor Activities**:
- Interview key personnel
- Review work products (TARA results, test reports)
- Trace requirements through implementation to verification

**OEM Preparation**:
- Schedule interviews (CSMS Manager, Security Architect, Test Engineer)
- Prepare evidence traceability matrix
- Have technical staff available for follow-up questions

**Example Interview Questions**:
- Security Architect: "Walk me through how you conducted TARA for threat 2.1.1"
- Test Engineer: "Show me a vulnerability you found and how it was resolved"
- CSMS Manager: "How do you monitor compliance with security processes?"

#### Audit Day 3: Technical Verification

**Auditor Activities**:
- Inspect vehicle (optional, if available)
- Review test evidence in detail
- Confirm mitigations are implemented as described

**OEM Preparation**:
- Have test vehicle available with diagnostic tools
- Demonstrate security features (secure boot, encrypted communication)
- Show monitoring dashboard (VSOC)

**Possible Demonstrations**:
- Secure boot preventing unsigned firmware
- SecOC rejecting unauthenticated CAN message
- IDS detecting simulated attack
- OTA update process end-to-end

### Phase 5: Certificate Maintenance (Ongoing)

**Objective**: Maintain UN R155 compliance through surveillance audits.

#### Annual Surveillance Audit

**Scope**: Verify CSMS remains effective and up-to-date.

**Auditor Focus Areas**:
- Changes to vehicle architecture since initial audit
- New vulnerabilities discovered and addressed
- Incident response effectiveness (if incidents occurred)
- Security updates deployed to fleet
- Supplier management activity

**Evidence Required**:
- CSMS change log
- Vulnerability log (new CVEs since last audit)
- Security update statistics
- Incident reports (if any)
- Supplier audit results

#### CSMS Evolution

Continuously improve CSMS based on:
- Industry threat intelligence (Auto-ISAC bulletins)
- Internal lessons learned (incidents, near-misses)
- Regulatory updates (UN R155 amendments)
- Technology advances (new security capabilities)

**Example Improvement Log**:
| Date | Trigger | Change | Impact |
|------|---------|--------|--------|
| 2024-09-15 | Auto-ISAC warning about V2X vulnerability | Added V2X certificate validation | Reduced V2X attack risk |
| 2025-01-10 | Incident: Researcher found DoIP vulnerability | Implemented DoIP authentication | Prevented exploit |
| 2025-03-20 | UN R155 Rev.1 published | Updated CSMS processes to align | Maintained compliance |

## Tools and Templates

### CSMS Implementation Toolkit

**Recommended Tools**:
| Tool Category | Tool Examples | Purpose |
|---------------|---------------|---------|
| **TARA Tool** | Threat Composer, Attack Trees | Document threat analysis |
| **Vulnerability Scanner** | Nessus, Qualys, OpenVAS | Automated scanning |
| **Fuzzer** | AFL, Honggfuzz, Peach | Protocol/API fuzzing |
| **Static Analysis** | Coverity, Fortify, CodeQL | Source code analysis |
| **Penetration Testing** | Metasploit, Burp Suite, CANoe | Manual security testing |
| **SBOM Management** | Syft, Grype, Dependency-Track | Track software components |
| **Incident Response** | TheHive, MISP, Cortex | IR case management |
| **Monitoring** | Splunk, ELK, Grafana | VSOC dashboards |

### Document Templates

All templates available in CSMS toolkit package.

## Next Steps

- **Level 4**: Quick reference checklists and Annex 5 threat catalog
- **Level 5**: Advanced multi-OEM CSMS and supply chain security

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: CSMS implementers, compliance project managers
