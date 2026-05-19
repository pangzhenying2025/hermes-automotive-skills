# 50 New Command Scripts Created

## Summary

Created 50 new executable bash command scripts across 11 domains, bringing the total from 32 to 82 commands.

## SAFETY (5 commands) - /commands/safety/

1. **hara-template.sh** - Generate HARA (Hazard Analysis and Risk Assessment) worksheet with severity/exposure/controllability ratings per ISO 26262-3
2. **fmea-template.sh** - Generate FMEA worksheet with AIAG-VDA methodology, RPN calculation
3. **asil-decompose.sh** - Calculate valid ASIL decomposition options per ISO 26262-9
4. **safety-case-init.sh** - Initialize safety case folder structure using GSN (Goal Structuring Notation)
5. **pmhf-calculate.sh** - PMHF (Probabilistic Metric for Hardware Failure) calculator per ISO 26262-5 Annex B

## SECURITY (5 commands) - /commands/security/

6. **tara-template.sh** - Generate TARA (Threat Analysis and Risk Assessment) template per ISO/SAE 21434
7. **vuln-scan.sh** - Run dependency vulnerability scanning (pip-audit, npm audit, cargo audit)
8. **sbom-generate.sh** - Generate Software Bill of Materials using CycloneDX or SPDX
9. **cert-check.sh** - Check X.509 certificate validity, expiration, and chain for V2X/OTA/ISO15118
10. **secret-rotate.sh** - Rotate secrets in .env files with cryptographically secure random values

## V2X (4 commands) - /commands/v2x/

11. **v2x-simulate.sh** - Launch V2X message simulation (CAM, DENM, SPaT, MAP, BSM)
12. **dsrc-test.sh** - Test DSRC/802.11p communication parameters (channels 170-184)
13. **c-v2x-config.sh** - Configure C-V2X PC5 sidelink parameters (3GPP Rel 14/15 Mode 4)
14. **v2x-decode.sh** - Decode ASN.1 V2X messages from hexadecimal input

## CLOUD (5 commands) - /commands/cloud/

15. **iot-provision.sh** - Provision IoT device on AWS IoT Core or Azure IoT Hub
16. **ota-package.sh** - Package OTA updates with delta generation (bsdiff/xdelta3) and signing
17. **fleet-status.sh** - Query fleet device status from cloud backend (online/offline/firmware)
18. **digital-twin-sync.sh** - Sync vehicle data to Azure Digital Twins or AWS IoT TwinMaker
19. **telemetry-ingest.sh** - Configure telemetry pipeline (InfluxDB, TimescaleDB, Azure Data Explorer)

## CHARGING (4 commands) - /commands/charging/

20. **ocpp-test.sh** - Test OCPP 1.6/2.0.1 charge point communication
21. **iso15118-check.sh** - Validate ISO 15118 certificate chain for Plug & Charge
22. **charging-simulate.sh** - Simulate EV charging session with CC/CV power curves
23. **grid-impact.sh** - Calculate grid impact of N chargers (transformer sizing, load analysis)

## MANUFACTURING (4 commands) - /commands/manufacturing/

24. **oee-calculate.sh** - Calculate OEE (Overall Equipment Effectiveness)
25. **spc-chart.sh** - Generate SPC (Statistical Process Control) chart data
26. **cycle-time.sh** - Analyze manufacturing cycle time from log data
27. **bom-validate.sh** - Validate Bill of Materials structure and part numbers

## REGULATORY (4 commands) - /commands/regulatory/

28. **homologation-checklist.sh** - Generate homologation checklist for target market
29. **emissions-report.sh** - Format WLTP/EPA emissions test results
30. **rohs-check.sh** - Check material declarations against RoHS restricted substances
31. **battery-passport.sh** - Generate EU Battery Passport data template

## ADAS (additional 4) - /commands/adas/

32. **sensor-calibration.sh** - Generate sensor calibration parameter template (camera, radar, lidar)
33. **scenario-generate.sh** - Generate OpenSCENARIO test scenarios
34. **perception-eval.sh** - Evaluate perception metrics (mAP, IoU)
35. **odd-define.sh** - Generate ODD (Operational Design Domain) specification template

