# Automotive Secure Coding Practices

> Secure coding rules for automotive ECU software addressing
> ISO/SAE 21434 (Cybersecurity Engineering) requirements, UNECE R155
> compliance, and defense-in-depth strategies for connected vehicles.

## Scope

These rules apply to all software running in automotive ECUs that are
connected to external networks (CAN, Ethernet, V2X, cellular, Wi-Fi,
Bluetooth) or process external data (OTA updates, diagnostic sessions,
media files, navigation data).

---

## Threat Landscape

### Automotive Attack Surfaces

| Surface | Threat Examples | Risk Level |
|---------|----------------|------------|
| OBD-II port | Unauthorized diagnostic access, firmware extraction | High |
| CAN bus | Message injection, spoofing, DoS | Critical |
| Ethernet (DoIP) | Remote diagnostic exploitation | High |
| Cellular (TCU) | Remote code execution, eavesdropping | Critical |
| Wi-Fi | Man-in-middle, rogue AP | High |
| Bluetooth | Pairing exploitation, data exfiltration | Medium |
| USB / SD Card | Malicious media/firmware files | High |
| V2X (DSRC/C-V2X) | False safety messages, tracking | Critical |
| OTA updates | Firmware tampering, rollback attacks | Critical |
| GNSS | Spoofing, jamming | High |

---

## Input Validation Rules

### Rule 1: Validate All External Data at Trust Boundaries

```c
/* Every byte entering from outside the ECU is untrusted */

/* CAN message validation */
typedef enum {
    MSG_VALID,
    MSG_INVALID_DLC,
    MSG_INVALID_COUNTER,
    MSG_INVALID_CRC,
    MSG_INVALID_RANGE,
    MSG_TIMEOUT
} MsgValidation_t;

MsgValidation_t validate_can_message(
    const CanFrame_t* frame,
    const MsgSpec_t* spec,
    uint8_t* expected_counter) {

    /* Check DLC matches expected */
    if (frame->dlc != spec->expected_dlc) {
        return MSG_INVALID_DLC;
    }

    /* Check alive counter (rolling counter) */
    const uint8_t counter = extract_signal(frame, spec->counter_signal);
    const uint8_t expected = (*expected_counter + 1U) & spec->counter_mask;
    if (counter != expected) {
        /* Allow counter jump of 1 (missed message) but not more */
        if (((counter - *expected_counter) & spec->counter_mask) > 2U) {
            return MSG_INVALID_COUNTER;
        }
    }
    *expected_counter = counter;

    /* Check CRC */
    const uint8_t received_crc = extract_signal(frame, spec->crc_signal);
    const uint8_t computed_crc = compute_e2e_crc(frame, spec);
    if (received_crc != computed_crc) {
        return MSG_INVALID_CRC;
    }

    /* Check signal ranges */
    for (uint8_t i = 0U; i < spec->signal_count; i++) {
        const float value = extract_and_convert_signal(
            frame, &spec->signals[i]);
        if (value < spec->signals[i].min || value > spec->signals[i].max) {
            return MSG_INVALID_RANGE;
        }
    }

    return MSG_VALID;
}
```

### Rule 2: Buffer Overflow Prevention

```c
/* NEVER use unbounded copy/format functions */

/* BAD - buffer overflow risk */
void process_vin_bad(const char* input) {
    char vin[18];
    strcpy(vin, input);        /* No bounds check */
    sprintf(log_buf, "%s", input);  /* No bounds check */
}

/* GOOD - bounded operations */
bool process_vin_safe(const char* input, size_t input_len) {
    if (input == NULL) {
        return false;
    }
    if (input_len != VIN_LENGTH) {  /* VIN is exactly 17 chars */
        return false;
    }

    char vin[VIN_LENGTH + 1U];
    memcpy(vin, input, VIN_LENGTH);
    vin[VIN_LENGTH] = '\0';

    /* Validate VIN character set: A-HJ-NPR-Z0-9 */
    for (size_t i = 0U; i < VIN_LENGTH; i++) {
        if (!is_valid_vin_char(vin[i])) {
            return false;
        }
    }

    snprintf(log_buf, sizeof(log_buf), "VIN: %.17s", vin);
    return true;
}
```

