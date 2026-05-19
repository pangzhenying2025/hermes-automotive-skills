# OTA Update Security Requirements

> Security rules for Over-The-Air software update systems in automotive,
> covering the complete update lifecycle from build signing through
> delivery, installation, and rollback per UNECE R156 and ISO/SAE 21434.

## Scope

These rules apply to all OTA update infrastructure including backend
signing servers, delivery CDNs, vehicle download managers, ECU bootloaders,
and update orchestration software.

---

## OTA Security Architecture

```
+-------------------+     +-------------------+     +-------------------+
|   Build System    |     |   OTA Backend     |     |   Vehicle         |
|                   |     |                   |     |                   |
| Compile + Link    |     | Package Store     |     | Download Manager  |
| Sign (HSM)        |---->| Distribution CDN  |---->| Signature Verify  |
| Package           |     | Campaign Manager  |     | ECU Flash Manager |
| Version Catalog   |     | Device Registry   |     | Rollback Manager  |
+-------------------+     +-------------------+     +-------------------+
        |                         |                         |
   Offline HSM              TLS 1.2/1.3             Secure Boot
   Code Signing             Mutual Auth             HSM Verify
   Air-gapped               Certificate Pin         Version Check
```

---

## Package Signing Rules

### Build-Time Signing

```yaml
signing_policy:
  signing_environment: "Air-gapped HSM workstation"
  hsm_type: "Thales Luna Network HSM 7"
  key_algorithm: "ECDSA P-384"
  hash_algorithm: "SHA-384"
  dual_sign: true  # Two authorized signers required

  signing_workflow:
    1_build: "CI/CD builds firmware binary"
    2_hash: "Compute SHA-384 of binary on build server"
    3_transfer: "Transfer hash to air-gapped HSM workstation"
    4_sign: "Two authorized signers authenticate to HSM"
    5_signature: "HSM produces ECDSA P-384 signature"
    6_package: "Combine binary + signature + metadata"
    7_verify: "Independent verification on separate workstation"
    8_publish: "Upload verified package to OTA backend"
```

### Package Format

```c
/* OTA update package structure */
typedef struct {
    /* Header (unencrypted, signed) */
    uint32_t magic;                  /* 0x4F544155 "OTAU" */
    uint32_t format_version;         /* Package format version */
    uint32_t header_size;            /* Size of this header */
    uint32_t payload_size;           /* Size of encrypted payload */

    /* Target identification */
    uint8_t target_ecu_id[16];       /* ECU hardware identifier */
    uint32_t target_hw_version;      /* Compatible HW revision */
    uint32_t current_sw_version_min; /* Minimum current version required */
    uint32_t new_sw_version;         /* Version being installed */

    /* Security */
    uint8_t payload_hash[48];        /* SHA-384 of decrypted payload */
    uint8_t encrypted_payload_hash[48]; /* SHA-384 of encrypted payload */
    uint8_t header_signature[96];    /* ECDSA P-384 over header fields */
    uint8_t payload_signature[96];   /* ECDSA P-384 over decrypted payload */

    /* Encryption */
    uint8_t encryption_algorithm;    /* 0=none, 1=AES-256-GCM */
    uint8_t encrypted_dek[256];      /* DEK encrypted with ECU public key */
    uint8_t iv[12];                  /* AES-GCM initialization vector */
    uint8_t auth_tag[16];            /* AES-GCM authentication tag */

    /* Anti-rollback */
    uint32_t monotonic_counter;      /* Must be > current counter in ECU */
    uint32_t timestamp;              /* Package creation timestamp */

    /* Metadata */
    uint8_t release_notes_hash[48];  /* Hash of release notes document */
    uint32_t install_priority;       /* 0=optional, 1=recommended, 2=critical */
    uint32_t install_deadline;       /* Timestamp by which to install */

} OtaPackageHeader_t;
```

### Signature Verification on Vehicle

