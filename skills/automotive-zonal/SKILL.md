---
name: automotive-zonal
description: >
  Automotive Zonal expertise. Covers 5 topics: Automotive Ethernet, Network Security Zonal, Service Oriented Communication, Zonal Architecture Design, Zone Controller Development.
tags: [automotive, automotive-zonal]
---

# Automotive Zonal

## Automotive Ethernet

# Automotive Ethernet - TSN & AVB

**Category:** automotive-zonal
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Expert knowledge in automotive Ethernet technologies including Time-Sensitive Networking (TSN), Audio Video Bridging (AVB), physical layer standards (100BASE-T1, 1000BASE-T1), switch configuration, VLAN management, and Quality of Service (QoS) for deterministic vehicle networks.

## Core Competencies

### 1. Physical Layer Standards

#### 100BASE-T1 (IEEE 802.3bw)
```c
// 100BASE-T1 PHY Configuration
typedef struct {
    uint8_t standard;           // IEEE 802.3bw
    uint16_t data_rate_mbps;    // 100 Mbps full-duplex
    uint8_t wire_pairs;         // 1 twisted pair
    uint16_t max_length_m;      // 15 meters (typ), 40m (max)
    float voltage_p2p;          // 2.4V peak-to-peak
    uint8_t encoding;           // PAM3 (3-level)
    bool pma_master;            // Master/Slave negotiation
} BASE100_T1_Config;

// Example configuration for zone controller
BASE100_T1_Config zcu_phy = {
    .standard = IEEE_802_3bw,
    .data_rate_mbps = 100,
    .wire_pairs = 1,
    .max_length_m = 15,
    .voltage_p2p = 2.4,
    .encoding = PAM3,
    .pma_master = true  // Zone controller is master
};
```

#### 1000BASE-T1 (IEEE 802.3bp)
```c
// 1000BASE-T1 PHY Configuration (for cameras, ADAS)
typedef struct {
    uint8_t standard;           // IEEE 802.3bp
    uint16_t data_rate_mbps;    // 1000 Mbps full-duplex
    uint8_t wire_pairs;         // 1 unshielded twisted pair
    uint16_t max_length_m;      // 15m (standard), 40m (extended)
    uint8_t encoding;           // PAM3
    bool automotive_grade;      // AEC-Q100 qualified
    float temp_range[2];        // -40°C to +125°C
} BASE1000_T1_Config;

// Camera link configuration
BASE1000_T1_Config camera_phy = {
    .standard = IEEE_802_3bp,
    .data_rate_mbps = 1000,
    .wire_pairs = 1,
    .max_length_m = 15,
    .encoding = PAM3,
    .automotive_grade = true,
    .temp_range = {-40.0, 125.0}
};
```

#### 10BASE-T1S (IEEE 802.3cg) - Multidrop Bus
```c
// 10BASE-T1S for low-cost sensor networks
typedef struct {
    uint8_t standard;           // IEEE 802.3cg
    uint16_t data_rate_mbps;    // 10 Mbps half-duplex
    uint8_t topology;           // Multidrop bus
    uint8_t max_nodes;          // 8 nodes per segment
    uint16_t max_length_m;      // 25 meters
    uint8_t collision_detection; // CSMA/CD
    bool plca_mode;             // Physical Layer Collision Avoidance
} BASE10_T1S_Config;

// Sensor bus configuration
BASE10_T1S_Config sensor_bus = {
    .standard = IEEE_802_3cg,
    .data_rate_mbps = 10,
    .topology = MULTIDROP_BUS,
    .max_nodes = 8,
    .max_length_m = 25,
    .collision_detection = CSMA_CD,
    .plca_mode = true  // Enables deterministic access
};
```

### 2. Time-Sensitive Networking (TSN)

#### IEEE 802.1 TSN Standards

**Key Standards:**
- **802.1AS** - Precision Time Protocol (gPTP) for time synchronization
- **802.1Qbv** - Time-Aware Shaper (TAS) for scheduled traffic
- **802.1Qav** - Credit-Based Shaper (CBS) for AVB streams
- **802.1Qbu** - Frame Preemption for low-latency
- **802.1Qci** - Per-Stream Filtering and Policing
- **802.1CB** - Frame Replication and Elimination for Reliability (FRER)

```python
# TSN Configuration Example
class TSNSwitchConfig:
    def __init__(self):
        self.gptp_domain = 0  # Time domain for sync
        self.sync_interval_ms = 125  # gPTP sync every 125ms
        self.time_aware_shaper = True
        self.frame_preemption = True
        self.stream_reservation = True

    def configure_tas_schedule(self):
        """
        Configure Time-Aware Shaper (802.1Qbv) for deterministic scheduling.
        Divides time into repeating cycles with gates for each priority queue.
        """

        # 1ms cycle time (1,000,000 ns)
        cycle_time_ns = 1_000_000

        schedule = {
            'cycle_time_ns': cycle_time_ns,
            'gates': [
                # Time slot 0-100μs: Priority 7 (Safety-critical)
                {
                    'start_ns': 0,
                    'duration_ns': 100_000,
                    'open_gates': [7],  # Only priority 7 queue open
                    'traffic_class': 'Safety'
                },
                # Time slot 100-300μs: Priority 6 (ADAS)
                {
                    'start_ns': 100_000,
                    'duration_ns': 200_000,
                    'open_gates': [6],
                    'traffic_class': 'Control'
                },
                # Time slot 300-800μs: Priority 4-5 (Video streams)
                {
                    'start_ns': 300_000,
                    'duration_ns': 500_000,
                    'open_gates': [4, 5],
                    'traffic_class': 'AVB'
                },
                # Time slot 800-1000μs: Priority 0-3 (Best effort)
                {
                    'start_ns': 800_000,
                    'duration_ns': 200_000,
                    'open_gates': [0, 1, 2, 3],
                    'traffic_class': 'BestEffort'
                }
            ]
        }

        return schedule

    def configure_stream_reservation(self, stream_id, bandwidth_mbps, latency_us):
        """
        Configure stream reservation for AVB/TSN streams (802.1Qat/Qcc).

        Args:
            stream_id: Unique stream identifier
            bandwidth_mbps: Required bandwidth in Mbps
            latency_us: Maximum latency in microseconds
        """

        stream_config = {
            'stream_id': stream_id,
            'talker_mac': '00:11:22:33:44:55',
            'listener_mac': ['00:11:22:33:44:66'],
            'vlan_id': 100,
            'priority': 6,  # SR Class A
            'max_frame_size': 1522,
            'max_interval_frames': 1,
            'bandwidth_mbps': bandwidth_mbps,
            'max_latency_us': latency_us,
            'redundancy': 'FRER'  # Frame Replication
        }

        return stream_config
```

#### gPTP Time Synchronization (802.1AS)

```c
// gPTP Time Synchronization Configuration
typedef struct {
    uint8_t domain_number;           // 0 for automotive
    uint32_t sync_interval_ns;       // 125ms = 125,000,000 ns
    uint32_t pdelay_interval_ns;     // Peer delay measurement
    int8_t clock_class;              // 248 for automotive grandmaster
    int8_t clock_accuracy;           // 0xFE (unknown)
    uint16_t offset_scaled_log_var;  // Variance of clock
    uint8_t priority1;               // 248
    uint8_t priority2;               // 248
    bool as_capable;                 // TSN-capable port
} gPTP_Config_t;

// Grandmaster clock (gateway)
gPTP_Config_t grandmaster = {
    .domain_number = 0,
    .sync_interval_ns = 125000000,  // 125ms
    .pdelay_interval_ns = 1000000000,  // 1 second
    .clock_class = 248,  // Automotive default application-specific
    .clock_accuracy = 0xFE,
    .offset_scaled_log_var = 0x4E5D,
    .priority1 = 248,
    .priority2 = 248,
    .as_capable = true
};

// Typical time sync accuracy: ±500ns between nodes
```

### 3. VLAN Configuration

```python
class VLANManager:
    """
    Manage VLANs for traffic segregation in zonal architecture.
    """

    def __init__(self):
        self.vlans = {
            100: {'name': 'Safety', 'priority': 7, 'color': 'RED'},
            200: {'name': 'ADAS', 'priority': 6, 'color': 'ORANGE'},
            300: {'name': 'Infotainment', 'priority': 5, 'color': 'YELLOW'},
            400: {'name': 'Body', 'priority': 4, 'color': 'GREEN'},
            500: {'name': 'Diagnostics', 'priority': 3, 'color': 'BLUE'},
            999: {'name': 'Management', 'priority': 7, 'color': 'PURPLE'}
        }

    def configure_switch_ports(self):
        """
        Configure switch ports with VLAN memberships.
        """

        port_config = {
            'port_1': {  # Gateway uplink
                'mode': 'trunk',
                'allowed_vlans': [100, 200, 300, 400, 500, 999],
                'native_vlan': 999,
                'pvid': 999
            },
            'port_2': {  # Front-left ZCU
                'mode': 'trunk',
                'allowed_vlans': [100, 400],  # Safety + Body
                'native_vlan': 400,
                'pvid': 400
            },
            'port_3': {  # Front camera (ADAS)
                'mode': 'access',
                'vlan': 200,  # ADAS VLAN only
                'pvid': 200
            },
            'port_4': {  # Rear camera (infotainment)
                'mode': 'access',
                'vlan': 300,  # Infotainment VLAN
                'pvid': 300
            },
            'port_5': {  # Diagnostic connector (OBD-II)
                'mode': 'access',
                'vlan': 500,
                'pvid': 500
            }
        }

        return port_config
```

