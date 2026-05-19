# China Mandatory Standards Compliance Rules

Strict compliance rules for China's mandatory national standards (强制性国标 GB) applicable to intelligent connected vehicles. These rules must be followed for any product targeting the Chinese market.

## Purpose

- Ensure all ADAS/ADS products comply with China's mandatory national standards
- Prevent non-compliance issues during MIIT type approval
- Align development processes with Chinese regulatory requirements
- Bridge gaps between international standards and Chinese localized requirements

## Rule 1: ODD Must Be Explicitly Defined Per Chinese Road Conditions

### Rationale
Chinese road conditions differ from European/US standards. ODD definitions must account for China-specific infrastructure, traffic patterns, and environmental conditions.

### Rule
Every ADAS/ADS product targeting China must have a China-specific ODD document addressing:

```
Required ODD elements for China market:
├── Road types with Chinese classification
│   ├── 高速公路 (G highways, S highways)
│   ├── 城市快速路 (urban expressways)
│   ├── 城市道路 (urban roads) — if applicable
│   └── Specific exclusions documented
├── Speed ranges per Chinese speed limits
│   ├── Highway: 60-120 km/h
│   ├── Urban expressway: 40-80 km/h
│   └── Parking scenarios: 0-15 km/h
├── Lane marking types per Chinese standards
│   ├── GB 5768 road marking specifications
│   ├── Temporary construction zone markings
│   └── Toll station and service area markings
├── Weather conditions for Chinese regions
│   ├── Northern China: ice, snow, sandstorms
│   ├── Southern China: heavy rain, flooding
│   ├── Eastern coast: typhoon conditions
│   └── Central China: haze, fog
└── Mixed traffic participants
    ├── Electric bicycles and scooters (电动自行车)
    ├── Three-wheeled vehicles (三轮车)
    ├── Slow-moving agricultural vehicles
    └── Non-motorized vehicle lane interactions
```

## Rule 2: DMS Is Mandatory for L2 Combined Driving Assistance

### Rationale
China's L2 mandatory standard requires Driver Monitoring System (DMS) for all combined driving assistance functions to prevent misuse.

### Rule
Any L2 system combining longitudinal and lateral control MUST include:

```
DMS mandatory requirements:
1. Attention monitoring (gaze direction tracking)
   - Detection rate: >95%
   - Response time: <500ms
2. Hands-on detection (steering wheel torque sensor)
   - Warning thresholds: 15s / 30s / 60s
   - Must use multi-level escalation
3. Fatigue detection (eye closure monitoring)
   - PERCLOS threshold per standard
4. Anti-misuse mechanisms
   - Prevent activation without driver readiness
   - Marketing claims must match actual capabilities
```

## Rule 3: Chinese Language HMI Is Required

### Rationale
All safety-critical HMI elements must be in Simplified Chinese for the domestic market.

### Rule
```
HMI language requirements:
├── System status displays: Simplified Chinese (简体中文)
├── Warning messages: Chinese + optional English
├── Voice prompts: Mandarin Chinese (普通话)
├── Owner's manual: Chinese version mandatory
├── Quick start guide: Chinese with illustrations
└── Error codes: Bilingual (Chinese primary)
```

## Rule 4: Data Recording Must Comply with DSSAD + Chinese Privacy Law

### Rationale
China has strict data localization and privacy requirements (PIPL, DSL) that go beyond international DSSAD requirements.

### Rule
```
Data compliance requirements:
├── Data storage: Must be stored in China (data localization)
├── Personal information: PIPL compliant consent mechanisms
├── Cross-border transfer: Security assessment required
├── Driving data: Minimum retention periods per standard
├── Video/image data: Face anonymization for cloud upload
├── Map data: Must use GCJ-02 coordinate system (not WGS-84)
└── Data access: Law enforcement access interface required
```

## Rule 5: Cybersecurity Must Align with GB/T 40857 and Data Security Law

### Rationale
China's cybersecurity framework extends beyond UN R155 with additional data security and network security requirements specific to the Chinese regulatory environment.

### Rule
```
Cybersecurity mandatory elements:
├── Secure boot with Chinese cryptographic algorithms (SM2/SM3/SM4)
├── V2X communication using Chinese V2X standards (C-V2X)
├── OTA updates registered with MIIT
├── Vulnerability management per China CNVD requirements
├── Supply chain cybersecurity assessment
└── Annual cybersecurity audit reporting
```

## Rule 6: Testing Must Include China-Specific Scenarios

### Rationale
Chinese traffic patterns, road infrastructure, and driving behaviors create unique scenarios not covered by Euro NCAP or international test protocols.

### Rule
```
China-specific mandatory test scenarios:
├── 非机动车混行 (Non-motorized vehicle mixed traffic)
├── 电动自行车突然切入 (E-bike sudden cut-in)
├── 行人闯红灯横穿 (Pedestrian jaywalking against red light)
├── 高速公路收费站 (Highway toll station approach/exit)
├── 隧道群连续通过 (Consecutive tunnel passage)
├── 团雾突遇 (Sudden localized fog patches)
├── 高速公路匝道合流 (Highway ramp merging)
├── 施工区域临时改道 (Construction zone temporary diversion)
├── 高速应急车道障碍物 (Emergency lane obstacles)
└── 低矮障碍物（锥桶/轮挡）(Low obstacles: cones/wheel stops)
```

## Rule 7: Functional Safety Classification Must Use Chinese HARA Approach

### Rationale
While based on ISO 26262, the Chinese approach to HARA incorporates additional exposure scenarios specific to Chinese driving conditions.

### Rule
HARA must include Chinese driving exposure data for:
- Traffic density patterns (urban vs. rural vs. highway) based on Chinese statistics
- Accident type distribution from Chinese traffic accident database
- Road geometry data from Chinese national road network
- Driver behavior data from Chinese naturalistic driving studies

## Compliance Enforcement

```
Non-compliance consequences:
├── Product cannot obtain MIIT access (公告目录)
├── Existing products may face recall orders
├── OTA updates require re-approval if safety-relevant
├── Company reputation risk in Chinese market
└── Potential legal liability under product quality law
```

## Related Rules

- `iso-26262-compliance.md` — Base functional safety rules
- `safety-critical-code-rules.md` — ASIL C/D code rules
- `sotif-overview.md` — SOTIF analysis rules

## Related Skills (Aligned with P1-P3 Standard Recommendations)

- `skills/china-standards/functional-safety/` — GB/T 34590 功能安全（P1）
- `skills/china-standards/sotif/` — GB/T 43267 + CSAE 316.1/316.2/336（P1）
- `skills/china-standards/scenario-safety/` — ISO 34501/34502 场景安全（P1）
- `skills/china-standards/behavioral-safety/` — IEEE 2846 行为安全（P1）
- `skills/china-standards/ai-safety/` — ISO PAS 8800 + TR 5469（P1）
- `skills/china-standards/l3-fusa-sotif/` — L3 FuSa+SOTIF联合要求（P2）
- `skills/china-standards/ads-safety/` — ADS强制安全要求（P2）
- `skills/china-standards/l2-adas-safety/` — L2 ADAS强制安全要求（P2）
- `skills/china-standards/odd/` — ODD标准（P2）
- `skills/china-standards/multi-pillar/` — 多支柱方法（P2）
- `skills/automotive-china-l2-adas-compliance/` — L2合规详细指南
- `skills/automotive-china-l3-ads-compliance/` — L3合规详细指南
- `skills/automotive-china-parking-compliance/` — 泊车合规指南
