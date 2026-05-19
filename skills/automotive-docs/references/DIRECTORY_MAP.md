# Directory Mapping - Automotive Claude Code Agents

## Overview

This document explains the skill directory structure and addresses the apparent duplication between `automotive-*` prefixed directories and their non-prefixed counterparts.

## Directory Structure Explained

The skills directory contains **two distinct types** of content:

### 1. Generated Domain Skills (Base Directories)

**Location**: `skills/{domain}/`
**Format**: YAML skill files
**Count**: ~4,600 skills across 62 domains
**Naming**: `{feature}-{number}.yaml` (e.g., `adaptive-cruise-control-001.yaml`)

These are **automatically generated** skills covering specific automotive features. Each YAML file:
- Provides expert knowledge on a narrow domain application
- Follows consistent schema (name, version, category, description, instructions)
- Tagged with automotive standards (ISO 26262, AUTOSAR, ASPICE)
- Production-ready for ECU implementation guidance

**Example domains**:
- `skills/adas/` - 385 YAML files for ADAS features
- `skills/battery/` - Battery management system skills
- `skills/diagnostics/` - UDS, OBD-II diagnostic protocols
- `skills/powertrain/` - Engine control, transmission skills

### 2. Curated Expert Documentation (Automotive-Prefixed Directories)

**Location**: `skills/automotive-{domain}/`
**Format**: Markdown documentation files
**Count**: ~70 expert guides across 14 major categories
**Content**: Production-ready code, architecture patterns, testing frameworks

These are **hand-crafted expert resources** containing:
- Complete code implementations (C++, Python, AUTOSAR XML)
- Architecture patterns and best practices
- HIL/SiL testing strategies
- Performance benchmarks and standards compliance

**Example mappings**:

| Base Directory | Automotive-Prefixed Directory | Content Type |
|----------------|-------------------------------|--------------|
| `skills/adas/` | `skills/automotive-adas/` | YAML skills → Expert MD docs |
| `skills/diagnostics/` | `skills/automotive-diagnostics/` | YAML skills → Expert MD docs |
| `skills/powertrain/` | `skills/automotive-powertrain-chassis/` | YAML skills → Expert MD docs |
| `skills/safety/` | `skills/automotive-safety/` | YAML skills → Expert MD docs |
| `skills/v2x/` | `skills/automotive-v2x/` | YAML skills → Expert MD docs |

## Complete Directory Mapping

### Automotive-Prefixed Directories and Their Base Counterparts

| # | Automotive-Prefixed | Base Directory | Files | Type | Description |
|---|---------------------|----------------|-------|------|-------------|
| 1 | `automotive-adas` | `adas` | 7 MD vs 385 YAML | Expert docs vs Skills | ADAS features: ACC, LKA, AEB, sensor fusion |
| 2 | `automotive-ai-ecu` | *(generated)* | 15 MD | Expert docs | AI/ML on ECUs, edge inference, TensorFlow Lite |
| 3 | `automotive-cybersecurity` | `security` | 12 MD vs 180 YAML | Expert docs vs Skills | ISO 21434, secure boot, HSM, intrusion detection |
| 4 | `automotive-diagnostics` | `diagnostics` | 8 MD vs 220 YAML | Expert docs vs Skills | UDS, DoIP, OBD-II, flash programming |
| 5 | `automotive-ecu-systems` | `embedded` | 10 MD vs 150 YAML | Expert docs vs Skills | ECU architecture, MCAL, bootloader, watchdog |
| 6 | `automotive-hpc` | *(mixed)* | 18 MD | Expert docs | High-performance compute, hypervisors, SoC |
| 7 | `automotive-ml` | *(generated)* | 9 MD | Expert docs | ML for automotive, PyTorch, TensorRT, ONNX |
| 8 | `automotive-powertrain-chassis` | `powertrain` + `chassis` | 14 MD vs 350 YAML | Expert docs vs Skills | ECM, TCM, ESC, EPS, suspension control |
| 9 | `automotive-protocols` | `network` | 11 MD vs 180 YAML | Expert docs vs Skills | CAN, LIN, FlexRay, Automotive Ethernet, SOME/IP |
| 10 | `automotive-safety` | `safety` + `safety-analysis` | 16 MD vs 200 YAML | Expert docs vs Skills | ISO 26262 lifecycle, ASIL, FMEA, FTA, HARA |
| 11 | `automotive-sdv` | `cloud` + `cloud-native` | 12 MD vs 120 YAML | Expert docs vs Skills | Software-defined vehicle, OTA, digital twins |
| 12 | `automotive-v2x` | `v2x` | 9 MD vs 95 YAML | Expert docs vs Skills | V2V, V2I, DSRC, C-V2X, platooning |
| 13 | `automotive-workflow` | `project-management` | 6 MD vs 45 YAML | Expert docs vs Skills | V-Model, Scrum, ASPICE, requirements |
| 14 | `automotive-zonal` | *(generated)* | 10 MD vs 80 YAML | Expert docs vs Skills | Zonal architecture, zone controllers, gateway |

### Base Directories Without Automotive-Prefixed Counterparts

These domains have **only YAML skills** (no expert markdown documentation):

