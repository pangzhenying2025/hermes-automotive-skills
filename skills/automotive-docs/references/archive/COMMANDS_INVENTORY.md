# Complete Commands Inventory

## Total: 82 Command Scripts Across 25 Categories

### ADAS (5 scripts)
- `/commands/adas/perception-pipeline.sh` [EXISTING]
- `/commands/adas/sensor-calibration.sh` [NEW]
- `/commands/adas/scenario-generate.sh` [NEW]
- `/commands/adas/perception-eval.sh` [NEW]
- `/commands/adas/odd-define.sh` [NEW]

### AUTOSAR (5 scripts)
- `/commands/autosar/swc-gen.sh` [EXISTING]
- `/commands/autosar/arxml-validate.sh` [NEW]
- `/commands/autosar/swc-scaffold.sh` [NEW]
- `/commands/autosar/bsw-config.sh` [NEW]
- `/commands/autosar/rte-check.sh` [NEW]

### Battery (1 script)
- `/commands/battery/battery-simulate.sh` [EXISTING]

### Calibration (1 script)
- `/commands/calibration/ecu-calibrate.sh` [EXISTING]

### Charging (4 scripts)
- `/commands/charging/ocpp-test.sh` [NEW]
- `/commands/charging/iso15118-check.sh` [NEW]
- `/commands/charging/charging-simulate.sh` [NEW]
- `/commands/charging/grid-impact.sh` [NEW]

### Cloud (5 scripts)
- `/commands/cloud/iot-provision.sh` [NEW]
- `/commands/cloud/ota-package.sh` [NEW]
- `/commands/cloud/fleet-status.sh` [NEW]
- `/commands/cloud/digital-twin-sync.sh` [NEW]
- `/commands/cloud/telemetry-ingest.sh` [NEW]

### Diagnostics (3 scripts)
- `/commands/diagnostics/dtc-decode.sh` [EXISTING]
- `/commands/diagnostics/uds-client.sh` [EXISTING]
- `/commands/diagnostics/doip-scan.sh` [EXISTING]

### Embedded (2 scripts)
- `/commands/embedded/cross-build.sh` [EXISTING]
- `/commands/embedded/flash-ecu.sh` [EXISTING]

### General (6 scripts)
- `/commands/general/project-init.sh` [NEW]
- `/commands/general/lint-all.sh` [NEW]
- `/commands/general/doc-generate.sh` [NEW]
- `/commands/general/dep-audit.sh` [NEW]
- `/commands/general/release-notes.sh` [NEW]
- `/commands/general/skill-search.sh` [NEW]

### HIL/SIL (2 scripts)
- `/commands/hil-sil/hil-setup.sh` [EXISTING]
- `/commands/hil-sil/sil-test.sh` [EXISTING]

### Kubernetes (2 scripts)
- `/commands/kubernetes/k8s-deploy.sh` [EXISTING]
- `/commands/kubernetes/helm-package.sh` [EXISTING]

### LLM Council (4 scripts)
- `/commands/llm-council/council-decide.sh` [EXISTING]
- `/commands/llm-council/council-init.sh` [EXISTING]
- `/commands/llm-council/council-vote.sh` [EXISTING]
- `/commands/llm-council/decision-log.sh` [EXISTING]

### Logging (2 scripts)
- `/commands/logging/log-analyze.sh` [EXISTING]
- `/commands/logging/trace-decode.sh` [EXISTING]

### Manufacturing (4 scripts)
- `/commands/manufacturing/oee-calculate.sh` [NEW]
- `/commands/manufacturing/spc-chart.sh` [NEW]
- `/commands/manufacturing/cycle-time.sh` [NEW]
- `/commands/manufacturing/bom-validate.sh` [NEW]

### MBD (2 scripts)
- `/commands/mbd/mbd-generate.sh` [EXISTING]
- `/commands/mbd/mbd-test.sh` [EXISTING]

### Network (3 scripts)
- `/commands/network/can-monitor.sh` [EXISTING]
- `/commands/network/someip-test.sh` [EXISTING]
- `/commands/network/ethernet-config.sh` [EXISTING]

### QNX (2 scripts)
- `/commands/qnx/qnx-build.sh` [EXISTING]
- `/commands/qnx/qnx-deploy.sh` [EXISTING]

### Regulatory (4 scripts)
- `/commands/regulatory/homologation-checklist.sh` [NEW]
- `/commands/regulatory/emissions-report.sh` [NEW]
- `/commands/regulatory/rohs-check.sh` [NEW]
- `/commands/regulatory/battery-passport.sh` [NEW]

### Safety (5 scripts)
- `/commands/safety/hara-template.sh` [NEW]
- `/commands/safety/fmea-template.sh` [NEW]
- `/commands/safety/asil-decompose.sh` [NEW]
- `/commands/safety/safety-case-init.sh` [NEW]
- `/commands/safety/pmhf-calculate.sh` [NEW]

### Security (5 scripts)
- `/commands/security/tara-template.sh` [NEW]
- `/commands/security/vuln-scan.sh` [NEW]
- `/commands/security/sbom-generate.sh` [NEW]
- `/commands/security/cert-check.sh` [NEW]
- `/commands/security/secret-rotate.sh` [NEW]

### Testing (7 scripts)
- `/commands/testing/unit-test.sh` [EXISTING]
- `/commands/testing/integration-test.sh` [EXISTING]
- `/commands/testing/coverage-report.sh` [NEW]
- `/commands/testing/mcdc-check.sh` [NEW]
- `/commands/testing/fuzz-run.sh` [NEW]
- `/commands/testing/regression-suite.sh` [NEW]
- `/commands/testing/bench-compare.sh` [NEW]

### Tools (1 script)
- `/commands/tools/dependency-graph.sh` [EXISTING]

### V2X (4 scripts)
- `/commands/v2x/v2x-simulate.sh` [NEW]
- `/commands/v2x/dsrc-test.sh` [NEW]
- `/commands/v2x/c-v2x-config.sh` [NEW]
- `/commands/v2x/v2x-decode.sh` [NEW]

## New Commands by Domain (50 total)

| Domain | New Scripts | Description |
|--------|-------------|-------------|
| Safety | 5 | ISO 26262 HARA, FMEA, ASIL, PMHF, safety case |
| Security | 5 | ISO 21434 TARA, vulnerability scanning, SBOM, certificates |
| Cloud | 5 | IoT provisioning, OTA, fleet management, digital twins |
| V2X | 4 | DSRC, C-V2X, message simulation and decoding |
| Charging | 4 | OCPP, ISO 15118, charging simulation, grid impact |
| ADAS | 4 | Sensor calibration, scenarios, perception, ODD |
| AUTOSAR | 4 | ARXML validation, SWC scaffolding, BSW config |
| Manufacturing | 4 | OEE, SPC, cycle time, BOM validation |
| Regulatory | 4 | Homologation, emissions, RoHS, battery passport |
| Testing | 5 | Coverage, MC/DC, fuzzing, regression, benchmarks |
| General | 6 | Project init, linting, docs, security audit, releases |

## Existing Commands (32 total)

Retained from original implementation across:
- ADAS, AUTOSAR, Battery, Calibration, Diagnostics, Embedded
- HIL/SIL, Kubernetes, LLM Council, Logging, MBD
- Network, QNX, Testing, Tools

All commands are:
- Executable bash scripts (chmod +x)
- Self-documenting (--help flag)
- Follow consistent format (set -euo pipefail, colored output)
- Include real functionality with graceful degradation
