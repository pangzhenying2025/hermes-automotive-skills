# Automotive Cybersecurity Rules (ISO 21434)

ISO 21434 "Road vehicles - Cybersecurity engineering" defines requirements for cybersecurity risk management throughout the vehicle lifecycle. This guide focuses on secure coding practices and developer responsibilities.

## Purpose

- Protect vehicles from cyber attacks (remote exploitation, data theft, safety compromise)
- Implement defense-in-depth security architecture
- Ensure secure software development lifecycle (SDL)
- Comply with UN R155 cybersecurity regulations
- Support TARA (Threat Analysis and Risk Assessment) mitigation

## Secure Coding Principles

### Input Validation (Defense Against Injection Attacks)

```c
// VIOLATION: No input validation on CAN message
void process_can_message(uint32_t can_id, const uint8_t* data, uint8_t length) {
    uint16_t speed = (data[0] << 8) | data[1];  // Trusts input
    set_vehicle_speed(speed);
}

// COMPLIANT: Validate all external inputs
void process_can_message(uint32_t can_id, const uint8_t* data, uint8_t length) {
    // 1. Validate CAN ID against whitelist
    if (!is_authorized_can_id(can_id)) {
        log_security_event(SEC_EVENT_UNAUTHORIZED_CAN_ID, can_id);
        return;
    }

    // 2. Validate message length
    if (length != EXPECTED_SPEED_MSG_LENGTH) {
        log_security_event(SEC_EVENT_INVALID_LENGTH, length);
        return;
    }

    // 3. Validate data range
    uint16_t speed = ((uint16_t)data[0] << 8) | data[1];
    if (speed > MAX_PLAUSIBLE_SPEED_KMH) {
        log_security_event(SEC_EVENT_IMPLAUSIBLE_SPEED, speed);
        return;
    }

    // 4. Verify message authentication code (if available)
    if (!verify_can_mac(can_id, data, length)) {
        log_security_event(SEC_EVENT_MAC_FAILURE, can_id);
        return;
    }

    set_vehicle_speed(speed);
}
```

### Buffer Overflow Prevention

```c
// VIOLATION: Unsafe string copy
void set_vin_number(const char* vin) {
    char vin_buffer[17];
    strcpy(vin_buffer, vin);  // Buffer overflow if vin > 17 chars
}

// COMPLIANT: Bounds-checked copy
void set_vin_number(const char* vin) {
    char vin_buffer[18] = {0};  // 17 chars + null terminator

    if (vin == NULL) {
        return;
    }

    size_t vin_len = strlen(vin);
    if (vin_len > 17) {
        log_security_event(SEC_EVENT_INVALID_VIN_LENGTH, vin_len);
        return;
    }

    strncpy(vin_buffer, vin, sizeof(vin_buffer) - 1);
    vin_buffer[sizeof(vin_buffer) - 1] = '\0';  // Ensure null termination

    // Additional validation: VIN format check
    if (validate_vin_format(vin_buffer)) {
        store_vin(vin_buffer);
    }
}
```

### Integer Overflow Protection

```c
// VIOLATION: Unchecked arithmetic
uint16_t calculate_total_distance(uint16_t distance_km, uint16_t additional_km) {
    return distance_km + additional_km;  // May overflow
}

// COMPLIANT: Overflow detection
uint16_t calculate_total_distance(uint16_t distance_km, uint16_t additional_km, bool* overflow) {
    if (additional_km > (UINT16_MAX - distance_km)) {
        *overflow = true;
        log_security_event(SEC_EVENT_INTEGER_OVERFLOW, additional_km);
        return UINT16_MAX;  // Saturate
    }

    *overflow = false;
    return distance_km + additional_km;
}
```

### Command Injection Prevention

```c
// VIOLATION: Unsanitized system command
void execute_diagnostic_command(const char* command) {
    char cmd_buffer[256];
    sprintf(cmd_buffer, "/usr/bin/diag %s", command);  // Injection risk
    system(cmd_buffer);
}

// COMPLIANT: Use whitelist and parameterized execution
void execute_diagnostic_command(DiagnosticCommand_t cmd_id) {
    switch (cmd_id) {
        case DIAG_READ_DTC:
            read_diagnostic_trouble_codes();
            break;
        case DIAG_CLEAR_DTC:
            if (is_authorized_for_clear()) {
                clear_diagnostic_trouble_codes();
            }
            break;
        default:
            log_security_event(SEC_EVENT_INVALID_DIAG_COMMAND, cmd_id);
            break;
    }
    // Never execute arbitrary shell commands
}
```

