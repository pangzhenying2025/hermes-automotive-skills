# PKI and Key Lifecycle Management Rules

> Rules for managing cryptographic keys throughout their lifecycle in
> automotive systems, covering key generation, distribution, storage,
> rotation, and revocation for vehicle PKI infrastructure.

## Scope

These rules apply to all cryptographic key management in automotive
including ECU manufacturing provisioning, V2X certificate management,
OTA signing keys, diagnostic authentication keys, SecOC session keys,
and backend service credentials.

---

## Automotive PKI Hierarchy

```
Root CA (Offline, Air-gapped HSM)
  |
  +-- OEM Vehicle Sub-CA
  |     |
  |     +-- Vehicle Identity Certificates
  |     +-- ECU Identity Certificates
  |     +-- TLS Client Certificates
  |
  +-- OEM Backend Sub-CA
  |     |
  |     +-- OTA Server Certificates
  |     +-- Telemetry Server Certificates
  |     +-- API Gateway Certificates
  |
  +-- OEM Code Signing Sub-CA
  |     |
  |     +-- Firmware Signing Certificates
  |     +-- Calibration Signing Certificates
  |     +-- Bootloader Signing Certificates
  |
  +-- V2X Sub-CA (per region)
        |
        +-- V2X Pseudonym Certificates
        +-- V2X Long-term Certificates
```

### Certificate Authority Rules

| CA Level | HSM Requirement | Key Algorithm | Validity | Access Control |
|----------|----------------|---------------|----------|---------------|
| Root CA | FIPS 140-2 L3+ (offline) | ECDSA P-384 | 25 years | Dual custody |
| Sub-CA | FIPS 140-2 L3 (network) | ECDSA P-384 | 10 years | Role-based |
| End Entity | FIPS 140-2 L2 or ECU HSM | ECDSA P-256 | 1-10 years | Automated |
| V2X Pseudonym | FIPS 140-2 L2 or ECU HSM | ECDSA P-256 | 1 week | Automated |

---

## Key Lifecycle

### Lifecycle States

```
Generation -> Distribution -> Activation -> Active Use
                                               |
                                    +----------+----------+
                                    |          |          |
                                 Rotation   Suspension  Expiry
                                    |          |          |
                                    v          v          v
                                New Key    Reactivation  Archive
                                    |      or Revoke       |
                                    v          |          v
                                Active      Revoked    Destroyed
                                    |                     |
                                    +---------> Destroyed <+
```

### Key Generation Rules

```yaml
key_generation:
  environment:
    production_keys: "FIPS 140-2 Level 3 certified HSM"
    development_keys: "Software-based (clearly labeled DEV)"
    test_keys: "Separate key hierarchy (never shared with production)"

  entropy_source:
    primary: "HSM hardware TRNG (NIST SP 800-90B compliant)"
    health_test: "Continuous health monitoring (stuck/repetition/proportion)"
    minimum_entropy: "256 bits per key generation"

  algorithms:
    asymmetric:
      ecdsa_p256: { purpose: "ECU identity, V2X, SecOC" }
      ecdsa_p384: { purpose: "CA certificates, code signing" }
      ecdh_p256: { purpose: "Key agreement, session key derivation" }
    symmetric:
      aes_128: { purpose: "SecOC message authentication" }
      aes_256: { purpose: "Firmware encryption, data-at-rest" }
    mac:
      hmac_sha256: { purpose: "Message integrity, log protection" }
      aes_cmac: { purpose: "CAN message authentication (SecOC)" }

  separation:
    rule: "Different keys for different purposes (no key reuse)"
    examples:
      - "Signing key != encryption key"
      - "SecOC key != diagnostic key"
      - "Production key != development key"
      - "Per-ECU unique keys (no fleet-wide shared secrets)"
```

### Key Distribution

#### Manufacturing Provisioning

```yaml
manufacturing_provisioning:
  environment: "Secure manufacturing facility"
  process:
    1_identity: "Assign unique ECU identity (serial number, hardware ID)"
    2_keypair: "Generate key pair inside ECU HSM (private key never exported)"
    3_csr: "ECU generates Certificate Signing Request (CSR)"
    4_certificate: "Manufacturing CA signs CSR, returns certificate"
    5_root_trust: "Install Root CA certificate chain in ECU secure storage"
    6_symmetric: "Derive per-ECU symmetric keys from master key + ECU ID"
    7_verify: "Verify all provisioned credentials via self-test"
    8_lock: "Lock provisioning interface (no re-provisioning without factory auth)"

  key_injection:
    method: "HSM internal generation preferred over injection"
    fallback: "If injection required: encrypted transport via TLS to HSM"
    prohibited: "Never inject keys via plaintext interface"

  traceability:
    logged: true
    fields: ["ECU_ID", "Key_ID", "Timestamp", "Operator_ID", "Station_ID"]
    retention: "Life of vehicle + 10 years"
```

#### In-Field Key Update