### Rule 3: Integer Overflow Protection

```c
/* Check for overflow BEFORE performing the operation */

bool safe_multiply_u32(uint32_t a, uint32_t b, uint32_t* result) {
    if (b != 0U && a > (UINT32_MAX / b)) {
        return false;  /* Would overflow */
    }
    *result = a * b;
    return true;
}

bool safe_add_u32(uint32_t a, uint32_t b, uint32_t* result) {
    if (a > (UINT32_MAX - b)) {
        return false;  /* Would overflow */
    }
    *result = a + b;
    return true;
}

/* Use in safety-critical calculations */
uint32_t compute_energy_wh(uint32_t voltage_mv, uint32_t current_ma,
                            uint32_t time_s) {
    uint32_t power_uw;
    if (!safe_multiply_u32(voltage_mv, current_ma, &power_uw)) {
        report_overflow_error(__func__);
        return 0U;
    }
    /* Convert uW*s to Wh: divide by 3,600,000,000 */
    uint32_t energy_uws;
    if (!safe_multiply_u32(power_uw, time_s, &energy_uws)) {
        report_overflow_error(__func__);
        return 0U;
    }
    return energy_uws / 3600000000ULL;
}
```

---

## Memory Safety Rules

### Rule 4: No Dangling Pointers

```c
/* Set pointer to NULL after free (pool_free in embedded) */
void cleanup_session(Session_t** session) {
    if (session == NULL || *session == NULL) {
        return;
    }
    /* Scrub sensitive data before freeing */
    explicit_memzero((*session)->auth_token, sizeof((*session)->auth_token));
    explicit_memzero((*session)->session_key, sizeof((*session)->session_key));
    pool_free(&g_session_pool, *session);
    *session = NULL;  /* Prevent use-after-free */
}
```

### Rule 5: Sensitive Data Handling

```c
/* Sensitive data must be zeroed when no longer needed */

/* Use volatile to prevent compiler from optimizing away the zeroing */
void explicit_memzero(void* ptr, size_t len) {
    volatile uint8_t* vptr = (volatile uint8_t*)ptr;
    for (size_t i = 0U; i < len; i++) {
        vptr[i] = 0U;
    }
}

/* Sensitive data in stack variables */
bool verify_authentication(const uint8_t* challenge, size_t challenge_len) {
    uint8_t computed_response[HMAC_SHA256_SIZE];
    bool result;

    compute_hmac(challenge, challenge_len,
                 get_stored_key(), KEY_SIZE,
                 computed_response);

    result = constant_time_compare(computed_response,
                                    received_response,
                                    HMAC_SHA256_SIZE);

    /* CRITICAL: Zero the computed HMAC before returning */
    explicit_memzero(computed_response, sizeof(computed_response));
    return result;
}
```

---

## Authentication and Access Control

### Rule 6: Diagnostic Authentication (UDS Security Access)

