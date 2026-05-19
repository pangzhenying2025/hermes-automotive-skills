# Network Security Rules for CAN and Automotive Ethernet

> Rules for securing in-vehicle network communication including CAN bus,
> CAN FD, Automotive Ethernet, and gateway architectures per
> ISO/SAE 21434 and UNECE R155 requirements.

## Scope

These rules apply to all in-vehicle network communication software,
including CAN drivers, Ethernet stacks, network gateways, firewalls,
intrusion detection systems (IDS), and secure onboard communication (SecOC).

---

## Network Architecture Security

### Zone-Based Architecture

```
+-----------------------------------------------------------+
|                    Vehicle Network                         |
|                                                           |
|  +------------------+    +------------------+             |
|  | Safety Zone      |    | Connectivity Zone|             |
|  | (ASIL B-D)       |    | (QM)            |             |
|  |                  |    |                  |             |
|  | Powertrain CAN   |    | Infotainment    |             |
|  | Chassis CAN      |    | TCU (Cellular)  |             |
|  | BMS CAN          |    | Wi-Fi / BT      |             |
|  +--------+---------+    +--------+---------+             |
|           |                       |                       |
|  +--------+-----------------------+---------+             |
|  |           Central Gateway ECU            |             |
|  |                                          |             |
|  |  Firewall + IDS + Message Authentication |             |
|  |  + Rate Limiting + Protocol Translation  |             |
|  +--------+-----------------------+---------+             |
|           |                       |                       |
|  +--------+---------+    +--------+---------+             |
|  | Body Zone        |    | ADAS Zone        |             |
|  | (QM-ASIL A)      |    | (ASIL B-D)       |             |
|  |                  |    |                  |             |
|  | Body CAN         |    | Sensor Ethernet  |             |
|  | Comfort CAN      |    | Camera / Radar   |             |
|  +------------------+    +------------------+             |
+-----------------------------------------------------------+
```

**Rule**: Network zones must be isolated by gateway ECUs with:
- Message filtering (whitelist-based, not blacklist)
- Rate limiting per message ID
- Authentication for safety-critical messages
- Logging of all cross-zone traffic for forensics

---

## CAN Bus Security

### SecOC (Secure Onboard Communication)

```c
/* AUTOSAR SecOC implementation for CAN message authentication */

#define SECOC_FRESHNESS_SIZE     4U  /* 32-bit freshness value */
#define SECOC_MAC_SIZE           4U  /* Truncated 32-bit MAC */
#define SECOC_AUTH_DATA_SIZE     (SECOC_FRESHNESS_SIZE + SECOC_MAC_SIZE)

typedef struct {
    uint32_t message_id;
    uint8_t payload[8];
    uint8_t payload_length;
    uint32_t freshness_value;    /* Counter or timestamp */
    uint8_t truncated_mac[SECOC_MAC_SIZE];
} SecOcMessage_t;

/* Authenticate outgoing CAN message */
bool secoc_authenticate_tx(SecOcMessage_t* msg,
                            const HsmKeyHandle_t* key) {
    /* Step 1: Increment freshness counter */
    msg->freshness_value = secoc_get_next_freshness(msg->message_id);

    /* Step 2: Build authenticated data = Header | Payload | Freshness */
    uint8_t auth_input[20];
    size_t offset = 0U;
    memcpy(&auth_input[offset], &msg->message_id, 4U); offset += 4U;
    memcpy(&auth_input[offset], msg->payload, msg->payload_length);
    offset += msg->payload_length;
    memcpy(&auth_input[offset], &msg->freshness_value, SECOC_FRESHNESS_SIZE);
    offset += SECOC_FRESHNESS_SIZE;

    /* Step 3: Compute MAC via HSM (AES-128-CMAC) */
    uint8_t full_mac[16];
    if (!hsm_cmac_compute(key->hsm_key_slot, auth_input, offset, full_mac)) {
        return false;
    }

    /* Step 4: Truncate MAC to configured size */
    memcpy(msg->truncated_mac, full_mac, SECOC_MAC_SIZE);
    explicit_memzero(full_mac, sizeof(full_mac));

    return true;
}

/* Verify incoming CAN message */
SecOcResult_t secoc_verify_rx(const SecOcMessage_t* msg,
                               const HsmKeyHandle_t* key) {
    /* Step 1: Check freshness (anti-replay) */
    const uint32_t expected_freshness =
        secoc_get_expected_freshness(msg->message_id);
    if (msg->freshness_value <= expected_freshness) {
        return SECOC_REPLAY_DETECTED;
    }
    /* Allow small gap for missed messages */
    if ((msg->freshness_value - expected_freshness) > MAX_FRESHNESS_GAP) {
        return SECOC_FRESHNESS_OUT_OF_SYNC;
    }

    /* Step 2: Recompute and verify MAC */
    uint8_t auth_input[20];
    size_t offset = 0U;
    memcpy(&auth_input[offset], &msg->message_id, 4U); offset += 4U;
    memcpy(&auth_input[offset], msg->payload, msg->payload_length);
    offset += msg->payload_length;
    memcpy(&auth_input[offset], &msg->freshness_value, SECOC_FRESHNESS_SIZE);
    offset += SECOC_FRESHNESS_SIZE;

    uint8_t full_mac[16];
    if (!hsm_cmac_compute(key->hsm_key_slot, auth_input, offset, full_mac)) {
        return SECOC_CRYPTO_ERROR;
    }

    if (!constant_time_compare(msg->truncated_mac, full_mac, SECOC_MAC_SIZE)) {
        explicit_memzero(full_mac, sizeof(full_mac));
        return SECOC_MAC_MISMATCH;
    }

    explicit_memzero(full_mac, sizeof(full_mac));
    secoc_update_freshness(msg->message_id, msg->freshness_value);
    return SECOC_VERIFIED;
}
```