### 4. Quality of Service (QoS)

#### Priority Mapping (IEEE 802.1Q)

```c
// 8 priority levels (0-7)
typedef enum {
    PRIORITY_0_BEST_EFFORT = 0,     // Background
    PRIORITY_1_BACKGROUND = 1,      // Backup data
    PRIORITY_2_EXCELLENT_EFFORT = 2, // Business-critical
    PRIORITY_3_CRITICAL_APPS = 3,    // Call signaling
    PRIORITY_4_VIDEO = 4,            // Streaming video
    PRIORITY_5_VOICE = 5,            // Interactive voice/video
    PRIORITY_6_CONTROL = 6,          // Control plane (ADAS)
    PRIORITY_7_NETWORK_CONTROL = 7   // Safety-critical
} EthernetPriority_t;

// Traffic class mapping
typedef struct {
    EthernetPriority_t priority;
    uint8_t traffic_class;
    uint16_t max_latency_us;
    char description[32];
} QoS_Mapping_t;

QoS_Mapping_t qos_table[] = {
    {PRIORITY_7_NETWORK_CONTROL, 7, 100, "Safety (ABS, ESC)"},
    {PRIORITY_6_CONTROL, 6, 500, "ADAS (Braking, Steering)"},
    {PRIORITY_5_VOICE, 5, 2000, "Camera streams"},
    {PRIORITY_4_VIDEO, 4, 10000, "Infotainment video"},
    {PRIORITY_3_CRITICAL_APPS, 3, 20000, "Diagnostics"},
    {PRIORITY_2_EXCELLENT_EFFORT, 2, 50000, "SW updates"},
    {PRIORITY_1_BACKGROUND, 1, 100000, "Telemetry"},
    {PRIORITY_0_BEST_EFFORT, 0, 1000000, "General data"}
};
```

#### Credit-Based Shaper (802.1Qav)

```python
def configure_cbs(port, stream_class):
    """
    Configure Credit-Based Shaper for AVB traffic (SR Class A/B).

    Args:
        port: Ethernet port number
        stream_class: 'A' for Class A (2ms), 'B' for Class B (50ms)
    """

    if stream_class == 'A':
        config = {
            'idle_slope': 0x3FFF,      # 75% of link bandwidth
            'send_slope': -0x2AAA,     # -25% of link bandwidth
            'hi_credit': 0x186A0,      # 100,000 credits
            'lo_credit': -0x186A0,     # -100,000 credits
            'priority': 6
        }
    elif stream_class == 'B':
        config = {
            'idle_slope': 0x1FFF,      # 50% of link bandwidth
            'send_slope': -0x1FFF,     # -50% of link bandwidth
            'hi_credit': 0xC350,       # 50,000 credits
            'lo_credit': -0xC350,      # -50,000 credits
            'priority': 5
        }

    return config
```

### 5. Automotive Ethernet Switch Configuration

```yaml
# Example switch configuration (YAML)
switch:
  model: "NXP SJA1110"
  ports: 10
  tsn_capable: true

  global_config:
    gptp_domain: 0
    management_vlan: 999

  port_1:  # Uplink to gateway
    speed: "1000BASE-T1"
    mode: "trunk"
    vlans: [100, 200, 300, 400, 500, 999]
    tsn:
      tas_enabled: true
      frame_preemption: true

  port_2:  # Front-left zone controller
    speed: "100BASE-T1"
    mode: "trunk"
    vlans: [100, 400]
    tsn:
      tas_enabled: true

  port_3:  # Front camera
    speed: "1000BASE-T1"
    mode: "access"
    vlan: 200
    qos:
      priority: 6
      cbs_enabled: true
      stream_reservation: true

  port_4:  # Rear camera
    speed: "1000BASE-T1"
    mode: "access"
    vlan: 200
    qos:
      priority: 6
      cbs_enabled: true
```

## Network Performance Targets

| Traffic Type | Priority | Max Latency | Jitter | Packet Loss |
|--------------|----------|-------------|--------|-------------|
| Safety (ABS, ESC) | 7 | <100 μs | <10 μs | 0% |
| ADAS Control | 6 | <500 μs | <50 μs | <10^-9 |
| Camera Streams | 5-6 | <2 ms | <100 μs | <10^-6 |
| Infotainment | 4 | <10 ms | <1 ms | <10^-4 |
| Diagnostics | 3 | <50 ms | N/A | <10^-3 |
| Best Effort | 0-2 | <1 s | N/A | <10^-2 |

## Tools & Testing

**Network Analyzers:**
- **Vector VN5600** - TSN-capable network interface
- **Wireshark with Automotive plugins** - Packet capture and analysis
- **Ixia/Keysight IxNetwork** - TSN traffic generation and testing

**Configuration Tools:**
- **NXP SJA1110 Config Tool** - Switch configuration
- **Vector CANoe.Ethernet** - Network simulation
- **Marvell TSN Studio** - TSN stream configuration

## References

- IEEE 802.1 TSN Task Group Standards
- SAE J3161 On-Board Ethernet Communication
- OPEN Alliance BroadR-Reach Specification
- AUTOSAR Ethernet Communication Specification

---

## Network Security Zonal

# Network Security for Zonal Architecture

**Category:** automotive-zonal
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Expert knowledge in securing automotive Ethernet networks in zonal architectures. Covers MACsec (IEEE 802.1AE), IPsec, firewall rules for zone controllers, intrusion detection systems (IDS), secure gateway design, and IDPS deployment for vehicle networks.

## Core Competencies

### 1. MACsec (IEEE 802.1AE) - Layer 2 Encryption

```c
// MACsec Configuration for Automotive Ethernet
typedef struct {
    uint8_t enabled;
    uint8_t cipher_suite;       // AES-GCM-128 or AES-GCM-256
    uint8_t confidentiality;    // Encrypt payload
    uint8_t integrity;          // ICV (Integrity Check Value)
    uint32_t pn;                // Packet Number (anti-replay)
    uint8_t key[32];            // 128-bit or 256-bit key
    uint8_t sci[8];             // Secure Channel Identifier
} MACSec_Config_t;

// Example: MACsec between gateway and zone controller
MACSec_Config_t macsec_link = {
    .enabled = 1,
    .cipher_suite = AES_GCM_256,
    .confidentiality = 1,       // Encrypt
    .integrity = 1,             // 16-byte ICV
    .pn = 0x00000001,          // Initial packet number
    .key = {0x2b, 0x7e, 0x15, ...},  // 256-bit key from key management
    .sci = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77}
};
```

**MACsec Frame Structure:**
```
┌──────────────────────────────────────────────┐
│ Ethernet Header (14 bytes)                   │
├──────────────────────────────────────────────┤
│ SecTAG (8 bytes)                             │
│  - TCI/AN (1 byte): Version, encrypted flag │
│  - SL (1 byte): Short Length                │
│  - PN (4 bytes): Packet Number              │
│  - SCI (8 bytes): Secure Channel ID         │
├──────────────────────────────────────────────┤
│ Encrypted Payload                            │
├──────────────────────────────────────────────┤
│ ICV (16 bytes): Integrity Check Value        │
└──────────────────────────────────────────────┘
```

**Performance Impact:**
- Latency overhead: ~100-200 μs
- Throughput reduction: ~5-10% (due to encryption)
- CPU overhead: ~15% on zone controller

### 2. IPsec for End-to-End Security

```python
class IPsecTunnel:
    """
    IPsec tunnel configuration for secure SOME/IP communication.
    """

    def __init__(self):
        self.mode = 'ESP'  # Encapsulating Security Payload
        self.encryption = 'AES-256-CBC'
        self.authentication = 'HMAC-SHA256'
        self.pfs = True  # Perfect Forward Secrecy

    def configure_tunnel(self, local_ip, remote_ip):
        """
        Configure IPsec tunnel between two ECUs.

        Args:
            local_ip: Local zone controller IP
            remote_ip: Remote zone controller/gateway IP
        """

        config = {
            'src': local_ip,
            'dst': remote_ip,
            'protocol': 'ESP',  # ESP for encryption + auth
            'spi': 0x1234,  # Security Parameter Index
            'encryption': {
                'algorithm': 'AES-256-CBC',
                'key': self._generate_key(256)
            },
            'authentication': {
                'algorithm': 'HMAC-SHA256',
                'key': self._generate_key(256)
            },
            'lifetime': 3600,  # Rekey every hour
            'anti_replay': True,
            'window_size': 64
        }

        return config

    def _generate_key(self, bits):
        """Generate cryptographic key (placeholder - use proper KMS)."""
        import secrets
        return secrets.token_bytes(bits // 8)

# Example: Secure tunnel from FL zone to gateway
tunnel = IPsecTunnel()
config = tunnel.configure_tunnel(
    local_ip='192.168.1.10',   # FL Zone Controller
    remote_ip='192.168.1.1'     # Gateway
)
```

### 3. Firewall Rules for Zone Controllers