```c
/* UDS 0x27 Security Access - implement with proper seed-key */

typedef enum {
    DIAG_ACCESS_LOCKED,
    DIAG_ACCESS_SEED_SENT,
    DIAG_ACCESS_UNLOCKED
} DiagAccessState_t;

typedef struct {
    DiagAccessState_t state;
    uint8_t seed[SEED_SIZE];
    uint8_t failed_attempts;
    uint32_t lockout_end_time_ms;
} DiagSecurity_t;

static DiagSecurity_t s_diag_security;

/* Generate cryptographically secure seed */
DiagResponse_t handle_security_access_seed(uint8_t* response_data) {
    /* Check lockout */
    if (s_diag_security.failed_attempts >= MAX_FAILED_ATTEMPTS) {
        if (get_time_ms() < s_diag_security.lockout_end_time_ms) {
            return DIAG_NRC_EXCEEDED_ATTEMPTS;
        }
        s_diag_security.failed_attempts = 0U;
    }

    /* Generate random seed using hardware RNG */
    if (!hw_rng_generate(s_diag_security.seed, SEED_SIZE)) {
        return DIAG_NRC_CONDITIONS_NOT_CORRECT;
    }

    memcpy(response_data, s_diag_security.seed, SEED_SIZE);
    s_diag_security.state = DIAG_ACCESS_SEED_SENT;
    return DIAG_POSITIVE_RESPONSE;
}

/* Verify key with constant-time comparison */
DiagResponse_t handle_security_access_key(
    const uint8_t* received_key, size_t key_len) {

    if (s_diag_security.state != DIAG_ACCESS_SEED_SENT) {
        return DIAG_NRC_REQUEST_SEQUENCE_ERROR;
    }

    uint8_t expected_key[KEY_SIZE];
    compute_expected_key(s_diag_security.seed, expected_key);

    /* CRITICAL: Constant-time comparison to prevent timing attacks */
    if (!constant_time_compare(received_key, expected_key, KEY_SIZE)) {
        explicit_memzero(expected_key, sizeof(expected_key));
        s_diag_security.failed_attempts++;
        if (s_diag_security.failed_attempts >= MAX_FAILED_ATTEMPTS) {
            s_diag_security.lockout_end_time_ms =
                get_time_ms() + LOCKOUT_DURATION_MS;
        }
        s_diag_security.state = DIAG_ACCESS_LOCKED;
        return DIAG_NRC_INVALID_KEY;
    }

    explicit_memzero(expected_key, sizeof(expected_key));
    s_diag_security.state = DIAG_ACCESS_UNLOCKED;
    return DIAG_POSITIVE_RESPONSE;
}
```

### Rule 7: Principle of Least Privilege

```c
/* Each software component gets minimum required access */

typedef struct {
    uint32_t component_id;
    uint32_t can_read_mask;     /* Bitmask of readable CAN message groups */
    uint32_t can_write_mask;    /* Bitmask of writable CAN message groups */
    uint32_t memory_read_mask;  /* Bitmask of readable memory regions */
    uint32_t memory_write_mask; /* Bitmask of writable memory regions */
    uint32_t diag_service_mask; /* Bitmask of allowed UDS services */
} ComponentPermissions_t;

/* Permission table - defined at compile time */
static const ComponentPermissions_t s_permissions[] = {
    { .component_id = COMP_BMS_MONITOR,
      .can_read_mask = CAN_GRP_BMS | CAN_GRP_CHARGER,
      .can_write_mask = CAN_GRP_BMS_STATUS,
      .memory_read_mask = MEM_RGN_SENSORS | MEM_RGN_CALIBRATION,
      .memory_write_mask = MEM_RGN_BMS_DATA,
      .diag_service_mask = DIAG_SVC_READ_DATA },

    { .component_id = COMP_CHARGER_CTRL,
      .can_read_mask = CAN_GRP_BMS_STATUS | CAN_GRP_CHARGER,
      .can_write_mask = CAN_GRP_CHARGER,
      .memory_read_mask = MEM_RGN_CHARGER_CFG,
      .memory_write_mask = MEM_RGN_CHARGER_DATA,
      .diag_service_mask = DIAG_SVC_READ_DATA | DIAG_SVC_IO_CONTROL },
};
```

---

## Secure Boot and Runtime Integrity

### Rule 8: Code Authentication

