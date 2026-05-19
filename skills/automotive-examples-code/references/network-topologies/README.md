# Multi-ECU Network Topology Examples

Complete working examples of automotive network topologies for HIL/SIL testing.

## Overview

This directory contains ready-to-use network topologies for automotive ECU simulation and testing.

## Topology: 3-ECU Gateway with Hybrid CAN/Ethernet

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Host System                          │
│                                                             │
│  ┌──────────────┐              ┌──────────────┐           │
│  │  vcan0       │              │  vcan1       │           │
│  │  CAN Bus 0   │              │  CAN Bus 1   │           │
│  └──────────────┘              └──────────────┘           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │         CAN Domain Network (172.20.0.0/16)          │  │
│  │                  br-can bridge                       │  │
│  │                                                      │  │
│  │  ┌──────────────┐  ┌──────────────┐                │  │
│  │  │ Powertrain   │  │    Body      │                │  │
│  │  │     ECU      │  │     ECU      │                │  │
│  │  │ 172.20.0.20  │  │ 172.20.0.30  │                │  │
│  │  └──────┬───────┘  └──────┬───────┘                │  │
│  │         │                  │                         │  │
│  │         └────────┬─────────┘                         │  │
│  │                  │                                    │  │
│  │         ┌────────┴─────────┐                         │  │
│  │         │   Gateway ECU    │                         │  │
│  │         │  172.20.0.10     │                         │  │
│  │         │  192.168.100.10  │                         │  │
│  │         └────────┬─────────┘                         │  │
│  └──────────────────┼──────────────────────────────────┘  │
│                     │                                      │
│  ┌──────────────────┼──────────────────────────────────┐  │
│  │                  │                                   │  │
│  │         ┌────────┴─────────┐                         │  │
│  │         │                  │                         │  │
│  │  ┌──────┴────────┐  ┌──────┴──────┐                │  │
│  │  │     ADAS      │  │ Infotainment│                │  │
│  │  │      ECU      │  │     ECU     │                │  │
│  │  │ 192.168.100.20│  │192.168.100.30│               │  │
│  │  └───────────────┘  └─────────────┘                │  │
│  │                                                      │  │
│  │      Ethernet Domain Network (192.168.100.0/24)     │  │
│  │                  br-eth bridge                       │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### ECU Descriptions

| ECU | Domain | IP Address | Purpose |
|-----|--------|------------|---------|
| Gateway ECU | Both | 172.20.0.10 / 192.168.100.10 | Routes between CAN and Ethernet |
| Powertrain ECU | CAN | 172.20.0.20 | BMS, Motor Controller |
| Body ECU | CAN | 172.20.0.30 | Lighting, HVAC, Doors |
| ADAS ECU | Ethernet | 192.168.100.20 | Camera, Radar processing |
| Infotainment ECU | Ethernet | 192.168.100.30 | HMI, Audio, Connectivity |

## Prerequisites

### Host System Setup

```bash
# Install Docker and Docker Compose
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Create vcan interfaces on host
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
sudo ip link add dev vcan1 type vcan
sudo ip link set up vcan1

# Make vcan persistent (optional)
echo "vcan" | sudo tee -a /etc/modules
cat << 'EOF' | sudo tee /etc/network/interfaces.d/vcan
auto vcan0
iface vcan0 inet manual
    pre-up /sbin/ip link add dev vcan0 type vcan
    up /sbin/ip link set up vcan0

auto vcan1
iface vcan1 inet manual
    pre-up /sbin/ip link add dev vcan1 type vcan
    up /sbin/ip link set up vcan1
EOF
```

### Install CAN Tools (Optional)

```bash
# For CAN testing
sudo apt-get install can-utils

# Test vcan
cansend vcan0 123#DEADBEEF
candump vcan0
```

## Quick Start

### 1. Start the Topology

```bash
cd examples/network-topologies

# Start all ECUs
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 2. Verify Connectivity

```bash
# Test CAN domain connectivity
docker exec powertrain-ecu ping -c 3 172.20.0.10
docker exec body-ecu ping -c 3 172.20.0.10