### CAN Message Filtering

```c
/* Hardware-based CAN message acceptance filter */
typedef struct {
    uint32_t id;
    uint32_t mask;
    bool extended;
    MessageDirection_t direction;
} CanFilter_t;

/* Whitelist filter configuration - ONLY listed messages pass */
static const CanFilter_t s_can_rx_filters[] = {
    /* BMS Internal CAN - only accept known messages */
    { .id = 0x100, .mask = 0x7FF, .extended = false },  /* BMS_Status */
    { .id = 0x101, .mask = 0x7FF, .extended = false },  /* Cell_Voltages_1 */
    { .id = 0x102, .mask = 0x7FF, .extended = false },  /* Cell_Voltages_2 */
    { .id = 0x200, .mask = 0x7F0, .extended = false },  /* Charger range */
    /* All other message IDs silently dropped by hardware filter */
};

/* Rule: Default-deny policy - reject all messages not in whitelist */
/* Rule: Log rejected messages for IDS analysis */
```

### CAN Bus Anomaly Detection

```c
/* Intrusion Detection System (IDS) rules for CAN bus */
typedef struct {
    uint32_t message_id;
    uint32_t expected_period_ms;
    uint32_t tolerance_ms;
    uint32_t last_received_ms;
    uint32_t anomaly_count;
} CanIdsRule_t;

typedef enum {
    IDS_OK,
    IDS_UNEXPECTED_ID,          /* Message ID not in whitelist */
    IDS_FREQUENCY_ANOMALY,      /* Message arriving too fast/slow */
    IDS_DLC_ANOMALY,            /* Unexpected data length */
    IDS_SIGNAL_RANGE_ANOMALY,   /* Signal value outside physical range */
    IDS_COUNTER_ANOMALY,        /* Rolling counter jump */
    IDS_BUS_LOAD_ANOMALY        /* Overall bus utilization spike */
} IdsAlert_t;

IdsAlert_t ids_check_message(const CanFrame_t* frame,
                              CanIdsRule_t* rules,
                              size_t rule_count) {
    /* Find matching rule */
    CanIdsRule_t* rule = NULL;
    for (size_t i = 0U; i < rule_count; i++) {
        if (rules[i].message_id == frame->id) {
            rule = &rules[i];
            break;
        }
    }

    /* Unknown message ID */
    if (rule == NULL) {
        ids_log_alert(IDS_UNEXPECTED_ID, frame);
        return IDS_UNEXPECTED_ID;
    }

    /* Check timing */
    const uint32_t now = get_time_ms();
    const uint32_t delta = now - rule->last_received_ms;
    if (delta < (rule->expected_period_ms - rule->tolerance_ms)) {
        rule->anomaly_count++;
        ids_log_alert(IDS_FREQUENCY_ANOMALY, frame);
        return IDS_FREQUENCY_ANOMALY;
    }

    rule->last_received_ms = now;
    rule->anomaly_count = 0U;
    return IDS_OK;
}
```

---

## Automotive Ethernet Security

### MACsec (IEEE 802.1AE)

```yaml
macsec_configuration:
  enabled: true
  cipher_suite: "GCM-AES-128"
  confidentiality: true  # Encrypt payload
  integrity: true         # Always required

  secure_channels:
    - name: "Camera_Link"
      peer_mac: "AA:BB:CC:DD:EE:01"
      key_agreement: "MKA (IEEE 802.1X-2020)"
      rekey_interval_s: 3600

    - name: "Radar_Link"
      peer_mac: "AA:BB:CC:DD:EE:02"
      key_agreement: "Pre-shared key"
      rekey_interval_s: 86400
```

### IPsec for DoIP

```yaml
ipsec_configuration:
  mode: transport
  protocol: ESP  # Encapsulating Security Payload
  encryption: AES-256-GCM
  integrity: SHA-256
  key_exchange: IKEv2
  certificate_auth: true

  policies:
    - name: "Diagnostic_Access"
      source: "10.0.0.0/24"     # Diagnostic tester network
      destination: "10.0.1.0/24" # ECU network
      port: 13400               # DoIP standard port
      action: protect           # Must use IPsec
      sa_lifetime_s: 3600

    - name: "Default"
      source: "any"
      destination: "any"
      action: drop              # Block all non-policy traffic
```

### VLAN Segmentation

