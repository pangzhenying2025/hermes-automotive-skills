# ISO/SAE 21434 - Quick Reference

## TARA Quick Reference

### Attack Feasibility Scoring Table

| Factor | Very High (VH) | High (H) | Medium (M) | Low (L) | Very Low (VL) |
|--------|---------------|----------|------------|---------|---------------|
| **Elapsed Time** | ≤1 day (3) | ≤1 week (4) | ≤1 month (7) | ≤6 months (10) | >6 months (11) |
| **Expertise** | Layman (0) | Proficient (3) | Expert (6) | Multiple experts (8) | - |
| **Knowledge of Item** | Public (0) | Restricted (3) | Confidential (7) | Strictly confidential (11) | - |
| **Window of Opportunity** | Unlimited (0) | Easy (1) | Moderate (4) | Difficult (10) | - |
| **Equipment** | Standard (0) | Specialized (4) | Bespoke (7) | Multiple bespoke (9) | - |

**Total Feasibility Score** = Sum of all factors

| Total Score | Feasibility Rating |
|-------------|-------------------|
| 0-9 | Very High |
| 10-16 | High |
| 17-23 | Medium |
| 24-33 | Low |
| ≥34 | Very Low |

### Impact Rating Criteria

| Rating | Safety | Financial | Operational | Privacy |
|--------|--------|-----------|-------------|---------|
| **Severe** | Death or serious injury to multiple persons | >€1,000,000 | Complete system failure | Mass data breach affecting >10,000 users |
| **Major** | Light to moderate injury | €100,000 - €1,000,000 | Major degradation of functions | Significant PII exposure (100-10,000 users) |
| **Moderate** | Possible minor injury | €10,000 - €100,000 | Minor degradation | Limited data exposure (<100 users) |
| **Negligible** | No injury | <€10,000 | Inconvenience only | Minimal or no privacy impact |

### Risk Determination Matrix

| Impact ↓ / Feasibility → | Very High | High | Medium | Low | Very Low |
|--------------------------|-----------|------|--------|-----|----------|
| **Severe** | 🔴 Unacceptable | 🔴 Unacceptable | 🟠 High | 🟡 Medium | 🟢 Low |
| **Major** | 🔴 Unacceptable | 🟠 High | 🟠 High | 🟡 Medium | 🟢 Low |
| **Moderate** | 🟠 High | 🟡 Medium | 🟡 Medium | 🟢 Low | 🟢 Very Low |
| **Negligible** | 🟡 Medium | 🟢 Low | 🟢 Low | 🟢 Very Low | 🟢 Very Low |

**Risk Treatment**:
- 🔴 Unacceptable: Must be reduced (risk avoidance or mitigation)
- 🟠 High: Should be reduced, requires strong justification to retain
- 🟡 Medium: May be retained with management approval
- 🟢 Low/Very Low: Can be retained with documentation

## Cryptographic Algorithm Selection

### Recommended Algorithms (2026+)

| Use Case | Algorithm | Key/Hash Size | Notes |
|----------|-----------|---------------|-------|
| **Symmetric Encryption** | AES-GCM | 256-bit | Authenticated encryption |
| | ChaCha20-Poly1305 | 256-bit | Alternative for constrained devices |
| **Asymmetric Encryption** | RSA | 3072-bit minimum | Use OAEP padding |
| | ECDH | P-256 or higher | Key exchange |
| **Digital Signature** | ECDSA | P-256 or higher | Faster than RSA on embedded |
| | RSA-PSS | 3072-bit minimum | Widely supported |
| | EdDSA (Ed25519) | 256-bit | Recommended for new designs |
| **Hash Function** | SHA-256 | 256-bit | General purpose |
| | SHA-3 (SHA3-256) | 256-bit | Alternative to SHA-2 |
| **Message Authentication** | HMAC-SHA256 | 256-bit | For non-AEAD ciphers |
| | CMAC-AES | 128/256-bit | For AUTOSAR SecOC |
| **Key Derivation** | PBKDF2 | - | Min 100,000 iterations |
| | HKDF | - | For key expansion |

### Deprecated/Weak Algorithms (DO NOT USE)

| Algorithm | Status | Reason |
|-----------|--------|--------|
| DES, 3DES | ❌ Prohibited | Key size too small (56/112-bit) |
| MD5 | ❌ Prohibited | Collision attacks |
| SHA-1 | ❌ Prohibited | Collision attacks |
| RSA 1024-bit | ❌ Prohibited | Insufficient key length |
| RC4 | ❌ Prohibited | Statistical biases |
| ECB mode | ❌ Prohibited | Does not hide patterns |

## Security Controls Checklist

### Vehicle-Level Controls

