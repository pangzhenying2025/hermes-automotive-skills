# AUTOSAR Adaptive Platform - Conceptual Architecture

## Service-Oriented Architecture

AUTOSAR Adaptive Platform (AP) is fundamentally different from Classic Platform. Instead of statically configured software components, AP uses a service-oriented architecture (SOA) where applications discover and communicate with services at runtime.

### Key Paradigm Shift

```
Classic Platform              Adaptive Platform
┌──────────────┐             ┌──────────────┐
│ Static RTE   │             │ Runtime      │
│ Compile-time │             │ Discovery    │
│ Fixed mapping│             │ Dynamic bind │
└──────────────┘             └──────────────┘
```

**Classic**: All communication paths configured at build time, RTE generated from system description.

**Adaptive**: Services advertised at runtime, clients discover and bind dynamically, supports deployment flexibility.

## Functional Clusters

AP is organized into functional clusters, each providing specific capabilities:

### ara::com - Communication Management

Service-oriented middleware supporting multiple transport protocols.

**Architecture**:
```
┌─────────────────────────────────────┐
│  Application (Service/Proxy)        │
└─────────────────────────────────────┘
         ↕ ara::com API
┌─────────────────────────────────────┐
│  Communication Management           │
│  - Service Registry                 │
│  - Serialization                    │
│  - Transport Binding                │
└─────────────────────────────────────┘
         ↕ Bindings
┌──────────┬──────────┬──────────────┐
│ SOME/IP  │ DDS      │ IPC (Signal) │
└──────────┴──────────┴──────────────┘
```

**Concepts**:
- **Service Interface**: Defines contract (methods, events, fields)
- **Service Skeleton**: Server-side implementation
- **Service Proxy**: Client-side representation
- **Service Instance**: Runtime instantiation with instance ID

### ara::exec - Execution Management

Controls application lifecycle, process supervision, and state management.

**States**:
1. **Startup**: Platform initialization, load manifests
2. **Run**: Normal operation, applications executing
3. **Shutdown**: Graceful termination, cleanup
4. **Restart**: Recovery from critical errors

**Process States**:
```
       ┌─────────┐
       │ Loaded  │
       └────┬────┘
            ↓ Initialize()
       ┌────────┐
       │ Running│←─────┐
       └────┬───┘      │
            ↓          │ Recover
       ┌────────┐      │
       │Terminating────┘
       └────┬───┘
            ↓
       ┌────────┐
       │ Stopped│
       └────────┘
```

### ara::per - Persistency

Provides storage for application data with defined consistency guarantees.

**Storage Types**:
- **Key-Value Storage**: Fast access, simple data types
- **File Storage**: Arbitrary file content, POSIX-like API
- **Redundancy**: Configurable replication for safety-critical data

**Access Patterns**:
```cpp
// Key-Value
auto storage = ara::per::OpenKeyValueStorage("MyStorage");
storage->SetValue("VehicleSpeed", 85.5);
auto speed = storage->GetValue("VehicleSpeed");

// File
auto fileStorage = ara::per::OpenFileStorage("Logs");
auto file = fileStorage->OpenFile("error.log", OpenMode::Write);
file->Write(logData);
```

### ara::log - Logging & Tracing

Structured logging with severity levels, context tracking, and remote output.

**Severity Levels**:
- `kFatal`: Unrecoverable error, system halt
- `kError`: Recoverable error condition
- `kWarn`: Unexpected behavior, degraded operation
- `kInfo`: Notable events, state transitions
- `kDebug`: Detailed diagnostics
- `kVerbose`: Trace-level detail

### ara::core - Common Types

Fundamental data types and utilities used across all functional clusters.

**Key Types**:
- `Result<T, E>`: Error handling without exceptions
- `Optional<T>`: Represents optional values
- `Span<T>`: Non-owning view of contiguous data
- `StringView`: Non-owning string reference
- `ErrorCode`: Standardized error representation

**Result Pattern**:
```cpp
ara::core::Result<double> CalculateRatio(double a, double b) {
    if (b == 0.0) {
        return ara::core::Result<double>::FromError(
            ErrorCode::kDivisionByZero);
    }
    return ara::core::Result<double>::FromValue(a / b);
}

// Usage
auto result = CalculateRatio(10.0, 2.0);
if (result.HasValue()) {
    std::cout << "Result: " << result.Value() << std::endl;
} else {
    std::cout << "Error: " << result.Error() << std::endl;
}
```