```python
class ZonalFirewall:
    """
    Stateful firewall for zone controller Ethernet interface.
    """

    def __init__(self, zone_id):
        self.zone_id = zone_id
        self.rules = []
        self.default_policy = 'DROP'  # Deny by default

    def add_rule(self, rule):
        """
        Add firewall rule.

        Rule format:
        {
            'src_ip': '192.168.1.0/24',
            'dst_ip': '192.168.2.10',
            'protocol': 'UDP',
            'dst_port': 30500,
            'action': 'ALLOW'/'DROP'/'REJECT',
            'priority': 100
        }
        """
        self.rules.append(rule)
        # Sort by priority
        self.rules.sort(key=lambda x: x['priority'])

    def evaluate_packet(self, packet):
        """
        Evaluate packet against firewall rules.

        Returns:
            'ALLOW', 'DROP', or 'REJECT'
        """

        for rule in self.rules:
            if self._match_rule(packet, rule):
                return rule['action']

        return self.default_policy

    def _match_rule(self, packet, rule):
        """Check if packet matches rule."""
        # Check source IP
        if not self._ip_in_subnet(packet['src_ip'], rule.get('src_ip', 'any')):
            return False

        # Check destination IP
        if not self._ip_in_subnet(packet['dst_ip'], rule.get('dst_ip', 'any')):
            return False

        # Check protocol
        if rule.get('protocol', 'any') != 'any' and packet['protocol'] != rule['protocol']:
            return False

        # Check port
        if rule.get('dst_port') and packet.get('dst_port') != rule['dst_port']:
            return False

        return True

# Example: Firewall rules for FL Zone Controller
fw = ZonalFirewall(zone_id='FL_ZONE')

# Allow SOME/IP from gateway
fw.add_rule({
    'src_ip': '192.168.1.1',     # Gateway
    'dst_ip': '192.168.1.10',     # FL Zone
    'protocol': 'UDP',
    'dst_port': 30500,            # SOME/IP service port
    'action': 'ALLOW',
    'priority': 100
})

# Allow diagnostic access (DoIP)
fw.add_rule({
    'src_ip': '192.168.5.0/24',   # Diagnostic VLAN
    'dst_ip': '192.168.1.10',
    'protocol': 'TCP',
    'dst_port': 13400,            # DoIP port
    'action': 'ALLOW',
    'priority': 200
})

# Block all other incoming traffic
fw.add_rule({
    'src_ip': 'any',
    'dst_ip': '192.168.1.10',
    'action': 'DROP',
    'priority': 1000
})
```

### 4. Intrusion Detection System (IDS)

```python
class AutomotiveIDS:
    """
    Intrusion Detection System for automotive Ethernet networks.
    Detects anomalies and attacks specific to vehicle networks.
    """

    def __init__(self):
        self.baseline = {}  # Normal traffic patterns
        self.alerts = []

    def detect_anomalies(self, traffic_sample):
        """
        Detect network anomalies.

        Detection methods:
        - Signature-based: Known attack patterns
        - Anomaly-based: Deviation from baseline
        - Behavior-based: Unusual communication patterns
        """

        alerts = []

        # 1. Port scan detection
        if self._detect_port_scan(traffic_sample):
            alerts.append({
                'type': 'PORT_SCAN',
                'severity': 'HIGH',
                'description': 'Port scan detected from ' + traffic_sample['src_ip']
            })

        # 2. DoS detection (flooding)
        if self._detect_dos(traffic_sample):
            alerts.append({
                'type': 'DOS_ATTACK',
                'severity': 'CRITICAL',
                'description': 'Potential DoS attack detected'
            })

        # 3. Unusual SOME/IP service access
        if self._detect_unauthorized_service_access(traffic_sample):
            alerts.append({
                'type': 'UNAUTHORIZED_ACCESS',
                'severity': 'HIGH',
                'description': 'Unauthorized SOME/IP service access'
            })

        # 4. ARP spoofing detection
        if self._detect_arp_spoofing(traffic_sample):
            alerts.append({
                'type': 'ARP_SPOOFING',
                'severity': 'CRITICAL',
                'description': 'ARP spoofing detected'
            })

        # 5. Replay attack detection (abnormal packet rate)
        if self._detect_replay(traffic_sample):
            alerts.append({
                'type': 'REPLAY_ATTACK',
                'severity': 'MEDIUM',
                'description': 'Potential replay attack detected'
            })

        return alerts

    def _detect_port_scan(self, traffic):
        """
        Detect port scanning:
        - Multiple connection attempts to different ports
        - From same source IP in short time window
        """

        src_ip = traffic.get('src_ip')
        unique_ports = traffic.get('unique_dst_ports', [])
        time_window = traffic.get('time_window_sec', 0)

        # More than 20 ports in 10 seconds = port scan
        if len(unique_ports) > 20 and time_window < 10:
            return True

        return False

    def _detect_dos(self, traffic):
        """
        Detect Denial of Service:
        - Packet rate > 10x baseline
        - Same message repeated at high rate
        """

        pkt_rate = traffic.get('packets_per_second', 0)
        baseline_rate = self.baseline.get('avg_pkt_rate', 100)

        if pkt_rate > baseline_rate * 10:
            return True

        return False

    def _detect_unauthorized_service_access(self, traffic):
        """
        Detect unauthorized SOME/IP service access:
        - Access to service not in whitelist
        - Access from unauthorized client
        """

        service_id = traffic.get('someip_service_id')
        client_ip = traffic.get('src_ip')

        authorized_services = {
            0x1234: ['192.168.1.1'],  # Battery service - gateway only
            0x5678: ['192.168.1.1', '192.168.1.10']  # Body service - gateway + FL zone
        }

        if service_id in authorized_services:
            if client_ip not in authorized_services[service_id]:
                return True

        return False

    def _detect_arp_spoofing(self, traffic):
        """
        Detect ARP spoofing:
        - Different MAC for same IP
        - Gratuitous ARP with conflicting info
        """

        if traffic.get('protocol') == 'ARP':
            ip = traffic.get('ip')
            mac = traffic.get('mac')

            known_mac = self.baseline.get('ip_to_mac', {}).get(ip)

            if known_mac and known_mac != mac:
                return True  # MAC changed for this IP

        return False

    def _detect_replay(self, traffic):
        """
        Detect replay attacks:
        - Same packet repeated (duplicate sequence numbers)
        - Packet rate anomaly for specific message
        """

        msg_id = traffic.get('msg_id')
        pkt_count = traffic.get('pkt_count', 0)
        baseline_count = self.baseline.get('msg_counts', {}).get(msg_id, 1)

        if pkt_count > baseline_count * 5:
            return True

        return False
```

### 5. Secure Gateway Design

```c
// Secure gateway functionality
typedef struct {
    uint8_t zone_count;
    struct {
        uint8_t zone_id;
        uint32_t ip_address;
        uint8_t vlan_id;
        bool macsec_enabled;
        bool ipsec_enabled;
        bool firewall_enabled;
    } zones[8];

    struct {
        bool ids_enabled;
        bool ips_enabled;           // Intrusion Prevention
        uint16_t alert_threshold;
        char siem_server[64];       // SIEM logging
    } security;

} SecureGateway_t;

// Example gateway configuration
SecureGateway_t gateway = {
    .zone_count = 4,
    .zones = {
        {.zone_id = 1, .ip_address = 0xC0A80110, .vlan_id = 100, .macsec_enabled = true, .ipsec_enabled = false, .firewall_enabled = true},  // FL Zone
        {.zone_id = 2, .ip_address = 0xC0A80120, .vlan_id = 100, .macsec_enabled = true, .ipsec_enabled = false, .firewall_enabled = true},  // FR Zone
        {.zone_id = 3, .ip_address = 0xC0A80130, .vlan_id = 200, .macsec_enabled = true, .ipsec_enabled = true, .firewall_enabled = true},   // ADAS Zone (extra IPsec)
        {.zone_id = 4, .ip_address = 0xC0A80140, .vlan_id = 100, .macsec_enabled = true, .ipsec_enabled = false, .firewall_enabled = true}   // RL Zone
    },

    .security = {
        .ids_enabled = true,
        .ips_enabled = true,        // Block detected attacks automatically
        .alert_threshold = 10,      // Alert after 10 suspicious events
        .siem_server = "192.168.99.10"
    }
};
```

## Security Architecture Layers

```
┌────────────────────────────────────────────┐
│  Layer 7: Application Security            │
│  - SOME/IP authentication                 │
│  - Service access control                 │
└────────────────────────────────────────────┘
┌────────────────────────────────────────────┐
│  Layer 4-6: Transport/Session Security    │
│  - IPsec (ESP): End-to-end encryption     │
│  - TLS 1.3: For diagnostic protocols      │
└────────────────────────────────────────────┘
┌────────────────────────────────────────────┐
│  Layer 3: Network Security                │
│  - Firewall: Packet filtering             │
│  - IDS/IPS: Anomaly detection             │
└────────────────────────────────────────────┘
┌────────────────────────────────────────────┐
│  Layer 2: Data Link Security              │
│  - MACsec (IEEE 802.1AE): Link encryption │
│  - 802.1X: Port-based authentication      │
└────────────────────────────────────────────┘
```

## Key Management