- [ ] **Gateway Firewall**: CAN-Ethernet gateway with packet filtering
- [ ] **Network Segmentation**: Critical domains isolated from infotainment
- [ ] **Intrusion Detection System (IDS)**: Monitor CAN/Ethernet for anomalies
- [ ] **Secure Gateway**: Authenticated inter-domain communication
- [ ] **Diagnostic Access Control**: UDS seed-key authentication for Level 2+ services
- [ ] **Physical Security**: Tamper detection on critical ECUs
- [ ] **Secure Debug Port**: JTAG/SWD disabled or authenticated in production

### ECU-Level Controls

- [ ] **Secure Boot**: RSA/ECDSA signature verification of firmware
- [ ] **Code Signing**: All application software signed by OEM
- [ ] **Runtime Integrity**: Periodic CRC/hash checks of code in RAM
- [ ] **Memory Protection**: MPU/MMU configured to prevent code injection
- [ ] **Stack Protection**: Canaries, ASLR where supported
- [ ] **Watchdog**: Independent watchdog to detect lockup/tampering
- [ ] **Secure Storage**: HSM or secure element for keys
- [ ] **Anti-Rollback**: Version number enforcement to prevent downgrade attacks

### Communication Security

- [ ] **SecOC**: Message authentication on critical CAN/FlexRay messages
- [ ] **TLS 1.3**: For Ethernet-based protocols (DoIP, SOME/IP)
- [ ] **IPsec/MACsec**: Layer 3/2 encryption for zonal architectures
- [ ] **Certificate Management**: X.509 certificate lifecycle (issue, renew, revoke)
- [ ] **Freshness Values**: Counter or timestamp to prevent replay attacks
- [ ] **Rate Limiting**: Prevent DoS attacks on communication channels

### Backend/Cloud Security

- [ ] **OTA Update Security**: Signature verification, encrypted transport
- [ ] **Backend Authentication**: Mutual TLS between vehicle and cloud
- [ ] **API Security**: OAuth2/JWT for REST APIs
- [ ] **Data Privacy**: GDPR compliance for personal data
- [ ] **Secure Logging**: Tamper-evident logs for forensic analysis
- [ ] **Incident Response**: SOC monitoring, vulnerability disclosure process

## UN R155 Compliance Mapping

### CSMS Requirements → ISO 21434 Clauses

| UN R155 Requirement | ISO 21434 Clause | Deliverable |
|---------------------|------------------|-------------|
| Processes for risk management | Clause 8 (TARA) | TARA report, risk register |
| Manage threats/vulnerabilities | Clause 15 (Operations) | Vulnerability management plan |
| Test for cyber-attacks | Clause 11 (Validation) | Penetration test reports |
| Monitor/detect attacks | Clause 15.4 (Monitoring) | IDS/SIEM configuration, logs |
| Respond to attacks | Clause 15.5 (Response) | Incident response plan |
| Provide software updates | Clause 15.6 (Updates) | OTA update process, security patches |
| Mitigate risks in supply chain | Clause 14 (Dependencies) | Supplier cybersecurity agreements |

### Required CSMS Documentation

1. **Cybersecurity Policy** (ISO 21434 Clause 5.4.2)
2. **TARA Methodology** (Clause 9.3)
3. **Risk Treatment Plan** (Clause 9.4)
4. **Cybersecurity Validation Report** (Clause 11)
5. **Production Control Plan** (Clause 12)
6. **Vulnerability Management Process** (Clause 15.3)
7. **Incident Response Procedure** (Clause 15.5)
8. **Security Update Process** (Clause 15.6)

## Common Attack Scenarios

### Attack Vector Catalog (STRIDE)

| Attack Type | Vector | Example | Mitigation |
|-------------|--------|---------|------------|
| **Spoofing** | CAN injection | Fake brake pedal signal from compromised ECU | SecOC message authentication |
| **Tampering** | Firmware modification | Reflash ECU via unsecured diagnostic port | Secure boot, signed firmware |
| **Repudiation** | Log deletion | Attacker clears evidence after intrusion | Write-once logging, remote log forwarding |
| **Information Disclosure** | CAN eavesdropping | Passive monitoring of unencrypted CAN traffic | SecOC confidentiality mode (AUTOSAR R20+) |
| **Denial of Service** | CAN bus flooding | Send max-rate CAN frames to saturate bus | IDS with rate limiting, bus load monitoring |
| **Elevation of Privilege** | Diagnostic exploit | Exploit UDS service to gain programming access | Seed-key authentication, session control |

### UN R155 Annex 5 Threat Catalog (Excerpt)