```c
/* Multi-stage verification before any flash operation */
typedef enum {
    VERIFY_OK,
    VERIFY_HEADER_MAGIC_INVALID,
    VERIFY_HEADER_SIGNATURE_INVALID,
    VERIFY_VERSION_MISMATCH,
    VERIFY_HARDWARE_MISMATCH,
    VERIFY_ROLLBACK_DETECTED,
    VERIFY_PAYLOAD_HASH_MISMATCH,
    VERIFY_PAYLOAD_SIGNATURE_INVALID,
    VERIFY_DECRYPTION_FAILED,
    VERIFY_COUNTER_INVALID
} OtaVerifyResult_t;

OtaVerifyResult_t verify_ota_package(
    const OtaPackageHeader_t* header,
    const uint8_t* payload,
    size_t payload_size) {

    /* Stage 1: Verify header magic */
    if (header->magic != OTA_MAGIC) {
        return VERIFY_HEADER_MAGIC_INVALID;
    }

    /* Stage 2: Verify header signature (HSM) */
    if (!hsm_ecdsa_verify(OTA_SIGNING_KEY_SLOT,
                           (const uint8_t*)header,
                           offsetof(OtaPackageHeader_t, header_signature),
                           header->header_signature)) {
        return VERIFY_HEADER_SIGNATURE_INVALID;
    }

    /* Stage 3: Check hardware compatibility */
    if (!check_hardware_compatibility(header->target_ecu_id,
                                       header->target_hw_version)) {
        return VERIFY_HARDWARE_MISMATCH;
    }

    /* Stage 4: Anti-rollback check */
    if (header->new_sw_version <= get_current_sw_version()) {
        return VERIFY_ROLLBACK_DETECTED;
    }
    if (header->monotonic_counter <= get_secure_counter()) {
        return VERIFY_COUNTER_INVALID;
    }

    /* Stage 5: Verify encrypted payload hash */
    uint8_t computed_hash[48];
    sha384_compute(payload, payload_size, computed_hash);
    if (!constant_time_compare(computed_hash,
                                header->encrypted_payload_hash, 48U)) {
        return VERIFY_PAYLOAD_HASH_MISMATCH;
    }

    /* Stage 6: Decrypt payload (if encrypted) */
    if (header->encryption_algorithm == OTA_ENC_AES256_GCM) {
        if (!decrypt_ota_payload(header, payload, payload_size)) {
            return VERIFY_DECRYPTION_FAILED;
        }
    }

    /* Stage 7: Verify decrypted payload signature */
    if (!hsm_ecdsa_verify(OTA_SIGNING_KEY_SLOT,
                           decrypted_payload, decrypted_size,
                           header->payload_signature)) {
        return VERIFY_PAYLOAD_SIGNATURE_INVALID;
    }

    return VERIFY_OK;
}
```

---

## Transport Security

### Vehicle-to-Backend Communication

```yaml
transport_security:
  protocol: "TLS 1.3"
  mutual_authentication: true

  vehicle_certificate:
    type: "X.509 v3"
    key: "ECDSA P-256"
    issuer: "OEM Vehicle CA"
    subject: "VIN-based identity"
    validity: "10 years"
    storage: "HSM"

  server_certificate:
    type: "X.509 v3"
    key: "ECDSA P-384"
    issuer: "OEM Backend CA"
    pinning: true  # Certificate pinning required
    pin_backup_count: 2  # Backup pins for rotation

  download_verification:
    - "TLS channel integrity (in-transit)"
    - "SHA-384 hash verification (at-rest after download)"
    - "ECDSA signature verification (authenticity)"
    - "Monotonic counter check (anti-replay)"
```

### Download Integrity

```c
/* Streaming download with progressive verification */
typedef struct {
    Sha384Context_t hash_ctx;
    size_t bytes_received;
    size_t total_expected;
    uint32_t block_count;
    bool hash_initialized;
} DownloadState_t;

bool download_process_block(DownloadState_t* state,
                             const uint8_t* block, size_t block_size) {
    /* Initialize hash on first block */
    if (!state->hash_initialized) {
        sha384_init(&state->hash_ctx);
        state->hash_initialized = true;
    }

    /* Update running hash */
    sha384_update(&state->hash_ctx, block, block_size);
    state->bytes_received += block_size;
    state->block_count++;

    /* Write to staging partition */
    if (!nvm_write_staging(state->bytes_received - block_size,
                            block, block_size)) {
        return false;
    }

    return true;
}

bool download_finalize(DownloadState_t* state,
                        const uint8_t* expected_hash) {
    /* Complete hash computation */
    uint8_t final_hash[48];
    sha384_final(&state->hash_ctx, final_hash);

    /* Verify against expected hash from signed header */
    if (!constant_time_compare(final_hash, expected_hash, 48U)) {
        /* Hash mismatch - delete staging partition */
        nvm_erase_staging();
        return false;
    }

    return true;
}
```

---

## Anti-Rollback Protection

### Secure Version Counter

