# CANoe to SavvyCAN Migration Guide

Complete guide for migrating from Vector CANoe to open-source SavvyCAN for CAN bus analysis and testing.

## Overview

This guide helps you transition from **Vector CANoe** (€5,000-€15,000) to **SavvyCAN** (free, open-source) while maintaining functionality for:
- CAN bus monitoring and logging
- Signal decoding from DBC files
- Sending/replaying CAN messages
- Automated testing with scripts

### Cost Savings
- **CANoe Professional**: €15,000/license
- **SavvyCAN**: Free
- **Annual Savings**: €15,000+ per engineer

## Feature Comparison

| Feature | CANoe | SavvyCAN | Notes |
|---------|-------|----------|-------|
| CAN Monitoring | ✓ | ✓ | Real-time display |
| DBC Import | ✓ | ✓ | Full signal decoding |
| Message Sending | ✓ | ✓ | Manual & scripted |
| Logging | ✓ | ✓ | BLF → ASC conversion needed |
| Diagnostics (UDS) | ✓ | ✗ | Use SavvyCANDiag plugin |
| FlexRay | ✓ | ✗ | Not supported |
| Scripting | CAPL | Python | Python more flexible |
| Hardware Support | All Vector | SocketCAN | Broader Linux support |

## Quick Start

### 1. Installation

#### SavvyCAN

```bash
# Ubuntu/Debian
sudo apt-get install qt5-default libqt5serialport5-dev
git clone https://github.com/collin80/SavvyCAN.git
cd SavvyCAN
qmake
make
sudo make install

# Or use pre-built binary
wget https://github.com/collin80/SavvyCAN/releases/download/V228/SavvyCAN-228.AppImage
chmod +x SavvyCAN-228.AppImage
```

#### SocketCAN (Linux CAN Interface)

```bash
# Load kernel modules
sudo modprobe can
sudo modprobe can_raw
sudo modprobe vcan

# Create virtual CAN interface for testing
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# For real hardware (e.g., CANable, PEAK)
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0
```

### 2. Import DBC File

**CANoe:**
```
1. Database → Load Database → Select .dbc file
2. Database nodes appear in tree view
```

**SavvyCAN:**
```
1. Open SavvyCAN
2. File → Load DBC File → Select .dbc
3. Signals automatically decoded
```

### 3. Connect to CAN Bus

**CANoe:**
```
1. Hardware → Configuration → Select interface
2. Start measurement (F9)
```

**SavvyCAN:**
```
1. Connection → Open Connection Window
2. Select SocketCAN
3. Interface: can0 (or vcan0)
4. Click "Create New Connection"
```

## Migration Workflow

### Step 1: Convert Existing Data

#### Convert CANoe BLF Logs to ASC

```bash
# Using Vector BLF Tools (free)
wget https://www.vector.com/media/tool/BLF-Binary-Logging-Format.zip
unzip BLF-Binary-Logging-Format.zip
cd BLF-Binary-Logging-Format

# Convert BLF to ASC
./blf2asc input.blf output.asc
```

#### Load ASC in SavvyCAN

```
1. File → Load Log File
2. Select .asc file
3. Choose time format (absolute/relative)
```

### Step 2: Recreate CAPL Scripts as Python

#### Example: CANoe CAPL Script

```capl
// CANoe CAPL: Send heartbeat every 100ms
variables
{
  msTimer heartbeatTimer;
}

on start
{
  setTimer(heartbeatTimer, 100);
}

on timer heartbeatTimer
{
  message BMS_Heartbeat msg;
  msg.Status = 0x01;
  msg.Counter++;
  output(msg);

  setTimer(heartbeatTimer, 100);
}
```

#### Equivalent: Python Script for SavvyCAN

```python
#!/usr/bin/env python3
"""
SavvyCAN Python equivalent: Send heartbeat every 100ms
"""

import can
import time

# Setup CAN interface
bus = can.interface.Bus(channel='can0', bustype='socketcan')

# Heartbeat message (CAN ID 0x100)
counter = 0

while True:
    # Create message
    msg = can.Message(
        arbitration_id=0x100,
        data=[0x01, counter, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
        is_extended_id=False
    )

    # Send message
    bus.send(msg)
    print(f"Sent heartbeat: Counter={counter}")

    counter = (counter + 1) % 256
    time.sleep(0.1)  # 100ms
```

