# SocketCAN - Linux CAN Networking Stack - Overview

## What is SocketCAN?

SocketCAN is the official CAN (Controller Area Network) implementation in the Linux kernel. It provides a socket-based API for CAN communication, making CAN bus access as simple as network socket programming. SocketCAN is the standard for CAN communication in Linux-based automotive systems.

## Key Characteristics

- **In-kernel implementation**: CAN drivers integrated in Linux kernel
- **Socket API**: Standard BSD socket interface (familiar to developers)
- **Protocol families**: Multiple CAN protocols supported
- **Hardware abstraction**: Works with various CAN controllers
- **Filtering**: Efficient hardware and software filtering
- **Zero-copy**: Direct hardware access for performance
- **Open-source**: Free, MIT/GPL licensed

## Architecture

```
┌─────────────────────────────────────────┐
│   Application (User Space)              │
│   - can-utils, Python-CAN, custom apps  │
└─────────────────────────────────────────┘
              ↓↑ Socket API
┌─────────────────────────────────────────┐
│   SocketCAN (Kernel Space)              │
│   ┌─────────────────────────────────┐   │
│   │  Protocol Layer                 │   │
│   │  - CAN_RAW, CAN_BCM, CAN_ISOTP  │   │
│   └─────────────────────────────────┘   │
│              ↓↑                          │
│   ┌─────────────────────────────────┐   │
│   │  CAN Device Layer               │   │
│   │  - can-dev, vcan, slcan         │   │
│   └─────────────────────────────────┘   │
│              ↓↑                          │
│   ┌─────────────────────────────────┐   │
│   │  CAN Controller Drivers         │   │
│   │  - mcp251x, sja1000, flexcan    │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
              ↓↑ Hardware Access
┌─────────────────────────────────────────┐
│   CAN Controller Hardware               │
│   - SPI, PCI, USB CAN adapters          │
└─────────────────────────────────────────┘
              ↓↑
┌─────────────────────────────────────────┐
│   CAN Bus (Physical Layer)              │
└─────────────────────────────────────────┘
```

## Protocol Families

### CAN_RAW
Raw CAN frame transmission and reception.

**Use Case**: Direct CAN frame access, diagnostic tools, logging
**Features**:
- Send/receive standard and extended CAN frames
- Hardware filtering
- Error frame reception
- Loopback control

### CAN_BCM (Broadcast Manager)
Content-based filtering and cyclic message transmission.

**Use Case**: Periodic message transmission, signal change notification
**Features**:
- Cyclic transmission with automatic timing
- Content-based filtering (only notify on change)
- Throttle message reception rate
- Timeout detection

### CAN_ISOTP (ISO-TP)
ISO 15765-2 transport protocol for multi-frame messages.

**Use Case**: Diagnostic communication (UDS), large data transfer
**Features**:
- Automatic segmentation/reassembly
- Flow control
- Single-frame and multi-frame support
- Padding and extended addressing

### CAN_J1939
SAE J1939 protocol for heavy-duty vehicles.

**Use Case**: Truck, bus, agricultural vehicle communication
**Features**:
- Address claiming
- Transport protocol
- Parameter group numbers (PGN)
- Multi-packet transport

## Virtual CAN (vcan)

Virtual CAN interface for testing without hardware.

```bash
# Create virtual CAN interface
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Use like real CAN interface
cansend vcan0 123#DEADBEEF
candump vcan0
```

**Use Cases**:
- Software testing without hardware
- CI/CD integration testing
- Development and debugging

## Supported Hardware

SocketCAN supports a wide range of CAN controllers:

### SPI-based
- **MCP2515**: Popular low-cost controller
- **MCP25625**: Integrated transceiver

### USB Adapters
- **PEAK PCAN-USB**: Professional adapter
- **Kvaser**: Various USB models
- **SocketCAN USB**: Generic USB-CAN adapters

### PCI/PCIe
- **PEAK PCAN-PCI**: PCIe CAN card
- **ESD CAN**: Industrial PCI cards

### Embedded SoC
- **FlexCAN**: i.MX, Kinetis SoCs
- **SJA1000**: Classic CAN controller
- **M_CAN**: Bosch CAN FD controller
- **RCAR_CAN**: Renesas R-Car

## Basic Usage

### Send CAN Frame

```bash
# Command line (can-utils)
cansend can0 123#DEADBEEF

# Format: <CAN_ID>#<DATA>
# Standard ID (11-bit): 000-7FF
# Extended ID (29-bit): 00000000-1FFFFFFF (use 8 hex digits)

# Extended ID example
cansend can0 12345678#11223344

# Remote Transmission Request (RTR)
cansend can0 123#R

# CAN FD frame
cansend can0 123##1DEADBEEF  # Note: ## for FD
```

### Receive CAN Frames

```bash
# Dump all frames
candump can0

# Output format:
# can0  123  [8] DE AD BE EF 01 02 03 04

# Filter by ID
candump can0,123:7FF  # Only ID 0x123

# Save to log file
candump -l can0

# Decode with DBC
candump can0 | cantools decode vehicle.dbc
```

### Configure Interface

```bash
# Bring up CAN interface
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0

# CAN FD mode
sudo ip link set can0 type can bitrate 500000 dbitrate 2000000 fd on
sudo ip link set up can0

# Loopback mode (for testing)
sudo ip link set can0 type can bitrate 500000 loopback on
sudo ip link set up can0

# Listen-only mode (bus monitoring)
sudo ip link set can0 type can bitrate 500000 listen-only on
sudo ip link set up can0

# Show statistics
ip -details -statistics link show can0
```

