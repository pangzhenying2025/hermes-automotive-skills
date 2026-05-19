# OTA Updates - Level 2: Conceptual Architecture

> Audience: System architects, senior engineers, technical leads
> Purpose: Understand OTA system architecture, update strategies, and design patterns

## OTA System Architecture

### End-to-End Architecture

```
+-------------------+     +-------------------+     +-------------------+
|   OEM Backend     |     |   CDN / Edge      |     |   Vehicle         |
|                   |     |                   |     |                   |
| Campaign Mgmt     |     | Package Delivery  |     | Download Manager  |
| Package Signing   |---->| Delta Generation  |---->| Update Orchestrator|
| Vehicle Registry  |     | Caching           |     | ECU Flash Manager |
| Analytics         |     | Bandwidth Mgmt    |     | Rollback Manager  |
+-------------------+     +-------------------+     +-------------------+
```

### Vehicle-Side Architecture

```
+---------------------------------------------------------------+
|                   OTA Update Orchestrator                      |
|  Campaign handler | Dependency resolver | Scheduling           |
+---------------------------------------------------------------+
|                                                               |
|  +-----------------+  +-----------------+  +-----------------+|
|  | Download Mgr    |  | Verification    |  | Install Mgr     ||
|  | Resume support  |  | Signature check |  | A/B partition   ||
|  | Delta/full      |  | Version check   |  | Sequential ECU  ||
|  | Bandwidth ctrl  |  | Integrity hash  |  | Dependency order||
|  +-----------------+  +-----------------+  +-----------------+|
|                                                               |
|  +-----------------+  +-----------------+  +-----------------+|
|  | Rollback Mgr    |  | Status Reporter |  | Consent Mgr     ||
|  | Auto rollback   |  | Progress upload |  | User approval   ||
|  | Health check    |  | Error reporting |  | Scheduling prefs||
|  +-----------------+  +-----------------+  +-----------------+|
+---------------------------------------------------------------+
```

## Update Strategies

### A/B Partition Strategy
- Two complete firmware partitions on each ECU
- Download to inactive partition, verify, then swap
- Instant rollback by reverting to previous partition
- Doubles storage requirement but maximizes safety

### Delta Updates
- Only transmit the differences between current and target version
- Reduces download size by 60-90%
- Requires knowledge of current version on vehicle
- More complex verification (must reconstruct full image)

### Phased Rollout
- Stage 1: Internal fleet (1% of vehicles)
- Stage 2: Early adopters (5%)
- Stage 3: Regional rollout (25%)
- Stage 4: Full deployment (100%)
- Automatic pause if error rates exceed threshold

## Update Lifecycle

```
Create -> Sign -> Publish -> Campaign -> Download -> Verify
  |        |        |          |           |          |
  v        v        v          v           v          v
Build    HSM     Backend    Target      Vehicle    Crypto
Package  Keys    Store      Vehicles    Storage    Check
                                                     |
Install -> Verify -> Commit -> Report -> Monitor
  |          |         |         |          |
  v          v         v         v          v
Flash     Health    Counter   Backend   Analytics
ECU       Check     Update    Status    Dashboard
```

## Key Design Decisions

| Decision | Options | Recommendation |
|----------|---------|---------------|
| Partition scheme | A/B, streaming, in-place | A/B for safety-critical |
| Download timing | Immediate, scheduled, charging-only | User preference + rules |
| Install timing | Ignition-off, maintenance window | Safety-dependent |
| Rollback trigger | Auto on boot failure, manual | Automatic for safety ECUs |
| Consent model | Mandatory, opt-in, background | UNECE R156 compliant |

## Summary

OTA architecture requires careful balance between update speed, safety,
security, and user experience. A/B partitioning with phased rollouts and
automatic rollback provides the safest approach for safety-critical systems.