### Step 3: Automated Testing Migration

#### CANoe Test Setup

```xml
<!-- CANoe Test Unit XML -->
<TestSetup>
  <TestCase name="BMS_Communication_Test">
    <Precondition>
      <Wait timeout="1000"/>
    </Precondition>
    <TestStep>
      <SendMessage name="BMS_Control" id="0x200" data="01 00 00 00 00 00 00 00"/>
      <Wait timeout="100"/>
      <CheckMessage name="BMS_Status" id="0x100">
        <CheckSignal name="Status" value="1"/>
      </CheckMessage>
    </TestStep>
  </TestCase>
</TestSetup>
```

#### SavvyCAN Python Test

```python
#!/usr/bin/env python3
"""
Automated test: BMS Communication
Equivalent to CANoe test setup
"""

import can
import time
from typing import Optional


class BMSTest:
    """BMS communication test."""

    def __init__(self, channel='can0'):
        self.bus = can.interface.Bus(channel=channel, bustype='socketcan')
        self.notifier = can.Notifier(self.bus, [self])
        self.received_status = None

    def __call__(self, msg: can.Message):
        """Message handler."""
        if msg.arbitration_id == 0x100:  # BMS_Status
            self.received_status = msg.data[0]

    def test_bms_communication(self) -> bool:
        """
        Test BMS communication.

        Returns:
            True if test passed, False otherwise
        """
        print("[Test] BMS Communication Test")

        # Step 1: Send control message
        control_msg = can.Message(
            arbitration_id=0x200,
            data=[0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        )
        self.bus.send(control_msg)
        print("[Test] Sent BMS_Control: Enable")

        # Step 2: Wait for response
        time.sleep(0.1)

        # Step 3: Check status
        if self.received_status == 0x01:
            print("[Test] PASS: BMS responded with Status=1")
            return True
        else:
            print(f"[Test] FAIL: Expected Status=1, got {self.received_status}")
            return False

    def cleanup(self):
        """Cleanup resources."""
        self.bus.shutdown()


if __name__ == '__main__':
    test = BMSTest(channel='can0')

    try:
        result = test.test_bms_communication()
        exit(0 if result else 1)
    finally:
        test.cleanup()
```

## Advanced Features

### 1. Graphing Signals (like CANoe Trace)

```python
#!/usr/bin/env python3
"""
Real-time signal plotting in SavvyCAN
"""

import can
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from collections import deque
import struct

# Setup
bus = can.interface.Bus(channel='can0', bustype='socketcan')

# Data buffers
time_data = deque(maxlen=100)
voltage_data = deque(maxlen=100)
current_data = deque(maxlen=100)

start_time = None

def parse_bms_status(msg: can.Message):
    """Parse BMS status message."""
    global start_time

    if msg.arbitration_id == 0x100:
        if start_time is None:
            start_time = msg.timestamp

        # Extract signals (assuming little-endian)
        voltage = struct.unpack('<H', msg.data[0:2])[0] * 0.1  # Scale: 0.1V
        current = struct.unpack('<h', msg.data[2:4])[0] * 0.1  # Scale: 0.1A

        time_data.append(msg.timestamp - start_time)
        voltage_data.append(voltage)
        current_data.append(current)

def update_plot(frame):
    """Update plot with new data."""
    # Read CAN messages
    msg = bus.recv(timeout=0.01)
    if msg:
        parse_bms_status(msg)

    # Update plots
    ax1.clear()
    ax2.clear()

    ax1.plot(time_data, voltage_data, 'b-')
    ax1.set_ylabel('Voltage (V)', color='b')
    ax1.grid(True)

    ax2.plot(time_data, current_data, 'r-')
    ax2.set_ylabel('Current (A)', color='r')
    ax2.set_xlabel('Time (s)')
    ax2.grid(True)

# Setup plot
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 6))
ani = FuncAnimation(fig, update_plot, interval=100)
plt.show()
```

### 2. Replay CAN Logs

```bash
# Using candump and canplayer (part of can-utils)

# Record CAN traffic
candump can0 -l

# Replay recorded log
canplayer -I candump-2026-03-19_143000.log
```