## Programming with SocketCAN

### C Example

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>

int main(void)
{
    int s;
    struct sockaddr_can addr;
    struct ifreq ifr;
    struct can_frame frame;

    /* Create socket */
    s = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (s < 0) {
        perror("socket");
        return 1;
    }

    /* Specify can0 interface */
    strcpy(ifr.ifr_name, "can0");
    ioctl(s, SIOCGIFINDEX, &ifr);

    /* Bind socket to can0 */
    memset(&addr, 0, sizeof(addr));
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;
    bind(s, (struct sockaddr *)&addr, sizeof(addr));

    /* Send frame */
    frame.can_id = 0x123;
    frame.can_dlc = 2;
    frame.data[0] = 0xDE;
    frame.data[1] = 0xAD;
    write(s, &frame, sizeof(struct can_frame));

    /* Receive frame */
    read(s, &frame, sizeof(struct can_frame));
    printf("Received: ID=0x%X DLC=%d Data=", frame.can_id, frame.can_dlc);
    for (int i = 0; i < frame.can_dlc; i++) {
        printf("%02X ", frame.data[i]);
    }
    printf("\n");

    close(s);
    return 0;
}
```

### Python Example

```python
import can

# Create bus instance
bus = can.interface.Bus(channel='can0', bustype='socketcan')

# Send message
msg = can.Message(arbitration_id=0x123,
                  data=[0xDE, 0xAD, 0xBE, 0xEF],
                  is_extended_id=False)
bus.send(msg)

# Receive messages
for msg in bus:
    print(f"ID: 0x{msg.arbitration_id:X} Data: {msg.data.hex()}")
    if msg.arbitration_id == 0x456:
        break

bus.shutdown()
```

## Filtering

### Hardware Filtering

```c
/* Accept only frames with ID 0x123 */
struct can_filter filter;
filter.can_id = 0x123;
filter.can_mask = CAN_SFF_MASK;  /* Standard frame mask */
setsockopt(s, SOL_CAN_RAW, CAN_RAW_FILTER, &filter, sizeof(filter));

/* Accept multiple IDs */
struct can_filter filters[2];
filters[0].can_id = 0x123;
filters[0].can_mask = CAN_SFF_MASK;
filters[1].can_id = 0x456;
filters[1].can_mask = CAN_SFF_MASK;
setsockopt(s, SOL_CAN_RAW, CAN_RAW_FILTER, filters, sizeof(filters));

/* Accept range of IDs (0x100-0x10F) */
filter.can_id = 0x100;
filter.can_mask = 0x7F0;  /* Mask lower 4 bits */
```

### Error Frames

```c
/* Receive error frames */
can_err_mask_t err_mask = CAN_ERR_MASK;
setsockopt(s, SOL_CAN_RAW, CAN_RAW_ERR_FILTER, &err_mask, sizeof(err_mask));

/* Check for error frame */
if (frame.can_id & CAN_ERR_FLAG) {
    printf("Error frame received\n");
}
```

## CAN-Utils Toolkit

Essential command-line tools for CAN:

### candump
Dump CAN traffic.

```bash
candump can0                    # Dump all
candump -l can0                 # Log to file
candump -c can0                 # Colorized output
candump -a can0                 # Absolute timestamps
candump can0,123:7FF            # Filter ID 0x123
```

### cansend
Send single CAN frame.

```bash
cansend can0 123#DEADBEEF       # Send frame
cansend can0 123#R              # RTR frame
```

### cangen
Generate random CAN traffic.

```bash
cangen can0 -g 10               # Generate every 10ms
cangen can0 -I 123              # Fixed ID 0x123
cangen can0 -L 8                # Fixed DLC 8
```

### canplayer
Replay logged CAN traffic.

```bash
canplayer -I candump-2024-03-19.log
```

### canbusload
Show bus load percentage.

```bash
canbusload can0@500000          # 500 kbps bitrate
```

### cansequence
Test sequence numbers.

```bash
cansequence can0                # Send sequence
```

## Performance

SocketCAN performance characteristics:

**Throughput**:
- CAN 2.0: Up to ~7,800 frames/sec (theoretical max)
- CAN FD: Up to ~60,000 frames/sec (8 Mbps data phase)

**Latency**:
- Typical: < 100 μs (user space to hardware)
- Real-time kernel: < 50 μs

**CPU Usage**:
- Minimal overhead (kernel-based)
- Zero-copy for efficiency

## Use Cases

**Automotive Development**:
- ECU testing and validation
- Network simulation
- Diagnostic tool development
- Data logging

**Embedded Linux**:
- Yocto-based ECU platforms
- Raspberry Pi CAN projects
- Industrial automation
- Robotics

**Testing & Diagnostics**:
- CAN bus monitoring
- Fault injection
- Protocol analysis
- Regression testing

## Integration with Tools

**Python-CAN**: High-level Python interface
**CANopen for Python**: CANopen protocol stack
**J1939**: Heavy-duty vehicle protocol
**UDS (udsoncan)**: Diagnostic protocol

## Next Steps

- **Level 2**: Conceptual understanding of protocol families
- **Level 3**: Detailed programming guide with examples
- **Level 4**: Complete API reference and configuration
- **Level 5**: Advanced filtering, real-time optimization, kernel tuning

## References

- Linux SocketCAN Documentation: https://www.kernel.org/doc/html/latest/networking/can.html
- can-utils: https://github.com/linux-can/can-utils
- python-can: https://python-can.readthedocs.io

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Embedded Linux developers, automotive test engineers, CAN developers