## Cryptographic Requirements

### Secure Key Storage

```c
// VIOLATION: Hardcoded cryptographic key
const uint8_t aes_key[16] = {
    0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
    0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
};

// COMPLIANT: Key stored in secure element or TPM
#include "hsm_interface.h"  // Hardware Security Module

void encrypt_data(const uint8_t* plaintext, size_t length, uint8_t* ciphertext) {
    // Key never leaves HSM
    uint32_t key_handle = HSM_KEY_SLOT_0;

    // HSM performs encryption internally
    hsm_aes_encrypt(key_handle, plaintext, length, ciphertext);
}

// Key provisioning during manufacturing
void provision_device_key(void) {
    // Unique key per vehicle, injected in secure manufacturing environment
    // Key generation inside HSM, never exposed to software
    hsm_generate_unique_key(HSM_KEY_SLOT_0, KEY_TYPE_AES256);
}
```

### Secure Random Number Generation

```c
// VIOLATION: Weak random number generation
uint32_t generate_session_token(void) {
    srand(time(NULL));  // Predictable seed
    return rand();      // Weak PRNG
}

// COMPLIANT: Cryptographically secure RNG
#include "mbedtls/entropy.h"
#include "mbedtls/ctr_drbg.h"

uint32_t generate_session_token(void) {
    mbedtls_entropy_context entropy;
    mbedtls_ctr_drbg_context ctr_drbg;
    uint32_t token;

    mbedtls_entropy_init(&entropy);
    mbedtls_ctr_drbg_init(&ctr_drbg);

    // Seed with hardware entropy
    mbedtls_ctr_drbg_seed(&ctr_drbg, mbedtls_entropy_func, &entropy, NULL, 0);

    // Generate cryptographically secure random token
    mbedtls_ctr_drbg_random(&ctr_drbg, (uint8_t*)&token, sizeof(token));

    mbedtls_ctr_drbg_free(&ctr_drbg);
    mbedtls_entropy_free(&entropy);

    return token;
}
```

### Message Authentication Codes (MAC)

```c
// CAN message authentication using CMAC (AUTOSAR SecOC)
#include "mbedtls/cmac.h"

#define CMAC_KEY_SIZE 16
#define CMAC_OUTPUT_SIZE 8  // Truncated to 64 bits for CAN

typedef struct {
    uint32_t can_id;
    uint8_t data[8];
    uint8_t mac[CMAC_OUTPUT_SIZE];
} SecureCANMessage_t;

bool generate_can_mac(SecureCANMessage_t* msg) {
    const mbedtls_cipher_info_t* cipher_info;
    uint8_t mac_full[16];

    cipher_info = mbedtls_cipher_info_from_type(MBEDTLS_CIPHER_AES_128_ECB);

    // Compute CMAC over CAN ID + data
    uint8_t mac_input[12];
    memcpy(mac_input, &msg->can_id, 4);
    memcpy(mac_input + 4, msg->data, 8);

    // Get key from HSM
    uint8_t mac_key[CMAC_KEY_SIZE];
    if (!hsm_get_mac_key(HSM_KEY_SLOT_CAN_MAC, mac_key, CMAC_KEY_SIZE)) {
        return false;
    }

    mbedtls_cipher_cmac(cipher_info, mac_key, CMAC_KEY_SIZE * 8,
                        mac_input, sizeof(mac_input), mac_full);

    // Truncate to 64 bits for CAN bandwidth
    memcpy(msg->mac, mac_full, CMAC_OUTPUT_SIZE);

    // Zero out key material
    mbedtls_platform_zeroize(mac_key, CMAC_KEY_SIZE);

    return true;
}

bool verify_can_mac(const SecureCANMessage_t* msg) {
    SecureCANMessage_t verify_msg;
    memcpy(&verify_msg, msg, sizeof(SecureCANMessage_t));

    // Recompute MAC
    if (!generate_can_mac(&verify_msg)) {
        return false;
    }

    // Constant-time comparison (prevent timing attacks)
    return mbedtls_constant_time_memcmp(msg->mac, verify_msg.mac, CMAC_OUTPUT_SIZE) == 0;
}
```

