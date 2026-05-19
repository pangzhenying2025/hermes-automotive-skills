# UN R155 - Quick Reference

## Annex 5 Threat Catalog (Complete)

### Category 1: Back-end Server

| Threat ID | Description | Typical Attack Vectors | Key Mitigations |
|-----------|-------------|----------------------|-----------------|
| **1.1.1** | Attack on back-end servers | SQL injection, DDoS, credential theft | WAF, authentication, intrusion detection |
| **1.2.1** | Attack on update procedure | MITM, malicious update injection | Code signing, TLS, signature verification |
| **1.3.1** | Attack on communication channel between back-end server and vehicle | Network sniffing, MITM, DNS spoofing | TLS 1.3, certificate pinning, mutual auth |

### Category 2: External Connectivity

| Threat ID | Description | Typical Attack Vectors | Key Mitigations |
|-----------|-------------|----------------------|-----------------|
| **2.1.1** | Attack on external connectivity to access vehicle functions/data | Remote exploit of TCU, gateway vulnerability | Firewall, network segmentation, authenticated services |
| **2.2.1** | Attack on wireless interfaces (WiFi, Bluetooth, V2X, cellular) | Bluetooth pairing exploit, WiFi WPA crack, V2X message spoofing | Strong encryption (WPA3), V2X certificates, disable unused interfaces |

### Category 3: Wired Connectivity

| Threat ID | Description | Typical Attack Vectors | Key Mitigations |
|-----------|-------------|----------------------|-----------------|
| **3.1.1** | Attack via wired connections (OBD-II, Ethernet, USB) | Physical access to diagnostic port, USB malware | Physical access control, authenticated diagnostics (seed-key), USB input validation |

### Category 4: Data and Code

| Threat ID | Description | Typical Attack Vectors | Key Mitigations |
|-----------|-------------|----------------------|-----------------|
| **4.1.1** | Attack on vehicle data and code | ECU firmware extraction, reverse engineering | Secure boot, encrypted storage, code obfuscation |
| **4.2.1** | Manipulation of vehicle data and code | Firmware reflashing, memory tampering, CAN injection | Secure boot, runtime integrity checks, SecOC |

### Category 5: Misuse

| Threat ID | Description | Typical Attack Vectors | Key Mitigations |
|-----------|-------------|----------------------|-----------------|
| **5.1.1** | Misuse of debug/diagnostic/service functions | Abuse of service mode, diagnostic session escalation | Role-based access control, audit logging, disable debug in production |

## CSMS Requirements Checklist

### UN R155 Paragraph 7.2 Compliance

- [ ] **7.2.1 - Risk Management Processes**
  - [ ] Threat identification methodology documented
  - [ ] All Annex 5 threats assessed
  - [ ] Risk treatment decisions recorded
  - [ ] Verification evidence for each mitigation

- [ ] **7.2.2 - Testing for Vulnerabilities**
  - [ ] Penetration testing performed by accredited lab
  - [ ] Vulnerability scanning process established
  - [ ] Test reports cover all attack surfaces
  - [ ] Remediation of findings documented

- [ ] **7.2.3 - Monitoring**
  - [ ] Vehicle-level anomaly detection implemented
  - [ ] Fleet telemetry for security events
  - [ ] VSOC or equivalent monitoring center operational
  - [ ] Threat intelligence feeds integrated

- [ ] **7.2.4 - Incident Response**
  - [ ] Incident response procedure documented
  - [ ] Escalation matrix defined with SLAs
  - [ ] Incident logging system in place
  - [ ] Post-incident review process

- [ ] **7.2.5 - Security Updates**
  - [ ] OTA update mechanism secured (signing, encryption)
  - [ ] Update deployment procedure documented
  - [ ] Patch SLAs defined by vulnerability severity
  - [ ] Update success rate tracked

- [ ] **7.2.6 - Supply Chain**
  - [ ] Supplier cybersecurity requirements in contracts
  - [ ] Supplier assessment/audit process
  - [ ] SBOM provided by suppliers
  - [ ] Vulnerability notification SLAs with suppliers

- [ ] **7.2.7 - Governance**
  - [ ] Cybersecurity policy approved by executive
  - [ ] Roles and responsibilities assigned
  - [ ] CSMS training program for personnel
  - [ ] Annual management review conducted

## Audit Preparation Checklist

### Document Readiness

- [ ] **CSMS Manual**
  - [ ] Version controlled and current
  - [ ] Signed by authorized executive
  - [ ] Contains all required processes
  - [ ] Cross-references to detailed procedures

