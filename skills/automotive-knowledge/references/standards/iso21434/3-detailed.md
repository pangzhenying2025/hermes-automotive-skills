# ISO/SAE 21434 - Implementation Guide

## Security Controls Catalog

This section provides detailed implementation guidance for common cybersecurity controls required by ISO 21434.

## Cryptography

### Secure Boot Implementation

Secure boot ensures only authenticated firmware executes on ECUs.

**Boot Chain**:
```
[Power-On] → [ROM Bootloader]
               ↓ (verify signature)
             [Primary Bootloader]
               ↓ (verify signature)
             [Application SW]
```

**Implementation Steps**:

1. **Generate Key Pair**
   ```bash
   # Generate RSA-2048 key pair
   openssl genrsa -out private_key.pem 2048
   openssl rsa -in private_key.pem -pubout -out public_key.pem

   # Extract public key modulus and exponent for embedding
   openssl rsa -in public_key.pem -pubin -text -noout
   ```

2. **Sign Firmware**
   ```bash
   # Create SHA-256 hash of firmware
   openssl dgst -sha256 -binary -out firmware.hash firmware.bin

   # Sign hash with private key
   openssl rsautl -sign -inkey private_key.pem \
     -in firmware.hash -out firmware.sig

   # Concatenate firmware and signature
   cat firmware.bin firmware.sig > firmware_signed.bin
   ```

3. **Bootloader Verification Code**
   ```c
   #include <mbedtls/rsa.h>
   #include <mbedtls/sha256.h>

   bool verify_firmware(const uint8_t *fw, size_t fw_len,
                        const uint8_t *sig, size_t sig_len) {
       mbedtls_rsa_context rsa;
       mbedtls_sha256_context sha256;
       uint8_t hash[32];

       // Compute firmware hash
       mbedtls_sha256_init(&sha256);
       mbedtls_sha256_starts(&sha256, 0);
       mbedtls_sha256_update(&sha256, fw, fw_len);
       mbedtls_sha256_finish(&sha256, hash);

       // Verify RSA signature
       mbedtls_rsa_init(&rsa, MBEDTLS_RSA_PKCS_V15, 0);
       rsa.len = 256; // 2048-bit key
       mbedtls_mpi_read_binary(&rsa.N, public_key_n, 256);
       mbedtls_mpi_read_binary(&rsa.E, public_key_e, 3);

       int ret = mbedtls_rsa_pkcs1_verify(&rsa, NULL, NULL,
                                          MBEDTLS_RSA_PUBLIC,
                                          MBEDTLS_MD_SHA256,
                                          32, hash, sig);

       mbedtls_rsa_free(&rsa);
       return (ret == 0);
   }
   ```

4. **Boot Decision Logic**
   ```c
   void secure_boot(void) {
       uint32_t *app_start = (uint32_t *)APPLICATION_BASE;
       uint8_t *fw_data = (uint8_t *)app_start;
       uint8_t *fw_sig = fw_data + FIRMWARE_SIZE;

       if (verify_firmware(fw_data, FIRMWARE_SIZE,
                          fw_sig, SIGNATURE_SIZE)) {
           // Signature valid, jump to application
           jump_to_application(app_start);
       } else {
           // Signature invalid, halt or enter recovery mode
           enter_safe_mode();
       }
   }
   ```

### Secure Communication (AUTOSAR SecOC)

Secure Onboard Communication protects CAN/LIN/FlexRay messages.

**Message Authentication Code (MAC) Generation**:

```c
#include <autosar/SecOC.h>

// SecOC configuration
const SecOC_ConfigType secoc_config = {
    .algorithm = SECOC_AUTH_AES_CMAC,
    .key_id = 1,
    .freshness_bit_length = 24,
    .truncated_mac_length = 28
};

// Transmit protected message
void send_protected_message(uint8_t msg_id, const uint8_t *data,
                            uint8_t data_len) {
    uint8_t authenticator[4]; // 28-bit MAC + 4-bit freshness
    uint32_t freshness_value;

    // Get freshness value from counter
    freshness_value = SecOC_GetTxFreshness(msg_id);

    // Compute authenticator
    SecOC_GenerateAuthenticator(msg_id, data, data_len,
                                freshness_value,
                                authenticator);

    // Build secured PDU: [Data | Freshness | MAC]
    uint8_t secured_pdu[64];
    memcpy(secured_pdu, data, data_len);
    secured_pdu[data_len] = (freshness_value >> 16) & 0xFF;
    secured_pdu[data_len + 1] = (freshness_value >> 8) & 0xFF;
    secured_pdu[data_len + 2] = freshness_value & 0xFF;
    memcpy(&secured_pdu[data_len + 3], authenticator, 4);

    // Transmit on CAN
    Can_Write(CAN_HTH_SECOC, msg_id, secured_pdu, data_len + 7);
}

// Receive and verify protected message
bool receive_protected_message(uint8_t msg_id, uint8_t *data,
                               uint8_t *data_len) {
    uint8_t secured_pdu[64];
    uint8_t pdu_len;
    uint32_t freshness_value;
    uint8_t received_mac[4];
    uint8_t computed_mac[4];

    // Receive from CAN
    Can_Read(CAN_HRH_SECOC, secured_pdu, &pdu_len);

    // Extract components
    *data_len = pdu_len - 7;
    memcpy(data, secured_pdu, *data_len);
    freshness_value = (secured_pdu[*data_len] << 16) |
                      (secured_pdu[*data_len + 1] << 8) |
                      secured_pdu[*data_len + 2];
    memcpy(received_mac, &secured_pdu[*data_len + 3], 4);

    // Verify freshness (replay protection)
    if (!SecOC_VerifyFreshness(msg_id, freshness_value)) {
        return false; // Replayed message
    }

    // Compute expected MAC
    SecOC_GenerateAuthenticator(msg_id, data, *data_len,
                                freshness_value, computed_mac);

    // Constant-time comparison
    return (memcmp_ct(received_mac, computed_mac, 4) == 0);
}
```

### TLS for Ethernet Communication

**AUTOSAR TLS Configuration** (for DoIP, SOME/IP):

```xml
<TlsConnection Name="DiagnosticOverIP">
  <Protocol>TLS 1.3</Protocol>
  <CipherSuite>TLS_AES_256_GCM_SHA384</CipherSuite>
  <ClientAuth>Required</ClientAuth>
  <CertificateChain>
    <Certificate>/certificates/ecu_cert.pem</Certificate>
    <IntermediateCA>/certificates/oem_ca.pem</IntermediateCA>
    <RootCA>/certificates/root_ca.pem</RootCA>
  </CertificateChain>
  <PrivateKey>/keys/ecu_private_key.pem</PrivateKey>
  <CipherSuitePreferences>
    <Suite>TLS_CHACHA20_POLY1305_SHA256</Suite>
    <Suite>TLS_AES_128_GCM_SHA256</Suite>
  </CipherSuitePreferences>
</TlsConnection>
```

**TLS Handshake in C** (using mbedTLS):