## Manifest Concept

Manifests are JSON/ARXML files describing application metadata, service requirements, and deployment configuration. Unlike Classic Platform's system description, manifests are read at runtime.

### Manifest Types

#### Application Manifest
Describes the application itself:
```json
{
  "ApplicationName": "BatteryManagement",
  "Executable": "/opt/apps/battery_mgmt",
  "ProcessType": "Application",
  "StartupOption": "Automatic",
  "DependsOn": ["PlatformHealthManagement"]
}
```

#### Service Interface Manifest
Defines service contract:
```json
{
  "ServiceInterface": "BatteryMonitor",
  "ServiceVersion": "1.0",
  "Methods": [
    {
      "MethodName": "GetCellVoltages",
      "InputParameters": [],
      "OutputParameters": [{"Type": "VoltageArray"}]
    }
  ],
  "Events": [
    {
      "EventName": "CriticalAlarm",
      "DataType": "AlarmData"
    }
  ]
}
```

#### Service Instance Manifest
Maps service to deployment:
```json
{
  "ServiceInstance": "BatteryMonitor_1",
  "ServiceInterface": "BatteryMonitor",
  "InstanceId": "101",
  "ProvidedPort": {
    "CommunicationBinding": "SOMEIP",
    "NetworkEndpoint": "192.168.1.10:30501"
  }
}
```

#### Machine Manifest
Describes ECU capabilities:
```json
{
  "Machine": "HighPerformanceECU",
  "Processors": [
    {
      "ProcessorName": "ARM_A72",
      "Cores": 4,
      "Frequency": "1.5GHz"
    }
  ],
  "NetworkInterfaces": [
    {
      "InterfaceName": "eth0",
      "IPAddress": "192.168.1.10",
      "NetworkType": "Ethernet"
    }
  ]
}
```

#### Execution Manifest
Deployment-specific configuration:
```json
{
  "Process": "BatteryManagement",
  "Machine": "HighPerformanceECU",
  "StateDependent": [
    {
      "FunctionGroup": "Driving",
      "State": "Active"
    }
  ],
  "ResourceLimits": {
    "MemoryLimit": "256MB",
    "CPUQuota": "50%"
  }
}
```

## Communication Patterns

### Method Call (Request-Response)

Client invokes method on service, waits for response.

```
Client                    Server
  │                          │
  ├──── Request ────────────>│
  │                          │ Process
  │<───── Response ──────────┤
  │                          │
```

**Use cases**: Configuration queries, command execution

### Event Subscription (Publish-Subscribe)

Server publishes events, clients subscribe to receive updates.

```
Server                    Client
  │                          │
  │<──── Subscribe ──────────┤
  │                          │
  ├──── Event Data ────────>│
  ├──── Event Data ────────>│
  ├──── Event Data ────────>│
```

**Use cases**: Sensor data streams, status updates, alarms

### Field Access (Get/Set/Notify)

Combines getter/setter methods with change notification.

```
Client                    Server
  │                          │
  ├──── Get Field ─────────>│
  │<───── Value ─────────────┤
  │                          │
  ├──── Set Field ─────────>│
  │<───── Ack ───────────────┤
  │                          │
  │<──── Notification ───────┤ (on change)
```

**Use cases**: Configuration parameters, state variables

## Transport Bindings

AP supports multiple transport protocols, selected via manifest configuration.

### SOME/IP

Automotive-specific protocol for service-oriented communication.

**Characteristics**:
- UDP for events (low latency)
- TCP for methods (reliability)
- Service discovery via SD (Service Discovery)
- Serialization: Binary, compact

**Message Structure**:
```
┌────────────────────────────┐
│ Message ID (32 bit)        │ Service ID + Method ID
├────────────────────────────┤
│ Length (32 bit)            │
├────────────────────────────┤
│ Request ID (32 bit)        │ Client ID + Session ID
├────────────────────────────┤
│ Protocol Version (8 bit)   │
├────────────────────────────┤
│ Interface Version (8 bit)  │
├────────────────────────────┤
│ Message Type (8 bit)       │ REQUEST/RESPONSE/EVENT
├────────────────────────────┤
│ Return Code (8 bit)        │ OK/ERROR
├────────────────────────────┤
│ Payload                    │ Serialized arguments
└────────────────────────────┘
```