- [ ] **TARA Report**
  - [ ] Covers all Annex 5 threat categories (1.x.x through 5.x.x)
  - [ ] Impact ratings justified (safety, financial, operational, privacy)
  - [ ] Attack feasibility scores calculated per ISO 21434 method
  - [ ] Risk matrix applied, risk levels determined
  - [ ] Mitigations selected for High/Unacceptable risks

- [ ] **Architectural Specifications**
  - [ ] Network architecture diagrams
  - [ ] ECU interconnection diagrams
  - [ ] Security zone definitions
  - [ ] Firewall rules documented

- [ ] **Test Evidence**
  - [ ] Penetration test reports (one per vehicle type minimum)
  - [ ] Vulnerability scan results
  - [ ] Secure boot verification test
  - [ ] SecOC functionality test
  - [ ] OTA update security test

- [ ] **Operational Records**
  - [ ] Vulnerability management log (all CVEs tracked)
  - [ ] Incident log (if no incidents, document "none occurred")
  - [ ] Security update campaign statistics
  - [ ] Supplier audit/questionnaire results
  - [ ] Training attendance records

### Personnel Readiness

- [ ] **CSMS Manager** prepared for audit lead interview
  - [ ] Can explain CSMS governance model
  - [ ] Knows escalation procedures
  - [ ] Familiar with all process documents

- [ ] **Security Architect** prepared for technical interview
  - [ ] Can walk through TARA methodology
  - [ ] Explain security architecture decisions
  - [ ] Describe cryptographic implementations

- [ ] **Test Engineer** prepared to demonstrate testing
  - [ ] Show penetration test execution
  - [ ] Explain vulnerability remediation process
  - [ ] Demonstrate security validation tools

- [ ] **Facility Readiness**
  - [ ] Conference room for audit
  - [ ] Network access for auditors (if needed)
  - [ ] Test vehicle available for demonstration
  - [ ] Diagnostic tools and laptops ready

## Vulnerability Severity Response SLAs

| CVSS Score | Severity | Triage Time | Patch Dev Time | Deployment Start | Full Fleet | Disclosure |
|------------|----------|-------------|----------------|------------------|------------|------------|
| **9.0-10.0** | Critical | 4 hours | 7 days | 14 days | 30 days | After patch available |
| **7.0-8.9** | High | 24 hours | 30 days | 45 days | 90 days | After 90% fleet patched |
| **4.0-6.9** | Medium | 7 days | 60 days | 90 days | 180 days | After patch available |
| **0.1-3.9** | Low | 30 days | Next release | Next release | Next release | Immediate (low risk) |

## Incident Severity Classification

| Severity | Response Time | Escalation | Notification | Examples |
|----------|---------------|------------|--------------|----------|
| **P1 - Critical** | 1 hour | CTO, CEO | Regulators within 24h | Active remote exploitation, safety impact |
| **P2 - High** | 4 hours | VP Engineering | Management within 24h | Confirmed vulnerability, no active exploit |
| **P3 - Medium** | 24 hours | Director | Weekly security meeting | Suspected incident, under investigation |
| **P4 - Low** | 72 hours | Team Lead | Monthly report | False positive, minor information disclosure |

## Supplier Cybersecurity Assessment

### Tier 1 Supplier Requirements

| Requirement | Evidence | Frequency |
|-------------|----------|-----------|
| ISO 21434 or UN R155 CSMS certification | Certificate copy | Annual renewal |
| TARA for supplied components | TARA report | Per product delivery |
| Software Bill of Materials (SBOM) | SPDX or CycloneDX file | Per SW release |
| Vulnerability notification | <48h for CVSS ≥7.0 | As discovered |
| Security patch support | Minimum 10 years | Per contract |
| Right to audit | Allow OEM cybersecurity audit | Annual or on-demand |
| Secure development | SDL process document | Annual review |
| Incident cooperation | Participate in OEM incident response | As needed |

### Supplier Assessment Scorecard

| Category | Weight | Score (0-10) | Weighted Score |
|----------|--------|--------------|----------------|
| CSMS Maturity | 25% | - | - |
| Technical Controls | 30% | - | - |
| Vulnerability Management | 20% | - | - |
| Incident Response | 10% | - | - |
| Supply Chain Security | 15% | - | - |
| **Total** | **100%** | - | - |

**Passing Score**: ≥70% required for Tier 1 supplier approval

## Security Testing Matrix