# Test Ethernet domain connectivity
docker exec adas-ecu ping -c 3 192.168.100.10
docker exec infotainment-ecu ping -c 3 192.168.100.10

# Test cross-domain routing (through gateway)
docker exec powertrain-ecu ping -c 3 192.168.100.20
docker exec adas-ecu ping -c 3 172.20.0.20
```

### 3. Interact with ECUs

```bash
# Enter ECU shell
docker exec -it gateway-ecu sh

# From inside gateway ECU:
# - Check interfaces
ip addr show

# - Check routing
ip route show

# - Monitor traffic
tcpdump -i eth0 -n

# Exit
exit
```

## Advanced Usage

### Monitor Network Traffic

```bash
# Monitor traffic on host
sudo tcpdump -i br-can -n
sudo tcpdump -i br-eth -n

# Monitor specific ECU traffic
docker exec gateway-ecu tcpdump -i eth0 -n

# Capture to file
docker exec gateway-ecu tcpdump -i eth0 -w /tmp/capture.pcap -n
docker cp gateway-ecu:/tmp/capture.pcap ./gateway-capture.pcap

# Analyze with Wireshark
wireshark gateway-capture.pcap
```

### CAN Bus Communication

```bash
# Send CAN frame from host to vcan0
cansend vcan0 123#1122334455667788

# Listen from powertrain ECU (requires can-utils in container)
docker exec powertrain-ecu sh -c "
  apk add --no-cache can-utils &&
  candump vcan0
"

# Generate CAN traffic
cangen vcan0 -g 100 -I 100 -L 8
```

### Network Performance Testing

```bash
# Install iperf3 in containers
docker exec adas-ecu apk add --no-cache iperf3
docker exec infotainment-ecu apk add --no-cache iperf3

# Start iperf3 server on ADAS ECU
docker exec -d adas-ecu iperf3 -s

# Run iperf3 client from Infotainment ECU
docker exec infotainment-ecu iperf3 -c 192.168.100.20 -t 10
```

### Simulate Network Conditions

```bash
# Add latency to gateway ECU
docker exec gateway-ecu sh -c "
  tc qdisc add dev eth0 root netem delay 10ms
"

# Add packet loss
docker exec gateway-ecu sh -c "
  tc qdisc add dev eth1 root netem loss 2%
"

# Remove traffic shaping
docker exec gateway-ecu sh -c "
  tc qdisc del dev eth0 root
  tc qdisc del dev eth1 root
"
```

### Custom ECU Scripts

Create scripts in `ecu-scripts/` directory and they will be available in all containers at `/scripts/`.

```bash
mkdir -p ecu-scripts

# Create test script
cat > ecu-scripts/test-connectivity.sh << 'EOF'
#!/bin/sh
echo "Testing connectivity from $(hostname)..."
ping -c 3 172.20.0.10 && echo "CAN Gateway: OK"
ping -c 3 192.168.100.10 && echo "ETH Gateway: OK"
EOF

chmod +x ecu-scripts/test-connectivity.sh

# Run from ECU
docker exec powertrain-ecu /scripts/test-connectivity.sh
```

## Topology Variants

### Simple 2-ECU Topology

```bash
# Create simple topology
cat > docker-compose-simple.yml << 'EOF'
version: '3.8'
services:
  ecu1:
    image: alpine:latest
    container_name: ecu1
    networks:
      auto-net:
        ipv4_address: 192.168.100.11
    command: tail -f /dev/null

  ecu2:
    image: alpine:latest
    container_name: ecu2
    networks:
      auto-net:
        ipv4_address: 192.168.100.12
    command: tail -f /dev/null

networks:
  auto-net:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24
EOF