```c
/* Verify firmware signature before execution */
typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t code_size;
    uint8_t signature[ECDSA_P256_SIG_SIZE];  /* 64 bytes */
    uint8_t public_key_hash[SHA256_SIZE];     /* 32 bytes */
} FirmwareHeader_t;

bool verify_firmware_integrity(const FirmwareHeader_t* header,
                                const uint8_t* code_base) {
    /* Step 1: Verify header magic */
    if (header->magic != FIRMWARE_MAGIC) {
        return false;
    }

    /* Step 2: Verify public key hash matches stored root of trust */
    uint8_t key_hash[SHA256_SIZE];
    sha256_compute(get_signing_public_key(), PUBLIC_KEY_SIZE, key_hash);
    if (!constant_time_compare(key_hash, header->public_key_hash,
                                SHA256_SIZE)) {
        return false;
    }

    /* Step 3: Verify ECDSA signature over code */
    uint8_t code_hash[SHA256_SIZE];
    sha256_compute(code_base, header->code_size, code_hash);
    return ecdsa_p256_verify(get_signing_public_key(),
                              code_hash, header->signature);
}
```

### Rule 9: Runtime Integrity Monitoring

```c
/* Periodic flash integrity check in background task */
void task_integrity_monitor(void) {
    static uint32_t check_offset = 0U;
    const uint32_t block_size = FLASH_CHECK_BLOCK_SIZE;

    /* Check one block per cycle (spread over time) */
    const uint32_t block_crc = crc32_compute(
        (const uint8_t*)(FLASH_BASE + check_offset), block_size);

    if (block_crc != g_flash_crc_table[check_offset / block_size]) {
        report_integrity_violation(check_offset);
        enter_safe_state(SAFE_STATE_INTEGRITY_FAILURE);
    }

    check_offset += block_size;
    if (check_offset >= APPLICATION_SIZE) {
        check_offset = 0U;  /* Wrap around */
    }
}
```

---

## Secure Communication

### Rule 10: End-to-End Protection (AUTOSAR E2E)

```c
/* E2E protection profile for safety-critical CAN messages */
typedef struct {
    uint8_t counter;       /* 4-bit rolling counter */
    uint8_t data_id;       /* Message identifier for CRC scope */
    uint8_t crc;           /* CRC-8 SAE J1850 */
} E2E_Profile01_t;

uint8_t e2e_compute_crc(const uint8_t* data, uint8_t length,
                         uint8_t data_id, uint8_t counter) {
    uint8_t crc = CRC_INITIAL_VALUE;
    crc = crc8_update(crc, data_id);
    for (uint8_t i = 0U; i < length; i++) {
        crc = crc8_update(crc, data[i]);
    }
    crc = crc8_update(crc, counter);
    return crc ^ CRC_XOR_VALUE;
}
```

---

## Prohibited Practices

| Practice | Risk | Alternative |
|----------|------|-------------|
| `strcpy`, `strcat`, `sprintf` | Buffer overflow | `strncpy`, `strncat`, `snprintf` |
| `memcmp` for secrets | Timing attack | `constant_time_compare` |
| Hardcoded keys/passwords | Key extraction | Secure storage / HSM |
| `rand()` / `srand()` | Predictable output | Hardware RNG |
| Debug ports enabled in production | Unauthorized access | Disable JTAG/SWD |
| Plaintext sensitive data in NVM | Data extraction | Encrypt with AES-256 |
| Shared secrets across ECU families | One compromise = all | Unique per-ECU keys |
| Firmware without signature | Tampering | ECDSA/RSA signature |
| Open diagnostic access | Unauthorized control | Authentication required |

---

## Review Checklist

- [ ] All external inputs validated at trust boundaries
- [ ] Buffer operations use bounded functions
- [ ] Integer operations checked for overflow
- [ ] Sensitive data zeroed after use
- [ ] Diagnostic access requires authentication with lockout
- [ ] Component permissions follow least privilege
- [ ] Firmware signature verified at boot
- [ ] Runtime integrity monitoring active
- [ ] E2E protection on safety-critical messages
- [ ] No hardcoded keys, passwords, or credentials
- [ ] Constant-time comparison for all secret comparisons
- [ ] Debug interfaces disabled in production builds