## Key Management

### Key Lifecycle

```c
// Key hierarchy for automotive ECU
typedef enum {
    KEY_TYPE_ROOT,           // Master key in HSM, never extracted
    KEY_TYPE_TRANSPORT,      // Used for secure software update delivery
    KEY_TYPE_SESSION,        // Temporary key for diagnostic session
    KEY_TYPE_MESSAGE_AUTH    // CAN message authentication
} KeyType_t;

// Key rotation policy
#define SESSION_KEY_LIFETIME_MS  (15 * 60 * 1000)  // 15 minutes
#define TRANSPORT_KEY_ROTATION_INTERVAL_DAYS  90

void key_rotation_task(void) {
    static uint32_t last_rotation_timestamp = 0;
    uint32_t current_time = get_timestamp_ms();

    // Rotate session keys periodically
    if ((current_time - last_rotation_timestamp) > SESSION_KEY_LIFETIME_MS) {
        hsm_derive_session_key(HSM_KEY_SLOT_ROOT, HSM_KEY_SLOT_SESSION);
        last_rotation_timestamp = current_time;
    }
}

// Secure key deletion
void delete_session_key(void) {
    // Overwrite key slot with random data before deletion
    hsm_zeroize_key_slot(HSM_KEY_SLOT_SESSION);
    hsm_delete_key(HSM_KEY_SLOT_SESSION);
}
```

### Certificate Management

```c
// X.509 certificate validation for OTA updates
#include "mbedtls/x509_crt.h"
#include "mbedtls/pk.h"

bool verify_update_package_signature(const uint8_t* package_data,
                                     size_t package_size,
                                     const uint8_t* signature,
                                     size_t signature_size) {
    mbedtls_x509_crt cert;
    mbedtls_pk_context pk;
    int ret;

    mbedtls_x509_crt_init(&cert);

    // Load OEM root certificate (stored in secure flash)
    ret = mbedtls_x509_crt_parse(&cert, oem_root_cert, oem_root_cert_size);
    if (ret != 0) {
        log_security_event(SEC_EVENT_CERT_PARSE_FAILED, ret);
        goto cleanup;
    }

    // Verify certificate chain and validity period
    uint32_t flags;
    ret = mbedtls_x509_crt_verify(&cert, &cert, NULL, NULL, &flags, NULL, NULL);
    if (ret != 0) {
        log_security_event(SEC_EVENT_CERT_VERIFICATION_FAILED, flags);
        goto cleanup;
    }

    // Verify signature using certificate's public key
    pk = cert.pk;
    uint8_t hash[32];
    mbedtls_sha256(package_data, package_size, hash, 0);

    ret = mbedtls_pk_verify(&pk, MBEDTLS_MD_SHA256,
                           hash, sizeof(hash),
                           signature, signature_size);

cleanup:
    mbedtls_x509_crt_free(&cert);
    return (ret == 0);
}
```

## Secure Boot Chain

```c
// Stage 1: ROM bootloader (immutable, in mask ROM)
void rom_bootloader(void) {
    // 1. Verify Stage 2 bootloader signature using OEM public key (fused in OTP)
    if (!verify_bootloader_signature(STAGE2_BOOTLOADER_ADDR, oem_pubkey_hash)) {
        enter_safe_mode();  // Cannot boot, enter recovery
        return;
    }

    // 2. Enable security features
    enable_mpu();
    enable_secure_debug_lockout();

    // 3. Jump to Stage 2
    jump_to_bootloader(STAGE2_BOOTLOADER_ADDR);
}

// Stage 2: Secure bootloader (updatable, signed by OEM)
void secure_bootloader(void) {
    // 1. Initialize HSM and verify integrity
    hsm_init();
    if (!hsm_self_test()) {
        report_security_failure(FAILURE_HSM_INTEGRITY);
        return;
    }

    // 2. Verify application firmware signature
    if (!verify_firmware_signature(APPLICATION_ADDR)) {
        // Attempt rollback to previous version
        if (!rollback_to_backup_firmware()) {
            enter_safe_mode();
            return;
        }
    }

    // 3. Verify firmware has not been revoked
    uint32_t firmware_version = read_firmware_version(APPLICATION_ADDR);
    if (firmware_version < get_minimum_allowed_version()) {
        log_security_event(SEC_EVENT_REVOKED_FIRMWARE, firmware_version);
        enter_safe_mode();
        return;
    }

    // 4. Enable runtime security mechanisms
    configure_watchdog();
    configure_memory_protection();

    // 5. Jump to application
    jump_to_application(APPLICATION_ADDR);
}

// Application: Runtime security checks
void application_init(void) {
    // Verify we were launched from secure bootloader (anti-bypass)
    if (!verify_boot_chain_integrity()) {
        trigger_security_reset();
    }

    // Enable runtime protections
    enable_stack_canary();
    enable_aslr();  // If supported by platform
    configure_firewall_rules();

    // Start security monitoring task
    create_task(security_monitor_task, PRIORITY_HIGH);
}
```

