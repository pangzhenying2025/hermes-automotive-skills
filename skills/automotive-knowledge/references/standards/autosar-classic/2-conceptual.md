# AUTOSAR Classic Platform - Conceptual Guide

## Architecture Philosophy

AUTOSAR Classic follows a **layered architecture** principle where each layer has well-defined responsibilities and interfaces. This separation enables:

- **Portability**: Application software can run on different hardware platforms
- **Scalability**: Components can be reused across vehicle projects
- **Maintainability**: Changes in one layer don't affect others
- **Testability**: Layers can be tested independently

## Detailed Layer Architecture

### Application Layer

The application layer contains **Software Components (SWCs)** that implement vehicle functions.

#### SWC Types

1. **Application SWC**: Business logic (e.g., cruise control algorithm)
2. **Sensor/Actuator SWC**: Interface to physical I/O
3. **Service SWC**: Provides services to other SWCs
4. **Complex Driver**: Direct hardware access for time-critical functions
5. **ECU Abstraction SWC**: Wraps BSW functionality

#### SWC Structure

```
┌────────────────────────────────┐
│  Software Component (SWC)      │
│                                │
│  ┌──────────┐    ┌──────────┐ │
│  │ Runnable │    │ Runnable │ │
│  │ Entity 1 │    │ Entity 2 │ │
│  └──────────┘    └──────────┘ │
│                                │
│  Ports:                        │
│  - Require Port (R-Port) ←──  │
│  - Provide Port (P-Port) ──→  │
└────────────────────────────────┘
```

**Runnable Entity**: Atomic execution unit, scheduled by AUTOSAR OS
**Ports**: Communication interfaces (sender/receiver or client/server)

### Runtime Environment (RTE)

The RTE is **generated code** that provides:

#### Communication Services

- **Intra-ECU**: Direct function calls between SWCs on same ECU
- **Inter-ECU**: Communication via COM stack (CAN, LIN, FlexRay, Ethernet)

#### RTE APIs

```c
/* Sender/Receiver Communication */
Std_ReturnType Rte_Write_<Port>_<DataElement>(DataType data);
Std_ReturnType Rte_Read_<Port>_<DataElement>(DataType* data);

/* Client/Server Communication */
Std_ReturnType Rte_Call_<Port>_<Operation>(ArgType1 arg1, ...);

/* Mode Management */
Std_ReturnType Rte_Mode_<Port>_<ModeGroup>(ModeType* mode);

/* Trigger Events */
Std_ReturnType Rte_Trigger_<Port>_<Trigger>(void);
```

#### Event Types

1. **TimingEvent**: Periodic execution (e.g., every 10ms)
2. **DataReceivedEvent**: Triggered on data reception
3. **OperationInvokedEvent**: Triggered by client request
4. **ModeSwitch Event**: Triggered on mode change

### Basic Software (BSW)

The BSW is organized into **layers** and **clusters**:

#### Services Layer

**System Services**
- **OS**: AUTOSAR Operating System (OSEK/VDX based)
- **EcuM**: ECU State Manager (startup, shutdown, sleep modes)
- **BswM**: BSW Mode Manager (coordinates mode switches)
- **ComM**: Communication Manager (manages network communication)
- **Dem**: Diagnostic Event Manager (fault memory)
- **Det**: Development Error Tracer (debug support)

**Memory Services**
- **NvM**: Non-Volatile Memory Manager (EEPROM/Flash management)
- **MemIf**: Memory Abstraction Interface
- **Fee**: Flash EEPROM Emulation
- **Ea**: EEPROM Abstraction

**Communication Services**
- **Com**: Communication Manager (signal routing)
- **PduR**: PDU Router (message routing between modules)
- **IpduM**: I-PDU Multiplexer (signal multiplexing)
- **SecOC**: Secure Onboard Communication (authentication/encryption)

