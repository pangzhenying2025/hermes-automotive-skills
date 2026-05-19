# V2X Communication - Level 1: Overview

> Audience: Executives, product managers, non-technical stakeholders
> Purpose: Understand what V2X is, why it matters, and its business impact

## What is V2X?

Vehicle-to-Everything (V2X) communication enables vehicles to exchange
information with their surroundings in real time. The "X" represents
any entity: other vehicles, infrastructure, pedestrians, networks, and
cloud services.

V2X is considered a foundational technology for autonomous driving,
traffic safety, and smart transportation systems.

## V2X Communication Types

| Type | Full Name | What It Does |
|------|-----------|-------------|
| V2V | Vehicle-to-Vehicle | Cars warn each other of hazards, coordinate speeds |
| V2I | Vehicle-to-Infrastructure | Traffic signals share timing, road conditions |
| V2P | Vehicle-to-Pedestrian | Protect walkers and cyclists at crossings |
| V2N | Vehicle-to-Network | Cloud connectivity for maps, traffic, OTA updates |
| V2G | Vehicle-to-Grid | Electric vehicles interact with power grid |

## Why V2X Matters

### Safety Impact
- The US Department of Transportation estimates V2X could prevent up to
  80% of non-impaired vehicle crashes
- Enables awareness beyond line-of-sight (around corners, over hills)
- Provides advance warning of hazards seconds before they become visible

### Business Impact
- Enables new revenue streams: traffic data, insurance telematics,
  EV charging optimization
- Required by regulation in some markets (EU mandates for new vehicles)
- Differentiator for OEMs in connected vehicle features

### Technology Impact
- Complements camera/radar/lidar with communication-based sensing
- Enables cooperative driving (platooning, cooperative merging)
- Bridges the gap between Level 2 and Level 4 autonomous driving

## Two Competing Technologies

| Aspect | DSRC (IEEE 802.11p) | C-V2X (3GPP) |
|--------|-------------------|--------------|
| Origin | Wi-Fi based | Cellular based |
| Spectrum | 5.9 GHz ITS band | 5.9 GHz + cellular |
| Latency | ~2 ms (direct) | ~5 ms (direct, PC5) |
| Range | ~300 m (typical) | ~450 m (typical) |
| Status | Mature, deployed in some regions | Growing, backed by telecoms |
| Evolution | Limited | Evolves with 5G NR-V2X |

The industry is converging toward C-V2X due to its evolution path
through 5G and beyond, though DSRC remains deployed in some regions.

## Current Market Status

- **China**: Mandating C-V2X in new vehicles starting 2025-2026
- **EU**: ITS-G5 (DSRC variant) deployed; C-V2X gaining momentum
- **US**: FCC reallocated DSRC spectrum; C-V2X adoption accelerating
- **Japan/Korea**: Hybrid approach, supporting both technologies

## Key Standards and Bodies

| Standard/Body | Role |
|--------------|------|
| ETSI ITS | European V2X message formats and protocols |
| SAE J2945 | US V2X application specifications |
| 3GPP Release 16+ | C-V2X radio specifications |
| IEEE 1609 (WAVE) | DSRC networking stack |
| ISO 17419/17423 | International V2X standards |

## V2X in Battery Electric Vehicles

V2X is particularly relevant for BEVs:
- **V2G**: Bidirectional charging enables grid services
- **Range optimization**: V2I traffic signal data reduces energy waste
- **Charging coordination**: V2N finds available chargers, reserves slots
- **Eco-routing**: Infrastructure data enables energy-optimal routes

## Summary

V2X is a transformative technology that extends vehicle perception beyond
onboard sensors. It improves safety, enables new business models, and is
essential for the evolution toward autonomous driving. The automotive
industry is standardizing on C-V2X with 5G evolution, making this a
critical area for investment and development.
