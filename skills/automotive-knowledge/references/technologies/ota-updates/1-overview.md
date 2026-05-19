# OTA Updates - Level 1: Overview

> Audience: Executives, product managers, non-technical stakeholders
> Purpose: Understand OTA update capabilities, business value, and market landscape

## What Are OTA Updates?

Over-The-Air (OTA) updates allow vehicle software to be updated remotely,
similar to smartphone updates, without requiring a visit to a dealership
or service center. This applies to infotainment, telematics, ADAS
functions, powertrain calibration, and even safety-critical ECU firmware.

## Types of OTA Updates

| Type | Scope | Example | Risk Level |
|------|-------|---------|-----------|
| SOTA | Software (non-critical) | Maps, infotainment apps | Low |
| FOTA | Firmware (ECU-level) | Powertrain calibration, BMS | High |
| Configuration | Parameter changes | Feature enablement, limits | Medium |

## Business Value

- **Cost reduction**: Eliminate recall visits ($300-500 per vehicle per visit)
- **Revenue generation**: Feature-on-demand monetization
- **Quality improvement**: Fix bugs without physical recalls
- **Customer experience**: New features delivered continuously
- **Regulatory compliance**: Rapid response to safety issues (UNECE R156)

## Market Context

- Tesla pioneered consumer OTA with Model S (2012)
- Most major OEMs now have OTA capability for at least infotainment
- UNECE R156 mandates Software Update Management Systems (SUMS)
- Estimated 1.3 billion OTA-capable vehicles by 2030

## Key Challenges

- **Safety**: Updates to safety-critical systems require rigorous verification
- **Bandwidth**: Full firmware updates can be 1-2 GB per ECU
- **Availability**: Vehicles must remain operational during updates
- **Security**: Update pipeline must be tamper-proof end-to-end
- **Rollback**: Failed updates must not brick the vehicle
- **Consent**: Driver must approve safety-relevant updates

## Regulatory Requirements

| Regulation | Scope | Key Requirement |
|-----------|-------|----------------|
| UNECE R156 | Global (UNECE members) | Software Update Management System |
| UNECE R155 | Global (UNECE members) | Cybersecurity Management System |
| GB/T (China) | China | OTA technical requirements |
| ISO 24089 | International | OTA engineering process |

## Summary

OTA updates are transforming the automotive industry from hardware-defined
to software-defined vehicles. They reduce costs, enable new revenue, and
improve safety response time. However, they require robust security,
safety validation, and regulatory compliance frameworks.