```python
class VehicleKeyManagement:
    """
    Key management for MACsec and IPsec.
    Supports both static provisioning and dynamic key exchange.
    """

    def __init__(self):
        self.keys = {}
        self.key_lifetime_hours = 24  # Rotate every 24 hours

    def provision_static_key(self, zone_id, key_type, key_material):
        """
        Provision static key during manufacturing.

        Args:
            zone_id: Zone controller ID
            key_type: 'MACSEC' or 'IPSEC'
            key_material: 256-bit key
        """

        self.keys[zone_id] = {
            'type': key_type,
            'key': key_material,
            'provisioned_at': time.time(),
            'valid_until': time.time() + (self.key_lifetime_hours * 3600)
        }

    def rotate_keys(self):
        """
        Automatic key rotation every 24 hours.
        Uses Diffie-Hellman key exchange for new keys.
        """

        for zone_id, key_info in self.keys.items():
            if time.time() > key_info['valid_until']:
                # Generate new key
                new_key = self._dh_key_exchange(zone_id)
                self.keys[zone_id]['key'] = new_key
                self.keys[zone_id]['valid_until'] = time.time() + (self.key_lifetime_hours * 3600)

    def _dh_key_exchange(self, zone_id):
        """Diffie-Hellman key exchange (simplified)."""
        # In production, use proper DH or ECDH
        import secrets
        return secrets.token_bytes(32)  # 256-bit key
```

## Performance Impact

| Security Feature | Latency Overhead | CPU Overhead | Throughput Impact |
|------------------|------------------|--------------|-------------------|
| MACsec (AES-128) | +100 μs | +10% | -5% |
| MACsec (AES-256) | +150 μs | +15% | -8% |
| IPsec (ESP) | +200 μs | +20% | -10% |
| Firewall | +50 μs | +5% | -2% |
| IDS (passive) | +10 μs | +8% | 0% |
| IPS (active) | +100 μs | +15% | -5% |

## Tools & Testing

- **Wireshark with MACsec plugin** - Decrypt and analyze MACsec traffic
- **Scapy** - Craft attack packets for security testing
- **Suricata** - Open-source IDS/IPS engine
- **Kali Linux** - Penetration testing toolkit
- **CANalyze** - Automotive-specific security testing

## References

- IEEE 802.1AE (MACsec) Standard
- ISO/SAE 21434 Cybersecurity Engineering
- UNECE R155 Cybersecurity Regulation
- AUTOSAR Secure Communication Specification

---

## Service Oriented Communication

# Service-Oriented Communication - SOME/IP & DDS

**Category:** automotive-zonal
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Expert knowledge in service-oriented middleware for automotive zonal architectures. Covers SOME/IP (Scalable Service-Oriented Middleware over IP), DDS (Data Distribution Service), service discovery, publish-subscribe patterns, event-driven architecture, and method invocations over Ethernet.

## Core Competencies

### 1. SOME/IP (AUTOSAR Standard)

#### Protocol Overview

**SOME/IP = Scalable Service-Oriented Middleware over IP**
- Used in AUTOSAR Adaptive Platform
- Transport: UDP or TCP over IPv4/IPv6
- Serialization: SOME/IP binary format
- Discovery: SOME/IP-SD (Service Discovery)

```c
// SOME/IP Message Header (16 bytes)
typedef struct __attribute__((packed)) {
    uint32_t message_id;      // Service ID (16 bits) + Method ID (16 bits)
    uint32_t length;          // Payload length + 8
    uint32_t request_id;      // Client ID (16 bits) + Session ID (16 bits)
    uint8_t  protocol_version; // 0x01
    uint8_t  interface_version; // Service interface version
    uint8_t  message_type;    // REQUEST=0x00, RESPONSE=0x80, ERROR=0x81, NOTIFICATION=0x02
    uint8_t  return_code;     // E_OK=0x00, E_NOT_OK=0x01, etc.
} SOMEIP_Header_t;

// Example: Request message
SOMEIP_Header_t request = {
    .message_id = 0x12340001,  // Service 0x1234, Method 0x0001
    .length = 24,              // Header (16) + Payload (8)
    .request_id = 0x00010001,  // Client 0x0001, Session 0x0001
    .protocol_version = 0x01,
    .interface_version = 0x01,
    .message_type = 0x00,      // REQUEST
    .return_code = 0x00        // E_OK
};
```

#### Service Definition (FIDL)

```fidl
// Franca IDL (FIDL) - SOME/IP Service Definition
package org.genivi.battery

interface BatteryManagementService {
    version { major 1 minor 0 }

    // Methods (Request/Response)
    method GetBatteryStatus {
        out {
            UInt8 stateOfCharge    // 0-100%
            Float voltage           // Volts
            Float current           // Amps
            Int8 temperature        // Celsius
        }
    }

    method SetChargingLimit {
        in {
            UInt8 targetSoC        // Target SOC %
        }
        out {
            Boolean success
        }
    }

    // Events (Notifications)
    broadcast BatteryAlarm {
        out {
            UInt16 alarmCode
            String description
        }
    }

    // Attributes (Getter/Setter/Notification)
    attribute UInt8 stateOfCharge readonly

    // Error codes
    enumeration BatteryError {
        OK = 0
        INVALID_PARAMETER = 1
        HARDWARE_FAULT = 2
        COMMUNICATION_ERROR = 3
    }
}
```

#### SOME/IP Service Implementation

```cpp
#include <CommonAPI/CommonAPI.hpp>
#include <v1/org/genivi/battery/BatteryManagementServiceProxy.hpp>

using namespace v1::org::genivi::battery;

class BatteryClient {
public:
    BatteryClient() {
        runtime_ = CommonAPI::Runtime::get();
        proxy_ = runtime_->buildProxy<BatteryManagementServiceProxy>(
            "local", "BatteryService");

        // Wait for service availability
        while (!proxy_->isAvailable()) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        // Subscribe to battery alarms
        proxy_->getBatteryAlarmEvent().subscribe(
            [](uint16_t alarmCode, std::string description) {
                std::cout << "Alarm " << alarmCode << ": "
                          << description << std::endl;
            });
    }

    void getBatteryStatus() {
        // Synchronous method call
        CommonAPI::CallStatus callStatus;
        uint8_t soc;
        float voltage, current;
        int8_t temperature;

        proxy_->GetBatteryStatus(callStatus, soc, voltage, current, temperature);

        if (callStatus == CommonAPI::CallStatus::SUCCESS) {
            std::cout << "SOC: " << (int)soc << "%" << std::endl;
            std::cout << "Voltage: " << voltage << "V" << std::endl;
            std::cout << "Current: " << current << "A" << std::endl;
            std::cout << "Temperature: " << (int)temperature << "°C" << std::endl;
        }
    }

    void setChargingLimit(uint8_t targetSoC) {
        // Asynchronous method call with callback
        proxy_->SetChargingLimitAsync(
            targetSoC,
            [](const CommonAPI::CallStatus& status, bool success) {
                if (status == CommonAPI::CallStatus::SUCCESS && success) {
                    std::cout << "Charging limit set successfully" << std::endl;
                }
            });
    }

private:
    std::shared_ptr<CommonAPI::Runtime> runtime_;
    std::shared_ptr<BatteryManagementServiceProxy<>> proxy_;
};
```

#### SOME/IP-SD (Service Discovery)

```python
class SOMEIPServiceDiscovery:
    """
    SOME/IP Service Discovery (SOME/IP-SD) implementation.
    Uses UDP multicast (224.244.224.245:30490) for service advertisement.
    """

    def __init__(self):
        self.multicast_group = '224.244.224.245'
        self.multicast_port = 30490
        self.services = {}

    def offer_service(self, service_id, instance_id, endpoint):
        """
        Offer a service via SOME/IP-SD.

        Args:
            service_id: Service identifier (16-bit)
            instance_id: Instance identifier (16-bit)
            endpoint: (IP, port, protocol)  protocol='UDP' or 'TCP'
        """

        offer_message = {
            'message_type': 'OfferService',
            'service_id': service_id,
            'instance_id': instance_id,
            'major_version': 1,
            'minor_version': 0,
            'ttl': 3,  # Time-to-live in seconds (0xFFFFFF = infinite)
            'endpoint': {
                'ipv4': endpoint[0],
                'port': endpoint[1],
                'protocol': endpoint[2]  # UDP or TCP
            }
        }

        # Send cyclic offers (every 1 second)
        # Until service is stopped
        return offer_message

    def find_service(self, service_id, instance_id=None):
        """
        Find a service via SOME/IP-SD.

        Args:
            service_id: Service to find
            instance_id: Specific instance (None = any)

        Returns:
            List of available service endpoints
        """

        find_message = {
            'message_type': 'FindService',
            'service_id': service_id,
            'instance_id': instance_id if instance_id else 0xFFFF,  # ANY
            'major_version': 0xFF,  # ANY
            'minor_version': 0xFFFFFFFF  # ANY
        }

        # Wait for OfferService responses
        # Return list of endpoints
        return []

# Example usage:
sd = SOMEIPServiceDiscovery()

# Offer battery service
sd.offer_service(
    service_id=0x1234,
    instance_id=0x0001,
    endpoint=('192.168.1.10', 30500, 'UDP')
)

# Find battery service
endpoints = sd.find_service(service_id=0x1234)
```

### 2. DDS (Data Distribution Service)

#### DDS Quality of Service (QoS)