## AUTOSAR (additional 4) - /commands/autosar/

36. **arxml-validate.sh** - Validate ARXML file structure against XSD schema
37. **swc-scaffold.sh** - Scaffold AUTOSAR SWC (Software Component) project structure
38. **bsw-config.sh** - Generate BSW (Basic Software) module configuration template
39. **rte-check.sh** - Check RTE (Runtime Environment) port connections consistency

## TESTING (additional 5) - /commands/testing/

40. **coverage-report.sh** - Generate unified code coverage report (gcov + lcov)
41. **mcdc-check.sh** - Check MC/DC (Modified Condition/Decision Coverage) for ASIL C/D
42. **fuzz-run.sh** - Run fuzzing campaign with AFL/libFuzzer
43. **regression-suite.sh** - Execute regression test suite with summary
44. **bench-compare.sh** - Compare benchmark results between two runs

## GENERAL (6 commands) - /commands/general/

45. **project-init.sh** - Initialize new automotive project with standard structure
46. **lint-all.sh** - Run all linters (cppcheck, ruff, eslint) across project
47. **doc-generate.sh** - Generate API documentation from source (Doxygen)
48. **dep-audit.sh** - Audit all dependencies for CVEs across languages
49. **release-notes.sh** - Generate release notes from git log
50. **skill-search.sh** - Search skills by keyword across all domains

## Standards Coverage

- **Functional Safety**: ISO 26262 (HARA, FMEA, ASIL, PMHF, safety case)
- **Cybersecurity**: ISO/SAE 21434 (TARA, threat modeling)
- **V2X**: ETSI ITS-G5, SAE J2735, IEEE 802.11p, 3GPP C-V2X
- **Charging**: ISO 15118, OCPP 1.6/2.0.1
- **AUTOSAR**: Classic and Adaptive platform
- **ADAS**: ISO 21448 (SOTIF), OpenSCENARIO

## Key Features

- **Consistent format**: All scripts follow same structure (40-80 lines, set -euo pipefail, colored output, usage help)
- **Real functionality**: Actual calculations, validations, and tool integrations (not just placeholders)
- **External tool checks**: Gracefully handle missing tools with installation instructions
- **Standards compliant**: Follow automotive industry standards and best practices
- **Executable**: All scripts chmod +x and ready to use

## Usage

All commands are self-documenting with `--help`:

```bash
# Example: Generate HARA worksheet
./commands/safety/hara-template.sh -i "Battery Management System" -a D

# Example: Test OCPP charger
./commands/charging/ocpp-test.sh -t authorize -i CP001

# Example: Scan for vulnerabilities
./commands/security/vuln-scan.sh -d . -f json
```

## File Paths

All scripts located at:
```
/home/rpi/Opensource/automotive-claude-code-agents/commands/
├── adas/           (sensor-calibration, scenario-generate, perception-eval, odd-define)
├── autosar/        (arxml-validate, swc-scaffold, bsw-config, rte-check)
├── charging/       (ocpp-test, iso15118-check, charging-simulate, grid-impact)
├── cloud/          (iot-provision, ota-package, fleet-status, digital-twin-sync, telemetry-ingest)
├── general/        (project-init, lint-all, doc-generate, dep-audit, release-notes, skill-search)
├── manufacturing/  (oee-calculate, spc-chart, cycle-time, bom-validate)
├── regulatory/     (homologation-checklist, emissions-report, rohs-check, battery-passport)
├── safety/         (hara-template, fmea-template, asil-decompose, safety-case-init, pmhf-calculate)
├── security/       (tara-template, vuln-scan, sbom-generate, cert-check, secret-rotate)
├── testing/        (coverage-report, mcdc-check, fuzz-run, regression-suite, bench-compare)
└── v2x/            (v2x-simulate, dsrc-test, c-v2x-config, v2x-decode)
```

Total: **82 command scripts** across **25 automotive domains**
