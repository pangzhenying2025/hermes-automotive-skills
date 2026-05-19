# Cryptography Implementation Rules for Automotive ECUs

> Rules for implementing cryptographic operations in automotive embedded
> systems, covering algorithm selection, key protection, side-channel
> resistance, and HSM (Hardware Security Module) integration.

## Scope

These rules apply to all cryptographic operations in automotive software,
including secure boot, secure communication, OTA update verification,
diagnostic authentication, V2X message signing, and data-at-rest protection.

---

## Fundamental Principles

### 1. Never Implement Your Own Cryptography

Use vetted, certified cryptographic libraries only:

| Library | Certification | Use Case |
|---------|-------------|----------|
| wolfSSL | FIPS 140-2/3, DO-178C | TLS, PKI operations |
| Mbed TLS | PSA Certified | Constrained embedded |
| AUTOSAR Crypto Stack | AUTOSAR Certified | AUTOSAR Classic/Adaptive |
| HSM Vendor Library | Common Criteria | Hardware-accelerated ops |
| OpenSSL | FIPS validated builds | Linux-based ECUs |

**Rule**: No custom implementation of AES, SHA, RSA, ECC, or any
cryptographic primitive. No "optimized" versions. No "simplified" variants.

### 2. Use Current Algorithms Only

| Purpose | Approved Algorithm | Key/Hash Size | Prohibited |
|---------|-------------------|---------------|-----------|
| Symmetric encryption | AES-128/256-GCM | 128/256 bit | DES, 3DES, RC4, Blowfish |
| Hash | SHA-256, SHA-384 | 256/384 bit | MD5, SHA-1 |
| MAC | HMAC-SHA-256, AES-CMAC | 256/128 bit | HMAC-MD5, HMAC-SHA-1 |
| Asymmetric signing | ECDSA P-256/P-384 | 256/384 bit | RSA-1024, DSA |
| Key exchange | ECDH P-256/P-384 | 256/384 bit | DH-1024, plain RSA |
| Key derivation | HKDF-SHA-256 | 256 bit | Custom KDF |
| Random generation | CTR_DRBG, HMAC_DRBG | N/A | rand(), linear congruential |
| Password hashing | Argon2id, PBKDF2 | N/A | Plain SHA, bcrypt |

---

## HSM Integration

### HSM Architecture

```
+----------------------------------+
|        Application SW            |
+----------------------------------+
|     Crypto Service Manager       |
|     (AUTOSAR CryptoStack or      |
|      custom abstraction)         |
+----------------------------------+
|     Crypto Driver                |
+--------+----------+--------------+
| SW     | HSM      | SHE/SHE+    |
| Crypto | Driver   | Driver      |
+--------+----------+--------------+
|        |  HSM HW  |  SHE HW    |
|        | (e.g.    | (e.g.      |
|        | Evita    | Infineon   |
|        | Medium)  | TC3xx)     |
+--------+----------+--------------+
```

### HSM Usage Rules

```c
/* Rule: All key operations MUST use HSM when available */

/* GOOD: Key never leaves HSM */
typedef struct {
    uint32_t hsm_key_slot;  /* Reference to key in HSM */
    uint8_t key_id[16];     /* Logical key identifier */
    KeyType_t type;         /* AES, ECC, HMAC, etc. */
    KeyUsage_t usage;       /* Sign, verify, encrypt, decrypt */
} HsmKeyHandle_t;

bool sign_message_via_hsm(const HsmKeyHandle_t* key,
                           const uint8_t* data, size_t data_len,
                           uint8_t* signature, size_t* sig_len) {
    /* Key material NEVER exposed to application software */
    return hsm_ecdsa_sign(key->hsm_key_slot, data, data_len,
                           signature, sig_len);
}

/* BAD: Key material in application RAM */
bool sign_message_insecure(const uint8_t* private_key,
                            const uint8_t* data, size_t data_len,
                            uint8_t* signature) {
    /* PROHIBITED: Private key in application memory is extractable */
    return sw_ecdsa_sign(private_key, data, data_len, signature);
}
```

### Key Slot Allocation