### DDS (Data Distribution Service)

OMG standard for data-centric pub-sub.

**Characteristics**:
- Quality of Service (QoS) policies
- Global data space concept
- Discovery without central broker
- Topic-based filtering

**QoS Policies**:
- `Reliability`: Best-effort vs. reliable delivery
- `Durability`: Transient vs. persistent data
- `History`: Keep-last vs. keep-all samples
- `Deadline`: Maximum time between updates

### Signal-based IPC

Lightweight local communication for same-ECU services.

**Mechanisms**:
- Shared memory for zero-copy data transfer
- POSIX signals for event notification
- Unix domain sockets for method calls

## Service Discovery

Dynamic mechanism for finding service instances at runtime.

### FindService Pattern

```cpp
// Client discovers BatteryMonitor service
auto findHandle = ara::com::FindService<BatteryMonitorProxy>(
    ara::com::InstanceIdentifier("BatteryMonitor_1"));

findHandle.SetFindServiceHandler([](auto services) {
    if (services.size() > 0) {
        // Service found, create proxy
        BatteryMonitorProxy proxy(services[0]);
        // Use proxy for communication
    }
});

ara::com::StartFindService(findHandle);
```

### Service Registry

Central registry maintaining available service instances.

**Registry Content**:
- Service interface name
- Instance ID
- Network endpoint (IP:Port)
- Transport binding type
- Service version

**Update Triggers**:
- Service starts: Offer service
- Service stops: Stop offering
- Network change: Update endpoint
- Version upgrade: Update version

## E2E Protection

End-to-End protection ensures data integrity across communication chains.

### Protection Mechanisms

**Counter**: Detects message loss
```
Msg 1: Counter=1  →  Received: Counter=1 ✓
Msg 2: Counter=2  →  Received: Counter=2 ✓
Msg 3: Counter=3  →  Lost
Msg 4: Counter=4  →  Received: Counter=4 ✗ (gap detected)
```

**CRC**: Detects data corruption
```
Payload: [0x12, 0x34, 0x56, 0x78]
CRC: 0xABCD  →  Receiver recalculates: 0xABCD ✓
```

**Alive Counter**: Detects timeout
```
Expected period: 100ms
Last message: T0
Current time: T0 + 250ms  →  Timeout error ✗
```

### E2E Profiles

- **Profile 1**: CRC-8, 8-bit counter, max 240 bytes
- **Profile 2**: CRC-8, 4-bit counter, max 2048 bytes
- **Profile 4**: CRC-32, 16-bit counter, unlimited size
- **Profile 7**: CRC-64, 32-bit counter, safety-critical

## Platform Health Management (PHM)

Monitors application health, detects failures, triggers recovery.

### Health States

```
        ┌────────┐
        │  OK    │
        └───┬────┘
            ↓ Failure detected
        ┌────────┐
        │ FAILED │
        └───┬────┘
            ↓ Recovery action
        ┌────────┐
        │RECOVERING
        └───┬────┘
            ↓ Success
        ┌────────┐
        │  OK    │
        └────────┘
```

### Supervision Types

**Alive Supervision**: Application sends heartbeat
```cpp
auto supervision = ara::phm::CreateAliveSupervision("MyApp");
while (running) {
    supervision->ReportAlive();
    std::this_thread::sleep_for(100ms);
}
```

**Deadline Supervision**: Operation completes within time limit
```cpp
auto checkpoint = ara::phm::ReportCheckpoint("DataProcessing");
// ... perform processing ...
checkpoint->ReportCompletion();  // Must complete within deadline
```

**Logical Supervision**: Application-specific health checks
```cpp
auto logical = ara::phm::CreateLogicalSupervision("SensorCheck");
if (sensorDataValid) {
    logical->ReportOk();
} else {
    logical->ReportError(ErrorCode::kSensorFailure);
}
```

## Next Steps

- **Level 3**: Detailed implementation guide with complete code examples
- **Level 4**: API reference with all ara:: interfaces
- **Level 5**: Advanced topics including multi-binding, IAM, UCM

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Automotive software architects, AUTOSAR AP developers
