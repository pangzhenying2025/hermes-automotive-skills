# AUTOSAR Adaptive Platform - Overview

## What is AUTOSAR Adaptive?

AUTOSAR Adaptive Platform (AP) is a service-oriented software platform for high-performance computing ECUs in modern vehicles. Introduced in 2017, it complements AUTOSAR Classic by supporting dynamic, service-oriented architectures required for autonomous driving, connectivity, and over-the-air updates.

## Key Characteristics

- **Service-Oriented Architecture (SOA)**: Based on ara::com (SOME/IP)
- **Dynamic configuration**: Services discovered and configured at runtime
- **POSIX-based**: Runs on Linux/Unix-like operating systems
- **High-performance**: Designed for multi-core ARM/x86 processors
- **Modern C++**: Uses C++14 standard with C++17/20 extensions

## Architecture Overview

```
┌─────────────────────────────────────────┐
│   Adaptive Applications                 │
│   (C++14 with Functional Clusters)      │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│   Adaptive AUTOSAR Services (ARA)       │
│   - ara::com (Communication)            │
│   - ara::exec (Execution Management)    │
│   - ara::per (Persistency)              │
│   - ara::diag (Diagnostics)             │
│   - ara::crypto (Cryptography)          │
│   - ara::iam (Identity & Access Mgmt)   │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│   Operating System (Linux/POSIX)        │
└─────────────────────────────────────────┘
```

## Functional Clusters (ARA APIs)

### Communication (ara::com)
Service-oriented communication using SOME/IP protocol
- Service discovery
- Event/method/field communication
- Serialization (SOME/IP, DDS)

### Execution Management (ara::exec)
Application lifecycle and process management
- Process startup/shutdown
- State management
- Deterministic execution

### Persistency (ara::per)
Key-value storage and file-based persistence
- Atomic updates
- Redundancy support
- Installation fallback

### Diagnostics (ara::diag)
UDS-based diagnostics
- Event memory
- Data identifiers
- Routine control

### Cryptography (ara::crypto)
Security services
- Symmetric/asymmetric encryption
- Hashing, MAC, signatures
- Key management

### Identity & Access Management (ara::iam)
Authentication and authorization
- Certificate management
- Role-based access control

## Use Cases

AUTOSAR Adaptive excels in:
- Autonomous driving compute platforms
- V2X communication gateways
- High-performance domain controllers
- OTA (Over-The-Air) update management
- Cloud connectivity and telematics

## Classic vs. Adaptive Comparison

| Feature | Classic Platform | Adaptive Platform |
|---------|------------------|-------------------|
| **Architecture** | Static, ECU-centric | Dynamic, service-oriented |
| **Configuration** | Design-time (ARXML) | Runtime service discovery |
| **OS** | AUTOSAR OS (OSEK) | POSIX (Linux) |
| **Language** | C | C++14+ |
| **Communication** | Signal-based (CAN) | Service-based (Ethernet) |
| **CPU** | Single/multi-core MCU | Multi-core MPU |
| **Safety** | Up to ASIL D | Up to ASIL D (with extensions) |
| **Security** | SecOC | Comprehensive crypto stack |
| **Typical ECUs** | Powertrain, body, chassis | ADAS, gateways, infotainment |

## Release History

| Version | Year | Key Features |
|---------|------|--------------|
| R17-03 | 2017 | Initial release, core functional clusters |
| R17-10 | 2017 | Safety extensions, crypto |
| R18-03 | 2018 | Enhanced diagnostics, network binding |
| R18-10 | 2018 | State management, log & trace |
| R19-03 | 2019 | Time synchronization, platform health |
| R19-10 | 2019 | Update & configuration management |
| R20-11 | 2020 | Firewall, IDS/IPS |
| R21-11 | 2021 | Enhanced security, V2X |
| R22-11 | 2022 | Cloud connectivity extensions |

## Technology Stack

### Operating Systems
- Linux (Yocto, Ubuntu, custom distributions)
- QNX (supported by some vendors)
- POSIX-compliant RTOS

### Communication
- SOME/IP (primary)
- DDS (alternative binding)
- MQTT, HTTP/REST (extensions)

### Build System
- CMake
- Conan (dependency management)
- Docker (containerization)

## Getting Started

To develop AUTOSAR Adaptive applications:

1. **Development environment**: Linux workstation with C++14 compiler
2. **AUTOSAR AP stack**: Commercial (Vector, EB) or open-source
3. **Service Interface**: Define services in ARXML (ServiceInterface)
4. **Code generation**: Generate ara:: API bindings
5. **Implementation**: Implement application logic in C++
6. **Manifest**: Create execution manifest (JSON/ARXML)
7. **Deployment**: Deploy to target platform

## Example: Simple Service

```cpp
// Service Interface Definition (generated from ARXML)
#include "ara/com/sample_service_proxy.h"
#include "ara/exec/execution_client.h"

int main() {
    // Initialize execution management
    ara::exec::ExecutionClient exec_client;
    exec_client.ReportExecutionState(ara::exec::ExecutionState::kRunning);

    // Find service
    auto handle = ara::com::SampleService::StartFindService(
        [](ara::com::ServiceHandleContainer<ara::com::SampleService::HandleType> handles) {
            // Service found callback
        }
    ).Value();

    // Create proxy and call method
    ara::com::SampleService::Proxy proxy(handle);
    auto result = proxy.GetData();

    return 0;
}
```

## Next Steps

- **Level 2**: Conceptual understanding of functional clusters
- **Level 3**: Detailed API documentation and patterns
- **Level 4**: Complete reference for all ara:: interfaces
- **Level 5**: Advanced patterns, safety, and performance optimization

## References

- AUTOSAR Adaptive Platform Release R22-11
- AUTOSAR Specification of Adaptive Platform Core
- ISO 26262 ASIL D compliance guide for Adaptive Platform

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Automotive software engineers transitioning to Adaptive Platform