```python
from dataclasses import dataclass
from enum import Enum

class ReliabilityKind(Enum):
    BEST_EFFORT = 0  # UDP-like, lossy
    RELIABLE = 1      # TCP-like, guaranteed delivery

class DurabilityKind(Enum):
    VOLATILE = 0          # Only for live data
    TRANSIENT_LOCAL = 1   # Store last value for late joiners
    TRANSIENT = 2         # Persist across processes
    PERSISTENT = 3        # Persist to disk

@dataclass
class DDSQoS:
    """DDS Quality of Service configuration."""

    reliability: ReliabilityKind
    durability: DurabilityKind
    history_depth: int  # Number of samples to keep
    max_blocking_time_ms: int  # Max time to block writer
    latency_budget_ms: int  # Hint for latency optimization
    lifespan_ms: int  # Sample validity duration

# Example QoS profiles for different use cases

# Safety-critical real-time data (ESC, ABS)
SAFETY_QOS = DDSQoS(
    reliability=ReliabilityKind.RELIABLE,
    durability=DurabilityKind.VOLATILE,
    history_depth=1,  # Only latest value matters
    max_blocking_time_ms=10,
    latency_budget_ms=5,
    lifespan_ms=100
)

# Sensor data (high-rate, best-effort)
SENSOR_QOS = DDSQoS(
    reliability=ReliabilityKind.BEST_EFFORT,
    durability=DurabilityKind.VOLATILE,
    history_depth=5,
    max_blocking_time_ms=0,  # Non-blocking
    latency_budget_ms=1,
    lifespan_ms=50
)

# Configuration data (late-joiner support)
CONFIG_QOS = DDSQoS(
    reliability=ReliabilityKind.RELIABLE,
    durability=DurabilityKind.TRANSIENT_LOCAL,
    history_depth=1,
    max_blocking_time_ms=1000,
    latency_budget_ms=100,
    lifespan_ms=0  # No expiration
)
```

#### DDS Topic Definition (IDL)

```idl
// OMG IDL for DDS topics
module automotive {
    module battery {

        struct BatteryStatus {
            unsigned long timestamp;    // Unix timestamp (ms)
            octet stateOfCharge;        // 0-100%
            float voltage;              // Volts
            float current;              // Amps
            char temperature;           // Celsius
            boolean charging;
        };

        struct BatteryAlarm {
            unsigned long timestamp;
            unsigned short alarmCode;
            string<256> description;
            octet severity;  // 0=Info, 1=Warning, 2=Error, 3=Critical
        };

    };
};
```

#### DDS Publisher/Subscriber (C++)

```cpp
#include <dds/dds.hpp>
#include "BatteryStatus.hpp"

using namespace automotive::battery;

class BatteryPublisher {
public:
    BatteryPublisher() {
        // Create DDS participant (one per application)
        participant_ = dds::domain::DomainParticipant(0);

        // Create topic
        topic_ = dds::topic::Topic<BatteryStatus>(
            participant_, "BatteryStatusTopic");

        // Create publisher with QoS
        dds::pub::qos::PublisherQos pub_qos;
        publisher_ = dds::pub::Publisher(participant_, pub_qos);

        // Create data writer
        dds::pub::qos::DataWriterQos writer_qos;
        writer_qos << SAFETY_QOS;  // Use safety QoS profile
        writer_ = dds::pub::DataWriter<BatteryStatus>(publisher_, topic_, writer_qos);
    }

    void publishStatus(uint8_t soc, float voltage, float current, int8_t temp) {
        BatteryStatus status;
        status.timestamp(std::chrono::system_clock::now().time_since_epoch().count());
        status.stateOfCharge(soc);
        status.voltage(voltage);
        status.current(current);
        status.temperature(temp);
        status.charging(current > 0);

        writer_.write(status);
    }

private:
    dds::domain::DomainParticipant participant_;
    dds::topic::Topic<BatteryStatus> topic_;
    dds::pub::Publisher publisher_;
    dds::pub::DataWriter<BatteryStatus> writer_;
};

class BatterySubscriber {
public:
    BatterySubscriber() {
        participant_ = dds::domain::DomainParticipant(0);
        topic_ = dds::topic::Topic<BatteryStatus>(
            participant_, "BatteryStatusTopic");

        dds::sub::qos::SubscriberQos sub_qos;
        subscriber_ = dds::sub::Subscriber(participant_, sub_qos);

        dds::sub::qos::DataReaderQos reader_qos;
        reader_qos << SAFETY_QOS;
        reader_ = dds::sub::DataReader<BatteryStatus>(subscriber_, topic_, reader_qos);

        // Register listener for data arrival
        reader_.listener(
            new BatteryStatusListener(),
            dds::core::status::StatusMask::data_available());
    }

private:
    class BatteryStatusListener : public dds::sub::NoOpDataReaderListener<BatteryStatus> {
    public:
        void on_data_available(dds::sub::DataReader<BatteryStatus>& reader) override {
            auto samples = reader.take();
            for (const auto& sample : samples) {
                if (sample.info().valid()) {
                    std::cout << "SOC: " << (int)sample.data().stateOfCharge() << "%"
                              << " Voltage: " << sample.data().voltage() << "V"
                              << std::endl;
                }
            }
        }
    };

    dds::domain::DomainParticipant participant_;
    dds::topic::Topic<BatteryStatus> topic_;
    dds::sub::Subscriber subscriber_;
    dds::sub::DataReader<BatteryStatus> reader_;
};
```

### 3. Service Discovery Mechanisms

#### Comparison

| Feature | SOME/IP-SD | DDS Discovery |
|---------|-----------|---------------|
| Transport | UDP multicast | UDP/TCP multicast + unicast |
| Discovery time | 1-3 seconds | <100ms |
| Overhead | Low (periodic offers) | Medium (SPDP + SEDP) |
| Dynamic reconfiguration | Yes | Yes |
| QoS negotiation | Limited | Extensive |
| Best for | AUTOSAR Adaptive | Complex data flows |

### 4. Event-Driven Architecture Patterns

```python
class EventBus:
    """
    Automotive event bus for service-oriented communication.
    Supports both SOME/IP and DDS backends.
    """

    def __init__(self, backend='someip'):
        self.backend = backend
        self.subscribers = {}

    def publish(self, topic, data, qos='reliable'):
        """
        Publish event to topic.

        Args:
            topic: Event topic name
            data: Event payload
            qos: 'reliable' or 'best_effort'
        """

        if self.backend == 'someip':
            # SOME/IP notification
            self._someip_notify(topic, data)
        elif self.backend == 'dds':
            # DDS publish
            self._dds_publish(topic, data, qos)

    def subscribe(self, topic, callback, qos='reliable'):
        """
        Subscribe to topic with callback.

        Args:
            topic: Topic name
            callback: Function to call on event
            qos: QoS requirements
        """

        if topic not in self.subscribers:
            self.subscribers[topic] = []

        self.subscribers[topic].append({
            'callback': callback,
            'qos': qos
        })

        if self.backend == 'someip':
            self._someip_subscribe(topic)
        elif self.backend == 'dds':
            self._dds_subscribe(topic, qos)

# Usage example:
bus = EventBus(backend='someip')

# Subscribe to battery alarms
bus.subscribe('battery/alarm', lambda alarm: print(f"Alarm: {alarm}"))

# Publish alarm event
bus.publish('battery/alarm', {
    'code': 0x1234,
    'severity': 'critical',
    'description': 'Over-temperature detected'
})
```

## Performance Characteristics

### SOME/IP
- **Latency**: 1-5ms (local), 10-50ms (remote)
- **Throughput**: Up to 100 Mbps per service
- **Overhead**: ~16 bytes header per message
- **Discovery time**: 1-3 seconds (configurable)

### DDS
- **Latency**: <1ms (local), 5-20ms (remote)
- **Throughput**: Up to 1 Gbps aggregate
- **Overhead**: ~20 bytes RTPS header
- **Discovery time**: <100ms

## Best Practices

1. **Use SOME/IP** for AUTOSAR Adaptive services, ECU-to-ECU communication
2. **Use DDS** for high-throughput sensor data, complex QoS requirements
3. **Choose UDP** for time-critical best-effort data (sensors)
4. **Choose TCP** for reliable control commands, configuration
5. **Minimize service interfaces** - Fewer, richer services better than many small ones
6. **Use service versioning** - Major version in service ID, minor in header

## Tools

- **Vector MICROSAR** - SOME/IP stack for AUTOSAR Classic/Adaptive
- **RTI Connext DDS** - High-performance DDS implementation
- **Eclipse Cyclone DDS** - Open-source DDS (used in ROS 2)
- **vsomeip** - Open-source SOME/IP implementation (BMW/GENIVI)
- **CommonAPI** - Language bindings for SOME/IP and DDS

## References

- AUTOSAR Specification of SOME/IP Protocol (PRS_SOMEIPPROTOCOL)
- OMG Data Distribution Service (DDS) Specification v1.4
- AUTOSAR Adaptive Platform R22-11
- SOME/IP Protocol Specification v1.3.0

---

## Zonal Architecture Design

# Zonal Architecture Design

**Category:** automotive-zonal
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Expert knowledge in designing next-generation vehicle E/E zonal architectures. Covers zone controller placement, domain consolidation, topology optimization, cable harness reduction strategies, and migration from traditional domain architectures to zonal designs.

## Core Competencies

### 1. Zone Controller Placement Strategy

#### Optimal Zone Count
Typical modern vehicles use **4-8 zones**:
- **4 zones**: Entry-level vehicles (FL, FR, RL, RR corners)
- **6 zones**: Mid-range (4 corners + front-center + rear-center)
- **8 zones**: Premium (4 corners + FC, RC, left-center, right-center)