| Domain | Files | Description |
|--------|-------|-------------|
| `access-control` | 12 | Keyless entry, immobilizer, access control |
| `audio` | 45 | Audio processing, ANC, sound synthesis |
| `autosar` | 320 | AUTOSAR Classic/Adaptive platform skills |
| `battery-lifecycle` | 25 | Battery aging, SOH, predictive maintenance |
| `body` | 180 | Body control module, lighting, HVAC, seats |
| `braking` | 95 | ABS, ESC, brake-by-wire, regenerative braking |
| `calibration` | 40 | ECU calibration, A2L, XCP, INCA |
| `charging-infrastructure` | 30 | EV charging, CCS, CHAdeMO, ISO 15118 |
| `comfort` | 65 | Comfort features, climate control, seat memory |
| `crash-avoidance` | 55 | Collision avoidance, pre-crash systems |
| `driver-monitoring` | 40 | DMS, drowsiness detection, gaze tracking |
| `dynamics` | 75 | Vehicle dynamics, handling, stability control |
| `ev-tools` | 35 | EV-specific tools, battery testing, thermal |
| `exhaust` | 28 | Exhaust aftertreatment, SCR, DPF, OBD |
| `fuel-system` | 42 | Fuel injection, GDI, port injection |
| `hardware-safety` | 30 | Hardware safety mechanisms, redundancy |
| `hil-sil` | 50 | HIL/SiL testing, dSPACE, Vector CANoe |
| `hmi` | 120 | Human-machine interface, instrument cluster |
| `hvac` | 38 | HVAC control, climate algorithms |
| `hydrogen-fuelcell` | 22 | FCEV, hydrogen systems, fuel cell control |
| `infotainment` | 85 | Infotainment systems, Android Auto, CarPlay |
| `kubernetes` | 15 | Kubernetes for automotive edge/cloud |
| `lighting` | 55 | Adaptive headlights, DRL, ambient lighting |
| `logging` | 18 | Diagnostic logging, DLT, trace analysis |
| `manufacturing` | 32 | Manufacturing testing, EOL testing |
| `mbd` | 60 | Model-based design, MATLAB/Simulink |
| `middleware` | 48 | Middleware, DDS, SOME/IP service discovery |
| `navigation` | 70 | Navigation, routing, map matching |
| `occupant-safety` | 45 | Airbags, seat belts, crash sensors |
| `oem-decision-making` | 15 | OEM architecture decisions, platform strategy |
| `parking` | 50 | Parking assist, automated valet parking |
| `qnx` | 35 | QNX RTOS, safety-certified OS |
| `regulatory-compliance` | 25 | UN ECE, FMVSS, Euro NCAP compliance |
| `security-systems` | 40 | Security features, alarm systems, tracking |
| `sotif` | 30 | ISO 21448 SOTIF (Safety of Intended Functionality) |
| `steering` | 48 | EPS, steer-by-wire, steering control |
| `suspension` | 52 | Adaptive suspension, air suspension, damping |
| `telematics` | 55 | Telematics, fleet management, connected services |
| `testing` | 95 | Testing strategies, test automation, frameworks |
| `transmission` | 68 | Transmission control, DCT, CVT, AT |
| `advanced-materials` | 8 | Advanced materials (lightweight, battery) |

## Why This Structure?

### Design Rationale

1. **Breadth vs. Depth**:
   - Base directories provide **breadth** - thousands of specific skills
   - Automotive-prefixed directories provide **depth** - production code and expertise

2. **Generation vs. Curation**:
   - YAML skills can be **generated** from standards and requirements
   - Expert markdown requires **hand-crafted** production experience

3. **Use Case Separation**:
   - YAML skills: Quick reference, conceptual guidance, requirements analysis
   - Expert docs: Implementation, code examples, architecture decisions

4. **Tooling Integration**:
   - YAML skills: Machine-parseable, schema-validated, indexable
   - Expert docs: Human-readable, code-rich, tutorial-style

## Migration Plan

### Phase 1: Consolidation (Q2 2026)

Merge automotive-prefixed directories into base directories:

```
skills/adas/
├── skills/          # YAML skill files (existing)
├── expert/          # Markdown expert docs (from automotive-adas)
└── README.md        # Category overview
```

### Phase 2: Keyword Categories (Q3 2026)

Implement keyword-based organization:

- **Keywords**: `level: [beginner|intermediate|expert]`
- **Skill YAMLs**: `level: beginner` (guidance)
- **Expert MDs**: `level: expert` (production code)

Example:
```yaml
# skills/adas/adaptive-cruise-control-001.yaml
name: adaptive-cruise-control-001
category: adas
level: beginner
type: skill
```

vs.

```yaml
# skills/adas/expert/acc-production-implementation.md
title: ACC Production Implementation
category: adas
level: expert
type: expert-guide
```

### Phase 3: Unified Discovery (Q4 2026)

Single search interface:
```bash
# Find all ADAS content
claude-skills search --category adas

# Find expert-level content only
claude-skills search --category adas --level expert

# Find beginner skills
claude-skills search --category adas --level beginner
```

## Current Usage Patterns

### For Beginners
Start with **base directory YAML skills**:
```bash
skills/adas/adaptive-cruise-control-001.yaml  # Conceptual overview
skills/adas/lane-keep-assist-003.yaml         # LKA fundamentals
```

### For Experts
Reference **automotive-prefixed markdown docs**:
```bash
skills/automotive-adas/adas-features-implementation.md  # Production code
skills/automotive-adas/sensor-fusion-perception.md      # Architecture
```

### For Production Implementation
Combine both:
1. Read YAML skill for requirements and standards
2. Reference expert MD for production code patterns
3. Adapt code to specific ECU platform

## Validation

Schema validator (`scripts/validate-schema.py`) checks:
- **YAML skills**: Required fields (name, description, instructions)
- **Expert docs**: Exempt from schema validation (freeform markdown)

Only YAML files in base directories are validated.

## Questions?

See also:
- `CLAUDE.md` - Project overview
- `SOURCE_OF_TRUTH.md` - Canonical skill list
- `scripts/validate-schema.py` - Schema validation tool

For consolidation roadmap, see:
- `ROADMAP.md` - Future plans for unified skill organization