| Asset/Interface | Test Type | Tool | Frequency | Compliance Artifact |
|----------------|-----------|------|-----------|---------------------|
| **TCU Firmware** | Pentest | Manual + Metasploit | Yearly | Pentest report |
| **TCU Firmware** | Static analysis | Coverity | Per build | SAST report |
| **Gateway ECU** | Pentest | CANoe + custom scripts | Yearly | Pentest report |
| **CAN Bus** | Protocol fuzzing | Scapy | Quarterly | Fuzzing results |
| **Ethernet DoIP** | Pentest | Wireshark + Nmap | Yearly | Pentest report |
| **OTA Update** | Pentest | Burp Suite | Per OTA system change | Pentest report |
| **V2X Module** | Protocol analysis | OmniAir test suite | Yearly | V2X security cert |
| **Infotainment** | Web app pentest | OWASP ZAP | Yearly | Web app pentest report |
| **All ECUs** | Vulnerability scan | Nessus | Quarterly | Vuln scan report |
| **All Firmware** | SBOM CVE check | Grype | Per build | CVE scan results |

## Key Cryptographic Parameters

### Minimum Algorithm Strengths (2026+)

| Algorithm Type | Minimum Strength | Recommended | Notes |
|----------------|------------------|-------------|-------|
| **Symmetric Encryption** | AES-128 | AES-256-GCM | Use authenticated encryption |
| **Asymmetric Encryption** | RSA-2048 | RSA-3072 or ECC P-256 | ECC preferred for embedded |
| **Digital Signature** | RSA-2048 or ECDSA P-256 | Ed25519 | Ed25519 for new designs |
| **Hash Function** | SHA-256 | SHA-256 or SHA3-256 | No SHA-1 or MD5 |
| **Key Derivation** | PBKDF2 (100K iterations) | HKDF with SHA-256 | For deriving session keys |
| **Random Number Generator** | CSPRNG | Hardware TRNG | Use /dev/urandom or HSM RNG |

### Certificate Validity Periods

| Certificate Type | Validity Period | Renewal Lead Time | Key Storage |
|------------------|------------------|-------------------|-------------|
| Root CA | 20 years | N/A (offline) | Offline HSM |
| Intermediate CA (OEM) | 10 years | 1 year before expiry | Online HSM (FIPS 140-2 L3+) |
| ECU Certificate | 15 years (vehicle lifetime) | Not renewable | On-chip HSM/secure element |
| TLS Server Certificate | 1 year | 30 days before expiry | Backend HSM |
| V2X Certificate | 3 years | 90 days before expiry | ECU secure storage |

## Common Audit Findings and Remediation

| Finding | Root Cause | Remediation | Prevention |
|---------|------------|-------------|------------|
| Incomplete Annex 5 coverage | TARA missed some threat categories | Complete TARA for all 5 categories | Use Annex 5 checklist |
| No vulnerability SLAs | Process not defined | Document response times by severity | Adopt industry standard SLAs |
| Insufficient pentest evidence | Only one test performed | Perform annual pentest per vehicle type | Schedule recurring pentests |
| Weak supplier requirements | Generic contracts | Add specific cybersecurity clauses | Use supplier template |
| No incident response tests | IR plan not validated | Conduct tabletop exercise | Annual IR drill |
| Missing SBOM from suppliers | Not requested in contract | Require SBOM in SOW | Update procurement process |
| Inadequate training records | Training not tracked | Implement LMS for cybersecurity training | Assign training administrator |

## Regulatory Timeline Reference

| Date | Regulation | Milestone | Action Required |
|------|------------|-----------|-----------------|
| Jan 2021 | UN R155 | Entered into force | Available for voluntary adoption |
| Jul 2022 | UN R155 | Mandatory for new vehicle types | New types need CSMS certificate |
| Jan 2022 | UN R156 | Entered into force (OTA updates) | Secure OTA processes required |
| Jul 2024 | UN R155/R156 | Mandatory for all new vehicles | All production needs compliance |
| Ongoing | UN R155 | Annual surveillance audits | Maintain CSMS effectiveness |

## Useful Resources

| Resource | URL | Purpose |
|----------|-----|---------|
| **UN R155 Official Text** | unece.org/transport/vehicle-regulations | Regulatory reference |
| **ISO/SAE 21434 Standard** | iso.org or sae.org | Technical guidance |
| **Auto-ISAC** | automotiveisac.com | Threat intelligence |
| **NIST NVD** | nvd.nist.gov | CVE database |
| **MITRE ATT&CK for Automotive** | attack.mitre.org | Threat taxonomy |
| **OWASP Automotive** | owasp.org/www-project-automotive | Security testing guides |

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All UN R155 practitioners