## TARA Methodology Summary

Threat Analysis and Risk Assessment per ISO 21434.

### Asset Identification

```yaml
# Example: assets.yaml
asset_001:
  name: "Vehicle speed signal"
  type: "Data"
  confidentiality: Low
  integrity: High        # Safety-critical
  availability: High     # Required for safe operation
  damage_scenario: "Manipulation could cause incorrect speedometer, affect cruise control"

asset_002:
  name: "Diagnostic session key"
  type: "Cryptographic key"
  confidentiality: High
  integrity: High
  availability: Medium
  damage_scenario: "Unauthorized access to vehicle reprogramming"

asset_003:
  name: "Firmware update package"
  type: "Software"
  confidentiality: Medium  # Proprietary algorithms
  integrity: Critical      # Malicious firmware could compromise safety
  availability: Low        # Update is not time-critical
  damage_scenario: "Malware installation, vehicle theft, safety function disable"
```

### Threat Scenarios

```yaml
# Example: threats.yaml
threat_001:
  name: "CAN message spoofing"
  asset: asset_001
  attack_path: "Attacker injects fake speed messages on CAN bus via OBD-II port"
  attack_feasibility: High  # Physical access to OBD-II port
  impact: High              # Could affect safety functions
  risk_value: 8             # Feasibility × Impact
  mitigation: "Implement CAN message authentication (SecOC)"

threat_002:
  name: "Firmware downgrade attack"
  asset: asset_003
  attack_path: "Attacker replaces new firmware with old vulnerable version"
  attack_feasibility: Medium  # Requires diagnostic access
  impact: Critical            # Reintroduces known vulnerabilities
  risk_value: 9
  mitigation: "Anti-rollback protection with version monotonic counter"

threat_003:
  name: "Diagnostic session replay attack"
  asset: asset_002
  attack_path: "Attacker captures and replays diagnostic authentication messages"
  attack_feasibility: Medium
  impact: High  # Unauthorized vehicle access
  risk_value: 7
  mitigation: "Use challenge-response authentication with nonce"
```

### Risk Treatment Implementation

```c
// Mitigation for threat_002: Anti-rollback protection
#define VERSION_COUNTER_ADDRESS  0x0801F800  // OTP region

bool is_firmware_version_allowed(uint32_t firmware_version) {
    // Read monotonic counter from OTP (one-time programmable memory)
    uint32_t min_version = read_otp_counter(VERSION_COUNTER_ADDRESS);

    if (firmware_version < min_version) {
        log_security_event(SEC_EVENT_ROLLBACK_ATTEMPT, firmware_version);
        return false;
    }

    return true;
}

void update_minimum_firmware_version(uint32_t new_min_version) {
    uint32_t current_min = read_otp_counter(VERSION_COUNTER_ADDRESS);

    if (new_min_version > current_min) {
        // Write to OTP - this is irreversible
        write_otp_counter(VERSION_COUNTER_ADDRESS, new_min_version);
    }
}

// Mitigation for threat_003: Challenge-response authentication
typedef struct {
    uint8_t challenge[16];   // Random nonce
    uint32_t timestamp;
    uint8_t response[32];    // HMAC-SHA256 of challenge
} DiagAuthRequest_t;

bool authenticate_diagnostic_session(void) {
    DiagAuthRequest_t auth_req;

    // 1. Generate random challenge
    generate_random_bytes(auth_req.challenge, sizeof(auth_req.challenge));
    auth_req.timestamp = get_timestamp_ms();

    // 2. Send challenge to diagnostic tool
    send_diagnostic_message(DIAG_AUTH_CHALLENGE, &auth_req, sizeof(auth_req));

    // 3. Wait for response (with timeout)
    DiagAuthRequest_t auth_resp;
    if (!receive_diagnostic_message(&auth_resp, DIAG_AUTH_TIMEOUT_MS)) {
        return false;
    }

    // 4. Verify timestamp freshness (prevent replay)
    if ((get_timestamp_ms() - auth_resp.timestamp) > DIAG_AUTH_WINDOW_MS) {
        log_security_event(SEC_EVENT_STALE_AUTH_RESPONSE, 0);
        return false;
    }

    // 5. Verify HMAC response
    uint8_t expected_response[32];
    hmac_sha256(diagnostic_secret_key, sizeof(diagnostic_secret_key),
                auth_req.challenge, sizeof(auth_req.challenge),
                expected_response);

    return (mbedtls_constant_time_memcmp(auth_resp.response, expected_response, 32) == 0);
}
```