**Placement Criteria:**
```python
class ZonePlacementOptimizer:
    def __init__(self, vehicle_model):
        self.vehicle = vehicle_model
        self.sensors = []
        self.actuators = []

    def optimize_zones(self, max_cable_length=2.0):
        """
        Optimize zone placement to minimize cable length.

        Args:
            max_cable_length: Maximum cable run in meters (default 2m)

        Returns:
            List of zone controller locations
        """
        from sklearn.cluster import KMeans
        import numpy as np

        # Get all sensor/actuator positions
        positions = np.array([
            [comp.x, comp.y, comp.z]
            for comp in self.sensors + self.actuators
        ])

        # Cluster to find optimal zone centers
        n_zones = self._estimate_zone_count(positions, max_cable_length)
        kmeans = KMeans(n_clusters=n_zones, random_state=42)
        kmeans.fit(positions)

        zones = []
        for i, center in enumerate(kmeans.cluster_centers_):
            zone = {
                'id': f'ZCU_{i+1}',
                'location': center.tolist(),
                'components': [],
                'cable_savings': 0.0
            }

            # Assign components to zones
            labels = kmeans.labels_
            zone_components = [
                comp for idx, comp in enumerate(self.sensors + self.actuators)
                if labels[idx] == i
            ]
            zone['components'] = zone_components
            zones.append(zone)

        return zones

    def _estimate_zone_count(self, positions, max_length):
        """Estimate optimal number of zones based on component density."""
        bbox = positions.max(axis=0) - positions.min(axis=0)
        vehicle_length = bbox[0]
        vehicle_width = bbox[1]

        # Coverage area per zone (circle of radius max_length)
        zone_coverage = np.pi * (max_length ** 2)
        vehicle_area = vehicle_length * vehicle_width

        return max(4, int(np.ceil(vehicle_area / zone_coverage)))
```

#### Zone Controller Hardware Selection

| Zone Type | Hardware Platform | Cost | Use Case |
|-----------|------------------|------|----------|
| **Low-cost Corner** | NXP S32K344 | $15-20 | Lighting, windows, mirrors |
| **Standard Zone** | Renesas RH850/U2A | $25-35 | Body control, HVAC, doors |
| **Gateway/Central** | NXP S32G274A | $80-120 | Ethernet switch, firewall, routing |
| **High-performance** | Infineon AURIX TC397 | $60-90 | ADAS integration, safety |

**Selection Decision Tree:**
```
Is zone safety-critical (ASIL-C/D)?
├─ Yes → AURIX TC397 (lockstep cores, ECC RAM)
└─ No → Does zone need Ethernet switching?
    ├─ Yes → S32G274A (4x Gb Ethernet, TSN)
    └─ No → Component count?
        ├─ <20 → S32K344 (low-cost)
        └─ >20 → RH850/U2A (more I/O)
```

### 2. Cable Harness Reduction

**Traditional Domain Architecture:**
```
Total cable length: 4,500 meters
Total weight: 45 kg
Cost: $450 per vehicle
```

**Zonal Architecture Benefits:**
```python
class CableHarnessAnalyzer:
    def calculate_savings(self, domain_arch, zonal_arch):
        """
        Calculate cable harness savings from domain-to-zonal migration.

        Returns:
            dict: Savings in length, weight, and cost
        """
        # Domain architecture stats
        domain_cables = {
            'sensor_to_ecu': 2800,  # meters
            'inter_ecu': 1200,
            'power_distribution': 500
        }

        # Zonal architecture stats
        zonal_cables = {
            'sensor_to_zone': 1500,  # <2m each, drastically shorter
            'zone_to_gateway': 150,  # Ethernet backbone only
            'power_distribution': 300  # Zonal PDUs
        }

        total_domain = sum(domain_cables.values())
        total_zonal = sum(zonal_cables.values())

        reduction_meters = total_domain - total_zonal
        reduction_percent = (reduction_meters / total_domain) * 100

        # Weight savings (0.01 kg/meter average)
        weight_savings = reduction_meters * 0.01  # kg

        # Cost savings ($0.10/meter cable + installation)
        cost_savings = reduction_meters * 0.15  # USD

        return {
            'cable_reduction_m': reduction_meters,
            'cable_reduction_pct': reduction_percent,
            'weight_savings_kg': weight_savings,
            'cost_savings_usd': cost_savings
        }

# Example output:
# {
#     'cable_reduction_m': 2550,
#     'cable_reduction_pct': 56.7%,
#     'weight_savings_kg': 25.5 kg,
#     'cost_savings_usd': $382.50
# }
```

**Actual OEM Results:**
- **VW MEB Platform**: 30% cable reduction
- **Tesla Model 3**: 1.5 km total harness (vs 3 km traditional)
- **Rivian R1T**: 40% weight reduction in harness

### 3. Network Topology Design

#### Topology Options

**A. Star Topology (Recommended for Safety)**
```
                    ┌─────────────┐
                    │   Gateway   │
                    │   S32G274   │
                    └──────┬──────┘
                           │
        ┌──────────────┬───┴───┬──────────────┐
        │              │       │              │
    ┌───┴───┐      ┌───┴───┐ ┌┴─────┐    ┌───┴───┐
    │ FL ZCU│      │ FR ZCU│ │RC ZCU│    │ RL ZCU│
    └───────┘      └───────┘ └──────┘    └───────┘

Pros:
+ Direct gateway connection (low latency)
+ Simple fault isolation
+ Easy TSN configuration
+ No cascading failures

Cons:
- More cable to gateway
- Single point of failure (mitigated with redundant gateway)
```

**B. Ring Topology (High Availability)**
```
    ┌─────────┐──────┐Gateway│──────┐─────────┐
    │         │      └────────┘      │         │
    │         │                      │         │
┌───┴───┐ ┌───┴───┐              ┌───┴───┐ ┌───┴───┐
│FL ZCU │ │FR ZCU │              │RR ZCU │ │RL ZCU │
└───────┘ └───────┘              └───────┘ └───────┘

Pros:
+ Redundant paths (fault tolerance)
+ Load balancing possible
+ Cable length optimization

Cons:
- Complex TSN configuration
- Potential for loops (need STP/RSTP)
```

**C. Daisy Chain (Cost-Optimized)**
```
┌────────┐    ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐
│Gateway │────│FL ZCU│────│FR ZCU│────│RR ZCU│────│RL ZCU│
└────────┘    └──────┘    └──────┘    └──────┘    └──────┘

Pros:
+ Minimal cable length
+ Lowest cost

Cons:
- Cascading failures
- Higher latency for distant zones
- Not suitable for safety-critical
```

#### Ethernet Physical Layer Selection

```c
// 100BASE-T1 Configuration (Standard zones)
struct ethernet_phy_config {
    uint8_t standard;        // 100BASE-T1
    uint16_t max_distance;   // 15 meters
    uint32_t bandwidth;      // 100 Mbps
    uint8_t pair_count;      // 1 twisted pair
    float cost_per_meter;    // $0.50
};

// 1000BASE-T1 Configuration (High-bandwidth zones - cameras, ADAS)
struct ethernet_phy_1g {
    uint8_t standard;        // 1000BASE-T1
    uint16_t max_distance;   // 40 meters
    uint32_t bandwidth;      // 1 Gbps
    uint8_t pair_count;      // 1 twisted pair
    float cost_per_meter;    // $0.80
};

// 10BASE-T1S Configuration (Low-cost multidrop sensors)
struct ethernet_phy_10base {
    uint8_t standard;        // 10BASE-T1S
    uint16_t max_distance;   // 25 meters (multidrop bus)
    uint32_t bandwidth;      // 10 Mbps
    uint8_t topology;        // Multidrop (up to 8 nodes per segment)
    float cost_per_meter;    // $0.30
};
```

### 4. Power Distribution Architecture

**Zonal Power Distribution Units (PDUs):**

```c
typedef struct {
    char zone_id[16];
    uint8_t num_power_rails;
    float voltage_12v;
    float voltage_5v;
    float voltage_3v3;
    uint8_t load_shedding_priority[8];  // 0=critical, 7=lowest
    bool intelligent_fusing;
} ZonalPDU_Config_t;

// Example: Front-Left Zone PDU
ZonalPDU_Config_t fl_pdu = {
    .zone_id = "FL_ZONE",
    .num_power_rails = 8,
    .voltage_12v = 12.0,
    .voltage_5v = 5.0,
    .voltage_3v3 = 3.3,
    .load_shedding_priority = {
        0,  // Headlights (critical)
        1,  // Turn signals (safety)
        2,  // DRL (legal requirement)
        5,  // Fog lights
        6,  // Puddle lights
        7,  // Ambient lighting
    },
    .intelligent_fusing = true
};

// Load shedding during low battery
void perform_load_shedding(ZonalPDU_Config_t *pdu, uint8_t battery_soc) {
    if (battery_soc < 20) {
        // Shed priority 7 loads (ambient lighting)
        disable_loads_by_priority(pdu, 7);
    }
    if (battery_soc < 10) {
        // Shed priority 6 loads (puddle lights)
        disable_loads_by_priority(pdu, 6);
    }
    if (battery_soc < 5) {
        // Shed priority 5 loads (fog lights)
        disable_loads_by_priority(pdu, 5);
        // Keep only priority 0-2 (critical/safety)
    }
}
```

**Power Budget per Zone:**
| Zone | Typical Power | Peak Power | Components |
|------|--------------|-----------|------------|
| FL Corner | 150W | 300W | Headlights, turn signals, window, mirror |
| FR Corner | 150W | 300W | Headlights, turn signals, window, mirror |
| RL Corner | 100W | 200W | Taillights, window |
| RR Corner | 100W | 200W | Taillights, window |
| Front Center | 200W | 400W | Wipers, HVAC blower, sensors |
| Rear Center | 80W | 150W | Trunk, license plate light |

### 5. Domain-to-Zonal Migration Strategy