| Threat ID | Description | Target Asset | Typical Mitigation |
|-----------|-------------|--------------|-------------------|
| 1.1.1 | Back-end server attack | Cloud services | TLS, authentication, WAF |
| 1.2.1 | Update procedure attack | OTA mechanism | Signed updates, secure transport |
| 1.3.1 | Vehicle communication channel attack | Telematics | Encrypted channels, firewall |
| 2.1.1 | External connectivity attack | TCU, gateway | Authentication, IDS |
| 2.2.1 | Wireless communication attack | V2X, WiFi, BT | WPA3, encryption |
| 3.1.1 | Wired communication attack | OBD-II, Ethernet | Physical access control, auth |
| 4.1.1 | Vehicle data/code attack | Flash memory | Secure boot, encrypted storage |

## Cybersecurity Work Products

### Minimum Required Artifacts

| Artifact | Purpose | Owner | Update Frequency |
|----------|---------|-------|------------------|
| **Cybersecurity Plan** | Overall cybersecurity strategy | CSMS Manager | Yearly |
| **Asset Register** | List of all protected assets | System Architect | Per project |
| **TARA Report** | Threat analysis and risk assessment | Security Engineer | Per release |
| **Security Requirements Spec** | Functional and technical security requirements | Security Architect | Per release |
| **Cybersecurity Verification Plan** | Test strategy for security controls | Test Engineer | Per release |
| **Cybersecurity Validation Report** | Results of penetration testing | Security Tester | Per release |
| **Vulnerability Management Log** | Tracking of CVEs and patches | Security Operations | Continuous |
| **Incident Response Log** | Record of security incidents | SOC Team | Continuous |

## Security Testing Quick Reference

### Penetration Testing Scope

| Target | Tools | Focus Areas |
|--------|-------|-------------|
| **CAN Bus** | CANoe, Kayak, can-utils | Message injection, replay, DoS |
| **Ethernet** | Wireshark, Nmap, Metasploit | Port scanning, protocol fuzzing |
| **ECU Firmware** | IDA Pro, Ghidra, binwalk | Reverse engineering, backdoors |
| **OTA Updates** | Burp Suite, mitmproxy | MITM, signature bypass |
| **Diagnostic** | CarShark, ODX Studio | UDS service exploitation |
| **V2X** | OmniAir, Cohda | V2X message spoofing |

### Vulnerability Severity Scoring (CVSS)

| CVSS Score | Severity | Action Required |
|------------|----------|-----------------|
| 9.0 - 10.0 | Critical | Immediate patch (< 7 days) |
| 7.0 - 8.9 | High | Patch within 30 days |
| 4.0 - 6.9 | Medium | Patch within 90 days |
| 0.1 - 3.9 | Low | Patch in next release |

## Key Management Lifecycle

### Certificate Validity Periods

| Certificate Type | Validity Period | Renewal Trigger |
|------------------|------------------|-----------------|
| Root CA | 20 years | N/A (offline) |
| Intermediate CA (OEM) | 10 years | 1 year before expiry |
| ECU Certificate | 15 years (vehicle life) | Not renewable (key in HSM) |
| TLS Server Certificate | 1 year | Auto-renewal at 30 days |
| V2X Certificate | 3 years | Auto-renewal at 90 days |

### Key Storage Requirements

| Key Type | Storage Location | Protection |
|----------|------------------|------------|
| Root CA private key | Offline HSM | Air-gapped, multi-person access |
| OEM intermediate CA key | Online HSM | FIPS 140-2 Level 3+ |
| ECU private key | On-chip HSM/secure element | Hardware-bound, non-extractable |
| Symmetric session keys | Secure RAM | Cleared on reset, never written to flash |

## Compliance Checklist

### ISO 21434 Compliance Status

- [ ] Clause 5: Organizational cybersecurity management
  - [ ] 5.4.2: Cybersecurity policy defined
  - [ ] 5.4.3: Roles and responsibilities assigned
  - [ ] 5.4.5: Cybersecurity culture established
- [ ] Clause 8: Continuous cybersecurity activities
  - [ ] 8.3: Cybersecurity monitoring
  - [ ] 8.4: Cybersecurity event assessment
- [ ] Clause 9: Concept phase
  - [ ] 9.3: Threat analysis and risk assessment (TARA)
  - [ ] 9.4: Cybersecurity goals defined
  - [ ] 9.5: Cybersecurity concept
- [ ] Clause 10: Product development
  - [ ] 10.4: Cybersecurity requirements specification
  - [ ] 10.5: Architectural design
  - [ ] 10.6: Detailed design
  - [ ] 10.7: Integration and verification
- [ ] Clause 11: Cybersecurity validation
  - [ ] 11.4: Validation plan
  - [ ] 11.5: Validation execution (penetration testing)
- [ ] Clause 12: Production
  - [ ] 12.4: Production control plan
- [ ] Clause 13: Operations and maintenance
  - [ ] 13.4: Vulnerability management
  - [ ] 13.5: Cybersecurity incident response
  - [ ] 13.6: Security updates
- [ ] Clause 14: Distributed cybersecurity activities
  - [ ] 14.4: Supplier requirements

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All automotive cybersecurity practitioners