## Incident Response

### Security Event Logging

```c
typedef enum {
    SEC_EVENT_UNAUTHORIZED_CAN_ID = 0x01,
    SEC_EVENT_MAC_FAILURE = 0x02,
    SEC_EVENT_CERT_VERIFICATION_FAILED = 0x03,
    SEC_EVENT_ROLLBACK_ATTEMPT = 0x04,
    SEC_EVENT_INTRUSION_DETECTED = 0x05,
    SEC_EVENT_DEBUG_ACCESS_ATTEMPT = 0x06
} SecurityEventType_t;

typedef struct {
    uint32_t timestamp;
    SecurityEventType_t event_type;
    uint32_t event_data;
    uint8_t severity;  // 1=Info, 2=Warning, 3=Critical
} SecurityEvent_t;

#define SECURITY_LOG_SIZE 100
static SecurityEvent_t security_log[SECURITY_LOG_SIZE];
static uint16_t log_index = 0;

void log_security_event(SecurityEventType_t event_type, uint32_t event_data) {
    SecurityEvent_t event = {
        .timestamp = get_timestamp_ms(),
        .event_type = event_type,
        .event_data = event_data,
        .severity = get_event_severity(event_type)
    };

    // Store in circular buffer
    security_log[log_index] = event;
    log_index = (log_index + 1) % SECURITY_LOG_SIZE;

    // For critical events, trigger immediate response
    if (event.severity == 3) {
        handle_critical_security_event(&event);
    }

    // Write to non-volatile storage for post-incident analysis
    if (event.severity >= 2) {
        write_security_event_to_flash(&event);
    }
}

void handle_critical_security_event(const SecurityEvent_t* event) {
    switch (event->event_type) {
        case SEC_EVENT_INTRUSION_DETECTED:
            // Disable external interfaces
            disable_can_communication();
            disable_ethernet_communication();
            // Notify vehicle gateway ECU
            send_intrusion_alert_to_gateway();
            break;

        case SEC_EVENT_ROLLBACK_ATTEMPT:
            // Prevent boot of compromised firmware
            enter_safe_mode();
            break;

        default:
            break;
    }
}
```

### Intrusion Detection

```c
// Runtime integrity monitoring
#define CODE_SECTION_START  0x08000000
#define CODE_SECTION_SIZE   0x00080000

uint32_t calculate_code_checksum(void) {
    const uint32_t* code = (const uint32_t*)CODE_SECTION_START;
    uint32_t checksum = 0;

    for (size_t i = 0; i < (CODE_SECTION_SIZE / sizeof(uint32_t)); i++) {
        checksum ^= code[i];
    }

    return checksum;
}

void integrity_monitor_task(void) {
    static uint32_t expected_checksum = 0;

    // Calculate expected checksum at boot
    if (expected_checksum == 0) {
        expected_checksum = calculate_code_checksum();
    }

    while (1) {
        // Periodically verify code integrity
        uint32_t current_checksum = calculate_code_checksum();

        if (current_checksum != expected_checksum) {
            log_security_event(SEC_EVENT_INTRUSION_DETECTED, current_checksum);
            trigger_security_reset();
        }

        task_delay(INTEGRITY_CHECK_INTERVAL_MS);
    }
}
```