**Phase 1: Hybrid Architecture (18-24 months)**
- Keep existing domain ECUs
- Add zone controllers for new sensors
- Use gateway to bridge domains and zones
- Validate zonal concept

**Phase 2: Partial Migration (24-36 months)**
- Migrate body domain to zonal
- Keep powertrain/ADAS domains
- 40-50% cable reduction achieved

**Phase 3: Full Zonal (36-48 months)**
- All functions on zone controllers
- Domain ECUs eliminated
- 50-60% cable reduction
- Central compute for ADAS/infotainment

```python
class MigrationPlanner:
    def create_migration_roadmap(self):
        """Generate phased migration from domain to zonal architecture."""

        phases = [
            {
                'phase': 1,
                'name': 'Hybrid Introduction',
                'duration_months': 18,
                'zones_added': ['FL', 'FR'],
                'functions_migrated': ['Lighting', 'Windows'],
                'cable_reduction': '15%',
                'cost': '$2M NRE',
                'risk': 'Low'
            },
            {
                'phase': 2,
                'name': 'Body Domain Migration',
                'duration_months': 24,
                'zones_added': ['RL', 'RR', 'FC', 'RC'],
                'functions_migrated': ['All body', 'HVAC', 'Doors'],
                'cable_reduction': '45%',
                'cost': '$5M NRE',
                'risk': 'Medium'
            },
            {
                'phase': 3,
                'name': 'Full Zonal',
                'duration_months': 36,
                'zones_added': ['LC', 'RC'],
                'functions_migrated': ['All functions'],
                'cable_reduction': '60%',
                'cost': '$8M NRE',
                'risk': 'High',
                'payback': '2.5 years at 100k units/year'
            }
        ]

        return phases
```

## ROI Calculation

**Per-Vehicle Savings:**
```
Cable harness reduction: $250
Weight reduction (fuel economy): $50/vehicle lifetime
Assembly time reduction: $100
Service diagnostics improvement: $30

Total savings: $430 per vehicle
```

**NRE Investment:**
```
Zone controller development: $3M
Software architecture: $2M
Testing & validation: $2M
Production tooling: $1M

Total NRE: $8M
```

**Payback Period:**
```
At 50,000 units/year:
$8M / ($430 × 50,000) = 0.37 years (4.5 months)

At 100,000 units/year:
Immediate positive ROI
```

## Best Practices

1. **Start with body domain** - Lowest safety criticality, highest cable savings
2. **Use star topology** for safety-critical zones
3. **Implement intelligent power management** - Load shedding, priority-based
4. **Plan for redundancy** - Dual Ethernet links to gateway
5. **Use TSN** for deterministic latency (<10ms p99)
6. **Leverage 10BASE-T1S** for low-cost sensors (multidrop)
7. **Plan thermal management** - Zone controllers generate more heat than distributed ECUs

## Tools & Frameworks

- **Capital Harness Designer** - Cable routing and optimization
- **PREEvision** - E/E architecture design
- **SystemDesk** - AUTOSAR Adaptive configuration
- **Vector CANoe** - Network simulation and testing

## References

- VDA Recommendation on Zonal E/E Architecture
- IEEE 802.1 TSN Standards
- AUTOSAR Adaptive Platform R22-11
- SAE J3161 On-Board Ethernet Communication

---

## Zone Controller Development

# Zone Controller Development

**Category:** automotive-zonal
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Expert knowledge in developing zone controller firmware and software for next-generation zonal E/E architectures. Covers hardware platforms (NXP S32K3, Renesas RH850, Infineon AURIX), I/O handling, sensor aggregation, actuator control, gateway functions, and AUTOSAR integration.

## Core Competencies

### 1. Zone Controller Hardware Platforms

#### NXP S32K3 (Entry to Mid-Range)

**S32K344 Specifications:**
```c
// NXP S32K344 - Low-cost zone controller
typedef struct {
    char model[32];
    struct {
        char core[16];          // ARM Cortex-M7
        uint32_t frequency_mhz; // 160 MHz
        uint8_t cores;          // 1
        bool lockstep;          // No (QM)
    } cpu;

    struct {
        uint32_t flash_kb;      // 4096 KB
        uint32_t ram_kb;        // 512 KB
        bool ecc;               // Optional
    } memory;

    struct {
        uint8_t can_fd;         // 6x CAN-FD
        uint8_t lin;            // 3x LIN
        uint8_t ethernet_100m;  // 1x 100BASE-T1
        uint8_t spi;            // 4x SPI
        uint8_t i2c;            // 2x I2C
    } communication;

    struct {
        uint8_t adc_12bit;      // 3x ADC (12-bit)
        uint8_t pwm_channels;   // 32x eMIOS PWM
        uint8_t gpio;           // 144 GPIO
    } io;

    uint8_t asil_rating;        // ASIL-B capable
    float cost_usd;             // $18-22
} S32K344_Spec_t;
```

**Use Cases:**
- Corner zones (FL, FR, RL, RR)
- Lighting control
- Window/mirror control
- Low-complexity body functions

#### Renesas RH850/U2A (Mid-Range)

**RH850/U2A8 Specifications:**
```c
// Renesas RH850/U2A8 - Standard zone controller
typedef struct {
    char model[32];
    struct {
        char core[16];          // RH850 G4MH
        uint32_t frequency_mhz; // 320 MHz
        uint8_t cores;          // 2 (lockstep option)
        bool lockstep;          // Yes (ASIL-D)
    } cpu;

    struct {
        uint32_t flash_kb;      // 8192 KB
        uint32_t ram_kb;        // 1024 KB
        bool ecc;               // Yes
    } memory;

    struct {
        uint8_t can_fd;         // 8x CAN-FD
        uint8_t lin;            // 8x LIN
        uint8_t ethernet_100m;  // 2x 100BASE-T1
        uint8_t flexray;        // 2x FlexRay
    } communication;

    struct {
        uint8_t adc_12bit;      // 4x ADC (12-bit)
        uint8_t pwm_channels;   // 48x PWM
        uint8_t gpio;           // 200+ GPIO
    } io;

    uint8_t asil_rating;        // ASIL-D
    float cost_usd;             // $28-35
} RH850_U2A8_Spec_t;
```

**Use Cases:**
- Front-center zone (HVAC, wipers)
- Rear-center zone (trunk, tailgate)
- Body domain consolidation
- HVAC control

#### Infineon AURIX TC397 (High-Performance)

**TC397 Specifications:**
```c
// Infineon AURIX TC397 - High-performance safety zone
typedef struct {
    char model[32];
    struct {
        char core[16];          // TriCore 1.8
        uint32_t frequency_mhz; // 300 MHz
        uint8_t cores;          // 3 lockstep pairs (6 total)
        bool lockstep;          // Yes (all cores)
    } cpu;

    struct {
        uint32_t flash_kb;      // 16384 KB
        uint32_t ram_kb;        // 1536 KB
        bool ecc;               // Yes (all memories)
    } memory;

    struct {
        uint8_t can_fd;         // 12x CAN-FD
        uint8_t lin;            // 4x LIN
        uint8_t ethernet_1g;    // 1x 1000BASE-T1
        uint8_t flexray;        // 2x FlexRay
    } communication;

    struct {
        uint8_t adc_12bit;      // 8x ADC (12-bit)
        uint8_t pwm_channels;   // 64x GTM PWM
        uint8_t gpio;           // 300+ GPIO
        bool hss_drivers;       // High-side switches
        bool lss_drivers;       // Low-side switches
    } io;

    uint8_t asil_rating;        // ASIL-D
    float cost_usd;             // $65-90
} TC397_Spec_t;
```

**Use Cases:**
- Gateway/central controller
- Safety-critical zones
- ADAS integration point
- Complex control algorithms

### 2. Zone Controller Firmware Architecture

```c
// Zone Controller Application Structure
typedef struct {
    char zone_id[16];           // "FL_ZONE", "FR_ZONE", etc.
    uint8_t hardware_platform;  // S32K3, RH850, AURIX
    uint8_t asil_rating;        // QM, ASIL-A/B/C/D

    // I/O Configuration
    struct {
        uint8_t num_digital_inputs;
        uint8_t num_digital_outputs;
        uint8_t num_analog_inputs;
        uint8_t num_pwm_outputs;
        uint8_t num_lin_slaves;
    } io_config;

    // Communication
    struct {
        bool ethernet_enabled;
        uint8_t can_channels;
        uint8_t lin_channels;
        uint16_t someip_port;
    } comm_config;

    // Functions
    void (*init)(void);
    void (*cyclic_10ms)(void);
    void (*cyclic_100ms)(void);
    void (*handle_ethernet_rx)(uint8_t* data, uint16_t len);
    void (*handle_lin_frame)(uint8_t node, uint8_t* data);
} ZoneController_t;

// Example: Front-Left Zone Controller
ZoneController_t fl_zone = {
    .zone_id = "FL_ZONE",
    .hardware_platform = HW_S32K344,
    .asil_rating = ASIL_B,

    .io_config = {
        .num_digital_inputs = 20,   // Door switches, buttons
        .num_digital_outputs = 12,  // Relays, LEDs
        .num_analog_inputs = 4,     // Temperature sensors
        .num_pwm_outputs = 8,       // Headlight dimming, motor control
        .num_lin_slaves = 4         // Window motor, mirror motors
    },

    .comm_config = {
        .ethernet_enabled = true,
        .can_channels = 2,          // CAN1: vehicle bus, CAN2: diagnostics
        .lin_channels = 2,          // LIN1: windows, LIN2: mirrors
        .someip_port = 30500
    },

    .init = FL_Zone_Init,
    .cyclic_10ms = FL_Zone_Cyclic10ms,
    .cyclic_100ms = FL_Zone_Cyclic100ms,
    .handle_ethernet_rx = FL_Zone_EthernetRx,
    .handle_lin_frame = FL_Zone_LinRx
};
```