```yaml
hsm_key_slots:
  - slot: 0
    key_type: AES-128
    usage: "Secure boot MAC verification"
    provisioned: factory
    updateable: false
    asil: D

  - slot: 1
    key_type: ECDSA-P256
    usage: "OTA update signature verification"
    provisioned: factory
    updateable: true  # Root key update via secure protocol
    asil: B

  - slot: 2
    key_type: AES-256
    usage: "Diagnostic session encryption"
    provisioned: first_boot
    updateable: true
    asil: B

  - slot: 3
    key_type: HMAC-SHA256
    usage: "CAN message authentication (SecOC)"
    provisioned: key_exchange
    updateable: true  # Session key rotated
    asil: C

  - slot: 4-7
    key_type: AES-128
    usage: "SHE key slots for SecOC"
    provisioned: secure_key_update
    updateable: true
    asil: C
```

---

## Side-Channel Resistance

### Timing Attack Prevention

```c
/* CRITICAL: All secret-dependent comparisons must be constant-time */

/* Constant-time memory comparison */
bool constant_time_compare(const uint8_t* a, const uint8_t* b,
                            size_t length) {
    volatile uint8_t result = 0U;
    for (size_t i = 0U; i < length; i++) {
        result |= a[i] ^ b[i];
    }
    return (result == 0U);
}

/* Constant-time conditional select */
uint32_t constant_time_select(uint32_t condition,
                               uint32_t value_if_true,
                               uint32_t value_if_false) {
    /* condition must be 0 or 1 */
    const uint32_t mask = (uint32_t)(-(int32_t)condition);
    return (value_if_true & mask) | (value_if_false & ~mask);
}
```

### Power Analysis Prevention

```c
/* For software crypto (when HSM not available): */

/* Rule: Add dummy operations to mask power consumption patterns */
/* Rule: Use constant-time algorithm variants */
/* Rule: Enable hardware countermeasures where available */

/* Montgomery ladder for scalar multiplication (constant-time ECC) */
/* Note: Prefer HSM for all ECC operations */
```

### Cache Timing Prevention

```c
/* For software AES (when HSM not available): */

/* Rule: Use bit-sliced or constant-time AES implementation */
/* Rule: Do not use T-table AES on platforms with shared cache */
/* Rule: Flush cache before and after crypto operations */

void aes_encrypt_cache_safe(const uint8_t* key, const uint8_t* plaintext,
                             uint8_t* ciphertext) {
    /* Flush data cache before crypto operation */
    cache_flush_range((uint32_t)aes_tables, sizeof(aes_tables));

    /* Perform encryption */
    aes_encrypt_constant_time(key, plaintext, ciphertext);

    /* Flush data cache after crypto operation */
    cache_flush_range((uint32_t)aes_tables, sizeof(aes_tables));
}
```

---

## Random Number Generation

### Hardware RNG Rules

```c
/* Always use hardware TRNG with health checks */
typedef struct {
    bool health_check_passed;
    uint32_t consecutive_failures;
    uint32_t total_generated_bytes;
} TrngState_t;

bool hw_rng_generate(uint8_t* buffer, size_t length) {
    /* Step 1: Verify TRNG health */
    if (!trng_health_check()) {
        s_trng_state.consecutive_failures++;
        if (s_trng_state.consecutive_failures > MAX_TRNG_FAILURES) {
            report_security_event(SEC_EVT_TRNG_FAILURE);
        }
        return false;
    }
    s_trng_state.consecutive_failures = 0U;

    /* Step 2: Read from hardware TRNG */
    for (size_t i = 0U; i < length; i += 4U) {
        uint32_t random_word;
        if (!trng_read_word(&random_word)) {
            return false;
        }
        const size_t copy_len = (length - i < 4U) ? (length - i) : 4U;
        memcpy(&buffer[i], &random_word, copy_len);
    }

    /* Step 3: Condition through DRBG for uniform distribution */
    return drbg_reseed_and_generate(buffer, length);
}

/* PROHIBITED: Using predictable sources */
/* rand(), srand(time(NULL)), /dev/urandom without checking */
```

---

## Certificate and Key Lifecycle

### Key States

```
+----------+     +-----------+     +--------+     +---------+
| Generated| --> | Activated | --> | Active | --> | Expired |
+----------+     +-----------+     +--------+     +---------+
     |                                  |              |
     v                                  v              v
 +----------+                    +-----------+   +----------+
 | Destroyed|                    | Suspended |   | Archived |
 +----------+                    +-----------+   +----------+
                                       |
                                       v
                                 +-----------+
                                 | Revoked   |
                                 +-----------+
```