```c
/* Secure key update protocol for SecOC keys */
typedef struct {
    uint8_t key_id[16];           /* Which key to update */
    uint32_t key_version;          /* Must be > current version */
    uint8_t encrypted_new_key[48]; /* New key encrypted with KEK */
    uint8_t iv[12];                /* AES-GCM IV */
    uint8_t auth_tag[16];          /* AES-GCM authentication tag */
    uint8_t signature[64];         /* ECDSA signature over all above */
} KeyUpdateMessage_t;

KeyUpdateResult_t process_key_update(const KeyUpdateMessage_t* msg) {
    /* Step 1: Verify signature (proves message is from authorized source) */
    if (!hsm_ecdsa_verify(KEY_UPDATE_AUTH_SLOT,
                           (const uint8_t*)msg,
                           offsetof(KeyUpdateMessage_t, signature),
                           msg->signature)) {
        return KEY_UPDATE_AUTH_FAILED;
    }

    /* Step 2: Check version (anti-replay) */
    if (msg->key_version <= get_current_key_version(msg->key_id)) {
        return KEY_UPDATE_REPLAY_DETECTED;
    }

    /* Step 3: Decrypt new key material using KEK in HSM */
    uint8_t new_key[32];
    if (!hsm_aes_gcm_decrypt(KEK_SLOT, msg->iv, msg->encrypted_new_key,
                              sizeof(msg->encrypted_new_key),
                              NULL, 0, msg->auth_tag, new_key)) {
        return KEY_UPDATE_DECRYPT_FAILED;
    }

    /* Step 4: Store new key in HSM */
    if (!hsm_import_key(get_key_slot(msg->key_id), new_key,
                         sizeof(new_key))) {
        explicit_memzero(new_key, sizeof(new_key));
        return KEY_UPDATE_STORAGE_FAILED;
    }

    /* Step 5: Update version counter */
    update_key_version(msg->key_id, msg->key_version);

    explicit_memzero(new_key, sizeof(new_key));
    return KEY_UPDATE_SUCCESS;
}
```

---

## Key Storage Rules

### Storage Classification

| Key Type | Storage Location | Access Control |
|----------|-----------------|---------------|
| Root CA public key | OTP/eFuse (immutable) | Read-only |
| ECU private key | HSM key slot | HSM-internal only |
| ECU certificate | Secure NVM (signed) | Read by application |
| SecOC session keys | HSM key slots | HSM-internal only |
| Diagnostic auth key | HSM key slot | HSM-internal only |
| Firmware encryption DEK | HSM key slot | HSM-internal only |
| TLS session tickets | RAM (volatile) | Cleared on shutdown |

### Key Storage Implementation

```c
/* Key storage abstraction - keys never in application RAM */
typedef enum {
    KEY_STORE_HSM,           /* Hardware Security Module */
    KEY_STORE_SECURE_NVM,    /* Encrypted NVM partition */
    KEY_STORE_OTP,           /* One-Time Programmable memory */
    KEY_STORE_RAM_VOLATILE   /* Session keys only, cleared on reset */
} KeyStoreType_t;

typedef struct {
    uint8_t key_id[16];
    KeyStoreType_t store;
    uint32_t slot_index;
    KeyType_t type;
    KeyUsage_t allowed_usage;
    uint32_t version;
    uint32_t creation_timestamp;
    uint32_t expiry_timestamp;
    bool exportable;           /* Always false for private keys */
} KeyMetadata_t;

/* Key usage enforcement */
bool check_key_usage(const KeyMetadata_t* key, KeyUsage_t requested) {
    /* Verify allowed usage */
    if ((key->allowed_usage & requested) == 0U) {
        security_log(SEC_EVT_KEY_USAGE_VIOLATION,
                     key->key_id, requested);
        return false;
    }

    /* Verify not expired */
    if (get_current_time() > key->expiry_timestamp) {
        security_log(SEC_EVT_KEY_EXPIRED, key->key_id, 0U);
        return false;
    }

    return true;
}
```

---

## Key Rotation Policy

### Rotation Schedule

| Key Type | Rotation Period | Trigger |
|----------|----------------|---------|
| Root CA | 20 years (re-sign sub-CAs) | Planned ceremony |
| Sub-CA | 5-7 years | Planned ceremony |
| ECU identity cert | 10 years (vehicle lifetime) | OTA update |
| OTA signing key | 2 years | Key ceremony |
| SecOC master key | 1 year | Key update protocol |
| SecOC session key | Per-trip or daily | Key derivation |
| TLS session key | Per-connection | TLS handshake |
| V2X pseudonym cert | 1 week | Automated renewal |
| Diagnostic session key | Per-session | UDS Security Access |

### Rotation Process