## Vulnerability Management

### Secure Development Lifecycle

```yaml
# SDL phases and security activities

requirements_phase:
  activities:
    - "Define security requirements based on TARA"
    - "Identify cryptographic requirements"
    - "Define access control policies"

design_phase:
  activities:
    - "Security architecture review"
    - "Threat modeling (STRIDE framework)"
    - "Define secure communication protocols"

implementation_phase:
  activities:
    - "Secure coding training for developers"
    - "Static analysis (SAST) on every commit"
    - "Code review with security checklist"

testing_phase:
  activities:
    - "Penetration testing (authorized ethical hacking)"
    - "Fuzzing of external interfaces (CAN, Ethernet, USB)"
    - "Vulnerability scanning"

deployment_phase:
  activities:
    - "Secure key injection in manufacturing"
    - "Firmware signing and verification"
    - "Secure storage of audit logs"

maintenance_phase:
  activities:
    - "Security patch management"
    - "Vulnerability disclosure handling"
    - "Incident response procedures"
```

### Vulnerability Disclosure Response

```markdown
# Vulnerability Response Procedure

## Reception (Day 0)
1. Security researcher reports vulnerability via security@oem.com
2. Acknowledge receipt within 24 hours
3. Assign CVE identifier if applicable
4. Create internal security ticket (confidential)

## Analysis (Days 1-7)
1. Reproduce vulnerability in lab environment
2. Assess impact (CVSS scoring)
3. Identify affected vehicle models and software versions
4. Determine if safety is impacted (ISO 26262 safety case review)

## Mitigation (Days 7-30)
1. Develop security patch
2. Test patch (regression testing, vulnerability validation)
3. Prepare OTA update package
4. Coordinate with dealers for non-OTA vehicles

## Disclosure (Day 30+)
1. Notify regulatory authorities (UNECE WP.29 R155 requirement)
2. Publish security advisory
3. Credit researcher (if agreed)
4. Deploy OTA update to affected fleet
```

## Code Review Security Checklist

Use this checklist for every code review involving security-sensitive code:

### Input Validation
- [ ] All external inputs validated (range, format, type)
- [ ] CAN message IDs checked against whitelist
- [ ] Buffer sizes verified before copy operations
- [ ] Integer overflow checked for arithmetic operations
- [ ] String inputs null-terminated and length-checked

### Cryptography
- [ ] No hardcoded keys or passwords
- [ ] Cryptographically secure RNG used (not rand())
- [ ] Keys stored in HSM or secure element
- [ ] Certificates validated (chain, expiration, revocation)
- [ ] Constant-time comparison for security-critical checks

### Authentication & Authorization
- [ ] Challenge-response authentication for diagnostic access
- [ ] Session tokens generated with sufficient entropy
- [ ] Privilege separation enforced (least privilege principle)
- [ ] Debug interfaces disabled in production builds
- [ ] Anti-replay mechanisms for security-critical messages

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] Secure erase for deleted cryptographic material
- [ ] Memory not leaked through error messages
- [ ] Secrets not logged or transmitted in clear text

### Secure Boot
- [ ] Boot chain integrity verified at each stage
- [ ] Anti-rollback protection enforced
- [ ] Firmware signature validated before execution
- [ ] Recovery mode secured against bypass

### Error Handling
- [ ] Error messages do not leak sensitive information
- [ ] Security failures logged with sufficient detail
- [ ] System enters safe state on security failure
- [ ] Critical events trigger alerts to security monitoring

### Dependencies
- [ ] Third-party libraries scanned for known vulnerabilities
- [ ] Library versions pinned (no floating dependencies)
- [ ] SBOM (Software Bill of Materials) updated
- [ ] License compliance verified

## References

- ISO/SAE 21434:2021 - Road vehicles - Cybersecurity engineering
- UN Regulation No. 155 - Cybersecurity and cybersecurity management system
- UN Regulation No. 156 - Software update and software update management system
- AUTOSAR SecOC (Secure Onboard Communication) specification
- NIST Cybersecurity Framework for connected vehicles
- OWASP Embedded Application Security Top 10
