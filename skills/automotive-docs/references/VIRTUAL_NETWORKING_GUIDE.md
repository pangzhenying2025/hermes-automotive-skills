# Virtual Networking Guide for Automotive Testing

Complete guide to setting up virtual networks for HIL/SIL automotive testing using veth pairs, network namespaces, bridges, and virtual CAN interfaces.

## Table of Contents

- [Overview](#overview)
- [Virtual Ethernet (veth)](#virtual-ethernet-veth)
- [Virtual CAN (vcan)](#virtual-can-vcan)
- [TAP/TUN Interfaces](#taptun-interfaces)
- [Network Namespaces](#network-namespaces)
- [Bridge Networks](#bridge-networks)
- [Traffic Shaping](#traffic-shaping)
- [Multi-ECU Topologies](#multi-ecu-topologies)
- [Docker Integration](#docker-integration)
- [QEMU Integration](#qemu-integration)
- [Automotive Protocols](#automotive-protocols)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

Virtual networking enables software-in-the-loop (SIL) and hardware-in-the-loop (HIL) testing without physical hardware. This guide covers:

- **veth pairs**: Virtual Ethernet point-to-point links
- **vcan**: Virtual CAN bus interfaces
- **TAP/TUN**: Virtual network devices for userspace programs
- **Network namespaces**: Isolated network stacks for ECU simulation
- **Bridges**: Virtual switches for multi-ECU connectivity
- **Traffic shaping**: Realistic network conditions simulation

### Use Cases

1. **ECU Software Testing**: Test ECU software without hardware
2. **Integration Testing**: Multi-ECU communication testing
3. **Protocol Validation**: DoIP, SOME/IP, UDS testing
4. **Gateway Testing**: CAN-to-Ethernet gateway validation
5. **Network Stress Testing**: Simulate packet loss, latency, jitter
6. **CI/CD Integration**: Automated testing in containers

## Virtual Ethernet (veth)

### Basic Concepts

veth (Virtual Ethernet) devices are always created in pairs. Traffic sent to one end appears at the other end.

### Creating veth Pairs

```bash
# Create veth pair
ip link add veth0 type veth peer name veth1

# Bring interfaces up
ip link set veth0 up
ip link set veth1 up

# Assign IP addresses
ip addr add 192.168.100.1/24 dev veth0
ip addr add 192.168.100.2/24 dev veth1

# Test connectivity
ping -c 3 192.168.100.2
```

### ECU Simulation Example

```bash
# Create veth pair for ECU simulation
ip link add ecu1-eth type veth peer name host-ecu1

# Configure ECU side
ip addr add 172.16.1.10/24 dev ecu1-eth
ip link set ecu1-eth up

# Configure host side
ip addr add 172.16.1.1/24 dev host-ecu1
ip link set host-ecu1 up

# Test connection
ping -c 3 172.16.1.10
```

### Multiple veth Pairs

```bash
# Create multiple ECU connections
for i in 1 2 3; do
  ip link add ecu$i-eth type veth peer name host-ecu$i
  ip addr add 172.16.$i.10/24 dev ecu$i-eth
  ip addr add 172.16.$i.1/24 dev host-ecu$i
  ip link set ecu$i-eth up
  ip link set host-ecu$i up
done
```

## Virtual CAN (vcan)

### Setup vcan Interface

```bash
# Load vcan kernel module
sudo modprobe vcan

# Create vcan interface
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Verify
ip link show vcan0
```

### Multiple vcan Interfaces

```bash
# Create multiple CAN buses
for i in 0 1 2; do
  ip link add dev vcan$i type vcan
  ip link set up vcan$i
done

# List CAN interfaces
ip link show type vcan
```

### Testing vcan with can-utils

```bash
# Install can-utils
sudo apt-get install can-utils

# Send CAN frame
cansend vcan0 123#DEADBEEF

# Receive CAN frames (in another terminal)
candump vcan0

# Generate CAN traffic
cangen vcan0 -g 10 -I 123 -L 8

# Log CAN traffic
canlogserver -a vcan0 -s /tmp/can.log
```

### Python vcan Example

```python
import can
import time

# Create CAN bus
bus = can.interface.Bus(channel='vcan0', bustype='socketcan')

# Send message
msg = can.Message(
    arbitration_id=0x123,
    data=[0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x00, 0x00, 0x00],
    is_extended_id=False
)
bus.send(msg)

# Receive messages
for message in bus:
    print(f"Received: {message}")
    break

bus.shutdown()
```

## TAP/TUN Interfaces

### Creating TAP Interface

TAP operates at Layer 2 (Ethernet frames), TUN at Layer 3 (IP packets).

```bash
# Create TAP interface
sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up
sudo ip addr add 192.168.150.1/24 dev tap0

# Create with specific user
sudo ip tuntap add dev tap0 mode tap user $USER
sudo ip link set tap0 up

# Delete TAP interface
sudo ip tuntap del dev tap0 mode tap
```

### TAP for QEMU VMs

```bash
# Create TAP for VM
sudo ip tuntap add dev tap-vm0 mode tap user $USER
sudo ip link set tap-vm0 up

# Add to bridge for VM connectivity
sudo ip link add br-vm type bridge
sudo ip link set br-vm up
sudo ip link set tap-vm0 master br-vm
sudo ip addr add 192.168.122.1/24 dev br-vm

# Launch QEMU with TAP
qemu-system-x86_64 \
  -netdev tap,id=net0,ifname=tap-vm0,script=no,downscript=no \
  -device e1000,netdev=net0 \
  -drive file=disk.qcow2 \
  -m 2G
```

## Network Namespaces

Network namespaces provide isolated network stacks, perfect for ECU simulation.

### Basic Namespace Operations

```bash
# Create namespace
sudo ip netns add ecu1

# List namespaces
ip netns list

# Execute command in namespace
sudo ip netns exec ecu1 ip addr show

# Run shell in namespace
sudo ip netns exec ecu1 bash

# Delete namespace
sudo ip netns delete ecu1
```

### ECU in Namespace

```bash
# Create namespace for ECU
sudo ip netns add gateway-ecu

# Create veth pair
sudo ip link add veth-gw type veth peer name veth-host

# Move one end to namespace
sudo ip link set veth-gw netns gateway-ecu

# Configure interface in namespace
sudo ip netns exec gateway-ecu ip addr add 192.168.50.1/24 dev veth-gw
sudo ip netns exec gateway-ecu ip link set veth-gw up
sudo ip netns exec gateway-ecu ip link set lo up

# Configure host side
sudo ip addr add 192.168.50.10/24 dev veth-host
sudo ip link set veth-host up

# Test from namespace
sudo ip netns exec gateway-ecu ping -c 3 192.168.50.10
```

### Multi-ECU Namespace Setup

```bash
#!/bin/bash

# Create 3 ECUs in separate namespaces
for i in 1 2 3; do
  # Create namespace
  sudo ip netns add ecu$i

  # Create veth pair
  sudo ip link add veth-ecu$i type veth peer name veth-host$i

  # Move to namespace
  sudo ip link set veth-ecu$i netns ecu$i

  # Configure ECU interface
  sudo ip netns exec ecu$i ip addr add 192.168.100.$((10+i))/24 dev veth-ecu$i
  sudo ip netns exec ecu$i ip link set veth-ecu$i up
  sudo ip netns exec ecu$i ip link set lo up

  # Configure host side
  sudo ip addr add 192.168.100.$i/24 dev veth-host$i
  sudo ip link set veth-host$i up

  echo "ECU $i: 192.168.100.$((10+i))"
done
```

### Routing Between Namespaces

```bash
# Create gateway namespace
sudo ip netns add gateway

# Enable IP forwarding in gateway
sudo ip netns exec gateway sysctl -w net.ipv4.ip_forward=1

# Create veth pairs to gateway
sudo ip link add veth-ecu1-gw type veth peer name veth-gw-ecu1
sudo ip link add veth-ecu2-gw type veth peer name veth-gw-ecu2

# Move to namespaces
sudo ip link set veth-ecu1-gw netns ecu1
sudo ip link set veth-ecu2-gw netns ecu2
sudo ip link set veth-gw-ecu1 netns gateway
sudo ip link set veth-gw-ecu2 netns gateway

# Configure gateway interfaces
sudo ip netns exec gateway ip addr add 10.0.1.1/24 dev veth-gw-ecu1
sudo ip netns exec gateway ip addr add 10.0.2.1/24 dev veth-gw-ecu2
sudo ip netns exec gateway ip link set veth-gw-ecu1 up
sudo ip netns exec gateway ip link set veth-gw-ecu2 up

# Configure ECU interfaces and routes
sudo ip netns exec ecu1 ip addr add 10.0.1.10/24 dev veth-ecu1-gw
sudo ip netns exec ecu1 ip link set veth-ecu1-gw up
sudo ip netns exec ecu1 ip route add default via 10.0.1.1

sudo ip netns exec ecu2 ip addr add 10.0.2.10/24 dev veth-ecu2-gw
sudo ip netns exec ecu2 ip link set veth-ecu2-gw up
sudo ip netns exec ecu2 ip route add default via 10.0.2.1

# Test routing
sudo ip netns exec ecu1 ping -c 3 10.0.2.10
```

## Bridge Networks

Bridges act as virtual switches, connecting multiple interfaces.

### Basic Bridge Setup

```bash
# Create bridge
sudo ip link add br-ecu type bridge
sudo ip link set br-ecu up
sudo ip addr add 192.168.200.1/24 dev br-ecu

# Create veth pairs for ECUs
sudo ip link add veth-ecu1 type veth peer name br-veth1
sudo ip link add veth-ecu2 type veth peer name br-veth2

# Attach to bridge
sudo ip link set br-veth1 master br-ecu
sudo ip link set br-veth2 master br-ecu
sudo ip link set br-veth1 up
sudo ip link set br-veth2 up

# Configure ECU sides
sudo ip addr add 192.168.200.11/24 dev veth-ecu1
sudo ip addr add 192.168.200.12/24 dev veth-ecu2
sudo ip link set veth-ecu1 up
sudo ip link set veth-ecu2 up

# Test connectivity
ping -c 3 192.168.200.11
ping -c 3 192.168.200.12
```

### Multi-ECU Bridge Topology

```bash
#!/bin/bash

# Create automotive bridge network
sudo ip link add br-automotive type bridge
sudo ip link set br-automotive up
sudo ip link set br-automotive multicast on
sudo ip addr add 172.20.0.1/16 dev br-automotive

# Connect multiple ECUs
for i in 1 2 3 4 5; do
  sudo ip link add veth-ecu$i type veth peer name br-veth$i
  sudo ip link set br-veth$i master br-automotive
  sudo ip link set br-veth$i up
  sudo ip addr add 172.20.0.$((10+i))/16 dev veth-ecu$i
  sudo ip link set veth-ecu$i up
  echo "ECU $i connected: 172.20.0.$((10+i))"
done

# Enable IGMP snooping for multicast
echo 1 | sudo tee /sys/class/net/br-automotive/bridge/multicast_snooping
```

## Traffic Shaping

Simulate realistic network conditions using tc (traffic control).

### Basic Traffic Shaping

```bash
# Add latency
sudo tc qdisc add dev veth0 root netem delay 10ms

# Add packet loss
sudo tc qdisc add dev veth0 root netem loss 2%

# Add bandwidth limit
sudo tc qdisc add dev veth0 root tbf rate 100mbit burst 32kbit latency 400ms

# Combine effects
sudo tc qdisc add dev veth0 root netem \
  delay 10ms \
  loss 1% \
  rate 100mbit

# Remove traffic shaping
sudo tc qdisc del dev veth0 root
```

### Automotive Ethernet Simulation

```bash
# 100BASE-TX Automotive Ethernet
sudo tc qdisc add dev veth-ecu root netem \
  delay 1ms 0.2ms distribution normal \
  loss 0.1% 25% \
  rate 100mbit \
  limit 1000

# 1000BASE-T1 Automotive Ethernet
sudo tc qdisc add dev veth-ecu root netem \
  delay 0.5ms 0.1ms distribution normal \
  loss 0.01% \
  rate 1000mbit \
  limit 2000
```

### Varying Network Conditions

```bash
# Good conditions
sudo tc qdisc change dev veth-ecu root netem \
  delay 1ms \
  loss 0.01%

# Medium conditions
sudo tc qdisc change dev veth-ecu root netem \
  delay 5ms 2ms \
  loss 0.5%

# Poor conditions (EMI interference)
sudo tc qdisc change dev veth-ecu root netem \
  delay 20ms 10ms \
  loss 5% 50% \
  duplicate 1% \
  corrupt 0.1%
```

## Multi-ECU Topologies

### Basic 2-ECU Topology

```bash
#!/bin/bash
# Basic 2-ECU setup with bridge

sudo ip link add br-automotive type bridge
sudo ip link set br-automotive up
sudo ip addr add 192.168.100.1/24 dev br-automotive

for i in 1 2; do
  sudo ip link add veth-ecu$i type veth peer name br-veth$i
  sudo ip link set br-veth$i master br-automotive
  sudo ip link set br-veth$i up
  sudo ip addr add 192.168.100.$((10+i))/24 dev veth-ecu$i
  sudo ip link set veth-ecu$i up

  # Apply traffic shaping
  sudo tc qdisc add dev veth-ecu$i root netem delay 1ms loss 0.05% rate 100mbit
done

sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

echo "Setup complete!"
echo "ECU1: 192.168.100.11"
echo "ECU2: 192.168.100.12"
echo "Bridge: 192.168.100.1"
echo "CAN: vcan0"
```

### Gateway Topology (CAN + Ethernet)

```bash
#!/bin/bash
# 3-ECU gateway topology with namespaces

# Create namespaces
sudo ip netns add can-domain
sudo ip netns add eth-domain
sudo ip netns add gateway

# Enable forwarding in gateway
sudo ip netns exec gateway sysctl -w net.ipv4.ip_forward=1

# CAN domain connections
sudo ip link add veth-can-ecu type veth peer name veth-can-gw
sudo ip link set veth-can-ecu netns can-domain
sudo ip link set veth-can-gw netns gateway

sudo ip netns exec can-domain ip addr add 172.20.0.20/16 dev veth-can-ecu
sudo ip netns exec can-domain ip link set veth-can-ecu up
sudo ip netns exec can-domain ip link set lo up
sudo ip netns exec can-domain ip route add default via 172.20.0.1

sudo ip netns exec gateway ip addr add 172.20.0.1/16 dev veth-can-gw
sudo ip netns exec gateway ip link set veth-can-gw up

# Ethernet domain connections
sudo ip link add veth-eth-ecu type veth peer name veth-eth-gw
sudo ip link set veth-eth-ecu netns eth-domain
sudo ip link set veth-eth-gw netns gateway

sudo ip netns exec eth-domain ip addr add 192.168.100.20/24 dev veth-eth-ecu
sudo ip netns exec eth-domain ip link set veth-eth-ecu up
sudo ip netns exec eth-domain ip link set lo up
sudo ip netns exec eth-domain ip route add default via 192.168.100.1

sudo ip netns exec gateway ip addr add 192.168.100.1/24 dev veth-eth-gw
sudo ip netns exec gateway ip link set veth-eth-gw up
sudo ip netns exec gateway ip link set lo up

# Create vcan in CAN domain
sudo ip netns exec can-domain ip link add dev vcan0 type vcan
sudo ip netns exec can-domain ip link set vcan0 up

echo "Gateway topology created!"
echo "CAN Domain: 172.20.0.20 (namespace: can-domain)"
echo "Eth Domain: 192.168.100.20 (namespace: eth-domain)"
echo "Gateway: 172.20.0.1 / 192.168.100.1 (namespace: gateway)"
echo ""
echo "Test: sudo ip netns exec can-domain ping 192.168.100.20"
```

## Docker Integration

### Docker Networks for ECUs

```bash
# Create CAN domain network
docker network create \
  --driver bridge \
  --subnet 172.20.0.0/16 \
  --gateway 172.20.0.1 \
  can-domain

# Create Ethernet domain network
docker network create \
  --driver bridge \
  --subnet 192.168.100.0/24 \
  --gateway 192.168.100.1 \
  eth-domain

# List networks
docker network ls
```

### Docker Compose Multi-ECU

```yaml
# docker-compose.yml
version: '3.8'

services:
  gateway-ecu:
    image: automotive-ecu:gateway
    container_name: gateway-ecu
    networks:
      can-domain:
        ipv4_address: 172.20.0.10
      eth-domain:
        ipv4_address: 192.168.100.10
    privileged: true
    volumes:
      - /dev/vcan0:/dev/vcan0

  powertrain-ecu:
    image: automotive-ecu:powertrain
    container_name: powertrain-ecu
    networks:
      can-domain:
        ipv4_address: 172.20.0.20
    privileged: true
    volumes:
      - /dev/vcan0:/dev/vcan0

  adas-ecu:
    image: automotive-ecu:adas
    container_name: adas-ecu
    networks:
      eth-domain:
        ipv4_address: 192.168.100.20
    privileged: true

  body-ecu:
    image: automotive-ecu:body
    container_name: body-ecu
    networks:
      can-domain:
        ipv4_address: 172.20.0.30
    privileged: true
    volumes:
      - /dev/vcan1:/dev/vcan1

networks:
  can-domain:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1

  eth-domain:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24
          gateway: 192.168.100.1
```

### Running Docker ECUs

```bash
# Start ECU containers
docker-compose up -d

# Execute commands in ECU
docker exec -it gateway-ecu bash

# Monitor CAN traffic from container
docker exec -it powertrain-ecu candump vcan0

# Test connectivity
docker exec -it adas-ecu ping -c 3 192.168.100.10
```

## QEMU Integration

### QEMU with TAP Interface

```bash
# Create TAP interface
sudo ip tuntap add dev tap-qemu0 mode tap user $USER
sudo ip link set tap-qemu0 up

# Create bridge
sudo ip link add br-vm type bridge
sudo ip link set br-vm up
sudo ip link set tap-qemu0 master br-vm
sudo ip addr add 192.168.122.1/24 dev br-vm

# Launch QEMU ECU
qemu-system-x86_64 \
  -name ecu-simulator \
  -m 2G \
  -smp 2 \
  -drive file=ecu-disk.qcow2,format=qcow2 \
  -netdev tap,id=net0,ifname=tap-qemu0,script=no,downscript=no \
  -device e1000,netdev=net0,mac=52:54:00:12:34:56 \
  -nographic
```

### Multiple QEMU ECUs

```bash
#!/bin/bash

# Create bridge for QEMU ECUs
sudo ip link add br-qemu type bridge
sudo ip link set br-qemu up
sudo ip addr add 192.168.123.1/24 dev br-qemu

# Create TAP interfaces for 3 ECUs
for i in 1 2 3; do
  sudo ip tuntap add dev tap-ecu$i mode tap user $USER
  sudo ip link set tap-ecu$i up
  sudo ip link set tap-ecu$i master br-qemu
done

# Launch ECUs (in separate terminals or screen sessions)
# ECU 1
qemu-system-x86_64 \
  -name ecu1 \
  -m 1G \
  -drive file=ecu1.qcow2 \
  -netdev tap,id=net0,ifname=tap-ecu1,script=no,downscript=no \
  -device e1000,netdev=net0 \
  -nographic &

# ECU 2
qemu-system-x86_64 \
  -name ecu2 \
  -m 1G \
  -drive file=ecu2.qcow2 \
  -netdev tap,id=net0,ifname=tap-ecu2,script=no,downscript=no \
  -device e1000,netdev=net0 \
  -nographic &

# ECU 3
qemu-system-x86_64 \
  -name ecu3 \
  -m 1G \
  -drive file=ecu3.qcow2 \
  -netdev tap,id=net0,ifname=tap-ecu3,script=no,downscript=no \
  -device e1000,netdev=net0 \
  -nographic &
```

## Automotive Protocols

### DoIP over Virtual Ethernet

```bash
# Setup virtual network for DoIP testing
sudo ip link add veth-ecu type veth peer name veth-tester
sudo ip addr add 172.16.100.10/24 dev veth-ecu
sudo ip addr add 172.16.100.1/24 dev veth-tester
sudo ip link set veth-ecu up
sudo ip link set veth-tester up

# DoIP uses TCP port 13400
# Start DoIP server on ECU (example with Python)
python3 << 'EOF'
import socket

# DoIP server
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('172.16.100.10', 13400))
server.listen(1)
print("DoIP server listening on 172.16.100.10:13400")

while True:
    client, addr = server.accept()
    print(f"Connection from {addr}")
    data = client.recv(1024)
    print(f"Received: {data.hex()}")
    client.close()
EOF
```

### SOME/IP Service Discovery

```bash
# Setup network with multicast support
sudo ip link add br-someip type bridge
sudo ip link set br-someip up
sudo ip link set br-someip multicast on
sudo ip addr add 192.168.220.1/24 dev br-someip

# Enable IGMP snooping
echo 1 | sudo tee /sys/class/net/br-someip/bridge/multicast_snooping

# Add multicast route
sudo ip route add 224.0.0.0/4 dev br-someip

# SOME/IP SD multicast: 224.244.224.245:30490
# Monitor SOME/IP SD traffic
sudo tcpdump -i br-someip -n 'udp port 30490 and dst 224.244.224.245' -v
```

### UDS Diagnostics

```bash
# UDS typically runs over DoIP or CAN
# For CAN-based UDS:

sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Send UDS request (example: ReadDataByIdentifier)
# Using isotp (ISO-TP protocol for CAN)
sudo modprobe can-isotp

# Python UDS example
python3 << 'EOF'
import isotp
import can

# Create ISO-TP socket for UDS
bus = can.interface.Bus(channel='vcan0', bustype='socketcan')
addr = isotp.Address(rxid=0x7E8, txid=0x7E0)
stack = isotp.CanStack(bus, address=addr)

# Send UDS request: ReadDataByIdentifier (0x22)
request = bytes([0x22, 0xF1, 0x90])  # Read VIN
stack.send(request)

response = stack.recv()
print(f"UDS Response: {response.hex()}")

stack.close()
bus.shutdown()
EOF
```

## Troubleshooting

### Common Issues

#### Cannot Create veth Pair

```bash
# Check if name already exists
ip link show veth0

# Delete existing interface
sudo ip link delete veth0

# Check for permission issues
sudo -i
```

#### No Connectivity Between Namespaces

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Check routing tables
sudo ip netns exec ecu1 ip route show
sudo ip netns exec gateway ip route show

# Check firewall rules
sudo iptables -L -v -n
```

#### High Packet Loss

```bash
# Check MTU mismatch
ip link show veth0 | grep mtu
ip link show veth1 | grep mtu

# Set consistent MTU
sudo ip link set veth0 mtu 1500
sudo ip link set veth1 mtu 1500

# Check buffer sizes
cat /proc/sys/net/core/rmem_default
cat /proc/sys/net/core/wmem_default

# Increase buffer sizes
sudo sysctl -w net.core.rmem_default=262144
sudo sysctl -w net.core.wmem_default=262144
```

#### Traffic Shaping Not Working

```bash
# Check if tc is installed
which tc

# Install iproute2
sudo apt-get install iproute2

# Remove conflicting qdisc
sudo tc qdisc del dev veth0 root

# Verify qdisc
sudo tc qdisc show dev veth0
```

### Debugging Commands

```bash
# Show all virtual interfaces
ip link show type veth
ip link show type bridge
ip link show type vcan

# Show interface statistics
ip -s link show veth0

# Monitor interface in real-time
watch -n 1 'ip -s link show veth0'

# Capture traffic
sudo tcpdump -i veth0 -w capture.pcap
sudo tcpdump -i vcan0 -w can-capture.pcap

# Show routing table
ip route show
sudo ip netns exec ecu1 ip route show

# Show ARP table
ip neigh show

# Show network namespace details
sudo ip netns exec ecu1 ip addr show
```

## Best Practices

### IP Address Planning

```
# Recommended IP address allocation
- Bridge/Gateway: x.x.x.1
- Host interfaces: x.x.x.1-10
- ECU interfaces: x.x.x.11-254

# Example:
- br-automotive: 192.168.100.1/24
- veth-host1: 192.168.100.2
- veth-ecu1: 192.168.100.11
- veth-ecu2: 192.168.100.12
```

### Naming Conventions

```bash
# Consistent naming scheme
veth-ecu1      # ECU side of veth pair
veth-host1     # Host side of veth pair
br-automotive  # Bridge for automotive network
br-can         # Bridge for CAN domain
br-eth         # Bridge for Ethernet domain
tap-qemu0      # TAP for QEMU VM
vcan0          # Virtual CAN bus
```

### Resource Cleanup

```bash
#!/bin/bash
# cleanup-virtual-networks.sh

# Delete all veth interfaces
for veth in $(ip link show type veth | grep -o 'veth[^:@]*' | sort -u); do
  echo "Deleting $veth"
  sudo ip link delete $veth 2>/dev/null
done

# Delete all namespaces
for ns in $(ip netns list | awk '{print $1}'); do
  echo "Deleting namespace $ns"
  sudo ip netns delete $ns 2>/dev/null
done

# Delete all bridges
for br in $(ip link show type bridge | grep -o 'br-[^:@]*' | sort -u); do
  echo "Deleting bridge $br"
  sudo ip link delete $br 2>/dev/null
done

# Delete vcan interfaces
for vcan in $(ip link show type vcan | grep -o 'vcan[0-9]*' | sort -u); do
  echo "Deleting $vcan"
  sudo ip link delete $vcan 2>/dev/null
done

echo "Cleanup complete"
```

### Documentation Template

```markdown
# Network Topology: [Name]

## Overview
Brief description of the topology and its purpose.

## IP Address Allocation
| Interface | IP Address | Namespace | Purpose |
|-----------|------------|-----------|---------|
| br-automotive | 192.168.100.1/24 | default | Main bridge |
| veth-ecu1 | 192.168.100.11/24 | ecu1 | Gateway ECU |
| veth-ecu2 | 192.168.100.12/24 | ecu2 | ADAS ECU |

## Setup Commands
```bash
# Commands to recreate topology
...
```

## Test Commands
```bash
# Commands to verify topology
...
```

## Cleanup
```bash
# Commands to remove topology
...
```
```

### Monitoring and Logging

```bash
# Create monitoring script
#!/bin/bash

while true; do
  clear
  echo "=== Virtual Network Status ==="
  echo ""

  echo "--- veth Interfaces ---"
  for veth in $(ip link show type veth | grep -o 'veth-ecu[0-9]' | sort -u); do
    stats=$(ip -s link show $veth | grep -A1 "RX:")
    echo "$veth: $stats"
  done

  echo ""
  echo "--- Bridge Status ---"
  for br in $(ip link show type bridge | grep -o 'br-[^:]*'); do
    ip -br link show $br
  done

  sleep 2
done
```

### Performance Considerations

- Use bridges instead of routing for better performance
- Limit number of namespaces (each consumes resources)
- Use traffic shaping sparingly (adds CPU overhead)
- Monitor system resources during testing
- Consider using macvlan for better performance than bridges

### Security

- Isolate test networks from production
- Use namespaces for strong isolation
- Apply firewall rules to prevent unintended communication
- Clean up test networks after use
- Don't expose test interfaces externally

## Quick Reference

### Setup Script Usage

```bash
# Create basic topology
sudo ./scripts/setup-virtual-networks.sh create basic

# Create gateway topology
sudo ./scripts/setup-virtual-networks.sh create gateway

# Create multi-ECU topology
sudo ./scripts/setup-virtual-networks.sh create multi

# Create Docker topology
sudo ./scripts/setup-virtual-networks.sh create docker

# Show status
sudo ./scripts/setup-virtual-networks.sh status

# Destroy all
sudo ./scripts/setup-virtual-networks.sh destroy
```

### Python Adapter Usage

```python
from tools.adapters.network.virtual_network_adapter import (
    VirtualNetworkAdapter,
    VethPair,
    TrafficShapingConfig
)

# Create adapter
adapter = VirtualNetworkAdapter()

# Create veth pair
config = VethPair(
    end1="veth-ecu1",
    end2="veth-host1",
    ip1="192.168.100.11/24",
    ip2="192.168.100.1/24"
)
adapter.create_veth_pair(config)

# Apply traffic shaping
tc_config = TrafficShapingConfig(
    delay="1ms",
    loss="0.1%",
    rate="100mbit"
)
adapter.apply_traffic_shaping("veth-ecu1", tc_config)

# Cleanup
adapter.cleanup()
```

## Additional Resources

- [Linux Advanced Routing & Traffic Control HOWTO](https://lartc.org/)
- [Docker Networking Documentation](https://docs.docker.com/network/)
- [QEMU Networking Documentation](https://wiki.qemu.org/Documentation/Networking)
- [SocketCAN Documentation](https://www.kernel.org/doc/html/latest/networking/can.html)
- [IEEE 802.1Q VLAN Tagging](https://standards.ieee.org/)
- [SOME/IP Specification](https://www.autosar.org/)
- [DoIP ISO 13400](https://www.iso.org/standard/55283.html)