```yaml
vlan_configuration:
  - vlan_id: 10
    name: "ADAS_Sensors"
    members: [camera_1, camera_2, radar_1, lidar_1]
    security_level: high
    isolation: strict  # No inter-VLAN routing

  - vlan_id: 20
    name: "Diagnostic_Access"
    members: [doip_port, gateway_diag_if]
    security_level: high
    isolation: controlled  # Gateway-mediated only

  - vlan_id: 30
    name: "Infotainment"
    members: [head_unit, rear_display, tcmu]
    security_level: medium
    isolation: strict

  - vlan_id: 100
    name: "OTA_Update"
    members: [tcmu_ota_if, gateway_ota_if]
    security_level: critical
    isolation: strict
```

---

## Gateway Security Rules

### Firewall Rules

```c
/* Gateway message routing with security policy enforcement */
typedef struct {
    uint32_t source_bus;
    uint32_t dest_bus;
    uint32_t message_id;
    bool authentication_required;
    uint32_t max_rate_per_second;
    bool log_enabled;
} GatewayRoutingRule_t;

static const GatewayRoutingRule_t s_routing_table[] = {
    /* Safety CAN to Body CAN: limited set, authenticated */
    { .source_bus = BUS_SAFETY_CAN,
      .dest_bus = BUS_BODY_CAN,
      .message_id = 0x180,  /* Vehicle_Speed */
      .authentication_required = true,
      .max_rate_per_second = 100,
      .log_enabled = false },

    /* Infotainment to Safety: BLOCKED (no routing rule = denied) */
    /* Any message from infotainment network toward safety CAN
       is dropped at the gateway with no forwarding */
};

/* Rate limiter per message ID */
typedef struct {
    uint32_t message_id;
    uint32_t count_this_second;
    uint32_t max_per_second;
    uint32_t dropped_count;
} RateLimiter_t;

bool rate_limit_check(RateLimiter_t* limiter) {
    limiter->count_this_second++;
    if (limiter->count_this_second > limiter->max_per_second) {
        limiter->dropped_count++;
        ids_log_rate_limit_exceeded(limiter->message_id);
        return false;  /* Drop message */
    }
    return true;
}
```

### Gateway Logging for Forensics

```c
/* Security event log - tamper-evident, non-volatile */
typedef struct {
    uint32_t timestamp_ms;
    uint32_t event_type;
    uint32_t source_bus;
    uint32_t message_id;
    uint8_t details[16];
    uint32_t sequence_number;
    uint8_t hmac[8];  /* Truncated HMAC for integrity */
} SecurityLogEntry_t;

/* Log ring buffer in protected NVM */
#define SECURITY_LOG_SIZE  1024U
static SecurityLogEntry_t s_security_log[SECURITY_LOG_SIZE];
static uint32_t s_log_write_index;

void security_log_event(uint32_t event_type, uint32_t source_bus,
                         uint32_t message_id, const uint8_t* details) {
    SecurityLogEntry_t* entry = &s_security_log[
        s_log_write_index % SECURITY_LOG_SIZE];

    entry->timestamp_ms = get_time_ms();
    entry->event_type = event_type;
    entry->source_bus = source_bus;
    entry->message_id = message_id;
    if (details != NULL) {
        memcpy(entry->details, details, sizeof(entry->details));
    }
    entry->sequence_number = s_log_write_index;

    /* Compute HMAC for tamper evidence */
    compute_log_hmac(entry);

    s_log_write_index++;

    /* Persist to NVM periodically */
    if ((s_log_write_index % LOG_PERSIST_INTERVAL) == 0U) {
        nvm_write_security_log();
    }
}
```

---

## Prohibited Practices

| Practice | Risk | Requirement |
|----------|------|-------------|
| Unfiltered CAN message acceptance | Injection attacks | Whitelist filtering |
| No message authentication | Spoofing | SecOC or equivalent |
| Flat network (no segmentation) | Lateral movement | Zone architecture |
| Default-allow gateway policy | Unauthorized cross-zone | Default-deny with whitelist |
| No rate limiting | Bus DoS attack | Per-message rate limits |
| Plaintext diagnostic sessions | Eavesdropping | TLS/IPsec for diagnostics |
| No IDS monitoring | Undetected attacks | Real-time anomaly detection |
| No security logging | No forensic evidence | Tamper-evident logging |
| Bridging safety and infotainment | Attack propagation | Gateway isolation |
| Unencrypted Ethernet | Traffic analysis | MACsec or IPsec |

---

## Review Checklist

- [ ] Network architecture uses zone-based segmentation
- [ ] Central gateway enforces default-deny routing policy
- [ ] SecOC implemented for safety-critical CAN messages
- [ ] CAN hardware filters configured as whitelists
- [ ] IDS rules cover all known anomaly patterns
- [ ] Automotive Ethernet uses MACsec or IPsec
- [ ] VLAN segmentation isolates security domains
- [ ] Rate limiting active on all gateway-routed messages
- [ ] Security event logging to tamper-evident storage
- [ ] Diagnostic access requires authentication
- [ ] No direct path from infotainment to safety networks
- [ ] Network security tested with penetration testing