### Certificate Validation

```c
/* X.509 certificate chain validation */
typedef enum {
    CERT_VALID,
    CERT_EXPIRED,
    CERT_NOT_YET_VALID,
    CERT_SIGNATURE_INVALID,
    CERT_CHAIN_INCOMPLETE,
    CERT_REVOKED,
    CERT_UNKNOWN_ISSUER,
    CERT_SELF_SIGNED_NOT_TRUSTED
} CertValidation_t;

CertValidation_t validate_certificate_chain(
    const X509Cert_t* cert,
    const X509Cert_t* issuer_chain,
    size_t chain_length,
    const X509Cert_t* trusted_root) {

    /* Check expiry */
    if (get_current_time() > cert->not_after) {
        return CERT_EXPIRED;
    }
    if (get_current_time() < cert->not_before) {
        return CERT_NOT_YET_VALID;
    }

    /* Walk chain from leaf to root */
    const X509Cert_t* current = cert;
    for (size_t i = 0U; i < chain_length; i++) {
        if (!verify_signature(current, &issuer_chain[i])) {
            return CERT_SIGNATURE_INVALID;
        }
        current = &issuer_chain[i];
    }

    /* Verify chain terminates at trusted root */
    if (!verify_signature(current, trusted_root)) {
        return CERT_UNKNOWN_ISSUER;
    }

    /* Check revocation (CRL or OCSP) */
    if (is_certificate_revoked(cert)) {
        return CERT_REVOKED;
    }

    return CERT_VALID;
}
```

---

## Crypto Configuration Hardening

```yaml
tls_configuration:
  minimum_version: "TLS 1.2"  # TLS 1.3 preferred
  prohibited_versions: ["SSL 3.0", "TLS 1.0", "TLS 1.1"]

  allowed_cipher_suites:
    tls_1_3:
      - TLS_AES_256_GCM_SHA384
      - TLS_AES_128_GCM_SHA256
      - TLS_CHACHA20_POLY1305_SHA256
    tls_1_2:
      - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
      - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
      - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384

  prohibited_cipher_suites:
    - "*_CBC_*"        # CBC mode vulnerable to padding oracle
    - "*_RC4_*"        # RC4 broken
    - "*_DES_*"        # DES/3DES insufficient
    - "*_NULL_*"       # No encryption
    - "*_EXPORT_*"     # Export-grade (weak)
    - "*_anon_*"       # No authentication

  certificate_requirements:
    minimum_key_size_rsa: 2048
    minimum_key_size_ecc: 256
    signature_algorithm: ["ECDSA-SHA256", "ECDSA-SHA384", "RSA-SHA256"]
    certificate_pinning: required
    ocsp_stapling: recommended
```

---

## Prohibited Practices

| Practice | Risk | Requirement |
|----------|------|-------------|
| Custom crypto primitives | Unvetted, likely vulnerable | Use certified libraries |
| Keys in source code | Trivially extracted | HSM or secure provisioning |
| Keys in plaintext NVM | Extractable via debug | Encrypt or use HSM |
| ECB mode encryption | Pattern leakage | Use GCM or CTR mode |
| MD5 or SHA-1 for security | Collision attacks | SHA-256 minimum |
| RSA-1024 | Factoring feasible | RSA-2048 or ECC-P256 |
| Deterministic ECDSA | Nonce reuse leaks key | RFC 6979 deterministic nonce |
| `memcmp` for MAC verify | Timing attack | `constant_time_compare` |
| Software RNG (rand) | Predictable | Hardware TRNG + DRBG |
| Shared symmetric keys | Compromise propagation | Per-ECU unique keys |
| No key rotation | Long-term exposure | Rotate per policy |

---

## Review Checklist

- [ ] Only approved cryptographic algorithms used
- [ ] Certified cryptographic library integrated
- [ ] HSM used for all key storage and operations
- [ ] All comparisons of secrets use constant-time functions
- [ ] Hardware TRNG with health checks for random generation
- [ ] TLS configuration uses approved cipher suites only
- [ ] Certificate chain validation implemented with revocation check
- [ ] Key lifecycle management with rotation policy
- [ ] No hardcoded keys or secrets in source code
- [ ] Side-channel countermeasures for software crypto
- [ ] Sensitive data zeroed after use
- [ ] Crypto configuration reviewed by security team