```c
#include <mbedtls/ssl.h>
#include <mbedtls/net_sockets.h>

int establish_tls_connection(const char *server_ip, int port) {
    mbedtls_net_context server_fd;
    mbedtls_ssl_context ssl;
    mbedtls_ssl_config conf;
    mbedtls_x509_crt cacert, client_cert;
    mbedtls_pk_context pkey;

    // Initialize structures
    mbedtls_net_init(&server_fd);
    mbedtls_ssl_init(&ssl);
    mbedtls_ssl_config_init(&conf);
    mbedtls_x509_crt_init(&cacert);
    mbedtls_x509_crt_init(&client_cert);
    mbedtls_pk_init(&pkey);

    // Load certificates
    mbedtls_x509_crt_parse_file(&cacert, "/certs/root_ca.pem");
    mbedtls_x509_crt_parse_file(&client_cert, "/certs/ecu_cert.pem");
    mbedtls_pk_parse_keyfile(&pkey, "/keys/ecu_key.pem", NULL);

    // Configure TLS
    mbedtls_ssl_config_defaults(&conf,
                                MBEDTLS_SSL_IS_CLIENT,
                                MBEDTLS_SSL_TRANSPORT_STREAM,
                                MBEDTLS_SSL_PRESET_DEFAULT);
    mbedtls_ssl_conf_ca_chain(&conf, &cacert, NULL);
    mbedtls_ssl_conf_own_cert(&conf, &client_cert, &pkey);
    mbedtls_ssl_conf_authmode(&conf, MBEDTLS_SSL_VERIFY_REQUIRED);

    // Connect
    mbedtls_net_connect(&server_fd, server_ip,
                        port, MBEDTLS_NET_PROTO_TCP);
    mbedtls_ssl_set_bio(&ssl, &server_fd,
                        mbedtls_net_send, mbedtls_net_recv, NULL);

    // TLS handshake
    int ret = mbedtls_ssl_handshake(&ssl);
    if (ret != 0) {
        return -1; // Handshake failed
    }

    // Verify certificate
    uint32_t flags = mbedtls_ssl_get_verify_result(&ssl);
    if (flags != 0) {
        return -2; // Certificate verification failed
    }

    return 0; // Success
}
```

## Access Control

### Role-Based Access Control (RBAC)

**Diagnostic Session Control** (UDS ISO 14229):

```c
typedef enum {
    SESSION_DEFAULT = 0x01,
    SESSION_PROGRAMMING = 0x02,
    SESSION_EXTENDED = 0x03,
    SESSION_SAFETY = 0x04
} DiagnosticSession_t;

typedef enum {
    SECURITY_LEVEL_LOCKED = 0x00,
    SECURITY_LEVEL_L1 = 0x01, // Technician
    SECURITY_LEVEL_L2 = 0x03, // Engineer
    SECURITY_LEVEL_L3 = 0x05  // Manufacturer
} SecurityAccessLevel_t;

typedef struct {
    DiagnosticSession_t current_session;
    SecurityAccessLevel_t current_level;
    uint32_t seed_value;
    uint32_t failed_attempts;
    uint32_t lockout_time;
} DiagnosticState_t;

// Service access control matrix
const bool service_access_matrix[4][6] = {
    // L0   L1   L2   L3   Sessions
    {true, true, true, true},  // ReadDataByID
    {false, true, true, true}, // WriteDataByID
    {false, false, true, true},// RoutineControl
    {false, false, false, true}// RequestDownload
};

bool is_service_allowed(uint8_t service_id,
                        DiagnosticState_t *state) {
    if (state->current_session == SESSION_DEFAULT &&
        service_id != SID_DIAGNOSTIC_SESSION_CONTROL &&
        service_id != SID_SECURITY_ACCESS) {
        return false;
    }

    int service_idx = get_service_index(service_id);
    int level_idx = (state->current_level + 1) / 2;

    return service_access_matrix[service_idx][level_idx];
}
```

### Security Access (Seed-Key Authentication)