**Diagnostic Services**
- **Dcm**: Diagnostic Communication Manager (UDS protocol)
- **Dem**: Diagnostic Event Manager (DTC storage)
- **FiM**: Function Inhibition Manager (disable functions on faults)

#### ECU Abstraction Layer

**Communication Drivers**
- **CanIf**: CAN Interface
- **LinIf**: LIN Interface
- **FrIf**: FlexRay Interface
- **EthIf**: Ethernet Interface

**Memory Drivers**
- **Fls**: Flash Driver
- **Eep**: EEPROM Driver

**I/O Drivers**
- **Dio**: Digital I/O
- **Adc**: Analog-to-Digital Converter
- **Pwm**: Pulse Width Modulation
- **Icu**: Input Capture Unit

#### Microcontroller Abstraction Layer (MCAL)

Hardware-specific drivers provided by silicon vendors:
- **Can**: CAN Controller Driver
- **Lin**: LIN Controller Driver
- **Fr**: FlexRay Controller Driver
- **Eth**: Ethernet Controller Driver
- **Spi**: Serial Peripheral Interface
- **Mcu**: Microcontroller Unit Driver
- **Gpt**: General Purpose Timer
- **Wdg**: Watchdog Driver

## Communication Stack Example: CAN

```
Application Layer (SWC)
         ↓↑
    RTE (Generated)
         ↓↑
    COM (Signal Packing)
         ↓↑
    PduR (Routing)
         ↓↑
    CanTp (Transport Protocol) - for diagnostic messages
         ↓↑
    CanIf (Interface)
         ↓↑
    Can (Driver)
         ↓↑
    CAN Hardware
```

### Message Flow Example

**Sending a Signal**:
1. SWC calls `Rte_Write_SpeedValue(120)`
2. RTE calls `Com_SendSignal(SignalId, 120)`
3. COM packs signal into I-PDU
4. COM calls `PduR_ComTransmit(PduId, Data)`
5. PduR routes to `CanIf_Transmit(PduId, Data)`
6. CanIf calls `Can_Write(Hth, PduInfo)`
7. Can driver sends frame to CAN controller

## Operating System (AUTOSAR OS)

Based on OSEK/VDX standard with AUTOSAR extensions.

### OS Concepts

**Conformance Classes**:
- **BCC1**: Basic, non-preemptive, single activation
- **BCC2**: Basic, non-preemptive, multiple activation
- **ECC1**: Extended, preemptive, single activation
- **ECC2**: Extended, preemptive, multiple activation

**Task Scheduling**:
- **Priority-based preemptive scheduling**
- **Fixed priority assignment**
- **Run-to-completion or preemptive tasks**

**Resource Management**:
- **Priority Ceiling Protocol** for resource access
- **Prevents priority inversion**

**Alarms and Counters**:
- **Counter**: Hardware or software counter
- **Alarm**: Triggers action when counter reaches threshold

### OS Task Example

```c
TASK(Task_10ms)
{
    /* Read inputs */
    Rte_Read_VehicleSpeed(&speed);

    /* Execute control algorithm */
    CalculateTorque(speed, &torque);

    /* Write outputs */
    Rte_Write_MotorTorque(torque);

    TerminateTask();
}
```

## Configuration Workflow

### System Design Flow

1. **System Architecture**: Define SWCs, interfaces, and topology
2. **ECU Extract**: Generate ECU-specific configuration from system
3. **BSW Configuration**: Configure BSW modules using tools (tresos, DaVinci)
4. **RTE Generation**: Generate RTE from ARXML description
5. **Build Integration**: Compile and link all components
6. **ECU Validation**: Test on target hardware

### ARXML Structure

AUTOSAR uses **XML-based system description** (ARXML):

```xml
<AUTOSAR>
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>ComponentTypes</SHORT-NAME>
      <ELEMENTS>
        <APPLICATION-SW-COMPONENT-TYPE>
          <SHORT-NAME>CruiseControl</SHORT-NAME>
          <PORTS>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>VehicleSpeed</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF>SpeedInterface</REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
          </PORTS>
        </APPLICATION-SW-COMPONENT-TYPE>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

## Memory Management

### Memory Sections

AUTOSAR defines standardized memory sections:

```c
/* Code sections */
#define CODE                    /* Executable code */
#define CALLOUT_CODE            /* Callback functions */
#define INLINE                  /* Inline functions */