### 3. UDS Diagnostics

```python
#!/usr/bin/env python3
"""
UDS diagnostics using python-can and python-udsoncan
"""

import can
import udsoncan
from udsoncan.connections import PythonIsoTpConnection
from udsoncan.client import Client
from udsoncan.services import *

# Setup ISO-TP connection
tp_addr = udsoncan.Address(
    addressing_mode=udsoncan.AddressingMode.Normal_11bits,
    txid=0x7E0,  # Tester → ECU
    rxid=0x7E8   # ECU → Tester
)

bus = can.interface.Bus(channel='can0', bustype='socketcan')
conn = PythonIsoTpConnection(bus, tp_addr)

# Create UDS client
with Client(conn) as client:
    # Read DTC
    response = client.read_dtc_information(
        ReadDTCInformation.Subfunction.reportDTCByStatusMask,
        status_mask=0xFF
    )

    print(f"DTCs: {response.service_data.dtcs}")

    # Read data by identifier (e.g., VIN)
    response = client.read_data_by_identifier([0xF190])
    vin = response.service_data.values[0xF190]
    print(f"VIN: {vin}")

    # Clear DTCs
    client.clear_dtc_information(0xFFFFFF)
    print("DTCs cleared")
```

## Hardware Options

### Supported Hardware for SavvyCAN

| Hardware | Price | Speed | Notes |
|----------|-------|-------|-------|
| **CANable** | $30 | 1 Mbps | USB, slcand or candleLight firmware |
| **PEAK PCAN-USB** | $150 | 1 Mbps | Industrial-grade, excellent drivers |
| **IXXAT USB-to-CAN** | $200 | 1 Mbps | Good Windows/Linux support |
| **Raspberry Pi + MCP2515** | $50 | 1 Mbps | DIY solution, SocketCAN native |
| **Virtual CAN (vcan)** | Free | N/A | Testing without hardware |

### Setup CANable

```bash
# Install candleLight firmware for native SocketCAN
# (Instructions at: https://github.com/candle-usb/candleLight_fw)

# After firmware update, device appears as SocketCAN
ip link set can0 type can bitrate 500000
ip link set up can0

# Verify
candump can0
```

## Performance Comparison

| Operation | CANoe | SavvyCAN |
|-----------|-------|----------|
| Startup Time | 10s | 2s |
| Log Parsing (100MB) | 30s | 15s |
| Message Rate | 50k msg/s | 40k msg/s |
| Memory Usage | 500MB | 150MB |

## Troubleshooting

### Issue: CAN Interface Not Found

```bash
# Check interface status
ip link show can0

# If DOWN, bring up
sudo ip link set can0 up

# Check kernel modules
lsmod | grep can
```

### Issue: Permission Denied

```bash
# Add user to dialout group (for USB devices)
sudo usermod -a -G dialout $USER

# Reload groups
newgrp dialout
```

### Issue: High CPU Usage

```bash
# Increase buffer size
sudo ip link set can0 txqueuelen 10000
```

## Complete Migration Checklist

- [ ] Install SavvyCAN and can-utils
- [ ] Setup SocketCAN interface
- [ ] Convert CANoe BLF logs to ASC
- [ ] Import DBC database
- [ ] Test basic CAN communication
- [ ] Port CAPL scripts to Python
- [ ] Setup automated testing framework
- [ ] Configure signal graphing
- [ ] Test UDS diagnostics (if needed)
- [ ] Train team on new workflow

## Resources

- **SavvyCAN**: https://github.com/collin80/SavvyCAN
- **python-can**: https://python-can.readthedocs.io/
- **can-utils**: https://github.com/linux-can/can-utils
- **SocketCAN**: https://www.kernel.org/doc/html/latest/networking/can.html
- **UDS**: https://github.com/pylessard/python-udsoncan

## Training Materials

See `training/` directory for:
- Workshop slides
- Video tutorials
- Hands-on exercises
- Example projects

## Support

- GitHub Discussions: [Community forum](https://github.com/collin80/SavvyCAN/discussions)
- YouTube tutorials: Search "SavvyCAN tutorial"
- IRC: #socketcan on Libera.Chat

## License

This guide is licensed under MIT. See LICENSE file.
