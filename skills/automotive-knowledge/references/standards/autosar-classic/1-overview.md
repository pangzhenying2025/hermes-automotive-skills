# AUTOSAR Classic Platform - Overview

## What is AUTOSAR Classic?

AUTOSAR Classic Platform (CP) is a standardized software architecture for automotive electronic control units (ECUs). Established in 2003, it provides a layered architecture that separates application software from the underlying hardware and basic software.

## Key Characteristics

- **Event-driven architecture**: Based on OSEK/VDX operating system
- **Static configuration**: System configured at design time using configuration tools
- **ECU-centric**: Designed for single-core to multi-core microcontrollers
- **Safety-critical**: Suitable for ASIL D applications per ISO 26262

## Architecture Layers

```
┌─────────────────────────────────┐
│   Application Layer (SWCs)      │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│   Runtime Environment (RTE)     │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│   Basic Software (BSW)          │
│   - Services, ECU Abstraction   │
│   - MCAL (Drivers)              │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│   Microcontroller Hardware      │
└─────────────────────────────────┘
```

## Core Concepts

### Software Components (SWCs)
Application software units with defined interfaces (ports). SWCs are:
- Hardware-independent
- Reusable across different ECU platforms
- Connected via the RTE

### Runtime Environment (RTE)
Middleware layer providing:
- Communication between SWCs
- Abstraction from BSW services
- Generated from system description (ARXML)

### Basic Software (BSW)
Standardized modules including:
- Communication stack (CAN, LIN, FlexRay, Ethernet)
- Memory services (NvM, MemIf)
- Diagnostic services (Dcm, Dem)
- Operating system (AUTOSAR OS)

## Use Cases

AUTOSAR Classic excels in:
- Powertrain control (engine, transmission)
- Body electronics (lighting, HVAC)
- Chassis systems (ABS, ESP)
- Traditional ECU applications with deterministic behavior

## Release History

| Version | Year | Key Features |
|---------|------|--------------|
| R3.0 | 2008 | First complete specification |
| R4.0 | 2010 | Multi-core support, FlexRay |
| R4.2 | 2014 | Ethernet, security modules |
| R4.3 | 2016 | Enhanced diagnostics, E2E protection |
| R4.4 | 2018 | Automotive Ethernet improvements |
| R22-11 | 2022 | Latest release, continuous updates |

## Getting Started

To work with AUTOSAR Classic, you need:

1. **Configuration tool** (e.g., Vector DaVinci Configurator, EB tresos Studio)
2. **AUTOSAR BSW stack** (commercial or open-source like ARCTIC CORE)
3. **Compiler toolchain** for target microcontroller
4. **System description** in AUTOSAR XML (ARXML) format

## Next Steps

- **Level 2**: Conceptual understanding of AUTOSAR Classic architecture
- **Level 3**: Detailed module specifications and workflows
- **Level 4**: Complete reference documentation
- **Level 5**: Advanced implementation patterns and optimization

## References

- AUTOSAR Official Specifications: https://www.autosar.org
- AUTOSAR Classic Platform Release R22-11
- ISO 26262 Road Vehicles - Functional Safety

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Automotive engineers, software architects, newcomers to AUTOSAR
