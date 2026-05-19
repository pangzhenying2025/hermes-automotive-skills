# V2X Communication - Level 4: Reference

> Audience: Developers needing quick lookup tables and specifications
> Purpose: Rapid reference for V2X message IDs, data formats, and configuration

## Message ID Reference

| Message Type | ETSI ID | SAE ID | Purpose | Typical Size |
|-------------|---------|--------|---------|-------------|
| CAM | 2 | N/A | Cooperative awareness | 50-300 bytes |
| DENM | 1 | N/A | Hazard notification | 100-400 bytes |
| BSM | N/A | 0x0014 | Basic safety message | ~300 bytes |
| SPAT | 4 | 0x0013 | Signal phase/timing | 200-500 bytes |
| MAP | 5 | 0x0012 | Intersection geometry | 500-2000 bytes |
| IVIM | 6 | N/A | Infrastructure info | 200-1000 bytes |
| CPM | 14 | N/A | Collective perception | 200-1200 bytes |
| PSM | N/A | 0x0020 | Pedestrian safety | ~200 bytes |
| TIM | N/A | 0x001F | Traveler info | Variable |

## CAM Generation Frequency Rules

| Condition | Rate | Rule |
|-----------|------|------|
| Maximum rate | 10 Hz | Hard limit |
| Minimum rate | 1 Hz | Always send at least 1/s |
| Heading change > 4 deg | Immediate | Within 100 ms |
| Position change > 4 m | Immediate | Within 100 ms |
| Speed change > 0.5 m/s | Immediate | Within 100 ms |
| Stationary vehicle | 1 Hz | Minimum rate applies |

## Data Type Encoding Reference

| ITS Data Element | ASN.1 Type | Range | Resolution | Units |
|-----------------|-----------|-------|-----------|-------|
| Latitude | INTEGER | -900000000..900000001 | 0.0000001 | degrees |
| Longitude | INTEGER | -1800000000..1800000001 | 0.0000001 | degrees |
| Altitude | INTEGER | -100000..800001 | 0.01 | meters |
| Speed | INTEGER | 0..16383 | 0.01 | m/s |
| Heading | INTEGER | 0..3601 | 0.1 | degrees |
| Acceleration | INTEGER | -160..161 | 0.1 | m/s2 |
| Yaw Rate | INTEGER | -32766..32767 | 0.01 | deg/s |
| StationType | INTEGER | 0..255 | N/A | enum |
| TimestampIts | INTEGER | 0..4398046511103 | 1 | ms since 2004 |

## Station Type Values

| Value | Type | Description |
|-------|------|-------------|
| 0 | Unknown | Default/unknown |
| 1 | Pedestrian | Walking person |
| 2 | Cyclist | Bicycle rider |
| 3 | Moped | Motorized bicycle |
| 4 | Motorcycle | Motorcycle |
| 5 | PassengerCar | Standard car |
| 6 | Bus | Public transit bus |
| 7 | LightTruck | Van, pickup |
| 8 | HeavyTruck | Semi, heavy goods |
| 10 | Trailer | Towed trailer |
| 15 | RSU | Road-side unit |
| 16 | SpecialVehicle | Emergency/special |

## DENM Cause Codes

| Code | Cause | Sub-Causes |
|------|-------|-----------|
| 1 | Traffic Condition | Increased volume, speed drop |
| 2 | Accident | Multi-vehicle, heavy, w/ hazmat |
| 3 | Roadworks | Major, long-term, moving |
| 6 | Adverse Weather | Rain, fog, ice, wind |
| 9 | Hazardous Location | Surface, obstacle, animal |
| 10 | Emergency Vehicle | Approaching, stationary |
| 12 | Slow Vehicle | Maintenance, convoy |
| 14 | Stationary Vehicle | Breakdown, post-crash |
| 91 | Vehicle Breakdown | Fuel, tire, engine, electrical |
| 92 | Post-Crash | First aid, traffic cleared |
| 94 | Emergency Brake | EEBL activation |
| 95 | Collision Risk | Intersection, head-on, rear |

## C-V2X PC5 Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| Frequency band | 5855-5925 MHz | ITS 5.9 GHz band |
| Channel bandwidth | 10/20 MHz | 10 MHz standard |
| Subcarrier spacing | 15 kHz | LTE-V2X |
| TTI duration | 1 ms | Transmission time interval |
| Resource pool | SL (Sidelink) | Mode 4 autonomous |
| MCS range | 0-20 | Modulation & coding scheme |
| Tx power max | 23 dBm | 200 mW |
| HARQ | Enabled | 1 retransmission |
| Sensing window | 1000 ms | For resource selection |
| Selection window | 20-100 ms | Depending on latency req |

## Security Configuration

| Parameter | Value |
|-----------|-------|
| Signing algorithm | ECDSA P-256 |
| Hash algorithm | SHA-256 |
| Certificate format | IEEE 1609.2 |
| Pseudonym validity | 5 minutes (typical) |
| Certificate pool size | 20-100 certificates |
| CRL update interval | 24 hours |
| Maximum processing latency | < 5 ms per message |
| HSM key slot allocation | Slot 0-3: signing keys |

## GeoNetworking Parameters

| Parameter | Default Value | Range |
|-----------|--------------|-------|
| Beacon interval | 3000 ms | 1000-10000 ms |
| Location table entry lifetime | 20 s | 5-60 s |
| GeoUnicast max retransmissions | 3 | 0-10 |
| GeoBroadcast forwarding area | Circular, 500 m radius | 100-2000 m |
| Default hop limit | 10 | 1-255 |
| Maximum packet lifetime | 600 s | 1-6300 s |
| Minimum update frequency | 1000 ms | 100-10000 ms |

## Performance Targets

| Metric | V2V (PC5) | V2I (PC5) | V2N (Uu) |
|--------|----------|----------|---------|
| Latency (one-way) | < 20 ms | < 20 ms | < 100 ms |
| Reliability (PRR) | > 90% at 300 m | > 95% at 200 m | > 99% |
| Range | 300-500 m | 500-800 m | Cellular |
| Message rate | 10 Hz | 10 Hz | Variable |
| Channel load target | < 60% CBR | < 60% CBR | N/A |

## Relevant Standards Quick Reference

| Standard | Title | Key Content |
|----------|-------|-------------|
| ETSI EN 302 637-2 | CAM Specification | CAM format and generation rules |
| ETSI EN 302 637-3 | DENM Specification | DENM format and management |
| ETSI TS 103 300 | V2X Security | PKI and certificate management |
| SAE J2735 | DSRC Message Set | BSM, SPAT, MAP definitions |
| SAE J2945/1 | DSRC Performance | BSM generation requirements |
| 3GPP TS 36.300 | LTE-V2X | C-V2X sidelink specification |
| 3GPP TS 38.300 | NR-V2X | 5G V2X specification |
| IEEE 1609.2 | Security Services | Message signing format |
| ISO 17419 | GeoNetworking | Geographic routing protocol |