docker-compose -f docker-compose-simple.yml up -d
```

### Complex 7-ECU Topology

See `docker-compose-complex.yml` for a full vehicle architecture simulation with:
- Gateway ECU
- Powertrain ECUs (BMS, Motor Controller)
- Chassis ECUs (ABS, ESC)
- Body ECUs (BCM, HVAC)
- ADAS ECUs (Camera, Radar)
- Infotainment ECU
- Telematics ECU

## Testing Scenarios

### Scenario 1: DoIP Diagnostics

```bash
# Start DoIP server on Gateway ECU
docker exec gateway-ecu sh -c "
  apk add --no-cache python3 &&
  python3 -c '
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind((\"0.0.0.0\", 13400))
s.listen(1)
print(\"DoIP server listening on port 13400\")
while True:
    conn, addr = s.accept()
    print(f\"Connection from {addr}\")
    conn.close()
' &
"

# Test DoIP connection from ADAS ECU
docker exec adas-ecu sh -c "
  apk add --no-cache netcat-openbsd &&
  nc -zv 192.168.100.10 13400
"
```

### Scenario 2: SOME/IP Service Discovery

```bash
# Enable multicast on bridge
sudo ip link set br-eth multicast on

# Monitor SOME/IP SD multicast (224.244.224.245:30490)
docker exec adas-ecu tcpdump -i eth0 -n 'udp port 30490 and dst 224.244.224.245'
```

### Scenario 3: Gateway Routing Test

```bash
# Test routing from CAN domain to Ethernet domain
docker exec powertrain-ecu sh -c "
  echo 'Testing cross-domain routing...'
  ping -c 5 192.168.100.20
"

# Monitor on gateway
docker exec gateway-ecu tcpdump -i eth0 -n icmp
```

## Troubleshooting

### ECUs Cannot Communicate

```bash
# Check container status
docker-compose ps

# Check network configuration
docker network inspect network-topologies_can-domain
docker network inspect network-topologies_eth-domain

# Check routing in gateway
docker exec gateway-ecu ip route show

# Check IP forwarding
docker exec gateway-ecu sysctl net.ipv4.ip_forward

# Enable IP forwarding if needed
docker exec gateway-ecu sysctl -w net.ipv4.ip_forward=1
```

### vcan Not Available

```bash
# Check if vcan module is loaded
lsmod | grep vcan

# Load vcan module
sudo modprobe vcan

# Create vcan interface
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

### Docker Network Issues

```bash
# Remove and recreate networks
docker-compose down
docker network prune -f
docker-compose up -d

# Check Docker daemon
sudo systemctl status docker

# Check Docker logs
sudo journalctl -u docker -f
```

## Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove networks
docker network prune -f

# Remove vcan interfaces (optional)
sudo ip link delete vcan0
sudo ip link delete vcan1
```

## Integration with Test Frameworks

### Python-CAN Integration

```python
# test_can_communication.py
import can
import time

# Connect to vcan0
bus = can.interface.Bus(channel='vcan0', bustype='socketcan')

# Send message
msg = can.Message(
    arbitration_id=0x123,
    data=[0x11, 0x22, 0x33, 0x44],
    is_extended_id=False
)
bus.send(msg)

# Receive messages with timeout
message = bus.recv(timeout=1.0)
if message:
    print(f"Received: {message}")

bus.shutdown()
```

### Robot Framework Integration

```robot
*** Settings ***
Library    Process
Library    String

*** Test Cases ***
Test ECU Connectivity
    ${result}=    Run Process    docker    exec    powertrain-ecu    ping    -c    3    172.20.0.10
    Should Contain    ${result.stdout}    3 packets received
    Log    Powertrain ECU can reach Gateway

Test Cross Domain Routing
    ${result}=    Run Process    docker    exec    powertrain-ecu    ping    -c    3    192.168.100.20
    Should Contain    ${result.stdout}    3 packets received
    Log    CAN domain can reach Ethernet domain through Gateway
```

## Next Steps

- Explore the [Virtual Networking Guide](/docs/VIRTUAL_NETWORKING_GUIDE.md)
- Use the [setup script](/scripts/setup-virtual-networks.sh) for non-Docker topologies
- Try the [Python adapter](/tools/adapters/network/virtual_network_adapter.py)
- Review [virtual-ethernet skills](/skills/network/virtual-ethernet.yaml)

## References

- [Docker Networking](https://docs.docker.com/network/)
- [Linux Network Namespaces](https://man7.org/linux/man-pages/man8/ip-netns.8.html)
- [SocketCAN](https://www.kernel.org/doc/html/latest/networking/can.html)
- [Automotive Ethernet](https://opensig.org/automotive-ethernet/)