```yaml
key_rotation_process:
  planned_rotation:
    1_generate: "Generate new key pair in HSM"
    2_certify: "Obtain certificate for new key"
    3_distribute: "Push new key/cert to all affected systems"
    4_overlap: "Allow grace period where both old and new are valid"
    5_switch: "Switch primary usage to new key"
    6_verify: "Verify all systems using new key"
    7_revoke: "Revoke old certificate"
    8_destroy: "Destroy old private key material after grace period"

  emergency_rotation:
    trigger: "Suspected compromise, vulnerability disclosure, incident"
    1_revoke: "Immediately revoke compromised key/certificate"
    2_generate: "Generate replacement key on HSM"
    3_distribute: "Emergency push to all affected systems"
    4_incident: "File security incident report"
    5_forensics: "Investigate scope of compromise"
```

---

## Key Revocation

### Certificate Revocation

```yaml
revocation_mechanisms:
  crl:
    description: "Certificate Revocation List"
    distribution: "OTA download to vehicle, periodic"
    update_frequency: "Daily for V2X, weekly for vehicle certs"
    max_age: "48 hours before considered stale"
    fallback: "If CRL unavailable, use last known good + reduced trust"

  ocsp:
    description: "Online Certificate Status Protocol"
    usage: "Backend-to-backend verification"
    stapling: "OCSP stapling for TLS connections"
    timeout: "5 seconds, then fall back to CRL"

  vehicle_revocation:
    storage: "Secure NVM partition for CRL cache"
    max_entries: 10000
    update_source: "OTA backend via authenticated channel"
```

### Revocation Handling in ECU

```c
/* Check certificate revocation before trusting any peer */
typedef enum {
    REVOCATION_NOT_REVOKED,
    REVOCATION_REVOKED,
    REVOCATION_STATUS_UNKNOWN,
    REVOCATION_CRL_EXPIRED
} RevocationStatus_t;

RevocationStatus_t check_revocation(const X509Cert_t* cert) {
    /* Check local CRL cache first */
    if (crl_cache_contains(cert->serial_number, cert->issuer_hash)) {
        return REVOCATION_REVOKED;
    }

    /* Check CRL freshness */
    if (get_current_time() > g_crl_cache.next_update) {
        /* CRL is stale - request update */
        request_crl_update();

        /* Policy decision: what to do with stale CRL */
        if (get_current_time() > g_crl_cache.next_update + CRL_GRACE_PERIOD) {
            return REVOCATION_CRL_EXPIRED;
        }
    }

    return REVOCATION_NOT_REVOKED;
}
```

---

## Key Ceremony Procedures

### Root CA Key Ceremony

```yaml
root_ca_ceremony:
  participants:
    ceremony_lead: 1
    key_custodians: 3  # M-of-N quorum (3 of 5)
    witness: 1
    auditor: 1

  environment:
    location: "Secure room with access control and video recording"
    network: "Air-gapped (no network connectivity)"
    hsm: "FIPS 140-2 Level 3 certified, tamper-evident"

  procedure:
    1_verify_hsm: "Verify HSM serial number and tamper evidence"
    2_authenticate: "Each custodian presents smart card + PIN"
    3_generate: "Generate RSA-4096 or ECDSA P-384 key pair"
    4_backup: "Create encrypted backup to M-of-N smart card shares"
    5_self_sign: "Generate self-signed root certificate"
    6_verify: "Verify root certificate independently"
    7_export_public: "Export public key and certificate"
    8_seal: "Seal HSM, store smart cards in separate secure locations"
    9_document: "Document ceremony with witness signatures"

  audit_artifacts:
    - "Signed ceremony log"
    - "Video recording of ceremony"
    - "Public key hash for verification"
    - "HSM audit log export"
    - "Smart card custody records"
```

---

## Prohibited Practices

| Practice | Risk | Requirement |
|----------|------|-------------|
| Keys in source code | Trivially extractable | HSM storage |
| Shared keys across ECU types | Compromise propagation | Per-ECU unique keys |
| No key rotation | Long-term exposure | Rotation per schedule |
| Single custodian for root key | Single point of compromise | M-of-N quorum |
| Keys on networked systems | Remote theft | Air-gapped for root/signing |
| No revocation mechanism | Cannot respond to compromise | CRL + OCSP |
| Reusing keys across purposes | Cross-purpose attacks | Separate keys per purpose |
| Exporting private keys | Key material exposure | Non-exportable flag |
| No ceremony documentation | Audit failure | Documented ceremonies |
| Dev keys in production | Known to developers | Separate hierarchies |

---

## Review Checklist

- [ ] PKI hierarchy designed with appropriate CA levels
- [ ] Root CA key generated in air-gapped HSM ceremony
- [ ] M-of-N quorum for root key access
- [ ] Per-ECU unique key generation during manufacturing
- [ ] Private keys never leave HSM boundary
- [ ] Key rotation schedule defined and automated where possible
- [ ] CRL distribution to vehicles via authenticated channel
- [ ] Key usage enforcement (signing key cannot decrypt)
- [ ] Separate key hierarchies for dev/test/production
- [ ] Key ceremony procedures documented and auditable
- [ ] In-field key update protocol secured with authentication
- [ ] Key destruction procedures defined for end-of-life