```c
/* Monotonic counter in one-time-programmable (OTP) memory or HSM */

/* Read current secure counter from HSM */
uint32_t get_secure_counter(void) {
    return hsm_read_monotonic_counter(COUNTER_SLOT_OTA);
}

/* Increment counter ONLY after successful installation and verification */
bool increment_secure_counter(uint32_t new_value) {
    const uint32_t current = get_secure_counter();

    /* Must be strictly incrementing */
    if (new_value <= current) {
        return false;
    }

    /* Must not skip more than allowed gap */
    if ((new_value - current) > MAX_COUNTER_INCREMENT) {
        return false;
    }

    return hsm_increment_monotonic_counter(COUNTER_SLOT_OTA, new_value);
}

/* Post-installation commit:
 * 1. Verify new firmware boots and passes self-test
 * 2. THEN increment counter (prevents rollback to old version)
 * 3. If verification fails, rollback to previous version
 */
```

### Version Policy

```yaml
version_policy:
  format: "MAJOR.MINOR.PATCH (semantic versioning)"
  rollback_allowed: false  # Never allow downgrade in production
  version_checks:
    - "new_version > current_version"
    - "new_version.major <= current_version.major + 1"
    - "target_hw_version matches ECU hardware"
    - "minimum_sw_version <= current_version"
    - "monotonic_counter > stored_counter"
  emergency_override:
    enabled: true
    requires: "Factory diagnostic authentication (Security Access Level 3)"
    logging: "All overrides logged to tamper-evident security log"
```

---

## Installation Safety

### A/B Partition Scheme

```
+----------------------------------+
|  Partition A (Active)            |
|  Running firmware v2.3.0         |
|  Verified, counter = 42          |
+----------------------------------+
|  Partition B (Staging)           |
|  Downloaded firmware v2.4.0      |
|  Verified, ready to activate     |
+----------------------------------+
|  Bootloader (Protected)          |
|  Selects active partition        |
|  Verifies signature at boot      |
+----------------------------------+
|  Persistent Data                 |
|  Config, calibration, NVM        |
|  Preserved across updates        |
+----------------------------------+
```

### Installation State Machine

```c
typedef enum {
    OTA_STATE_IDLE,
    OTA_STATE_DOWNLOADING,
    OTA_STATE_DOWNLOAD_COMPLETE,
    OTA_STATE_VERIFYING,
    OTA_STATE_VERIFIED,
    OTA_STATE_INSTALLING,
    OTA_STATE_INSTALLED,
    OTA_STATE_ACTIVATING,
    OTA_STATE_ACTIVATED,
    OTA_STATE_COMMITTING,
    OTA_STATE_COMMITTED,
    OTA_STATE_ROLLING_BACK,
    OTA_STATE_FAILED
} OtaState_t;

/* Rule: Each state transition must be verified and logged */
/* Rule: Power loss at any state must be recoverable */
/* Rule: Failed installation triggers automatic rollback */
```

---

## Campaign Security

### Backend Authorization

```yaml
campaign_authorization:
  approval_required: true
  minimum_approvers: 2
  approval_roles: ["OTA_Manager", "Security_Engineer"]
  scope_limits:
    max_vehicles_per_campaign: 10000
    geographic_restriction: true
    time_window_required: true
  audit_logging:
    all_campaign_actions: true
    retention_days: 365
```

---

## Prohibited Practices

| Practice | Risk | Requirement |
|----------|------|-------------|
| Unsigned firmware packages | Tampered firmware | ECDSA-P384 signature |
| Unencrypted firmware in transit | IP theft, analysis | TLS + AES-256-GCM |
| No anti-rollback protection | Downgrade attacks | Monotonic counter |
| Signing keys on build server | Key compromise | Air-gapped HSM |
| Single-signer authority | Insider threat | Dual-signature requirement |
| No rollback capability | Bricked vehicles | A/B partition scheme |
| Hardcoded signing keys | Permanent compromise | HSM with rotation |
| No campaign authorization | Unauthorized updates | Multi-approver workflow |
| Skipping verification steps | Installing bad firmware | Multi-stage verification |
| No post-install validation | Silent failures | Boot-time self-test |

---

## Review Checklist

- [ ] Firmware packages signed with ECDSA P-384 via HSM
- [ ] Dual-signer authorization for all production packages
- [ ] TLS 1.3 with mutual authentication for all transfers
- [ ] Certificate pinning on vehicle-to-backend connections
- [ ] Multi-stage verification before any flash operation
- [ ] Anti-rollback via HSM monotonic counter
- [ ] A/B partition scheme with automatic rollback
- [ ] Power-loss resilient installation state machine
- [ ] Campaign authorization requires multiple approvers
- [ ] All OTA operations logged to tamper-evident storage
- [ ] Emergency rollback procedure documented and tested
- [ ] Penetration testing of complete OTA pipeline