/* Data sections */
#define VAR_INIT                /* Initialized RAM */
#define VAR_NOINIT              /* Uninitialized RAM (faster boot) */
#define VAR_POWER_ON_INIT       /* Init on power-on only */
#define CONST                   /* ROM constants */
```

### NvM (Non-Volatile Memory Manager)

Manages persistent data across ECU resets:

- **NvM Blocks**: Logical data units (e.g., calibration, DTC data)
- **Redundancy**: Mirror blocks for safety-critical data
- **CRC Protection**: Data integrity checking
- **Write Cycles**: Wear leveling for Flash/EEPROM

## Diagnostic Services (UDS)

AUTOSAR implements **ISO 14229 (Unified Diagnostic Services)**:

### Diagnostic Sessions

1. **Default Session (0x01)**: Normal operation, limited access
2. **Programming Session (0x02)**: Software update
3. **Extended Diagnostic Session (0x03)**: Full diagnostic access

### Common Services

```
0x10: Diagnostic Session Control
0x11: ECU Reset
0x14: Clear Diagnostic Information
0x19: Read DTC Information
0x22: Read Data By Identifier
0x27: Security Access
0x2E: Write Data By Identifier
0x31: Routine Control
0x34/36: Request Download/Upload (flashing)
0x3E: Tester Present
```

### DTC (Diagnostic Trouble Code) Management

**Dem (Diagnostic Event Manager)** handles:
- Fault detection and storage
- DTC status bits (test failed, confirmed, warning indicator)
- Freeze frame data (snapshot of system state)
- Aging and healing mechanisms

## Mode Management

AUTOSAR uses **mode management** for state coordination:

### ECU State Manager (EcuM) Modes

```
┌──────────────┐
│  SLEEP Mode  │
└──────┬───────┘
       │ Wakeup
       ↓
┌──────────────┐
│ STARTUP Mode │
└──────┬───────┘
       │ Init Complete
       ↓
┌──────────────┐
│  RUN Mode    │
└──────┬───────┘
       │ Shutdown Request
       ↓
┌──────────────┐
│ SHUTDOWN Mode│
└──────┬───────┘
       │
       ↓
┌──────────────┐
│  OFF Mode    │
└──────────────┘
```

### BswM (BSW Mode Manager)

Coordinates mode switches across BSW modules:
- Network modes (FULL_COMM, SILENT_COMM, NO_COMM)
- Diagnostic modes
- Power modes
- Application modes

## Security Features

AUTOSAR Classic includes security mechanisms:

### SecOC (Secure Onboard Communication)

- **Message Authentication**: CMAC (Cipher-based MAC)
- **Freshness Value**: Counter to prevent replay attacks
- **Authentication Data**: Appended to messages

### Crypto Stack

- **Crypto Service Manager (CSM)**: API for cryptographic operations
- **Crypto Driver**: Hardware acceleration (HSM, TPM)
- **Supported Algorithms**: AES, RSA, ECC, SHA

## Summary

AUTOSAR Classic provides a comprehensive, standardized platform for ECU software development. Key takeaways:

- **Layered architecture** separates concerns and enables reuse
- **RTE** abstracts communication between SWCs and BSW
- **BSW modules** provide standardized services for all automotive needs
- **Configuration-driven** development reduces manual coding
- **Safety and security** features meet automotive requirements

## Next Steps

- **Level 3**: Detailed module specifications, API references, configuration parameters
- **Level 4**: Complete reference documentation for all BSW modules
- **Level 5**: Advanced topics (multi-core, optimization, certification)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Target Audience**: Engineers with basic AUTOSAR knowledge seeking deeper understanding
