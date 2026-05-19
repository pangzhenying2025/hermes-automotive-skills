# OTA Updates - Level 4: Reference

> Audience: Developers needing quick lookup tables and specifications
> Purpose: Rapid reference for OTA protocols, error codes, and configurations

## OTA Error Codes

| Code | Name | Description | Recovery Action |
|------|------|-------------|----------------|
| 0x00 | SUCCESS | Operation completed | None |
| 0x10 | DOWNLOAD_FAILED | HTTP error during download | Retry with backoff |
| 0x11 | DOWNLOAD_TIMEOUT | Download timed out | Retry on better connection |
| 0x12 | HASH_MISMATCH | Downloaded file hash wrong | Re-download from scratch |
| 0x13 | INSUFFICIENT_STORAGE | Not enough space | Clean staging area |
| 0x20 | SIGNATURE_INVALID | Package signature failed | Reject package |
| 0x21 | CERTIFICATE_EXPIRED | Signing cert expired | Request new package |
| 0x22 | VERSION_MISMATCH | Source version wrong | Request correct delta |
| 0x23 | HW_INCOMPATIBLE | Wrong hardware revision | Reject package |
| 0x24 | ROLLBACK_DETECTED | Version lower than current | Reject (anti-rollback) |
| 0x30 | INSTALL_FAILED | Flash write error | Retry once, then rollback |
| 0x31 | VERIFY_FAILED | Post-flash CRC error | Rollback to previous |
| 0x32 | BOOT_FAILED | New firmware won't boot | Auto-rollback |
| 0x33 | SELFTEST_FAILED | Application self-test fail | Auto-rollback |
| 0x40 | PRECONDITION_FAIL | Vehicle state wrong | Wait for correct state |
| 0x41 | BATTERY_LOW | SOC below threshold | Wait for charge |
| 0x42 | IGNITION_ON | Safety ECU needs ign off | Prompt user |
| 0x43 | VEHICLE_MOVING | Update needs standstill | Wait |

## Update State Machine

```
IDLE -> CAMPAIGN_RECEIVED -> CONSENT_PENDING -> DOWNLOADING
  ^                                                |
  |                                    DOWNLOAD_COMPLETE
  |                                                |
  |                                           VERIFYING
  |                                                |
  |                           VERIFIED -> INSTALL_PENDING
  |                                                |
  |                                          INSTALLING
  |                                                |
  |                               INSTALL_COMPLETE -> BOOTING
  |                                                      |
  |                                         SELFTEST -> COMMITTED
  |                                            |
  +------ ROLLBACK <-- BOOT_FAILED / SELFTEST_FAILED
```

## Vehicle Preconditions

| Condition | SOTA | FOTA (Non-Safety) | FOTA (Safety) |
|-----------|------|-------------------|--------------|
| Battery SOC | > 20% | > 30% | > 50% |
| Charging | Optional | Recommended | Required |
| Ignition | Any | Off recommended | Off required |
| Vehicle speed | Any | 0 km/h | 0 km/h |
| Gear position | Any | Park | Park |
| Active driving | Allowed | Not allowed | Not allowed |
| Network quality | > 1 Mbps | > 2 Mbps | > 2 Mbps |
| Temperature | -20 to 50 C | -10 to 45 C | 0 to 40 C |

## Package Size Reference

| ECU Type | Full Update | Delta Update | Compression |
|----------|-------------|-------------|-------------|
| Infotainment | 500 MB - 2 GB | 50-200 MB | zstd |
| Telematics | 20-100 MB | 5-20 MB | lz4 |
| ADAS Domain Ctrl | 200-500 MB | 30-100 MB | zstd |
| BMS | 1-5 MB | 100-500 KB | lz4 |
| Body Controller | 500 KB - 2 MB | 50-200 KB | lz4 |
| Gateway | 2-10 MB | 200 KB - 1 MB | lz4 |

## Relevant Standards

| Standard | Title | Key Content |
|----------|-------|-------------|
| UNECE R156 | Software Update | SUMS requirements |
| ISO 24089 | SW Update Engineering | Process standard |
| ISO/SAE 21434 | Cybersecurity Engineering | Security requirements |
| AUTOSAR UCM | Update Config Mgmt | AUTOSAR update manager |
| Uptane | Automotive Update Framework | Security framework |

## Summary

This reference provides quick access to OTA error codes, state machines,
vehicle preconditions, package sizing, and applicable standards for
day-to-day OTA development and troubleshooting.