```c
#include <mbedtls/aes.h>

#define MAX_FAILED_ATTEMPTS 3
#define LOCKOUT_TIME_MS 600000 // 10 minutes

uint32_t generate_seed(DiagnosticState_t *state) {
    // Check lockout
    if (state->failed_attempts >= MAX_FAILED_ATTEMPTS) {
        uint32_t elapsed = get_time_ms() - state->lockout_time;
        if (elapsed < LOCKOUT_TIME_MS) {
            return 0; // Still locked out
        } else {
            state->failed_attempts = 0; // Reset
        }
    }

    // Generate cryptographic random seed
    uint32_t seed;
    mbedtls_ctr_drbg_random(&ctr_drbg_ctx, (uint8_t *)&seed, 4);
    state->seed_value = seed;

    return seed;
}

bool verify_key(DiagnosticState_t *state, uint32_t received_key) {
    uint32_t expected_key;

    // Compute expected key using AES-based algorithm
    mbedtls_aes_context aes;
    mbedtls_aes_setkey_enc(&aes, security_key_l2, 128);
    mbedtls_aes_crypt_ecb(&aes, MBEDTLS_AES_ENCRYPT,
                          (uint8_t *)&state->seed_value,
                          (uint8_t *)&expected_key);

    if (received_key == expected_key) {
        state->current_level = SECURITY_LEVEL_L2;
        state->failed_attempts = 0;
        return true;
    } else {
        state->failed_attempts++;
        if (state->failed_attempts >= MAX_FAILED_ATTEMPTS) {
            state->lockout_time = get_time_ms();
        }
        return false;
    }
}
```

## Intrusion Detection System (IDS)

### CAN IDS Implementation

**Anomaly Detection Rules**:

```c
typedef struct {
    uint32_t can_id;
    uint32_t expected_period_ms;
    uint32_t last_rx_timestamp;
    uint32_t rx_count;
    uint8_t expected_dlc;
    bool freshness_enabled;
    uint8_t last_counter;
} CANMessageProfile_t;

typedef enum {
    IDS_EVENT_NONE = 0,
    IDS_EVENT_REPLAY_ATTACK,
    IDS_EVENT_TIMING_VIOLATION,
    IDS_EVENT_DLC_MISMATCH,
    IDS_EVENT_UNKNOWN_ID,
    IDS_EVENT_BUS_FLOOD
} IDSEventType_t;

CANMessageProfile_t profiles[] = {
    {0x123, 100, 0, 0, 8, true, 0},  // Brake status, 10 Hz
    {0x200, 20,  0, 0, 8, true, 0},  // Steering angle, 50 Hz
    {0x456, 1000, 0, 0, 8, false, 0} // Vehicle speed, 1 Hz
};

IDSEventType_t check_can_message(uint32_t can_id, uint8_t dlc,
                                  const uint8_t *data,
                                  uint32_t timestamp) {
    CANMessageProfile_t *profile = find_profile(can_id);

    if (profile == NULL) {
        return IDS_EVENT_UNKNOWN_ID;
    }

    // Check DLC
    if (dlc != profile->expected_dlc) {
        return IDS_EVENT_DLC_MISMATCH;
    }

    // Check timing
    uint32_t delta_t = timestamp - profile->last_rx_timestamp;
    if (delta_t < profile->expected_period_ms * 0.8 ||
        delta_t > profile->expected_period_ms * 1.2) {
        return IDS_EVENT_TIMING_VIOLATION;
    }

    // Check freshness counter
    if (profile->freshness_enabled) {
        uint8_t counter = data[0] & 0x0F;
        uint8_t expected = (profile->last_counter + 1) % 16;
        if (counter != expected) {
            return IDS_EVENT_REPLAY_ATTACK;
        }
        profile->last_counter = counter;
    }

    // Update profile
    profile->last_rx_timestamp = timestamp;
    profile->rx_count++;

    return IDS_EVENT_NONE;
}

// Bus load monitoring
void monitor_bus_load(void) {
    static uint32_t msg_count_1s = 0;
    static uint32_t last_check_time = 0;

    msg_count_1s++;

    uint32_t now = get_time_ms();
    if (now - last_check_time >= 1000) {
        if (msg_count_1s > CAN_BUS_FLOOD_THRESHOLD) {
            trigger_ids_event(IDS_EVENT_BUS_FLOOD);
        }
        msg_count_1s = 0;
        last_check_time = now;
    }
}
```

## Firmware Update Security

### Over-the-Air (OTA) Update Flow