### 3. Sensor Aggregation

```c
// Sensor Aggregation for Zone Controller
typedef struct {
    uint32_t timestamp_ms;
    float value;
    uint8_t quality;  // 0=Invalid, 1=Questionable, 2=Good, 3=Excellent
    uint8_t source;   // Sensor ID
} SensorValue_t;

typedef struct {
    char sensor_name[32];
    uint8_t num_sources;        // Number of redundant sensors
    SensorValue_t values[4];    // Up to 4 redundant sources
    float fused_value;          // Fused result
    uint8_t fusion_algorithm;   // AVERAGE, MEDIAN, VOTER, KALMAN
} SensorAggregator_t;

// Sensor fusion algorithms
float sensor_fusion_average(SensorAggregator_t* agg) {
    float sum = 0.0;
    uint8_t count = 0;

    for (uint8_t i = 0; i < agg->num_sources; i++) {
        if (agg->values[i].quality >= 2) {  // Good or Excellent
            sum += agg->values[i].value;
            count++;
        }
    }

    return (count > 0) ? (sum / count) : 0.0;
}

float sensor_fusion_median(SensorAggregator_t* agg) {
    float sorted[4];
    uint8_t count = 0;

    // Copy valid values
    for (uint8_t i = 0; i < agg->num_sources; i++) {
        if (agg->values[i].quality >= 2) {
            sorted[count++] = agg->values[i].value;
        }
    }

    if (count == 0) return 0.0;

    // Bubble sort
    for (uint8_t i = 0; i < count - 1; i++) {
        for (uint8_t j = 0; j < count - i - 1; j++) {
            if (sorted[j] > sorted[j + 1]) {
                float temp = sorted[j];
                sorted[j] = sorted[j + 1];
                sorted[j + 1] = temp;
            }
        }
    }

    // Return median
    if (count % 2 == 0) {
        return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0;
    } else {
        return sorted[count / 2];
    }
}

// 2-out-of-3 voter
float sensor_fusion_voter(SensorAggregator_t* agg) {
    if (agg->num_sources < 2) return agg->values[0].value;

    // Check if any two sensors agree within tolerance
    const float tolerance = 0.05;  // 5% tolerance

    for (uint8_t i = 0; i < agg->num_sources - 1; i++) {
        for (uint8_t j = i + 1; j < agg->num_sources; j++) {
            float diff = fabs(agg->values[i].value - agg->values[j].value);
            float avg = (agg->values[i].value + agg->values[j].value) / 2.0;

            if (diff / avg < tolerance) {
                return avg;  // Two sensors agree
            }
        }
    }

    // No agreement - use sensor with best quality
    uint8_t best_idx = 0;
    for (uint8_t i = 1; i < agg->num_sources; i++) {
        if (agg->values[i].quality > agg->values[best_idx].quality) {
            best_idx = i;
        }
    }

    return agg->values[best_idx].value;
}

// Example: Temperature sensor aggregation
SensorAggregator_t temp_sensor = {
    .sensor_name = "AmbientTemperature",
    .num_sources = 3,
    .values = {
        {.timestamp_ms = 1000, .value = 23.5, .quality = 3, .source = 1},
        {.timestamp_ms = 1000, .value = 23.7, .quality = 3, .source = 2},
        {.timestamp_ms = 1000, .value = 23.6, .quality = 2, .source = 3}
    },
    .fusion_algorithm = FUSION_MEDIAN
};

// Perform fusion
temp_sensor.fused_value = sensor_fusion_median(&temp_sensor);
// Result: 23.6°C
```

### 4. Actuator Control

```c
// PWM-based actuator control (e.g., headlight dimming)
typedef struct {
    char actuator_name[32];
    uint8_t pwm_channel;
    uint16_t frequency_hz;      // PWM frequency
    uint8_t duty_cycle;         // 0-100%
    bool enabled;
} PWM_Actuator_t;

void set_headlight_brightness(PWM_Actuator_t* headlight, uint8_t brightness_pct) {
    // Limit to valid range
    if (brightness_pct > 100) brightness_pct = 100;

    headlight->duty_cycle = brightness_pct;

    // Update hardware PWM register (example for S32K3)
    eMIOS_SetDutyCycle(headlight->pwm_channel, brightness_pct);
}

// LIN-based actuator control (e.g., window motor)
typedef struct {
    uint8_t lin_channel;
    uint8_t node_address;
    enum {
        WINDOW_STOP = 0,
        WINDOW_UP = 1,
        WINDOW_DOWN = 2
    } command;
    uint8_t position_pct;       // 0=closed, 100=fully open
} LIN_WindowMotor_t;

void control_window(LIN_WindowMotor_t* window, uint8_t target_position) {
    uint8_t lin_frame[8];

    // Build LIN frame
    lin_frame[0] = window->node_address;
    lin_frame[1] = (target_position > window->position_pct) ? WINDOW_UP : WINDOW_DOWN;
    lin_frame[2] = target_position;

    // Send LIN frame
    LIN_SendFrame(window->lin_channel, lin_frame, 3);

    // Update state
    window->position_pct = target_position;
}
```

### 5. Gateway Functions

```c
// Gateway functionality (message routing, filtering, security)
typedef struct {
    uint8_t src_network;    // CAN, LIN, Ethernet
    uint8_t dst_network;
    uint32_t msg_id;        // CAN ID or SOME/IP service ID
    bool translate;         // Needs translation (CAN<->Ethernet)
    bool secure;            // Requires MACsec/authentication
} GatewayRoute_t;

// Routing table
GatewayRoute_t routing_table[] = {
    // CAN → Ethernet
    {.src_network = NET_CAN1, .dst_network = NET_ETH, .msg_id = 0x123, .translate = true, .secure = false},
    // Ethernet → CAN
    {.src_network = NET_ETH, .dst_network = NET_CAN2, .msg_id = 0x12340001, .translate = true, .secure = true},
    // LIN → Ethernet
    {.src_network = NET_LIN1, .dst_network = NET_ETH, .msg_id = 0x3C, .translate = true, .secure = false}
};

void gateway_route_message(uint8_t src_net, uint32_t msg_id, uint8_t* data, uint16_t len) {
    // Find routing rule
    for (uint8_t i = 0; i < sizeof(routing_table) / sizeof(GatewayRoute_t); i++) {
        if (routing_table[i].src_network == src_net &&
            routing_table[i].msg_id == msg_id) {

            if (routing_table[i].translate) {
                // Translate message format
                if (src_net == NET_CAN1 && routing_table[i].dst_network == NET_ETH) {
                    translate_can_to_someip(msg_id, data, len);
                } else if (src_net == NET_ETH && routing_table[i].dst_network == NET_CAN1) {
                    translate_someip_to_can(msg_id, data, len);
                }
            }

            if (routing_table[i].secure) {
                // Apply security (MACsec, authentication)
                apply_security(data, len);
            }

            // Forward to destination network
            forward_message(routing_table[i].dst_network, data, len);
            break;
        }
    }
}
```

### 6. AUTOSAR Integration

```c
// AUTOSAR Classic BSW configuration for zone controller
// RTE (Runtime Environment) configuration

// Sender-Receiver Interface
Rte_Write_HeadlightBrightness(uint8_t brightness) {
    // Implemented by RTE generator
    // Routes to SOME/IP or CAN
}

Rte_Read_DoorStatus(boolean* isOpen) {
    // Read from sensor via RTE
    *isOpen = gpio_read(DOOR_SWITCH_PIN);
    return RTE_E_OK;
}

// Cyclic runnable (10ms task)
void Zone_Controller_10ms_Runnable(void) {
    boolean door_open;
    uint8_t brightness;

    // Read inputs
    Rte_Read_DoorStatus(&door_open);

    // Control logic
    if (door_open) {
        brightness = 100;  // Full brightness when door open
    } else {
        brightness = get_adaptive_brightness();  // Adaptive based on ambient light
    }

    // Write outputs
    Rte_Write_HeadlightBrightness(brightness);
}
```

## Performance Targets

| Function | Cycle Time | CPU Load | Memory |
|----------|-----------|----------|--------|
| I/O scan | 10 ms | <5% | 10 KB |
| Sensor aggregation | 100 ms | <10% | 20 KB |
| Gateway routing | <1 ms | <15% | 50 KB |
| SOME/IP handling | Event-driven | <20% | 100 KB |
| Safety monitoring | 10 ms | <10% | 30 KB |

## Tools & Development Environment

- **NXP S32 Design Studio** - IDE for S32K3 development
- **Renesas CS+ / e² studio** - IDE for RH850 development
- **Infineon AURIX Development Studio** - IDE for TC397
- **Vector DaVinci Configurator** - AUTOSAR BSW configuration
- **EB tresos Studio** - AUTOSAR configuration (Elektrobit)
- **PCAN-View** - CAN/LIN debugging
- **Wireshark** - Ethernet debugging

## References

- NXP S32K3 Reference Manual
- Renesas RH850/U2A User's Manual
- Infineon AURIX TC3xx User Manual
- AUTOSAR Adaptive Platform R22-11
- LIN Specification 2.2A
