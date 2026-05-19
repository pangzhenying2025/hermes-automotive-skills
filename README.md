# Hermes Automotive Skills

**88 automotive domain skills for [Hermes Agent](https://hermes-agent.nousresearch.com)** — converted from [automotive-claude-code-agents](https://github.com/sydyg/automotive-claude-code-agents).

This repository provides a comprehensive set of automotive software engineering skills covering ADAS, AUTOSAR, functional safety (ISO 26262 / GB 34590), SOTIF, cybersecurity (ISO 21434), diagnostics (UDS), V2X, powertrain, chassis, embedded, battery/BMS, and China-specific regulatory standards. Each skill is packaged as a Hermes Agent `SKILL.md` file.

---

## Attribution

This work is a **format migration** of the excellent [automotive-claude-code-agents](https://github.com/sydyg/automotive-claude-code-agents) repository. The original project was authored by:

| Contributor | Role | Affiliation |
|-------------|------|-------------|
| [theja0473](https://github.com/theja0473) | Original author | automotive-claude-code-agents |
| [sydyg (张玉新)](https://github.com/sydyg) | Enhanced fork maintainer | Jilin University / Zhuoyu Technology (卓驭科技) / Yuyan Technology (驭研科技) |

**What changed in this fork:**

- **Format**: Converted 4,851 source files (YAML + Markdown) from Claude Code workspace format (`~/.claude/agents|skills|commands|rules`) into 88 Hermes Agent `SKILL.md` files with YAML frontmatter.
- **Merging**: Domain-level YAML skills (e.g., `adas/` with 376 individual YAML files → one `automotive-adas` Hermes skill) and `automotive-*` Markdown skills (e.g., `automotive-cybersecurity/` with 6 `.md` files → one `automotive-cybersecurity` Hermes skill) were merged per domain.
- **No content was removed or modified** beyond structural reformatting.

The original repository remains the authoritative source for Claude Code users. This repository is a complementary distribution for the Hermes Agent ecosystem.

---

## Skills Overview

### YAML Domain Skills (59)

Each domain directory from the original repo's `skills/` directory is merged into one Hermes skill. These cover the broadest automotive engineering knowledge base.

| Source Domain | Hermes Skill | Source Files | Standards Covered |
|---------------|-------------|-------------|-------------------|
| `adas/` | `automotive-adas` | 376 | ISO 26262, ASPICE, AUTOSAR 4.4 |
| `autosar/` | `automotive-autosar` | 264 | AUTOSAR Classic/Adaptive 4.4 |
| `battery/` | `automotive-battery` | 160 | ISO 26262, ASPICE |
| `diagnostics/` | `automotive-diagnostics` | 171 | UDS (ISO 14229), OBD-II, DoIP |
| `embedded/` | `automotive-embedded` | 241 | MISRA C, AUTOSAR, ISO 26262 |
| `powertrain/` | `automotive-powertrain` | 300 | ISO 26262, OBD-II, ASPICE |
| `safety/` | `automotive-safety` | 260+6 | ISO 26262, FMEA, FTA, HARA |
| `security/` | `automotive-security` | 198 | ISO 21434 |
| `testing/` | `automotive-testing` | 223 | ASPICE, ISO 26262 |
| `network/` | `automotive-network` | 194 | CAN, LIN, FlexRay, Ethernet |
| `v2x/` | `automotive-v2x` | 120 | IEEE 802.11p, C-V2X, SAE J2735 |
| `infotainment/` | `automotive-infotainment` | 252 | Android Auto, Apple CarPlay, GENIVI |
| ...and 47 more | *_see full list below_* | 1-166 | *various* |

### Automotive-\* Markdown Skills (21)

These skills were originally written as standalone Markdown documents with richer prose, examples, and detailed walkthroughs.

| Original Directory | Hermes Skill | Files | Topics |
|-------------------|-------------|-------|--------|
| `automotive-cybersecurity/` | `automotive-cybersecurity` | 6 | ISO 21434, Penetration Testing, Secure Boot, IDS |
| `automotive-diagnostics/` | `automotive-diagnostics` | 8 | UDS, DoIP, DTC, Flash Programming, Tooling |
| `automotive-sdv/` | `automotive-sdv` | 6 | OTA, Digital Twins, Vehicle App Stores, Cloud |
| `automotive-hpc/` | `automotive-hpc` | 5 | Hypervisor, Containerization, AUTOSAR Adaptive |
| `automotive-ml/` | `automotive-ml` | 6 | Anomaly Detection, Fleet Analytics, Predictive Maintenance |
| `automotive-ai-ecu/` | `automotive-ai-ecu` | 5 | Camera Vision, NPU, Voice NLU, Edge AI |
| `automotive-ecu-systems/` | `automotive-ecu-systems` | 8 | BCM, BMS, IVI, Domain Controller, PDU |
| ...and 14 more | *_see below_* | 1-10 | *various* |

### China Regulatory Standards (10)

Comprehensive coverage of China's automotive safety and regulatory landscape — most of these are unique to this enhanced fork.

| Source Directory | Hermes Skill | Standard |
|-----------------|-------------|----------|
| `china-standards/functional-safety/` | `china-functional-safety` | GB/T 34590-2022 (ISO 26262 IDT, 12 parts) |
| `china-standards/sotif/` | `china-sotif` | GB/T 43267-2023 + CSAE 316.1/316.2 + CSAE 336 |
| `china-standards/ads-safety/` | `china-ads-safety` | ADS Mandatory Safety Requirements (draft 2025.11) |
| `china-standards/l2-adas-safety/` | `china-l2-adas-safety` | L2 ADAS Mandatory Safety (draft v2.1) |
| `china-standards/l3-fusa-sotif/` | `china-l3-fusa-sotif` | L3 FuSa+SOTIF Combined Requirements (draft 2025.01) |
| `china-standards/ai-safety/` | `china-ai-safety` | ISO PAS 8800 + ISO/IEC TR 5469 (AI Safety) |
| `china-standards/behavioral-safety/` | `china-behavioral-safety` | IEEE 2846-2022 (RSS Safety Assumptions) |
| `china-standards/scenario-safety/` | `china-scenario-safety` | ISO 34501/34502/34503/34504/34505 |
| `china-standards/odd/` | `china-odd` | ODD (Operational Design Domain) Standard |
| `china-standards/multi-pillar/` | `china-multi-pillar` | Multi-Pillar Standards Application Guide (152 pp) |

---

## Full Skill List

<details>
<summary><b>Click to expand</b> — all 88 skills</summary>

### YAML Domain Skills (59)
automotive-access-control, automotive-adas, automotive-aftermarket, automotive-audio, automotive-autosar, automotive-battery, automotive-battery-lifecycle, automotive-body, automotive-braking, automotive-calibration, automotive-charging, automotive-chassis, automotive-cloud, automotive-cockpit, automotive-comfort, automotive-crash-avoidance, automotive-diagnostics, automotive-driver-monitoring, automotive-dynamics, automotive-embedded, automotive-ev-tools, automotive-exhaust, automotive-fuel-system, automotive-hardware-safety, automotive-hil-sil, automotive-hmi, automotive-hvac, automotive-hydrogen-fuelcell, automotive-infotainment, automotive-lighting, automotive-logging, automotive-manufacturing, automotive-materials, automotive-mbd, automotive-middleware, automotive-navigation, automotive-network, automotive-occupant-safety, automotive-oem-decision, automotive-parking, automotive-powertrain, automotive-project-management, automotive-protocols, automotive-qnx, automotive-quantum, automotive-regulatory-compliance, automotive-safety, automotive-safety-analysis, automotive-satellite, automotive-security, automotive-security-systems, automotive-sotif, automotive-steering, automotive-suspension, automotive-telematics, automotive-testing, automotive-transmission, automotive-uam-evtol, automotive-v2x, automotive-workflow, automotive-zonal

### Automotive-\* Markdown Skills (21)
automotive-adas, automotive-ai-ecu, automotive-china-l2-adas-compliance, automotive-china-l3-ads-compliance, automotive-china-parking-compliance, automotive-china-standards-overview, automotive-cybersecurity, automotive-dfm-benchmarking, automotive-diagnostics, automotive-e2e-safety-analysis, automotive-ecu-systems, automotive-hpc, automotive-ml, automotive-powertrain-chassis, automotive-protocols, automotive-safety, automotive-scenario-driven-testing, automotive-sdv, automotive-sotif-audit, automotive-sotif-hazard-scenario, automotive-sotif-highway-testing, automotive-v2x, automotive-workflow, automotive-zonal

### China Standards (10)
china-ads-safety, china-ai-safety, china-behavioral-safety, china-functional-safety, china-l2-adas-safety, china-l3-fusa-sotif, china-multi-pillar, china-odd, china-scenario-safety, china-sotif

</details>

---

## Installation

### For Hermes Agent

Copy the desired skill directories into your Hermes skills path:

```bash
# Clone the repo
git clone https://github.com/pangzhenying2025/hermes-automotive-skills.git

# Install all skills to Hermes
cp -r hermes-automotive-skills/skills/* /path/to/hermes/skills/

# Or install individual skills
cp -r hermes-automotive-skills/skills/automotive-autosar /path/to/hermes/skills/
```

Hermes will auto-discover the skills on next use. You can verify with:
```bash
hermes skills list | grep automotive
```

### For Claude Code

This is a Hermes-specific distribution. For the original Claude Code version, see [sydyg/automotive-claude-code-agents](https://github.com/sydyg/automotive-claude-code-agents) and run:
```bash
git clone https://github.com/sydyg/automotive-claude-code-agents.git
cd automotive-claude-code-agents
./install.sh
```

---

## Domain Coverage

- **ADAS / Autonomous Driving**: ACC, LKA, AEB, BSD, Lane Keeping, Path Planning, Sensor Fusion, Functional Architecture (L0-L5)
- **AUTOSAR**: Classic Platform (R4.4), Adaptive Platform, RTE, COM Stack, Diagnostic Stack, Memory Stack, Crypto Stack, Complex Drivers
- **Functional Safety**: ISO 26262 (GB/T 34590), HARA, FMEA, FTA, ASIL Decomposition, Safety Mechanisms, FMEDA
- **SOTIF**: ISO 21448, Hazard Scenarios, ODD Analysis, Trigger Events, Functional Insufficiencies
- **Cybersecurity**: ISO 21434, TARA, Secure Boot, HSM, PKI, IDS/IPS, Penetration Testing
- **Battery / BMS**: Cell Modeling, SOC/SOH/SOP Estimation, Thermal Management, Aging Prediction, Cell Balancing
- **Diagnostics**: UDS (ISO 14229), OBD-II (SAE J1979), DoIP, DTC Management, Flash Reprogramming, ODX
- **V2X**: DSRC (IEEE 802.11p), C-V2X (3GPP), Collective Perception, Platooning, Security Certificates
- **Powertrain / Chassis**: ECM, TCM, ESC, EPS, ABS, Active Suspension, Torque Vectoring
- **Embedded**: STM32, ARM Cortex, MISRA C, Bootloader, RTOS, AUTOSAR MCAL, Complex Drivers
- **SDV / HPC**: OTA Updates, Digital Twins, Containerized Apps, Hypervisors, Zonal Architecture, SOME/IP
- **China Standards**: GB/T 34590, GB/T 43267, ADS/L2/L3 Mandatory Safety Drafts, Multi-Pillar Guide
- **Cloud**: AWS IoT, Azure Digital Twins, Fleet Management, Telematics, Edge Computing
- **Testing**: HIL/SIL/MIL, Scenario-Based Testing, Regression, Coverage Analysis, ASPICE

---

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Issues and PRs are welcome. If you find inaccuracies in the skill content, the authoritative source is the [original repository](https://github.com/sydyg/automotive-claude-code-agents). Please consider contributing fixes upstream first.

---

*This project is not affiliated with AUTOSAR, ISO, or any automotive standards body. The skills are reference materials for automotive software engineers and should be validated against official standards documentation for production use.*