```
[Backend Server]
      ↓ 1. Request update
[Vehicle TCU]
      ↓ 2. Download encrypted package
[Verify signature]
      ↓ 3. If valid
[Decrypt firmware]
      ↓ 4. Store in secondary partition
[Target ECU]
      ↓ 5. Trigger ECU update via UDS
[ECU verifies & flashes]
      ↓ 6. Reboot
[Secure boot verification]
      ↓ 7. Report status
[Backend Server]
```

**Update Package Structure**:
```
[Header (256 bytes)]
  - Version info
  - Target ECU ID
  - Package size
  - Signature (RSA-2048)
[Encrypted Firmware (N bytes)]
  - AES-256-CBC encrypted
[HMAC (32 bytes)]
  - SHA-256 HMAC of header + encrypted data
```

**TCU Update Handler** (C code):

```c
#include <mbedtls/rsa.h>
#include <mbedtls/aes.h>

typedef struct {
    uint32_t version;
    uint32_t target_ecu_id;
    uint32_t fw_size;
    uint8_t signature[256];
} UpdateHeader_t;

bool process_ota_update(const uint8_t *package, size_t package_len) {
    UpdateHeader_t *header = (UpdateHeader_t *)package;
    const uint8_t *encrypted_fw = package + sizeof(UpdateHeader_t);
    const uint8_t *hmac = package + package_len - 32;

    // Step 1: Verify HMAC
    uint8_t computed_hmac[32];
    mbedtls_md_hmac(mbedtls_md_info_from_type(MBEDTLS_MD_SHA256),
                    update_hmac_key, 32,
                    package, package_len - 32,
                    computed_hmac);
    if (memcmp(hmac, computed_hmac, 32) != 0) {
        return false; // HMAC mismatch
    }

    // Step 2: Verify RSA signature
    uint8_t header_hash[32];
    mbedtls_sha256((uint8_t *)header,
                   sizeof(UpdateHeader_t) - 256,
                   header_hash, 0);
    if (!verify_rsa_signature(header_hash, 32, header->signature)) {
        return false; // Invalid signature
    }

    // Step 3: Decrypt firmware
    uint8_t *decrypted_fw = malloc(header->fw_size);
    mbedtls_aes_context aes;
    mbedtls_aes_setkey_dec(&aes, update_aes_key, 256);
    mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_DECRYPT,
                          header->fw_size,
                          update_aes_iv,
                          encrypted_fw,
                          decrypted_fw);

    // Step 4: Store to secondary partition
    flash_write(SECONDARY_PARTITION_ADDR, decrypted_fw,
                header->fw_size);

    // Step 5: Trigger ECU update via UDS RequestDownload
    bool success = flash_target_ecu(header->target_ecu_id,
                                    decrypted_fw,
                                    header->fw_size);

    free(decrypted_fw);
    return success;
}
```

## Logging and Monitoring

### Security Event Logging

```c
typedef struct {
    uint32_t timestamp;
    uint32_t ecu_id;
    uint16_t event_type;
    uint16_t severity;
    uint8_t data[64];
} SecurityLogEntry_t;

void log_security_event(uint16_t event_type, uint16_t severity,
                        const uint8_t *data, size_t data_len) {
    SecurityLogEntry_t entry;
    entry.timestamp = get_time_ms();
    entry.ecu_id = get_ecu_id();
    entry.event_type = event_type;
    entry.severity = severity;
    memcpy(entry.data, data, MIN(data_len, 64));

    // Write to secure flash partition
    flash_append(SECURITY_LOG_PARTITION, &entry,
                 sizeof(SecurityLogEntry_t));

    // If critical event, send immediate notification
    if (severity >= SEVERITY_CRITICAL) {
        send_security_alert_to_backend(&entry);
    }
}
```

## Next Steps

- **Level 4**: Quick reference tables and compliance checklists
- **Level 5**: Advanced VSOC, incident response, supply chain security

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Cybersecurity developers, embedded security engineers
