---
name: automotive-battery-lifecycle
description: >
  Expert knowledge of robotic disassembly systems for battery packs including module separation, high-voltage safety, X-ray sorting, and barcode tracking. Covers 20 topics across battery-lifecycle domain. Includes 20 skill files covering ATEX Directive 2014/34/EU (explosion protection), ATEX Directive for explosion protection, Basel Convention Annex IX B1090, Basel Convention Battery Transport, Battery-grade lithium purity specifications (>99.5% Li2CO3), Battery-grade material specifications (automotive OEM specs), Battery-grade sulfate purity specifications, EU Battery Regulation 2023/1542 and more.
tags: [automation, automotive, automotive-battery-lifecycle, baas, backup-power, battery-lifecycle, battery-passport, black-mass, blockchain, bms, carbon-footprint, carbonate, cathode, cell-replacement, circular-economy, cobalt, compliance, direct-recycling, disassembly, economics, eis, environmental-impact, epr, ess, eu-regulation, financial-modeling, frequency-regulation, gba, grid-scale, grid-services, hydrometallurgy, hydroxide, lca, leaching, leasing, lithium-recovery, machine-learning, material-recovery, mechanical-processing, metal-recovery, nickel, prognostics, pyrometallurgy, recycling, regulatory, relithiation, remanufacturing, residential-ess, robotics, rul-prediction, second-life, shredding, smelting, soh, solar, solvent-extraction, stationary-ess, stationary-storage, testing, traceability, v2g, vpp]
---

# Automotive Battery Lifecycle

20 skill files covering battery-lifecycle domain for automotive software engineering.

## Applicable Standards

- ATEX Directive 2014/34/EU (explosion protection)
- ATEX Directive for explosion protection
- Basel Convention Annex IX B1090
- Basel Convention Battery Transport
- Battery-grade lithium purity specifications (>99.5% Li2CO3)
- Battery-grade material specifications (automotive OEM specs)
- Battery-grade sulfate purity specifications
- EU Battery Regulation 2023/1542
- EU Battery Regulation 2023/1542 Article 13
- EU Battery Regulation Extended Producer Responsibility
- EU Battery Regulation carbon footprint requirements
- EU Battery Regulation recycled content targets
- EU Battery Regulation recycled content verification
- EU Industrial Emissions Directive (IED)
- Ellen MacArthur Foundation Circular Economy Principles
- Financial modeling best practices
- GBA (Global Battery Alliance) Battery Passport
- GBA (Global Battery Alliance) Battery Passport standard
- GDPR for data privacy
- GMP for battery materials
- GRI 306 Waste and Material Circularity Reporting
- IEC 61508 Functional Safety for automation
- IEC 61727 Photovoltaic Systems Grid Interface
- IEC 61850 Substation Automation for VPP
- IEC 62133 Battery Safety Testing
- IEC 62477 Power Electronic Converter Systems
- IEC 62619 Safety Requirements for Stationary Batteries
- IEC 62660 Lithium-ion Cells (replacement cell specs)
- IEC 62660 Lithium-ion Cells for EVs (test methods)
- IEC 62660 Secondary Lithium Cells Performance
- IEC 62933 Electrical Energy Storage Systems
- IEC 62933 Energy Storage System Integration
- IEC 62933 Energy Storage Systems
- IEEE 1188 Battery Maintenance and Testing
- IEEE 1547 Grid Interconnection
- IEEE 1547 Grid Interconnection Standard
- IEEE 1547 Grid Interconnection for DER
- IEEE 1936 Prognostics and Health Management
- IEEE 2030.5 Smart Energy Profile
- ISO 12100 Machinery Safety
- ISO 12405 Battery Testing for EVs
- ISO 12405 Test Procedures for Electric Vehicles
- ISO 14001 Environmental Management
- ISO 14025 Environmental Product Declarations (EPD)
- ISO 14040 Life Cycle Assessment
- ISO 14040/14044 Economic Analysis in LCA
- ISO 14040/14044 Life Cycle Assessment
- ISO 14046 Water Footprint
- ISO 14067 Carbon Footprint of Products
- ISO 15118 V2G Communication Protocol
- ISO 15686 Life Cycle Costing
- ISO 17367 Battery Safety Handling
- ISO 26262 Functional Safety (for prognostics in safety-critical systems)
- ISO 50001 Energy Management
- ISO 59004 Circular Economy Framework
- ISO 59020 Measuring Circularity
- ISO 9001 Quality Management for chemical processes
- ISO 9001 Quality Management for chemical production
- ISO 9001 Quality Management for remanufacturing
- ISO/IEC 15459 Unique Identifier Standards
- ISO/IEC 19762 AIDC Data Structures
- ISO/TS 15066 Collaborative Robots
- NEC Article 706 (National Electrical Code for ESS)
- NFPA 855 Installation of Stationary ESS
- OpenADR 2.0 Demand Response Protocol
- REACH Regulation for chemical handling
- REACH Regulation for chemical safety
- REACH Regulation for extractant chemicals
- REACH Regulation for metal recovery
- REACH Regulation for substance restrictions
- Responsible Cobalt Initiative (RCI) traceability
- SAE J2464 EV Battery Abuse Testing
- TCO (Total Cost of Ownership) frameworks
- UL 1741 Inverters and Charge Controllers
- UL 1973 Batteries for Stationary Applications
- UL 1973 Stationary Battery Energy Storage
- UL 1974 Evaluation for Repurposing Batteries
- UL 9540 Energy Storage Systems Safety
- UN 3480/3481 Battery Transport Classification
- UN 38.3 Transport of Dangerous Goods (for shipping)
- UN ECE R100 Battery Safety

## Use Cases

- Automated battery pack disassembly line design
- Robotic cell removal and module separation
- High-voltage safety interlocks and discharge systems
- X-ray and vision-based pack inspection
- Barcode tracking for traceability and chemistry sorting
- Battery passport IT architecture design
- GBA data model implementation
- QR code generation and laser marking
- Blockchain/DLT for tamper-proof records
- MES/PLM integration for automated data capture
- Mechanical recycling plant design and optimization
- Black mass quality specification and grading
- Shredding process safety and efficiency
- Material separation and concentration techniques
- Black mass trading and supply chain management
- Remaining Useful Life (RUL) prediction for warranty planning
- Machine learning models for capacity fade forecasting
- Knee-point detection (accelerated degradation onset)
- Calendar vs cycling aging decomposition
- SOH prognostics for fleet management

## Topics Covered

### Recycling

- battery-disassembly-automation
- black-mass-processing
- cobalt-nickel-recovery
- direct-recycling
- hydrometallurgy-process
- lithium-recovery
- pyrometallurgy-process
- recycling-economics
- recycling-environmental-impact
- recycling-overview

### Regulatory

- battery-passport-implementation
- eu-battery-regulation

### Second Life

- capacity-fade-prediction
- circular-economy-models
- module-remanufacturing
- residential-ess
- second-life-overview
- soh-grading-classification
- stationary-ess-integration
- v2g-second-life

## Constraints

- 50+ pack designs from OEMs require flexible tooling or multiple lines
- API scalability for millions of batteries (load balancing required)
- Adhesive-bonded packs difficult to automate (require thermal or ultrasonic cutting)
- Allocation methodology choice significantly impacts results (cut-off vs economic)
- Automation ROI requires >5k modules/year throughput
- BMS reprogramming requires OEM tools or reverse engineering
- Battery passport IT infrastructure complex (integration with MES, PLM, blockchain)
- Black mass price volatile (follows Co/Ni/Li commodity prices)
- Blockchain gas costs for on-chain storage (prefer off-chain with hash)
- CAPEX ($3-5M) requires high throughput (>25k packs/year) for ROI
- Carbon footprint verification requires extensive supplier data (transparency challenges)
- Cell sourcing difficult (OEM cells unavailable, aftermarket quality variance)
- Certification costs ($50-100k per design) favor standardization
- Chemical costs (acid, base, extractants) are 30-40% of OPEX
- Co-Ni separation purity depends on precise pH control (±0.1 pH units)

## Required Tools

- API gateway and authentication (OAuth 2.0, JWT)
- Assembly tools (torque wrenches, multimeters, oscilloscopes)
- Automated material handling (robots, conveyors)
- Automatic tool changers and custom end-effectors
- BMS (REC BMS, Orion BMS, Batrium, DIY Arduino/Raspberry Pi)
- BMS programming tools (CAN adapters, OEM software, or open-source)
- BMS reprogramming tools and CAN adapters
- BMS with cellular/WiFi (Particle, Hologram, Twilio SIM cards)
- Barcode/QR scanners for traceability
- Battery cyclers (Digatron, Arbin, Maccor, 0-1000V, 0-500A)
- Battery cycling datasets (NASA PCoE, CALCE, Panasonic/LG)
- Battery passport platform (Circulor, Minespider, SAP, custom)
- Battery passport platform (Circulor, Minespider, custom)
- Battery passport scanning systems
- Battery testing equipment (EIS, pulse tests, capacity cycling)


## Instructions

### battery-disassembly-automation

## Core Competencies
Expert in designing and implementing automated robotic systems for safe, efficient disassembly of automotive battery packs to recover modules, cells, and materials while maintaining worker safety and chemistry traceability.
### Disassembly Challenges
**Manual Disassembly Issues**: - Labor-intensive: 15-45 min per pack (cost $20-60) - Safety risks: High-voltage exposure (400-800V), thermal runaway potential - Inconsistent quality: Human error in module damage, incomplete discharge - Scalability limits: Trained technicians scarce, throughput <20 packs/day/worker - Ergonomics: Heavy packs (200-700 kg), repetitive strain injuries
**Automation Benefits**: - Throughput: 50-200 packs/day per line (3-10x improvement) - Safety: Isolates humans from high-voltage and fire hazards - Consistency: Repeatable disassembly sequences, minimal module damage - Data capture: Automated barcode scanning, weight measurement, voltage logging - Cost reduction: 40-60% lower cost per pack at scale
### Automated Disassembly Process Flow
**Stage 1: Pack Identification & Intake**
**Barcode/QR Code Scanning**: - Vision system reads pack identifier (VIN-based or OEM code) - Database lookup: Chemistry (NMC811, LFP, NCA), voltage, module count, disassembly procedure - Decision: Route to appropriate station (chemistry-specific tooling)
**Weight & Dimension Verification**: - Load cells verify pack mass (detect internal damage, electrolyte leakage) - Laser/vision system measures dimensions (detect swelling, deformation) - Acceptance criteria: ±5% of nominal weight/size
**X-ray Inspection** (optional, high-value packs): - Computed Tomography (CT) scan or 2D X-ray - Detect: Internal shorts, cell swelling, dendrite growth, missing components - Benefit: Avoid opening damaged packs (fire risk), prioritize for direct shredding
**Stage 2: High-Voltage Discharge & Safety Lockout**
**Voltage Measurement**: - Robotic arm connects to HV+ and HV- terminals via insulated probe - Measure pack voltage (should be <100V if pre-discharged, up to 400-800V if not) - Decision: If >100V, route to discharge station; if <50V, proceed to disassembly
**Active Discharge**: - Connect pack to resistive load bank (1-10 kW) - Discharge to 30-50% SOC (not 0% to avoid cell damage) - Time: 30 min to 4 hours depending on pack capacity (50-150 kWh) - Monitoring: Thermal camera detects cell hot spots (>40°C → abort)
**Safety Lockout**: - Remove service disconnect plug (robotic gripper with 1000V insulation) - Install shorting plug on HV terminals (prevent residual voltage) - Verify <50V with second independent measurement (redundant safety)
**Stage 3: Enclosure Removal (Pack Opening)**
**Bolt/Screw Removal**: - Robot arm with automatic tool changer (select screwdriver bit based on pack database) - Torque monitoring: Detect stripped threads, cross-threaded fasteners - Fastener sorting: Steel vs aluminum screws for recycling - Typical: 20-60 fasteners per pack (removal time: 3-8 min with multi-spindle tools)
**Adhesive/Sealant Cutting** (for glued enclosures): - Ultrasonic knife or hot wire cutter traces seam lines - Vision-guided path following (seam detection via machine learning) - Challenge: OEM-specific adhesives (polyurethane, epoxy, silicone) require different cutting strategies
**Lid Lift-off**: - Vacuum gripper or magnetic gripper lifts pack top cover (5-30 kg) - Place cover in parts bin (aluminum for recycling)
**Stage 4: BMS & Wiring Harness Removal**
**Connector Disconnection**: - Robot identifies connector types via vision (Molex, Amphenol, JST) - Custom end-effector with release mechanism (push-button, slide-lock, twist-lock) - Challenge: 50+ OEM-specific connector designs require modular grippers
**BMS PCB Extraction**: - Locate BMS board (typically bolted to pack lid or module top) - Unscrew mounting bolts (4-8 per BMS) - Lift BMS → route to electronics recycling (gold recovery from PCB)
**Cable Cutting**: - Automated wire cutters sever HV cables near bus bars - Copper cable → metal recovery stream - Benefit: Recover clean copper vs mixed in shredder
**Stage 5: Coolant Drainage** (liquid-cooled packs)
**Drain Port Access**: - Robot opens coolant drain valve or punctures coolant line - Pump drains coolant (ethylene glycol/water mix, 10-30 L per pack) - Coolant disposal: Recycle glycol or proper hazmat disposal
**Dry-out**: - Tilt pack to drain residual coolant (passive gravity drain for 5-10 min) - Compressed air purge of cooling channels (optional)
**Stage 6: Module Separation**
**Module Lifting**: - Robot gripper (vacuum cup arrays or mechanical clamps) lifts each module (10-40 kg) - Vision system locates module edges (handles dimensional variation between packs) - Lift sequence: Often back-to-front or top-to-bottom depending on pack design
**Bus Bar Disconnect**: - If modules series-connected via bus bars: robot cuts or unbolts bus bars - High-force cutting tool (hydraulic shear, 2-10 kN) for copper/aluminum bars - Safety: Verify 0V across bus bar before cutting (check for residual charge)
**Module Weight & Voltage Check**: - Each module placed on weighing station (QC check for internal damage) - Voltage measurement: Verify module is 20-50V (safe for handling) - Data logging: Module ID, weight, voltage → traceability database
**Chemistry Sorting**: - Based on pack ID or optional XRF analysis, route module to correct bin: - NMC811: Premium value, hydrometallurgy route - NMC622: Standard value, hydro or pyro - LFP: Low value, second-life or pyro - NCA: Tesla-specific, direct recycling pilot programs
**Stage 7: Cell Extraction** (optional, for second-life or direct recycling)
**Module Opening**: - Remove module plastic housing (snap fits or screws) - Expose cell pack (cylindrical 21700/4680 or pouch cells)
**Cell Removal**: - Cylindrical cells: Suction gripper with 18650/21700-sized cups - Pouch cells: Vacuum pad gripper (flexible to avoid puncture) - Welded tabs: Ultrasonic metal welder in reverse (melt and separate) or mechanical shear
**Cell Testing** (for second-life): - Automated cell tester measures: - Open-circuit voltage (OCV): Should be 3.0-4.2V for lithium-ion - Internal resistance (IR): <50 mΩ for good cell, >100 mΩ for degraded - Capacity test (optional, 1C discharge): Determines SOH - Sorting: Grade A (>80% SOH), Grade B (60-80%), Grade C (<60% → recycle)
### Robotic System Design
**Robot Selection**:
| Task | Robot Type | Payload | Reach | Speed | |------|-----------|---------|-------|-------| | Pack handling | Articulated 6-axis (KUKA, ABB, Fanuc) | 200-500 kg | 2.5-3.5 m | Slow (safety) | | Fastener removal | Collaborative robot (UR, Franka) | 5-15 kg | 1.3-1.8 m | Medium | | Module extraction | Gantry robot or Cartesian | 50-100 kg | 3-5 m XY, 1 m Z | Medium | | Cell handling | SCARA or delta robot | 1-5 kg | 0.8-1.5 m | Fast (precision) |
**End-Effectors (custom design critical)**: - Automatic tool changer: Quick swap between screwdriver, gripper, cutter, probe (30 sec changeover) - Screwdriver: Electric or pneumatic, torque monitoring (2-20 Nm range) - Gripper: Vacuum (for flat surfaces), magnetic (ferrous), mechanical (clamp) - Cutter: Hydraulic shear (bus bars), wire stripper (cables), ultrasonic knife (adhesive) - Probe: Insulated voltage measurement probe (1000V rated), temperature sensor
**Vision Systems**: - 2D cameras: Barcode reading, connector identification, module edge detection - 3D cameras (structured light, stereo): Bolt head location, deformation detection - Thermal cameras: Hot spot detection during discharge, cell temperature monitoring - X-ray: Internal damage assessment (optional for high-value packs)
**Safety Systems**: - Light curtains: Stop robot if human enters work envelope - Emergency stop buttons: Every 3 meters around line perimeter - Fume extraction: Local exhaust ventilation (LEV) at pack opening (electrolyte vapor risk) - Fire suppression: CO2 or water mist system triggered by smoke/temperature sensors - Electrical isolation: Robot controllers on separate circuit from HV discharge equipment
### Traceability & Data Management
**Battery Passport Integration**: - Scan pack QR code → retrieve battery passport data (chemistry, manufacturing date, OEM, vehicle VIN) - Log disassembly data: Discharge voltage, module weights, visual damage observations - Update passport: "End-of-life → recycling, date: 2026-03-19, facility: XYZ"
**Chemistry Tracking**: - Critical for maximizing recycling value (NMC811 vs LFP routing) - Database stores: Pack ID → chemistry → module bin assignment - Enables: Homogenous feedstock to hydrometallurgy (avoids chemistry mixing)
**Module-to-Cell Lineage**: - Each module gets unique ID (laser-etched or RFID tag) - Cell testing results linked to module ID → informs second-life applications - Enables warranty tracking for second-life products
### Economics of Automated Disassembly
**CAPEX (for 50k pack/year line)**: - Robots & end-effectors: $1.5-2.5M (3-5 robots) - Vision systems: $200-500k - Discharge equipment: $300-600k - Conveyors & material handling: $400-700k - Safety systems & enclosures: $300-500k - Control system & software: $200-400k - Total CAPEX: $3-5M
**OPEX (per pack)**: - Labor: $5-10 (1 operator supervising 4-6 robots) - Energy: $2-4 (robot power, discharge energy recovery possible) - Maintenance: $3-5 (tool wear, robot servicing) - Total OPEX: $10-19 per pack
**Comparison to Manual**: - Manual: $30-60 per pack - Automated: $10-19 per pack - Savings: 50-70% at 50k+ pack/year scale
**Payback Period**: - At 50k packs/year: 3-4 years - At 100k packs/year: 2-3 years - Break-even: ~25k packs/year
### Case Studies
- **Duesenfeld (Germany)**: Fully automated line with LN2 cooling, 3k ton/year, 96% recovery rate - **OnTo Technology (USA)**: Collaborative robots (UR) for module extraction, BMW partnership - **Li-Cycle (Canada)**: Semi-automated discharge + manual disassembly, 25k ton/year - **Northvolt (Sweden)**: Gigafactory recycling plant, automated disassembly planned for 125k ton/year by 2030
## Approach
1. **Pack Portfolio Analysis**: Catalog OEM pack designs (fastener types, module layouts, chemistries) 2. **Disassembly Sequence Planning**: CAD simulation of robot paths, collision avoidance 3. **End-Effector Design**: Custom grippers for highest-volume pack types (Pareto 80/20 rule) 4. **Safety Risk Assessment**: HAZOP analysis of discharge, cutting, lifting operations 5. **Pilot Line Setup**: Build 1-station prototype, validate cycle time and safety 6. **Vision Algorithm Training**: Machine learning for connector/bolt detection (requires 1000+ images per variant) 7. **Scale-Up Design**: Multi-station line with buffer storage, throughput balancing 8. **Economic Modeling**: CAPEX, OPEX, throughput sensitivity analysis
## Deliverables
- Disassembly sequence flowchart for top 10 pack types - Robot selection justification (payload, reach, speed requirements) - End-effector CAD designs with force analysis - Safety system specification (light curtains, e-stops, fire suppression) - Vision system requirements (resolution, frame rate, lighting) - Traceability database schema (pack ID, module ID, test results) - Line layout (floor plan, robot work envelopes, material flow) - Economic model (CAPEX, OPEX per pack, payback period)
## Best Practices
- Design for flexibility: Use automatic tool changers to handle 80%+ of pack variants with same robot - Implement modular stations: Each station (discharge, opening, module extraction) can operate independently - Use collaborative robots where possible: Lower cost, easier programming, safer human interaction - Capture data at every step: Voltage, weight, temperature → predictive analytics for future packs - Design for graceful degradation: If one robot fails, line continues at reduced throughput - Perform weekly torque calibration: Ensures fastener removal without stripping threads - Train vision systems with synthetic data: CAD-based image generation for rare pack variants - Implement closed-loop force control: Prevents module damage during extraction (esp. pouch cells)
## Integration with Automotive Workflow
- Accept whole battery packs from OEM collection networks with barcode intact - Scan and update battery passport at intake and completion - Route modules to second-life assembly lines or recycling based on SOH results - Provide module-level traceability for closed-loop cathode supply chains - Report disassembly data (module count, chemistry distribution) to OEM for EPR compliance

### battery-passport-implementation

Expert in technical implementation of digital battery passports meeting EU Regulation requirements and GBA standard. Covers data architecture (70+ fields: manufacturer, chemistry, capacity, carbon footprint, recycled content, supply chain, performance, disassembly), unique identifier generation (ISO 15459 compliance), QR code standards (data matrix ECC200, laser etching on pack housing), backend systems (cloud database, API endpoints for authorized access), blockchain integration (Hyperledger, Ethereum for immutable provenance), MES/PLM integration (auto-capture manufacturing data: test results, traceability lots, assembly date), access control (GDPR-compliant multi-level: public chemistry/weight, OEM performance data, recycler disassembly info), lifecycle updates (SOH from vehicle telematics, service events, battery swap history), and end-of-life data (collection date, recycling facility, material recovery yields). Implementation phases: pilot (100 batteries, validate data flows), scale (1000s/month, load testing), full production (integrate into all manufacturing lines). Key technical decisions: centralized vs distributed storage, on-chain vs off-chain data (gas costs), API rate limiting, data retention policy (lifetime + 15 years post-recycling). Tools: SAP Product Compliance, Circulor Responsible Sourcing, Minespider blockchain platform, custom REST APIs, laser marking systems (fiber laser 20W), vision verification (OCR check QR readability post-marking). Cost: €10-30 per battery (IT amortization, laser marking, data entry/validation). Integration: Connects to vehicle CAN (SOH updates), recycler portals (EOL data input), regulatory reporting (annual compliance summaries). Best practices: Generate unique ID at cell level (propagate to module/pack), implement data validation hooks (prevent bad data entry), use industry PKI (trusted certificate authorities for API authentication), design for 20+ year data retention (archival strategy), test QR durability (salt spray, thermal cycling per ISO 11507).

### black-mass-processing

## Core Competencies
Expert in mechanical processing of end-of-life lithium-ion batteries to produce black mass (fine powder containing cathode and anode active materials) for downstream pyrometallurgical or hydrometallurgical recycling.
### Black Mass Definition
**Black Mass** is the fine powder (<2mm particles) produced by mechanical shredding and separation of lithium-ion batteries, containing: - Cathode active material (LiCoO2, LiNi0.8Mn0.1Co0.1O2, LiFePO4, etc.) - Anode active material (graphite, some Li compounds from SEI layer) - Carbon black (cathode additive) - Small particles of copper (anode current collector) - Small particles of aluminum (cathode current collector) - Trace amounts of binder (PVDF), electrolyte residue
**Typical Composition** (NMC battery black mass): - Cathode material: 40-50% by mass - Graphite: 25-35% - Copper: 10-15% - Aluminum: 5-10% - Binder/carbon black: 2-5% - Electrolyte residue: <1%
### Mechanical Recycling Process Flow
**Stage 1: Battery Pre-Treatment**
**Depth of Discharge (DoD)**: - Target: Discharge to 20-30% SOC (not 0% to avoid cell damage, not >50% to reduce fire risk) - Methods: - Resistive discharge: Connect pack to resistive load (1-5 kW) over 2-8 hours - Salt water bath: Submerge modules in brine solution (short-circuits cells safely) - Active discharge: Use battery tester to controlled discharge (slowest, safest) - Safety: Monitor for thermal runaway signs (temp rise >5°C/min, voltage drop)
**Manual Disassembly** (if economical): - Remove pack housing (steel/aluminum enclosure) - Disconnect high-voltage bus bars (wear PPE, insulated tools) - Separate modules from cooling system (drain coolant first) - Remove BMS and wiring harness (can be resold or recycled separately) - Benefits: Higher material recovery (clean aluminum, copper, steel), safer shredding - Cost: 15-30 min labor per pack ($20-40 per pack)
**Stage 2: Shredding**
**Primary Shredding** (coarse reduction): - Equipment: Hammer mill or shear shredder - Input: Whole modules or cells (after optional disassembly) - Output size: 50-200 mm chunks - Purpose: Break open cell casing, expose electrode materials - Safety: Inert atmosphere (N2 or CO2 flooding) to prevent fires - Throughput: 1-5 tons/hour depending on shredder size
**Fire Prevention Strategies**: - Cryogenic shredding: Liquid nitrogen (LN2) at -196°C to embrittle materials, prevent short circuits - Water immersion shredding: Submerge batteries in water tank before/during shredding - Inert gas blanketing: Continuous N2 or CO2 flow to displace O2 (<5% O2 concentration) - Temperature monitoring: IR cameras detect hot spots (>60°C triggers shutdown)
**Secondary Shredding** (fine reduction): - Equipment: Impact mill or knife mill - Input: 50-200 mm chunks from primary shredder - Output size: 2-20 mm particles - Purpose: Further liberate cathode/anode materials from current collectors
**Tertiary Shredding** (optional, for high-purity black mass): - Equipment: Jet mill or pin mill - Input: 2-20 mm particles - Output size: <2 mm (fine powder) - Purpose: Create homogenous black mass for optimal leaching
**Stage 3: Thermal Treatment (Drying & Electrolyte Removal)**
**Low-Temperature Drying** (80-120°C): - Purpose: Evaporate residual moisture and volatile electrolyte solvents (DMC, EMC, EC) - Equipment: Rotary dryer or fluidized bed dryer - Time: 2-4 hours - Atmosphere: Inert (N2) or vacuum to prevent oxidation - Off-gas treatment: Condenser to recover solvents (DMC can be purified and resold)
**High-Temperature Pyrolysis** (400-600°C, optional): - Purpose: Burn off PVDF binder, residual electrolyte, SEI layer organics - Equipment: Rotary kiln or fluidized bed reactor - Atmosphere: Air or O2 (oxidative) to combust organics - Result: Mass reduction (5-10%), cleaner black mass (easier leaching) - Off-gas: CO2, HF (from LiPF6 electrolyte salt) → requires scrubbing - Caution: Can cause slight oxidation of cathode (e.g., Ni²⁺ → Ni³⁺)
**Stage 4: Sieving & Classification**
**Multi-Stage Sieving**: - Coarse screen (>10 mm): Removes large plastic/metal chunks → manual sorting - Medium screen (2-10 mm): Mixed metal/active material → further grinding or pyro recycling - Fine screen (<2 mm): **Black mass product** → highest cathode/anode content
**Particle Size Distribution** (typical black mass): - <0.1 mm: 20-30% (ultrafine cathode/carbon black) - 0.1-0.5 mm: 40-50% (cathode particles, graphite) - 0.5-2 mm: 20-30% (graphite, small metal fragments) - >2 mm: <5% (rejected, return to secondary shredder)
**Stage 5: Metal Separation**
**Magnetic Separation**: - Target: Ferrous metals (steel from casing, some stainless steel) - Equipment: Drum magnets or overhead magnets - Recovery: 95-99% of ferrous content - Output: Clean steel scrap for sale to steel mills
**Eddy Current Separation**: - Target: Non-ferrous metals (copper, aluminum) - Principle: Rotating magnetic field induces eddy currents in conductive metals → repulsion - Equipment: Eddy current separator with high-speed rotor - Effectiveness: 80-90% Cu/Al recovery (small particles escape) - Output: Mixed Cu/Al scrap → further separation by density or color sorting
**Air Classification (Zigzag Separator)**: - Target: Separate low-density (graphite, plastic) from high-density (cathode, metals) - Principle: Air jet blows light materials upward, heavy materials fall - Result: Graphite concentrate (90%+ purity) and cathode-enriched black mass - Benefit: Increases black mass cathode content from 40% to 55-65%
**Density Separation (Sink-Float)**: - Medium: Water or heavy liquid (density 2.0-3.5 g/cm³) - Principle: Cathode (4.5-5.2 g/cm³) sinks, graphite (2.2 g/cm³) floats - Equipment: Jig separator or dense media separator - Result: >70% cathode purity in sinking fraction - Challenge: Water introduces moisture (requires redrying)
**Stage 6: Quality Control & Analysis**
**Elemental Composition** (most critical): - Technique: ICP-OES (Inductively Coupled Plasma Optical Emission Spectroscopy) - Elements analyzed: Li, Co, Ni, Mn, Cu, Al, Fe, Ca (impurity) - Sampling: Homogenize 100 kg batch, take 500g representative sample - Reporting: % by mass of each element (dry basis)
**Example ICP-OES Report (NMC811 black mass)**: ``` Element    Content (% dry mass) Li         3.5 - 4.5% Ni         18 - 24% Mn         1.5 - 2.5% Co         2.5 - 4.0% Cu         8 - 12% Al         4 - 7% Fe         <1% (impurity from shredder wear) Ca         <0.5% (impurity from concrete dust) C (total)  20 - 30% (graphite + carbon black) ```
**Moisture Content**: - Method: Loss on drying (LOD) at 105°C for 2 hours - Target: <5% moisture (prevents caking, corrosion during storage) - High moisture (>10%) indicates incomplete drying
**Particle Size Distribution**: - Method: Laser diffraction (Malvern Mastersizer) or sieve analysis - Report: D10, D50, D90 (10th, 50th, 90th percentile particle sizes) - Target: D50 = 50-200 µm (optimal for leaching)
**Hazardous Characterization**: - pH of water extract: Should be neutral (pH 6-8) - Heavy metals (Pb, Cd, Hg): <100 ppm per element (waste classification) - Flammability: Self-heating test (UN 3090 classification)
### Black Mass Quality Grades
**Premium Grade** (for hydrometallurgy): - Cathode content: >55% (high Co/Ni/Li) - Cu + Al: <15% (low impurities) - Graphite: <25% (can interfere with leaching) - Moisture: <3% - Fe: <0.5% (interferes with solvent extraction) - Price: $8-15/kg (depending on Co/Ni market price)
**Standard Grade** (for pyrometallurgy or lower-grade hydro): - Cathode content: 40-55% - Cu + Al: 15-25% - Graphite: 25-35% - Moisture: <5% - Price: $4-8/kg
**Low Grade** (for pyrometallurgy only or disposal): - Cathode content: <40% - High plastic/aluminum content (difficult to process) - May require disposal fee rather than payment
### Economics of Black Mass Production
**Cost Breakdown** (per ton of input batteries): - Collection & transport: $100-200 - Discharge & disassembly: $100-300 (if manual disassembly performed) - Shredding (equipment amortization, energy, maintenance): $150-300 - Thermal treatment (energy, off-gas scrubbing): $100-200 - Sieving & separation (equipment, labor): $50-100 - Quality control (ICP-OES, labor): $50-100 - Total processing cost: $550-1200 per ton input batteries
**Revenue**: - Black mass yield: 400-600 kg per ton of input batteries (40-60%) - Black mass sale price: $4-15/kg (depends on chemistry, purity, market) - Scrap metal (Cu, Al, steel): $200-400 per ton input - Total revenue: $2000-5000 per ton input batteries
**Gross margin**: $800-3800 per ton (highly dependent on black mass purity and Co/Ni prices)
### Safety & Environmental Compliance
**Fire & Explosion Protection**: - ATEX Zone 1 or 2 classification for shredding area (explosive dust atmosphere) - Explosion vents on shredders (pressure relief panels) - Spark detection and suppression systems - Emergency shutdown interlocks (temperature, smoke, gas detection)
**Personal Protective Equipment (PPE)**: - Respiratory protection: P3 particulate filters (black mass is fine dust) - Skin protection: Nitrile gloves (electrolyte residue is corrosive) - Eye protection: Safety goggles (dust and liquid splash) - Hearing protection: Earplugs (shredders are 90-110 dB)
**Waste Streams**: - Plastic/separator material: 5-10% of input mass → landfill or energy recovery - Off-gas from drying: VOCs (DMC, EMC) → thermal oxidizer or condenser - HF from pyrolysis: Acid gas → alkaline scrubber (NaOH) - Contaminated water (if water immersion shredding): Metal-laden → treatment
### Major Black Mass Producers
- **Li-Cycle (Canada/USA)**: 25k ton/year capacity, water-based shredding ("Spoke" facilities) - **Duesenfeld (Germany)**: 3k ton/year, LN2 cryogenic shredding, 96% graphite recovery - **Retriev Technologies (USA)**: 10k ton/year, hammer mill + thermal treatment - **Redux (Germany)**: Battery-to-black-mass service for OEMs, 5k ton/year - **SNAM (France)**: 6k ton/year, rotary kiln pyrolysis integrated with shredding
## Approach
1. **Feedstock Characterization**: Determine battery chemistries, pack formats, contamination levels 2. **Process Selection**: Cryogenic vs inert gas shredding, manual disassembly vs direct shred 3. **Equipment Sizing**: Calculate throughput requirements, select shredder types 4. **Separation Strategy**: Optimize magnetic, eddy current, air classification sequence 5. **Quality Specification**: Define target black mass grade for downstream customer 6. **Safety Design**: ATEX compliance, fire suppression, off-gas treatment 7. **Pilot Testing**: Run 100-500 kg trials to validate yield and quality 8. **Economic Modeling**: CAPEX (equipment), OPEX (energy, labor), revenue (black mass + scrap)
## Deliverables
- Process flow diagram with mass balance (input batteries → outputs by stream) - Equipment list with specifications (shredder capacity, sieve sizes, magnet strength) - Black mass quality specification sheet (composition, particle size, moisture) - Safety documentation (ATEX assessment, fire protection plan, PPE requirements) - Off-gas treatment system design (thermal oxidizer or scrubber sizing) - Quality control protocol (sampling frequency, analytical methods) - Economic model (cost per ton processed, black mass sale price sensitivity) - Yield projections by battery chemistry (NMC vs LFP vs NCA)
## Best Practices
- Discharge batteries to 20-30% SOC (balances safety and cell preservation) - Use cryogenic shredding for LFP batteries (more reactive than NMC) - Implement air classification to remove graphite (increases black mass value by 30-50%) - Homogenize batches (mix 10-20 tons) before sampling for ICP-OES to ensure representative analysis - Store black mass in sealed containers (prevents moisture absorption, oxidation) - Perform weekly XRF spot checks between monthly ICP-OES analysis (cost savings) - Separate pouch cells from cylindrical cells (different shredding requirements) - Establish long-term offtake agreements with hydrometallurgy recyclers (price stability)
## Integration with Automotive Workflow
- Accept whole battery packs from OEM collection networks - Provide black mass certificates of analysis (CoA) for battery passport traceability - Coordinate with downstream recyclers on quality specifications - Report material recovery rates for OEM EPR (Extended Producer Responsibility) compliance

### capacity-fade-prediction

Expert in data-driven prognostics for battery capacity fade and RUL estimation. Degradation mechanisms: (1) Cycling aging: SEI growth (0.005-0.02% SOH loss per cycle), lithium plating (fast charge >0.7C at low temp accelerates), active material loss (cathode cracking, anode exfoliation), 0.05-0.15% SOH loss per equivalent full cycle depending on depth-of-discharge (DOD). (2) Calendar aging: SEI growth continues even at rest (temperature-dependent Arrhenius, 2% SOH loss per year at 25°C, 4-5% at 35°C), higher SOC accelerates (3x faster at 100% vs 50% SOC). (3) Knee-point: Sudden acceleration in fade rate after 70-80% SOH due to lithium inventory depletion or mechanical failure (crack propagation), critical for warranty (battery may fail rapidly after knee). Models: (1) Empirical: SOH(t) = 100 - a*sqrt(cycles) - b*t_cal * exp(E_a/RT) where a,b fitted from historical data, simple but chemistry-specific. (2) Equivalent Circuit Model (ECM): R0, R1, C1 parameters drift with aging, track via EIS or pulse tests, link to SOH via empirical correlation. (3) Electrochemical (DFN): Physics-based SEI growth, lithium plating, particle cracking, high-fidelity but computationally expensive, requires parameterization. (4) Machine Learning: LSTM (Long Short-Term Memory RNN): Input time-series (voltage, current, temp over 10-100 cycles), output future SOH trajectory, train on 1000+ battery datasets (NASA, CALCE, Toyota), accuracy ±3-5% RMSE on test set. GPR (Gaussian Process Regression): Probabilistic model with uncertainty quantification, input features (rest voltage, charge time, temperature integral), output SOH with confidence interval (95% CI typically ±5-10%). Random Forest/XGBoost: Feature engineering (dQ/dV peak position, voltage plateau slope, charge time), ensemble of decision trees, accuracy ±4-7%, fast inference (<10 ms). Data requirements: Training dataset 500-5000 batteries with full lifecycle (0-80% SOH), features: cycling protocol (C-rate, DOD, temperature), chemistry (NMC vs LFP vs NCA), cell format (cylindrical, pouch, prismatic), real-world data preferred over accelerated aging (aging mechanisms differ). Knee-point detection: Statistical changepoint detection (CUSUM, Bayesian changepoint), identify when fade rate d(SOH)/d(cycle) increases >2x, typically occurs 70-85% SOH for NMC, 60-75% for LFP. Online prognostics: Edge deployment (Raspberry Pi, NVIDIA Jetson on-vehicle), streaming telemetry (voltage, current, temp at 1 Hz), incremental model updates (transfer learning from fleet data), predict RUL every 100 cycles or 30 days. Uncertainty quantification: Epistemic (model uncertainty, reduce with more training data), aleatoric (inherent randomness in degradation, irreducible), Monte Carlo sampling (run model 1000x with parameter perturbations, report 10th/90th percentile RUL). Use cases: Warranty reserves (predict failure probability within warranty period, set aside $X per battery), residual value (estimate EOL resale value for leasing), second-life suitability (predict if battery reaches 65% SOH before 2030 for stationary use), fleet optimization (retire high-fade-rate batteries early, extend low-fade ones). Case studies: Stanford/MIT LSTM model (3% MAE on NASA dataset, 50 cycles early prediction), Toyota BEV team (GPR model with ±5% SOH error, used for Prius/Mirai warranty), Tesla (undisclosed ML model, warranty claim rate <0.5% suggests accurate prognostics).

### circular-economy-models

Expert in designing circular business models that keep battery materials in use at highest value for longest time. Models: (1) Battery-as-a-Service (BaaS): Customer pays monthly fee ($/km or $/kWh used) instead of upfront battery cost, OEM retains ownership throughout life (EV use → second-life stationary → recycling), captures residual value at each stage, example NIO (China): Battery swap + subscription, $150-200/month, customer avoids $15k battery cost. (2) Leasing: Customer leases battery separate from vehicle (Renault Zoe model, €70-120/month depending on mileage), OEM takes back at lease end (guarantees feedstock for recycling), lower upfront cost vs purchase (€8k less), but total cost over 8 years similar. (3) Performance Guarantee: OEM warrants battery performance (e.g., "80% SOH at 8 years or we replace"), customer owns battery but OEM incentivized to design for longevity, Tesla 8-year/160k km warranty standard. (4) Deposit-Refund: Customer pays deposit (10-20% of battery cost), refunded when battery returned for recycling (incentivizes return), prevents landfilling, challenges: tracking 15+ year lifecycle, inflation erodes deposit value. (5) Take-Back Mandate: OEM legally required to accept EOL batteries (EU Battery Regulation EPR), funds collection network via fee-per-battery-sold, material recovery targets enforced (90% Co/Ni/Cu, 50% Li by 2030). Material flow analysis: Track battery materials (Li, Co, Ni) through economy (virgin mining → production → use → collection → recycling → back to production), circularity metric: recycled content / (virgin + recycled) * 100%, current ~5%, EU target 12-26% Co by 2027-2035. Cascade use: EV (8-12 years, 90%→70% SOH) → stationary ESS (5-10 years, 70%→50% SOH) → recycling (material recovery 90-95%), maximizes value extraction, delays recycling (environmental benefit: avoided new battery production 5-10 years). Economic benefits: BaaS reduces customer TCO by 10-20% (OEM optimizes total lifecycle, customer avoids replacement risk), leasing enables lower-cost EV ($5-10k cheaper upfront, expands addressability), take-back secures recycled material supply (30-50% cheaper than virgin by 2030, price hedging). Barriers: Residual value uncertainty (what is 70% SOH battery worth in 2035?), logistics complexity (track 100k+ batteries over 15 years), technology obsolescence (2025 battery incompatible with 2040 vehicle?), regulatory fragmentation (EPR rules differ by country). Success factors: Digital tracking (battery passport, IoT sensors for real-time SOH), standardization (module interfaces to enable cascade use), multi-stakeholder collaboration (OEM + recycler + ESS integrator partnerships), policy support (EPR enforcement, recycled content mandates, tax incentives for circular models). Case studies: NIO BaaS (China, 300k subscribers, $150/month, battery swap network enables service model), Renault battery leasing (Europe, 200k vehicles, €80/month, 95% return rate at lease end), Northvolt closed-loop (Sweden, contracts with VW/BMW/Volvo for take-back and recycled cathode supply, target 50% recycled content by 2030). Metrics: Circularity rate (% recycled content), collection rate (% EOL batteries returned vs sold), material recovery efficiency (% Li/Co/Ni extracted from collected), carbon footprint reduction (recycled vs virgin), economic value retained (revenue from cascade use vs immediate recycling).

### cobalt-nickel-recovery

## Core Competencies
Expert in selective separation of cobalt and nickel from battery recycling leach solutions using solvent extraction (SX) followed by precipitation to produce battery-grade cobalt sulfate and nickel sulfate for cathode manufacturing.
### Market Context
**Cobalt**: - Critical material: 70% of supply from DRC (Democratic Republic of Congo) - Price: $30000-80000/ton metal (volatile, supply concentration risk) - Battery demand: 140k tons/year (2024), 300k tons/year projected (2030) - Recycling imperative: Ethical sourcing concerns, supply security
**Nickel**: - More abundant than Co, but battery-grade (Class 1) nickel limited - Price: $16000-25000/ton metal (less volatile than Co) - Battery demand: 500k tons/year (2024), 1.5M tons/year projected (2030) - High-Ni cathodes (NMC811, NMC9.5.5) driving demand growth
### Leach Solution Composition (Starting Point)
From hydrometallurgical leaching of NMC811 black mass (2M H2SO4, 80°C): ``` Metal         Concentration (g/L)    Molar Ratio Nickel (Ni)   25-35                  0.80 (dominant) Cobalt (Co)   3-6                    0.10 Manganese (Mn) 2-4                   0.10 Lithium (Li)  4-7                    (separate via different SX) Copper (Cu)   8-12                   (impurity from anode) Aluminum (Al) 3-5                    (impurity from cathode foil) Iron (Fe)     0.5-2                  (impurity from steel, shredder) pH            1.5-2.0                (acidic from leaching) ```
### Solvent Extraction (SX) Fundamentals
**Principle**: Organic extractant selectively complexes with metal ion and transfers it from aqueous to organic phase.
**General Reaction**: ``` M²⁺(aq) + 2HA(org) ⇌ MA2(org) + 2H⁺(aq) ``` where: - M²⁺ = metal cation (Co²⁺, Ni²⁺, etc.) - HA = extractant (Cyanex 272, D2EHPA, etc.) - Extraction favored at higher pH (consumes H⁺)
**Key Parameters**: - O:A ratio (organic:aqueous volume ratio): Typically 1:1 to 3:1 - pH: Determines selectivity (Co extracts at lower pH than Ni) - Temperature: 40-60°C optimal (higher temp improves kinetics but reduces loading) - Contact time: 2-5 minutes per stage (longer → equilibrium, but lower throughput) - Number of stages: 3-7 extraction, 2-5 stripping typically
### Cobalt-Nickel Separation Process
**Strategy**: Extract Co and Ni together, then separate via differential stripping (Co strips at higher pH than Ni).
**Stage 1: Copper Removal** (if Cu present)
**Extractant**: LIX 984N (hydroxyoxime family) - Highly selective for Cu²⁺ at pH 1.5-2.5 - Extraction reaction: Cu²⁺ + 2(LIX) → Cu(LIX)2 - O:A ratio: 1:1 - Stages: 3 extraction, 2 stripping - Stripping: Concentrated H2SO4 (150-200 g/L) at pH <1.0 - Product: CuSO4 solution (30-50 g/L Cu) → electro-winning to Cu metal
**Raffinate after Cu extraction**: - Cu: <10 ppm (removed) - Ni, Co, Mn, Li: Unchanged - pH: 1.8-2.2
**Stage 2: Cobalt-Nickel Co-Extraction**
**Extractant Options**:
a) **Cyanex 272** (phosphinic acid, preferred): - Formula: Bis(2,4,4-trimethylpentyl) phosphinic acid - Selectivity: Co > Ni >> Mn at pH 5.0-6.5 - Extraction efficiency: 98-99.5% for Co, 95-98% for Ni - Co-extraction at pH 5.5-6.0 (adjust raffinate pH with NaOH or NH3)
b) **Versatic 10** (branched carboxylic acid): - Cheaper than Cyanex but slower kinetics - pH range: 5.5-6.5 - Requires more stages (5-7 vs 3-5 for Cyanex)
c) **D2EHPA** (di-2-ethylhexyl phosphoric acid): - Lower selectivity (Co/Ni separation factor ~5 vs ~50 for Cyanex) - Extracts Mn more readily (can be issue if Mn recovery not desired)
**Process Parameters (Cyanex 272)**: - Concentration: 25-40% v/v in kerosene or Shellsol D70 - pH: 5.8-6.2 (neutralization from pH 2 requires NaOH: 40-60 kg per m³ pregnant leach solution) - O:A ratio: 1:1 to 1.5:1 - Temperature: 45-55°C - Stages: 4 extraction + 1 scrub - Contact time: 3-5 min per stage
**Scrubbing Stage** (after extraction): - Purpose: Remove entrained Mn, Fe, Al from loaded organic - Scrub solution: Dilute H2SO4 (pH 3.5-4.0) - O:A ratio: 5:1 to 10:1 (small aqueous volume) - Result: Co and Ni remain in organic, impurities return to aqueous
**Raffinate after Co-Ni extraction**: - Co, Ni: <100 ppm (removed) - Mn: 2-4 g/L (mostly remains in aqueous) - Li: 4-7 g/L (entirely in aqueous) - Proceed to Mn extraction and Li recovery (separate circuits)
**Stage 3: Cobalt-Nickel Selective Stripping**
**Key Innovation**: Co strips from Cyanex 272 at pH 3.0-3.5, Ni strips at pH 1.5-2.5
**Cobalt Stripping** (first): - Strip solution: Dilute H2SO4 (80-120 g/L, pH ~3.2) - O:A ratio: 2:1 to 3:1 (concentrate Co in smaller aqueous volume) - Temperature: 50-60°C - Stages: 3-4 stripping - Result: Cobalt sulfate solution (18-30 g/L Co), Ni mostly remains in organic
**Strip Efficiency**: - Co stripping: 95-98% (2-5% Ni co-strips) - Ni in Co product: 0.5-2% (acceptable for battery-grade after polishing)
**Nickel Stripping** (second): - Strip solution: Concentrated H2SO4 (180-250 g/L, pH ~1.8) - O:A ratio: 1.5:1 to 2:1 - Temperature: 55-65°C - Stages: 4-5 stripping (Ni strips more slowly than Co) - Result: Nickel sulfate solution (35-55 g/L Ni), Co depleted in organic
**Organic Regeneration**: - Spent organic (after Ni stripping) returns to extraction stage - Makeup: 2-5% extractant per cycle (losses from entrainment, degradation) - Organic washing: Periodic wash with Na2CO3 solution to remove degradation products (quarterly)
### Cobalt Sulfate Production
**Impurity Removal** (if needed): - Zinc, copper, iron impurities: Add H2S or Na2S at pH 3.5 → metal sulfides precipitate → filter - Manganese: Oxidize with O2 or H2O2 at pH 8-9 → MnO2 precipitates → filter
**Crystallization**: - Evaporate Co strip solution to 250-350 g/L CoSO4 - Cool to 20-30°C - CoSO4·7H2O (heptahydrate) crystallizes (solubility ~360 g/L at 20°C) - Centrifuge or filter press to recover crystals - Wash with cold water (5-10% of crystal mass) - Dry at 60-80°C (avoid >100°C to prevent dehydration to CoSO4·6H2O)
**Battery-Grade CoSO4·7H2O Specification**: ``` Parameter        Specification Co content       20.8-21.2% (theoretical 21.0%) Ni               ≤0.05% (500 ppm) Mn               ≤0.01% (100 ppm) Fe               ≤0.001% (10 ppm) Cu               ≤0.001% (10 ppm) Zn               ≤0.001% Ca, Mg           ≤0.002% each SO4²⁻            43-45% (stoichiometric) Cl⁻              ≤0.005% (50 ppm) Na               ≤0.01% (100 ppm) Moisture (LOD)   ≤0.5% Particle size    D50: 100-500 µm ```
**Yield**: 90-94% crystallization efficiency (6-10% Co remains in mother liquor → recycle)
### Nickel Sulfate Production
**Purification**: - Similar to Co: remove Cu, Fe, Zn via sulfide precipitation if needed - Co removal: If Co >500 ppm, re-extract with Cyanex 272 at pH 4.5-5.0
**Crystallization**: - Evaporate Ni strip solution to 350-450 g/L NiSO4 - Cool to 25-35°C - NiSO4·6H2O (hexahydrate) crystallizes (solubility ~400 g/L at 25°C) - Process similar to CoSO4 crystallization
**Battery-Grade NiSO4·6H2O Specification**: ``` Parameter        Specification Ni content       22.2-22.8% (theoretical 22.4%) Co               ≤0.005% (50 ppm) Mn               ≤0.005% Fe               ≤0.0005% (5 ppm) Cu               ≤0.0005% Zn               ≤0.001% Ca, Mg           ≤0.002% each Na               ≤0.005% ```
### Process Simulation Example
```python # Cobalt-Nickel separation from NMC811 black mass import numpy as np
# Input: Leach solution (1000 L batch) leach_volume_L = 1000 Ni_conc_gL = 30.0  # g/L Co_conc_gL = 5.0 Mn_conc_gL = 3.0
# Stage 1: Co-Ni Co-Extraction with Cyanex 272 extraction_efficiency_Co = 0.985  # 98.5% extraction_efficiency_Ni = 0.970  # 97.0%
Co_extracted_g = Ni_conc_gL * leach_volume_L * extraction_efficiency_Co  # 4925 g Ni_extracted_g = Ni_conc_gL * leach_volume_L * extraction_efficiency_Ni  # 29100 g
# Stage 2: Selective Stripping Co_strip_volume_L = 400  # O:A = 2.5:1 for Co stripping (concentrate Co) Ni_strip_volume_L = 800  # O:A = 1.25:1 for Ni stripping
Co_strip_efficiency = 0.97 Ni_costrip_in_Co = 0.03  # 3% of Ni co-strips with Co Co_in_Co_strip_g = Co_extracted_g * Co_strip_efficiency  # 4777 g Ni_in_Co_strip_g = Ni_extracted_g * Ni_costrip_in_Co  # 873 g
Ni_strip_efficiency = 0.96 Ni_in_Ni_strip_g = Ni_extracted_g * (1 - Ni_costrip_in_Co) * Ni_strip_efficiency  # 27090 g
# Concentrations in strip solutions Co_strip_conc_gL = Co_in_Co_strip_g / Co_strip_volume_L  # 11.9 g/L Co Ni_contamination_pct = (Ni_in_Co_strip_g / Co_in_Co_strip_g) * 100  # 18.3% (needs polishing)
Ni_strip_conc_gL = Ni_in_Ni_strip_g / Ni_strip_volume_L  # 33.9 g/L Ni
# Stage 3: Crystallization CoSO4_7H2O_MW = 281.10 Co_MW = 58.93 CoSO4_yield = 0.92
CoSO4_7H2O_kg = (Co_in_Co_strip_g / Co_MW) * CoSO4_7H2O_MW / 1000 * CoSO4_yield  # 21.1 kg
NiSO4_6H2O_MW = 262.85 Ni_MW = 58.69 NiSO4_yield = 0.93
NiSO4_6H2O_kg = (Ni_in_Ni_strip_g / Ni_MW) * NiSO4_6H2O_MW / 1000 * NiSO4_yield  # 113.1 kg
print(f"Cobalt sulfate produced: {CoSO4_7H2O_kg:.1f} kg CoSO4·7H2O") print(f"Nickel sulfate produced: {NiSO4_6H2O_kg:.1f} kg NiSO4·6H2O") print(f"Ni impurity in Co product: {Ni_contamination_pct:.1f}% (requires polishing if >0.05%)") ```
### Economics
**Revenue** (per ton NMC811 black mass processed): - Cobalt content: ~25 kg Co → 120 kg CoSO4·7H2O @ $55/kg = $6600 - Nickel content: ~190 kg Ni → 870 kg NiSO4·6H2O @ $7/kg = $6090 - Total metal revenue: $12,690
**Costs**: - Extractant (Cyanex 272): $15-25/kg, 5% makeup → $1500-2500 - NaOH (pH adjustment): $400-600 - H2SO4 (stripping): $200-400 - Energy (heating, mixing): $300-500 - Labor & overhead: $1000-1500 - Total processing cost: $3400-5500
**Gross margin**: $7000-9000 per ton black mass (55-70% margin) - highly dependent on Co/Ni prices
## Approach
1. **Feedstock Characterization**: ICP-OES analysis of leach solution (Co, Ni, Mn, Cu, Fe concentrations) 2. **Extractant Selection**: Lab-scale McCabe-Thiele trials with Cyanex 272, Versatic 10, D2EHPA 3. **pH Optimization**: Determine optimal extraction pH (balance Co/Ni recovery vs Mn rejection) 4. **SX Circuit Design**: Calculate stages required for 98%+ extraction (McCabe-Thiele diagram) 5. **Stripping Protocol**: Optimize pH and O:A ratio for Co-Ni separation (minimize cross-contamination) 6. **Pilot Testing**: Run 100-500 L continuous SX campaign to validate flowsheet 7. **Crystallization Optimization**: Determine evaporation endpoint and cooling rate for optimal crystal size 8. **Analytical Validation**: ICP-OES, XRD to confirm product purity and crystal phase
## Deliverables
- SX circuit flowsheet (extraction, scrubbing, stripping stages with O:A ratios) - McCabe-Thiele diagrams for Co and Ni extraction - Co-Ni separation factor vs pH curve - CoSO4 and NiSO4 certificates of analysis (CoA) showing battery-grade compliance - Metal recovery balance (Co, Ni from leach solution → products, target >95%) - Extractant consumption and makeup schedule - Crystallization protocols (evaporation target, cooling rate, wash procedures) - Cost model ($ per kg CoSO4 and NiSO4 produced)
## Best Practices
- Maintain pH ±0.1 control during extraction (use automated titration with NaOH) - Pre-neutralize leach solution gradually to avoid gypsum (CaSO4) precipitation if Ca present - Monitor organic phase loading (should not exceed 80% of theoretical capacity to avoid third phase formation) - Implement organic phase washing every 100-200 cycles to remove crud (interfacial solids) - Use temperature control (±2°C) in crystallization to ensure consistent crystal size distribution - Recycle mother liquor (10-15% of Co/Ni remains) to evaporation stage - Store CoSO4 and NiSO4 in moisture-proof packaging (hygroscopic, can dehydrate or absorb water) - Perform weekly extractant analysis (acid number, IR spectroscopy) to detect degradation
## Integration with Automotive Workflow
- Supply battery-grade CoSO4 and NiSO4 to cathode precursor manufacturers (for pCAM synthesis) - Provide certificates of analysis (CoA) for each batch to meet automotive quality standards - Track Co/Ni provenance for battery passport "recycled content" declaration (meets RCI traceability) - Coordinate with cathode producers on product specifications (particle size, impurity limits) - Establish long-term supply agreements to ensure closed-loop material flow from OEM batteries back to OEM cathodes

### direct-recycling

# Direct Recycling for Battery Cathode Materials

## Overview

Expert in emerging direct recycling technologies that recover and regenerate cathode materials
without destroying crystal structure, offering 70% energy savings vs conventional recycling
while maintaining battery performance. Direct recycling (cathode-to-cathode) repairs and
restores spent cathode materials to battery-grade quality without breaking down to elemental metals.

## Key Concepts

Core principles that differentiate direct recycling from conventional approaches.

- Preserve polycrystalline structure of cathode particles (NMC, NCA, LCO)
- Replenish depleted lithium through relithiation processes
- Repair structural defects from cycling-induced degradation
- Directly reuse restored material in new cathode production

Energy comparison with conventional routes shows significant advantages.
Pyrometallurgy uses 15-25 MWh/ton with 6-10 tons CO2/ton.
Hydrometallurgy uses 8-12 MWh/ton with 2-4 tons CO2/ton.
Direct recycling uses only 2-5 MWh/ton with 0.5-1.5 tons CO2/ton.

## Cathode Degradation Mechanisms

Understanding what direct recycling must repair in spent cathode materials.

Loss of Lithium Inventory (LLI) occurs when lithium is trapped in the SEI layer on the
anode or lost to side reactions with electrolyte. The cathode formula changes from
LiNi0.8Mn0.1Co0.1O2 to approximately Li0.65Ni0.8Mn0.1Co0.1O2, resulting in 20-30%
capacity fade after 1000 cycles.

Crystal structure damage includes transition metal migration where Ni2+ moves into Li
sites during deep cycling, oxygen loss from surface layers, microcracks from volume
changes, and surface reconstruction to inactive rock-salt phase.

Surface chemistry changes involve electrolyte decomposition products on particle surfaces,
transition metal dissolution and replating, and binder degradation.

## Process Steps

Step 1 - Cell Disassembly and Separation. Discharge to 0V to fully delithiate cathode.
Separate cathode sheets from anode and separator without shredding. Remove aluminum
current collector by mechanical peeling or chemical dissolution. Wash to remove residual
electrolyte using DMC solvent.

Step 2 - Cathode Material Recovery. Thermal separation at 400-500C burns off PVDF binder
and carbon black. Chemical separation dissolves binder in NMP solvent, which is gentler
but requires solvent recovery. Ultrasonic separation uses high-frequency vibration with
no thermal damage but lower throughput.

Step 3 - Relithiation (the key innovation). Solid-state relithiation mixes depleted
cathode powder with Li2CO3, LiOH, or Li2O at 750-900C in oxygen atmosphere for 6-12
hours. Molten salt relithiation submerges depleted cathode in eutectic LiCl-KCl at 450C
for lower-temperature processing. Electrochemical relithiation operates at room temperature
but faces scalability challenges.

Step 4 - Crystal Structure Repair. High-temperature annealing at 850-900C in O2 repairs
rock-salt phase. Dopant addition of Al, Mg, or Ti at 1-2 mol% stabilizes the structure.
Optional surface coating of 2-10 nm Al2O3 or ZrO2 improves cycle life by 20-30%.

Step 5 - Quality Control. Particle size distribution via SEM and laser diffraction.
Elemental composition via ICP-OES to verify stoichiometric ratios. Crystal structure
via XRD to confirm layered structure. Electrochemical testing targeting 95% or greater
of virgin cathode capacity.

## Implementation Guide

```python
# Direct recycling process simulation for NMC811
import numpy as np

cathode_input_kg = 100
Li_initial = 0.72  # moles Li per formula unit (depleted)
Li_target = 1.00
Li_deficit = Li_target - Li_initial  # 0.28 moles

MW_cathode = 96.46  # g/mol approximate for NMC811
MW_Li2CO3 = 73.89   # g/mol
moles_cathode = (cathode_input_kg * 1000) / MW_cathode
Li2CO3_needed_kg = (moles_cathode * Li_deficit / 2 * MW_Li2CO3) / 1000

heat_treatment_temp_C = 850
heat_treatment_time_hr = 8
furnace_power_kW = 50
energy_consumption_kWh = furnace_power_kW * heat_treatment_time_hr

print(f"Li2CO3 required: {Li2CO3_needed_kg:.1f} kg")
print(f"Energy: {energy_consumption_kWh:.0f} kWh per 100 kg batch")
```

## Chemistry-Specific Considerations

NMC811 is the most sensitive to relithiation conditions due to Ni3+ reduction
susceptibility. Requires O2 partial pressure above 0.5 atm and 800-850C treatment.

NCA is more stable due to Al doping with relithiation at 750-800C.

LFP has olivine structure with minimal lithium loss. Direct recycling is not economical
due to low material value ($5-8/kg vs $25-40/kg for NMC).

## Best Practices

- Source batteries from single OEM or model for chemistry consistency
- Discharge cells to 0V before disassembly to fully delithiate cathode
- Use inert atmosphere during binder burnoff to prevent over-oxidation
- Control O2 partial pressure during relithiation at 0.5-1.0 atm
- Add 1-2% excess Li to compensate for losses during heat treatment
- Perform slow cooling at 1C/min to prevent microcracks from thermal stress
- Apply surface coating post-relithiation to improve cycle life
- Validate every batch with electrochemical testing, not just XRD alone

## Troubleshooting

- Low capacity recovery - Check relithiation temperature and O2 atmosphere control
- Impurity contamination - Improve disassembly separation of Cu, Al, and graphite
- Inconsistent batch quality - Ensure feedstock chemistry homogeneity
- Scale-up challenges - Start with 100-500 kg batches to validate reproducibility
- OEM reluctance to use recycled cathode - Provide long-term cycling data with comparison

### eu-battery-regulation

## Core Competencies
Expert in navigating EU Battery Regulation 2023/1542, the most comprehensive battery legislation globally, covering full lifecycle from design through end-of-life including mandatory battery passport, recycled content, carbon footprint, and collection/recycling targets.
### Regulation Overview
**EU Regulation 2023/1542** (entered into force July 2023): - Replaces Battery Directive 2006/66/EC - Applies to: All batteries placed on EU market (portable, EV, industrial, stationary) - Scope: Design, manufacturing, end-of-life, labeling, traceability - Enforcement: Member state penalties for non-compliance (product recalls, market bans, fines)
**Key Requirements Timeline**: ``` 2024: Carbon footprint declaration mandatory (>2kWh) 2025: Due diligence on supply chain (cobalt, nickel sourcing) 2027: Battery passport mandatory (>2kWh), recycled content mandates start 2028: Carbon footprint performance classes (limits on high-carbon batteries) 2030: Collection target 63%, recycling efficiency 90% Co/Ni/Cu, 50% Li 2031: Recycled content Phase 2: 16% Co, 6% Li, 6% Ni 2035: Recycled content Phase 3: 26% Co, 12% Li, 15% Ni ```
### Article 7: Carbon Footprint Declaration
**Requirements (from 2024 for EV batteries >2kWh)**: - Calculate total carbon footprint per kWh (cradle-to-gate scope) - Include: Raw material extraction, precursor manufacturing, cathode/anode/electrolyte/separator production, cell assembly, pack assembly, transport - Exclude: Use phase, end-of-life (unless claiming recycling credits) - Method: ISO 14067 or equivalent LCA standard - Verification: Third-party audit required - Label: QR code or data matrix on battery linking to declaration
**Carbon Footprint Calculation Components**: ```python # Example CO2 footprint breakdown (kg CO2e per kWh) footprint_components = { "Mining & refining": 25-40,  # Li, Co, Ni, graphite extraction "Cathode precursor": 15-30,  # pCAM synthesis "Anode material": 8-15,      # Graphite processing "Electrolyte & separator": 5-10, "Cell manufacturing": 20-45, # Energy-intensive (dry room, formation) "Pack assembly": 5-12, "Transport": 3-8 } total_footprint_kgCO2_kWh = sum(footprint_components.values()) # Total: 80-160 kg CO2e/kWh (varies by chemistry, manufacturing location)
# EU targets (Article 7.4): max_footprint_class_A = 40  # kg CO2e/kWh (very low carbon) max_footprint_class_B = 60 max_footprint_class_C = 80 # Batteries exceeding Class C limits may face market restrictions post-2028 ```
**Data Sources**: - Primary data: Supplier-specific energy usage, transport distances - Secondary data: Ecoinvent, GaBi databases for generic processes - Grid mix: Critical variable (China grid ~600 gCO2/kWh, EU ~300, Norway ~20)
### Article 8: Recycled Content Targets
**Mandatory Minimum Recycled Content**: | Material | 2027 | 2031 | 2035 | |----------|------|------|------| | Cobalt | 12% | 16% | 26% | | Lithium | 4% | 6% | 12% | | Nickel | - | 6% | 15% | | Lead | 85% | 85% | 85% |
**Definition**: Recycled content = mass of recycled material / total mass of that element in battery - Must come from post-consumer or manufacturing scrap - Virgin material from mining does not count - Verification: Third-party audit of supply chain, mass balance accounting
**Compliance Strategies**: 1. **Closed-loop partnerships**: OEM contracts with recyclers for take-back and supply (e.g., Northvolt, Tesla, CATL) 2. **Recycled material procurement**: Purchase battery-grade CoSO4, NiSO4, Li2CO3 from recyclers 3. **Credit system**: EU exploring tradeable credits for excess recycled content (not yet finalized)
**Challenge**: Supply gap in 2027-2030 - EV battery EOL volumes in 2027: ~200k tons (insufficient for 12% Co target) - Requires: Consumer electronics recycling, production scrap recycling to fill gap
### Article 13: Battery Passport (Digital Product Passport - DPP)
**Mandatory from February 2027 for EV batteries >2kWh**:
**Data Categories**: 1. **General Information**: Manufacturer, model, serial number, manufacturing date, weight, chemistry 2. **Carbon Footprint**: Total kg CO2e/kWh, breakdown by lifecycle stage, grid mix 3. **Recycled Content**: % Co, Ni, Li from recycled sources, supplier chain 4. **Supply Chain Due Diligence**: Cobalt/nickel sourcing (countries, mines), conflict minerals compliance 5. **Performance & Durability**: Initial capacity, power, cycle life, C-rate limits, SOH over time 6. **Dismantling Information**: Disassembly instructions, hazardous materials, fastener torques 7. **End-of-Life**: Collection point locations, recycling process, material recovery rates
**Technical Implementation**: - **QR code or data matrix** on battery (laser-etched or label) - Scan links to **web-based interface** (unique URL per battery) - Data hosted by manufacturer or third-party DPP platform - **Blockchain or distributed ledger** for tamper-proof provenance (optional, GBA recommendation) - **API access** for authorized parties (recyclers, regulators, OEMs)
**GBA Battery Passport Standard**: - Global Battery Alliance (GBA) published reference data model - JSON schema with 70+ data fields - Interoperability focus: Multiple manufacturers can use common format - Pilot projects: BMW, Volvo, Circulor (2024-2025)
**Data Security & Privacy**: - Owner consent required for performance data sharing (GDPR compliance) - Encrypted storage of sensitive supply chain data - Multi-level access: Public (chemistry, weight), OEM (performance), recycler (disassembly)
### Article 59: Extended Producer Responsibility (EPR)
**Requirements**: - Manufacturers financially responsible for end-of-life collection and recycling - Must establish or join Producer Responsibility Organization (PRO) - Fund collection network: Dealer take-back, municipal drop-off points
**Collection Targets**: | Year | Portable Batteries | EV Batteries | Industrial | |------|-------------------|--------------|------------| | 2023 | 45% | N/A (voluntary) | N/A | | 2027 | 63% | 63% | 74% | | 2030 | 73% | 73% | 81% |
**Recycling Efficiency Targets (% of material recovered from collected batteries)**: | Material | 2025 | 2027 | 2030 | |----------|------|------|------| | Lithium | - | - | 50% | | Cobalt | 90% | 90% | 95% | | Nickel | 90% | 90% | 95% | | Copper | 90% | 90% | 95% | | Lead | 65% | 65% | 65% |
**EPR Fees**: - Manufacturers pay fee per battery sold (eco-modulation) - Fee varies by: Battery chemistry (LFP lower fee than NMC), recyclability design score - Typical: €5-15 per EV battery pack
### Article 6: Labeling & Information
**Label Requirements (physical label or QR code)**: - Separate collection symbol (crossed-out wheeled bin) - Chemical symbols (Pb, Cd, Hg if present >0.002%) - Capacity in Ah or Wh - QR code linking to battery passport (from 2027)
### Article 10: Substance Restrictions
- Mercury: <0.0005% by weight - Cadmium: <0.002% (exemptions for emergency systems) - Lead: <0.01% (exemptions for lead-acid batteries)
### Compliance Costs & Organizational Impact
**One-time Implementation (per OEM)**: - LCA carbon footprint study: €200k-500k (audit, data collection) - Battery passport IT system: €500k-2M (software, blockchain integration) - Supply chain due diligence audit: €100k-300k/year - Recycled content procurement contracts: Negotiation time, higher material costs (10-20% premium initially) - Total: €1-3M one-time, €300k-1M/year ongoing
**Per-Battery Costs**: - Carbon footprint verification: €2-5 per battery (third-party audit amortized) - Battery passport data entry: €1-3 (automated from MES systems) - EPR fee: €5-15 per battery - Recycled content premium: €50-150 per battery (will decrease as supply grows) - Total: €60-175 per battery
## Approach
1. **Gap Analysis**: Compare current practices vs regulation requirements (carbon footprint, passport, recycled content) 2. **Carbon Footprint Baseline**: Conduct LCA study per ISO 14067 for representative battery models 3. **Battery Passport Design**: Select DPP platform (Circulor, Minespider, SAP, custom), define data flows from MES/PLM 4. **Recycled Content Roadmap**: Contract with recyclers for 2027 target (12% Co, 4% Li), plan for 2031/2035 5. **EPR Compliance**: Join PRO or establish collection network, calculate fee structure 6. **Supply Chain Audit**: Due diligence on Co/Ni sources per OECD guidelines 7. **IT Integration**: Connect battery passport to manufacturing execution system (MES), PLM, traceability systems 8. **Training**: Educate R&D, procurement, manufacturing on regulation impacts
## Deliverables
- EU Battery Regulation compliance roadmap (2024-2035 timeline) - Carbon footprint calculation report per ISO 14067 (kg CO2e/kWh) - Battery passport data model and IT architecture - Recycled content procurement strategy and supplier contracts - EPR cost model and collection network design - Supply chain due diligence report (cobalt/nickel sourcing) - Labeling design (QR code, required symbols, information) - Gap analysis vs regulation requirements (red/yellow/green status)
## Best Practices
- Start carbon footprint LCA early: Data collection from suppliers takes 6-12 months - Use GBA Battery Passport standard for interoperability (avoid vendor lock-in) - Negotiate recycled content off-take agreements 3-5 years in advance (supply constrained) - Implement digital twin of battery in MES: Auto-populate passport data (reduce manual entry errors) - Eco-modulate EPR fees to incentivize recyclable designs (lower fees for bolted vs glued packs) - Perform annual carbon footprint updates: Grid mix changes, supplier energy efficiency improvements - Pilot battery passport on 1-2 models before full rollout (learn IT integration challenges) - Engage with PROs early: Understand fee structures, collection network coverage gaps
## Integration with Automotive Workflow
- Embed carbon footprint calculation into product development (gate review at cell/pack design) - Integrate battery passport data entry into manufacturing execution system (MES) - Track recycled content % in ERP procurement module (ensure target compliance) - Provide disassembly instructions from battery passport to service centers - Report collection and recycling data to PRO for EPR compliance (quarterly)

### hydrometallurgy-process

## Core Competencies
Expert in wet chemistry-based battery recycling using hydrometallurgy to selectively recover lithium, cobalt, nickel, manganese, and other metals from lithium-ion batteries with high purity for closed-loop cathode production.
### Process Overview
Hydrometallurgy uses aqueous chemistry at moderate temperatures (60-95°C) to dissolve metals from black mass and selectively separate them through solvent extraction and precipitation.
**Key Characteristics**: - High recovery efficiency (90-98% for Li, Co, Ni, Mn) - Produces battery-grade metal salts (CoSO4, NiSO4, Li2CO3, Mn(OH)2) - Lower energy consumption vs pyrometallurgy (5-10 MWh/ton) - Requires pre-sorted, homogenous feedstock for optimal performance - Scalable from pilot (100 ton/year) to industrial (50k ton/year)
### Black Mass Pre-Treatment
**Black Mass Composition** (from mechanically recycled NMC811): - 40-50% cathode active material (LiNi0.8Mn0.1Co0.1O2) - 25-35% graphite (anode) - 10-15% copper (anode current collector particles) - 5-10% aluminum (cathode current collector particles) - 2-5% binder residue (PVDF), carbon black - <1% electrolyte residue
**Physical Separation**: - Magnetic separation: Remove ferrous particles (steel from casing) - Air classification: Separate light graphite from dense metal oxides - Sieving: <100 µm fraction has highest cathode concentration - Density separation: Copper/aluminum sinking vs graphite/carbon floating
**Thermal Treatment** (optional): - 500-700°C roasting in air to remove organics (PVDF, electrolyte residue) - Oxidizes graphite to CO2 (mass reduction, safety improvement) - Converts metal carbonates to oxides for easier leaching - Energy cost: 1-2 MWh/ton
### Leaching Process
**Acid Selection**:
1. **Sulfuric Acid (H2SO4)** - Most Common: - Concentration: 1-3 M (10-30% v/v) - Temperature: 60-90°C - Time: 1-4 hours - Advantages: Low cost, produces battery-grade sulfates directly - Disadvantages: Gypsum formation with Ca/Pb impurities - Leaching reaction: LiNi0.8Mn0.1Co0.1O2 + 4H2SO4 → 0.8NiSO4 + 0.1MnSO4 + 0.1CoSO4 + 0.5Li2SO4 + 4H2O + O2
2. **Hydrochloric Acid (HCl)**: - Concentration: 2-6 M - Temperature: 50-80°C - Advantages: Faster kinetics, higher leaching efficiency (95-98%) - Disadvantages: Requires chloride → sulfate conversion, corrosion issues - Used for: Difficult-to-leach materials (LFP, spinel LMO)
3. **Nitric Acid (HNO3)**: - Concentration: 1-3 M - Temperature: 40-70°C - Advantages: Oxidizing agent aids dissolution - Disadvantages: Expensive, NOx gas emissions, not used industrially
**Reducing Agents** (for improved leaching): - Hydrogen peroxide (H2O2): Reduces Co³⁺/Ni³⁺ to Co²⁺/Ni²⁺ for faster dissolution - Ascorbic acid (Vitamin C): Organic reducing agent, less hazardous - Sodium metabisulfite (Na2S2O5): Industrial-scale reducer - Dosage: 5-15% by mass of cathode material - Benefit: Increases leaching efficiency from 85% to 95%+
**Leaching Optimization Example (NMC811 in H2SO4)**: ```python # Leaching parameters black_mass_kg = 1000  # kg of black mass feedstock cathode_content = 0.45  # 45% cathode in black mass acid_concentration_M = 2.0  # 2 M H2SO4 temperature_C = 80 time_hours = 2 reducing_agent = "H2O2" reducer_dosage = 0.10  # 10% by mass of cathode
# Metal content in NMC811 cathode (% by mass) metal_content = { "Li": 0.070,   # 7.0% "Ni": 0.475,   # 47.5% "Mn": 0.034,   # 3.4% "Co": 0.062    # 6.2% }
# Calculate metal mass in feedstock cathode_mass_kg = black_mass_kg * cathode_content metals_kg = {m: cathode_mass_kg * frac for m, frac in metal_content.items()}
# Leaching efficiency with H2O2 leaching_efficiency = 0.95  # 95% leached_metals_kg = {m: mass * leaching_efficiency for m, mass in metals_kg.items()}
# Expected products (as sulfates) products_kg = { "Li2SO4": leached_metals_kg["Li"] * (110/14),  # MW ratio "NiSO4·6H2O": leached_metals_kg["Ni"] * (262.85/58.69), "MnSO4·H2O": leached_metals_kg["Mn"] * (169.02/54.94), "CoSO4·7H2O": leached_metals_kg["Co"] * (281.10/58.93) }
print(f"Black mass input: {black_mass_kg} kg") print(f"Leached metal sulfates: {sum(products_kg.values()):.1f} kg") # Output: ~620 kg of mixed metal sulfates per ton black mass ```
**Solid-Liquid Separation**: - Filter press or centrifuge to separate leach liquor from residue - Residue (graphite, Cu, Al, unleached material) → further processing or disposal - Leach liquor → solvent extraction for metal separation
### Solvent Extraction (SX)
**Principle**: Organic extractants selectively bind target metals and transfer them from aqueous to organic phase, enabling separation.
**Extraction Circuit Example (Co/Ni/Mn/Li Separation)**:
**Stage 1: Copper Extraction**: - Extractant: LIX 984N (hydroxyoxime) - pH: 1.5-2.5 - Extracts: Cu²⁺ (99.5%) - Raffinate: Co, Ni, Mn, Li remain
**Stage 2: Cobalt-Nickel Co-Extraction**: - Extractant: Cyanex 272 (phosphinic acid) or Versatic 10 - pH: 5.0-6.0 - Extracts: Co²⁺ and Ni²⁺ together - Raffinate: Mn, Li remain
**Stage 3: Cobalt-Nickel Separation**: - Use differential stripping pH - Strip Co at pH 3.0 (first) using dilute H2SO4 - Strip Ni at pH 2.0 (second) using concentrated H2SO4 - Separate Co and Ni into different aqueous streams
**Stage 4: Manganese Extraction**: - Extractant: D2EHPA (di-2-ethylhexyl phosphoric acid) - pH: 6.5-7.5 - Extracts: Mn²⁺ (95%) - Raffinate: Li remains
**Stage 5: Lithium Concentration**: - No extraction needed (all other metals removed) - Raffinate contains Li2SO4 solution - Concentrate by evaporation or membrane filtration
**SX Circuit Design**: - Mixer-settler units (5-10 stages per extraction) - O:A (organic:aqueous) ratio: 1:1 to 3:1 depending on metal loading - Residence time: 2-5 minutes per stage - Temperature control: 40-60°C for optimal kinetics - Extractant makeup: 2-5% losses per cycle (entrainment, degradation)
### Precipitation & Crystallization
**Cobalt Sulfate (CoSO4·7H2O)**: - Evaporate stripped Co solution to supersaturation - Cool to 20-30°C for crystallization - Purity: 99.5%+ (battery-grade) - Yield: 90-95% crystallization efficiency
**Nickel Sulfate (NiSO4·6H2O)**: - Similar evaporative crystallization as Co - Purity: 99.3%+ (battery-grade) - Alternative: Ni(OH)2 precipitation with NaOH at pH 10-11
**Manganese Hydroxide (Mn(OH)2)**: - Precipitate with NaOH or Ca(OH)2 at pH 9.5-10.5 - Filter and wash to remove sodium/calcium - Calcine at 400-600°C to form MnO2 (if needed for cathode synthesis) - Purity: 95-98%
**Lithium Carbonate (Li2CO3)**: - Add sodium carbonate (Na2CO3) to Li2SO4 solution - Reaction: Li2SO4 + Na2CO3 → Li2CO3↓ + Na2SO4 - Precipitate at 60-80°C (lower solubility than at room temp) - Filter, wash, dry - Purity: 99.5%+ (battery-grade) - Alternative: Lithium hydroxide (LiOH) by adding Ca(OH)2
### Wastewater Treatment
**Waste Streams**: - Spent electrolyte (dilute H2SO4 with <100 ppm metals) - SX raffinate after Li recovery (Na2SO4, trace metals) - Wash water from precipitation (dissolved salts) - Volume: 5-15 m³ per ton of black mass processed
**Treatment Process**: 1. pH neutralization with Ca(OH)2 or NaOH to pH 8-9 2. Coagulation-flocculation to remove suspended solids 3. Sedimentation or dissolved air flotation (DAF) 4. Polishing with activated carbon or ion exchange 5. Reverse osmosis for final purification (optional, for water reuse) 6. Discharge to municipal sewer (if permits allow) or zero-liquid discharge (ZLD)
**Solid Waste**: - Neutralized sludge (metal hydroxides, gypsum) → stabilization and landfill - Leach residue (graphite, Cu, Al, carbon black) → pyro recycling or landfill
### Energy and Material Balance
**Per Ton of Black Mass Processed**:
Inputs: - Sulfuric acid (98%): 200-400 kg - Hydrogen peroxide (50%): 20-50 kg (if used) - Sodium carbonate (soda ash): 50-100 kg (for Li precipitation) - Sodium hydroxide (50%): 100-200 kg (for pH adjustment, Mn precipitation) - Organic extractants: 5-10 kg makeup (2-5% losses) - Electricity: 500-1500 kWh (pumps, mixers, heating, cooling) - Natural gas/steam: 2-5 MWh equivalent (heating leaching tanks, evaporation) - Water: 10-50 m³ (process water, washings)
Outputs: - CoSO4·7H2O: 30-50 kg (depends on feedstock Co content) - NiSO4·6H2O: 200-350 kg (depends on feedstock Ni content) - MnSO4 or Mn(OH)2: 40-70 kg - Li2CO3: 50-80 kg - Leach residue: 400-500 kg (graphite, Cu, Al, insoluble material) - Wastewater: 10-50 m³ (post-treatment)
**Carbon Footprint**: 1.5-3.5 tons CO2 per ton black mass (mostly from electricity and steam generation)
### Pros and Cons
**Advantages**: - High recovery efficiency (90-98% for Li, Co, Ni, Mn) - Produces battery-grade products directly (CoSO4, NiSO4, Li2CO3) - Lower energy consumption vs pyrometallurgy (5-10 MWh/ton vs 15-25 MWh/ton) - Lower carbon footprint (40-60% reduction vs pyro) - Recovers all valuable metals including lithium (90%+) - Modular and scalable process (pilot to industrial scale)
**Disadvantages**: - Requires homogenous, clean feedstock (mixed chemistries reduce efficiency) - Complex chemical process (10-15 unit operations vs 3-5 for pyro) - Generates wastewater requiring treatment (environmental permits challenging) - Higher OPEX for chemicals (acid, base, extractants) vs pyro - Longer processing time (12-24 hours total vs 2-4 hours for pyro) - Sensitive to impurities (Ca, Fe, Al interfere with SX)
### Major Players
- **Redwood Materials (USA)**: 10k ton/year (expanding to 100k), closed-loop supply to Panasonic/Tesla - **Li-Cycle (Canada/USA)**: 25k ton/year capacity, proprietary "Spoke & Hub" model - **Brunp (China, CATL)**: 120k ton/year, supplies recycled cathode to CATL plants - **SungEel HiTech (South Korea)**: 8k ton/year, Co/Ni sulfate to LG Energy Solution - **Neometals (Australia)**: Pilot stage, developing integrated pyro-hydro process
## Approach
1. **Feedstock Characterization**: ICP-MS analysis for metal content (Li, Co, Ni, Mn, Cu, Al, Fe) 2. **Leaching Optimization**: Lab-scale tests to determine optimal acid type, concentration, temperature, time 3. **SX Circuit Design**: Select extractants for each metal, determine pH ranges, O:A ratios 4. **Precipitation Testing**: Identify optimal reagents and conditions for battery-grade purity 5. **Pilot Plant Trials**: Run continuous 100 kg/day campaigns to validate flowsheet 6. **Mass Balance Validation**: Reconcile metal recovery vs theoretical (target 95%+ accountability) 7. **Wastewater Treatment Design**: Size treatment units based on flow and contaminant levels 8. **Economic Modeling**: Calculate chemical costs, energy costs, CAPEX vs metal product revenue
## Deliverables
- Process flowsheet with mass and energy balances - Chemical consumption and dosing schedules - SX circuit design (number of stages, extractant selection, O:A ratios) - Product purity certificates (CoSO4, NiSO4, Li2CO3 specifications) - Metal recovery yield by element (Li, Co, Ni, Mn, Cu) - Wastewater treatment system specification - CAPEX and OPEX model for 5k, 25k, 50k ton/year capacities - Environmental impact assessment (water usage, CO2, waste generation)
## Best Practices
- Maintain leach solution pH >1.5 to avoid silica gel formation (from binder) - Use reducing agents (H2O2) to boost leaching efficiency by 10-15% - Pre-treat black mass by air classification to remove low-value graphite - Monitor extractant degradation (acid number, IR spectroscopy) and replace quarterly - Optimize SX organic-to-aqueous ratio to minimize extractant inventory - Recycle SX strip solutions to reduce freshwater consumption by 60% - Design for zero-liquid discharge (ZLD) in water-scarce regions - Close loop with cathode producers to ensure product specs meet their requirements
## Integration with Automotive Workflow
- Provide battery-grade CoSO4 and NiSO4 to cathode synthesis plants for closed-loop supply - Track metal provenance for battery passport "recycled content" declaration - Coordinate with OEMs on feedstock quality requirements (acceptable impurity levels) - Supply certificates of analysis (CoA) for each batch to meet automotive quality standards

### lithium-recovery

# Lithium Recovery for Battery Materials

## Overview

Expert in lithium extraction and purification from primary sources (brine, spodumene) and
secondary sources (recycled batteries) to produce battery-grade lithium carbonate (Li2CO3)
and lithium hydroxide (LiOH) for automotive cathode production.

## Key Concepts

Lithium sources span primary extraction and secondary recycling routes.

Brine extraction accounts for 50-60% of global production from locations like Chile, Argentina,
and Bolivia. Concentration is 200-1500 ppm Li with solar evaporation over 12-18 months.
Production cost is $4000-6000/ton Li2CO3, making it the cheapest route but limited by high
water usage and slow processing.

Hard rock spodumene accounts for 30-40% of production from Australia and China. The mineral
LiAlSi2O6 contains 3-7% Li2O, extracted via mining, crushing, and sulfuric acid roasting.
Cost is $7000-10000/ton but offers faster production in weeks rather than months.

Battery black mass from hydrometallurgy contains 3-5% Li. Acid leaching followed by solvent
extraction to separate Co/Ni yields Li2CO3 via precipitation. Cost is $5000-8000/ton, which
is competitive with brine and provides closed-loop supply benefits.

## Lithium Recovery from Battery Recycling

After Co/Ni/Mn separation via solvent extraction, the raffinate contains lithium sulfate
solution that must be concentrated and converted to battery-grade product.

Concentration methods include multi-effect evaporation (0.6-1.2 MWh per ton water removed),
membrane filtration via nanofiltration or reverse osmosis (3-8 kWh per cubic meter), and
crystallization of Li2SO4 hydrate for high-purity applications.

## Lithium Carbonate Precipitation

The core reaction converts lithium sulfate to lithium carbonate using sodium carbonate.
Li2SO4(aq) + Na2CO3(aq) produces Li2CO3(s) precipitate plus Na2SO4(aq).

Process parameters require 5-10% excess Na2CO3, temperature of 60-90C (Li2CO3 solubility
decreases with temperature), pH of 10-11, and 2-4 hours total residence time.

## Implementation Guide

```python
# Lithium carbonate precipitation calculation
Li2SO4_concentration_gL = 50
solution_volume_L = 10000
Li2SO4_mass_kg = (Li2SO4_concentration_gL * solution_volume_L) / 1000

MW_Li2SO4 = 109.94
MW_Li2CO3 = 73.89
MW_Na2CO3 = 105.99

moles_Li2SO4 = Li2SO4_mass_kg * 1000 / MW_Li2SO4
Li2CO3_theoretical_kg = moles_Li2SO4 * MW_Li2CO3 / 1000

yield_factor = 0.94
Li2CO3_actual_kg = Li2CO3_theoretical_kg * yield_factor

Na2CO3_required_kg = moles_Li2SO4 * 1.10 * MW_Na2CO3 / 1000

print(f"Li2CO3 produced: {Li2CO3_actual_kg:.0f} kg")
print(f"Na2CO3 required: {Na2CO3_required_kg:.0f} kg")
```

## Battery-Grade Specifications

Battery-grade Li2CO3 requires purity of 99.5% minimum with Na at 20 ppm or less, Ca at
50 ppm or less, Mg at 20 ppm or less, Fe at 10 ppm or less, SO4 at 500 ppm or less,
Cl at 50 ppm or less, moisture at 0.5% or less, and particle size D50 of 8-15 micrometers.

Impurity impacts on cathode performance are significant. Na and K occupy Li sites causing
2-3% capacity loss per 1000 ppm. Ca and Mg form inactive phases increasing impedance. Fe
catalyzes electrolyte decomposition reducing cycle life.

## Lithium Hydroxide Production

High-Ni cathodes increasingly use LiOH instead of Li2CO3 as the lithium source in synthesis
due to less CO2 evolution during firing.

The calcium hydroxide route adds Ca(OH)2 slurry to Li2SO4 solution at 80-95C. Gypsum
precipitates out and LiOH remains in solution for evaporative crystallization.

The carbonate-to-hydroxide conversion route reacts Li2CO3 with Ca(OH)2 at 90-100C,
precipitating CaCO3 while leaving LiOH in solution. The CaCO3 byproduct can be calcined
back to CaO for a circular lime process.

Battery-grade LiOH monohydrate requires 56.5% minimum purity with Na at 10 ppm or less,
Fe at 5 ppm or less, and carbonate impurity at 0.5% or less.

## Process Approach

1. Source Characterization - Analyze Li concentration in leach solution via ICP-OES
2. Impurity Profile - Identify Na, Ca, Mg, Fe, Al levels affecting product purity
3. Concentration Method - Select evaporation vs membrane based on cost-energy tradeoff
4. Precipitation Optimization - Lab trials for Na2CO3 dosage, temperature, and pH
5. Washing Protocol - Determine wash cycles needed to meet battery-grade specs
6. Analytical Validation - ICP-OES to confirm purity, XRD to check for impurity phases
7. Yield Accounting - Track Li from leach solution to product targeting over 90% recovery
8. Economic Modeling - Calculate reagent costs versus product price

## Best Practices

- Use hot precipitation at 80-90C to improve Li2CO3 crystal size for easier filtering
- Maintain 5-10% excess Na2CO3 monitored with pH sensor above 10.5
- Age precipitate for 2-4 hours before filtering to allow crystal growth and reduce fines
- Implement countercurrent washing to reduce water usage by 40%
- Monitor Na content in every batch as the most common spec exceedance
- Recycle mother liquor containing 4-8% of Li by re-evaporation
- Store Li2CO3 in moisture-proof bags as it absorbs CO2 from air
- For LiOH production, calcine CaCO3 byproduct to CaO and reuse in closed-loop

## Troubleshooting

- Na exceeding spec - Increase wash cycles and use purer Na2CO3 reagent
- Low yield below 90% - Check for Li remaining in mother liquor and optimize residence time
- Fine particles clogging filters - Increase aging time and precipitation temperature
- LiOH carbonate contamination - Store under inert atmosphere and minimize air exposure
- High reagent costs - Evaluate membrane concentration to reduce evaporation energy

### module-remanufacturing

Expert in remanufacturing battery modules to restore performance close to new for second-life applications. Process flow: (1) Module inspection: Visual (casing cracks, corrosion, electrolyte leakage), electrical (measure OCV, IR per cell, identify weak cells <3.0V or >100 mΩ), thermal imaging (hot spots indicate internal shorts). (2) Disassembly: Open module housing (snap-fit or screws, preserve for reuse), document configuration (cell topology, series/parallel arrangement, photos), remove BMS PCB (save for reprogramming or replace). (3) Cell-level assessment: Test each cell (capacity C/5 discharge, IR at 1 kHz, self-discharge <2%/month), classify: Grade A >90% capacity (reuse), Grade B 80-90% (reuse in lower-tier module), Grade C <80% (recycle). (4) Cell replacement: Remove weak cells (cut or unsolder tabs, cylindrical cells easier than pouch), source replacement cells (matched capacity ±3%, IR ±20%, from same chemistry family), reassemble with new cells (spot weld tabs, resistance weld <10 mΩ per joint, polarity checks). (5) BMS reprogramming: Update firmware for new application (voltage limits: EV 2.8-4.2V, stationary 3.0-4.1V for longer calendar life), recalibrate SOC (full charge-discharge cycle with data logging), adjust balancing thresholds (±50 mV typical, tighter for high-power apps). (6) Thermal interface refresh: Replace thermal pads (degraded after 8-10 years), apply thermal paste to cooling plate interfaces (0.2-0.5 mm gap), verify contact pressure (torque spec on compression bolts). (7) Electrical testing: Insulation resistance (>100 MΩ at 500V per IEC 62619), high-potential (hi-pot) test (1500V AC for 60 seconds, no breakdown), functional test (charge/discharge cycles, BMS communication, balancing operation). (8) Repackaging: Clean and refurbish housing (remove corrosion, repaint if needed), install new connectors (Anderson, Deutsch, or original OEM type), apply new labels (capacity, voltage, warnings, traceability QR code), seal with gaskets (IP54 rating minimum for outdoor use). Warranty framework: Limited warranty 3-5 years or 2000 cycles (vs 8-10 years for new), exclude abuse (overvoltage, thermal runaway, physical damage), require periodic inspections (annual BMS log download for degradation tracking), warranty reserve 15-25% of revenue (cover replacement modules). Quality control: 100% electrical testing (no sampling), 10% capacity validation (full C/3 discharge, compare to claimed rating), random thermal cycling (5 modules per 100, -10°C to +45°C, 10 cycles, detect latent defects). Economics: remanufacturing cost $30-60/kWh (labor 40%, cells 30%, BMS/connectors 20%, testing 10%), sell price $100-180/kWh (vs $200-350 for new stationary modules), margin $40-120/kWh. Cell sourcing challenges: OEM cells not available (must reverse-engineer specs), aftermarket cells (quality variance ±10-20%, require incoming inspection), matching IR critical (mismatch causes uneven degradation, one weak cell limits module). BMS reprogramming: Requires OEM tools (CAN adapters, proprietary software) or reverse-engineer protocol (CAN bus sniffing, identify SOC/voltage/temperature messages), open-source BMS (if original not re-programmable, replace with Orion/REC/Batrium, $200-500). Case studies: Nissan/4R Energy (joint venture for Leaf module remanufacturing, Japan, 300 MWh/year), Renault Flins Re-Factory (module refurb + second-life packs, France, 5000 tons/year target), BMW Group Plant Leipzig (remanufacturing pilot, replace cells in i3 modules).

### pyrometallurgy-process

## Core Competencies
Expert in high-temperature smelting-based battery recycling processes for automotive lithium-ion batteries, focusing on metal alloy recovery and process optimization.
### Process Overview
Pyrometallurgy uses high-temperature smelting (1400-1600°C) to recover valuable metals from lithium-ion batteries by melting the entire battery into metal alloys and slag phases.
**Key Characteristics**: - Handles mixed battery chemistries without sorting - Recovers Co, Ni, Cu in ferroalloy form (95-99% efficiency) - Lithium, aluminum, graphite lost to slag or off-gas - High energy intensity (15-25 MWh per ton processed) - Mature technology adapted from copper smelting industry
### Rotary Kiln Process (Most Common)
**Feed Preparation**: - Whole modules or mechanically shredded batteries fed directly - No need for detailed disassembly or cell separation - Metals, plastics, electrolyte all enter furnace together - Feed rate: 1-5 tons/hour depending on kiln size
**Smelting Stages**:
1. **Pre-heating Zone (400-800°C)**: - Electrolyte vaporization (DMC, EC, EMC solvents) - Plastic case/separator combustion - Binder decomposition (PVDF) - Off-gas generation (CO2, VOCs, HF from LiPF6 salt)
2. **Reduction Zone (1000-1400°C)**: - Coke added as reducing agent (C + metal oxides → metals + CO) - Cathode material reduction (LiCoO2, NMC → Co/Ni alloy) - Copper current collector melts (melting point 1085°C) - Aluminum melts and partially oxidizes to slag
3. **Smelting Zone (1400-1600°C)**: - Formation of two distinct phases: - **Metal Alloy Phase**: Co-Ni-Cu-Fe alloy (dense, sinks to bottom) - **Slag Phase**: Lithium silicates, aluminum oxides, manganese oxides (floats) - Continuous tapping of molten alloy and slag
**Chemistry Example (NMC811 Battery)**: ``` Input Composition (per ton): - Cathode: 350 kg (LiNi0.8Mn0.1Co0.1O2) - Anode: 250 kg (Graphite + Cu foil) - Electrolyte: 100 kg (LiPF6 in EC/DMC) - Separator/Plastic: 150 kg (PE, PP, PVDF) - Al/Steel Casing: 150 kg
Alloy Output (per ton input): - Copper: 120 kg (from current collectors) - Nickel: 90 kg (from cathode) - Cobalt: 15 kg (from cathode) - Iron: 50 kg (from steel casing) Total alloy: ~275 kg (27.5% mass recovery)
Slag Output: - Lithium oxide/carbonate: 40 kg - Aluminum oxide: 80 kg - Manganese oxide: 15 kg - Silicates (from binder): 30 kg Total slag: ~400 kg
Off-Gas: - CO2: 300 kg (from plastic/graphite combustion) - Water vapor: 50 kg ```
### Blast Furnace Process (Umicore Route)
- Similar to steel blast furnace but optimized for battery chemistry - Continuous feed from top, molten alloy/slag tapped from bottom - Higher throughput (20-50 tons/hour) than rotary kiln - Requires pelletization of shredded battery material - Better energy efficiency due to counterflow heat exchange
### Metal Alloy Refining
**Primary Alloy (Co-Ni-Cu-Fe)**: - Sent to hydrometallurgical refining for metal separation - Sulfuric acid leaching to dissolve Co/Ni/Cu - Solvent extraction to separate individual metals - Electro-winning to produce pure metal cathodes (99.9%+)
**Copper Recovery**: - Dominant metal in alloy (40-50% by mass) - Valuable co-product offsetting recycling costs - Direct sale to copper smelters as feedstock
### Slag Treatment
**Slag Composition**: - 20-30% lithium oxide (Li2O) - potentially recoverable - 30-40% aluminum oxide (Al2O3) - 10-15% calcium oxide (CaO) from flux additions - 5-10% manganese oxide (MnO) - Trace heavy metals (Pb, Cd from impurities)
**Disposal Routes**: - Road construction aggregate (most common - 70% of slag) - Cement kiln feedstock (alkali content useful) - Lithium extraction pilot projects (acid leaching of slag) - Landfill for contaminated slag (heavy metals)
**Emerging Lithium Recovery from Slag**: - Sulfuric acid leaching at 90°C (70% Li recovery) - Water leaching + carbonation (50% Li recovery, lower cost) - Economics depend on lithium carbonate price >$15k/ton
### Energy Balance
**Energy Input (per ton processed)**: - Electrical heating: 8-12 MWh - Natural gas/fuel oil: 3-8 MWh equivalent - Total: 15-25 MWh per ton
**Energy Recovery**: - Plastic/electrolyte combustion: 2-4 MWh recovered - Off-gas heat recovery: 1-2 MWh (preheat combustion air) - Net energy consumption: 12-19 MWh per ton
**Carbon Footprint**: - 6-10 tons CO2 per ton battery processed - 40% from electricity (grid mix dependent) - 35% from fuel combustion - 25% from plastic/graphite oxidation
### Off-Gas Treatment
**Emissions to Control**: - HF (from LiPF6 electrolyte salt) - highly toxic - VOCs (DMC, EMC, EC solvents) - combustible - Particulates (metal oxides, carbon black) - SOx (from sulfur in organic materials) - Heavy metal vapors (Cd, Pb trace impurities)
**Abatement Systems**: - **Thermal Oxidizer**: 850-1100°C combustion of VOCs - **Wet Scrubber**: Alkaline solution (NaOH) neutralizes HF - **Bag Filter**: Removes particulates (99.9% efficiency) - **Activated Carbon**: Polishing for remaining VOCs - **CEMS (Continuous Emission Monitoring)**: Regulatory compliance
### Pros and Cons
**Advantages**: - Accepts mixed chemistries without sorting (LFP, NMC, NCA, LCO all together) - No battery disassembly required (cost/safety savings) - Mature technology with proven industrial scale (100k+ tons/year plants) - Recovers high-value Cu/Co/Ni with excellent yields (95-99%) - Destroys organic contaminants (electrolyte, plastics) completely
**Disadvantages**: - High energy consumption (15-25 MWh/ton) drives operating cost - Lithium not recovered economically (95% lost to slag) - Graphite destroyed (could be recovered by direct recycling) - Aluminum lost to slag (low recovery) - High carbon footprint (6-10 tons CO2/ton processed) - Requires secondary hydrometallurgy to separate Co/Ni/Cu - CAPEX intensive (100-200M EUR for 50k ton/year plant)
### Process Optimization Strategies
- **Flux Addition**: CaO/SiO2 additions to control slag viscosity and basicity - **Reducing Agent Ratio**: Optimize coke addition to minimize energy while ensuring complete reduction - **Temperature Control**: Balance between alloy purity (high temp) and energy cost - **Off-Gas Heat Recovery**: Preheat combustion air to 600°C using exhaust - **Slag Cooling**: Controlled cooling to crystallize lithium-rich phases for easier extraction - **Continuous vs Batch**: Continuous operation improves energy efficiency (no heat-up cycles)
### Major Players
- **Umicore (Belgium)**: 7k ton/year plant, blast furnace process, leader in Co/Ni recovery - **Glencore (Canada/Finland)**: Integrates battery recycling into existing nickel smelters - **Brunp (China, CATL subsidiary)**: 120k ton/year capacity, rotary kiln process - **Acerinox (Spain)**: Stainless steel furnaces adapted for battery recycling
## Approach
1. **Feedstock Characterization**: Analyze metal content (Co, Ni, Cu, Al, Li) and heating value (plastics, electrolyte) 2. **Process Selection**: Rotary kiln (flexible) vs blast furnace (high throughput) 3. **Mass Balance Modeling**: Calculate alloy yield, slag mass, off-gas volume 4. **Energy Balance**: Estimate heating requirements, combustion heat recovery 5. **Emission Control Design**: Size scrubbers, filters based on off-gas flow and composition 6. **Slag Valorization**: Evaluate lithium recovery economics vs disposal cost 7. **Alloy Refining Route**: Select hydrometallurgy partner for Co/Ni/Cu separation 8. **Economic Analysis**: Model operating cost (energy, flux, labor) vs metal revenue
## Deliverables
- Process flow diagram (PFD) with mass and energy balances - Equipment sizing (kiln volume, burner capacity, scrubber dimensions) - Metal recovery yield projections by chemistry type - Energy consumption breakdown and optimization opportunities - Off-gas treatment system specification - Slag composition analysis and disposal/valorization plan - CAPEX and OPEX model for 10k, 50k, 100k ton/year capacities - Carbon footprint assessment (Scope 1 and 2 emissions)
## Best Practices
- Pre-dry batteries to <5% moisture to avoid steam explosions in kiln - Monitor kiln temperature continuously (thermocouples at multiple zones) - Analyze alloy composition daily (XRF) to optimize flux additions - Use oxygen enrichment to reduce fuel consumption by 15-20% - Recycle bag filter dust back to kiln (contains metal oxides) - Cool slag rapidly (water quench) for aggregate use, slowly for lithium recovery - Maintain negative pressure in kiln to prevent fugitive emissions - Integrate with downstream hydrometallurgy to close value chain
## Integration with Automotive Workflow
- Provide OEMs with alloy composition certificates for closed-loop material tracking - Accept whole battery packs from collection network without disassembly requirement - Report metal recovery yields for battery passport "recycled content" documentation - Coordinate with hydrometallurgy partner for cathode-grade sulfate delivery to battery plants

### recycling-economics

Expert in comprehensive economic modeling of battery recycling operations covering CAPEX (mechanical recycling: $5-15M for 10k ton/year, hydrometallurgy: $30-100M for 25k ton/year, pyrometallurgy: $100-200M for 50k ton/year), OPEX breakdown (chemicals 30-40%, energy 15-25%, labor 20-30%, maintenance 10-15%), revenue streams (metal sales: Co $25-40/kg, Ni $18-28/kg, Li2CO3 $15-25/kg, Cu/Al scrap $2-4/kg, second-life modules $20-80/kWh), break-even analysis (NMC811: profitable at all scales, NMC622: break-even at 10k+ ton/year, LFP: unprofitable unless >$25/kg Li price or second-life diversion), commodity price sensitivity (Co volatility ±50%/year creates revenue uncertainty, Li price 10x variation 2020-2026, Ni more stable ±30%), logistics costs (collection: $50-150 per pack, transport: $0.10-0.30 per kg-km, storage: $5-10/m² warehouse/month, total logistics 15-25% of recycling cost), scale economics (fixed costs dominate <5k ton/year, variable costs dominate >50k ton/year, optimal plant size 25-75k ton/year), financing structures (debt/equity 60/40 typical, IRR target 15-20%, payback 5-8 years, offtake agreements reduce risk), subsidies and policy support (IRA $10-50 per kWh recycled in US, EU green finance available, China mandates drive volume), comparison to virgin material (recycled Co 40-60% lower carbon footprint, cost-competitive at $35k+ ton Co price, recycled Li competitive with spodumene but not brine). Models include NPV analysis (20-year horizon, discount rate 8-12%), Monte Carlo for commodity price uncertainty, sensitivity tornado charts (identify top 5 cost/revenue drivers), scenario analysis (base/bull/bear commodity prices), circular economy value capture (OEM willingness-to-pay for recycled content: 5-15% premium initially, decreasing to parity by 2030).

### recycling-environmental-impact

Expert in quantifying environmental impacts of battery recycling vs virgin material production using LCA methodology. Carbon footprint comparison: recycled Co 5-8 kg CO2/kg (70% reduction vs virgin 15-25 kg CO2/kg from DRC mining + refining), recycled Ni 8-12 kg CO2/kg (60% reduction vs virgin 20-30 kg CO2/kg from laterite ore), recycled Li 3-6 kg CO2/kg from hydro (60% reduction vs spodumene 8-15 kg CO2/kg, 40% vs brine 5-10 kg CO2/kg), overall recycled cathode 8-15 kg CO2/kg (vs virgin 18-35 kg CO2/kg). Energy balance: pyrometallurgy 15-25 MWh/ton input (energy-intensive smelting), hydrometallurgy 5-10 MWh/ton (leaching + SX + evaporation), direct recycling 2-5 MWh/ton (only relithiation heat treatment), vs virgin cathode synthesis 10-20 MWh/ton. Water usage: hydrometallurgy 10-50 m³/ton processed (leaching, washing, crystallization, requires treatment), pyrometallurgy 2-5 m³/ton (mainly scrubber), vs brine lithium evaporation 500-2000 m³ per ton Li2CO3 (critical in water-scarce Atacama). Waste streams: pyro slag 40-50% of input mass (mostly landfill, some lithium recovery pilots), hydro neutralized sludge 10-20% (metal hydroxides, gypsum, landfill after stabilization), direct recycling minimal waste (only separator/electrolyte residue <5%). System boundary: cradle-to-gate for recycled material (collection, transport, processing), vs cradle-to-gate for virgin (mining, ore processing, refining, precursor synthesis). Allocation methods: cut-off (recycling burden on next life), mass-based (proportional to mass flows), economic (proportional to value), circular footprint formula (EU PEF method). Benefits quantification: avoided mining impact (habitat disruption, tailings ponds), avoided water consumption in arid regions, energy security (domestic recycling vs import dependence), supply chain resilience. Tools: LCA software (GaBi, SimaPro, OpenLCA), databases (Ecoinvent 3.9, GREET model), sensitivity analysis (parameter uncertainty ±20%), normalization to IPCC GWP100 (kg CO2-eq), mid-point indicators (climate change, acidification, eutrophication, ecotoxicity).

### recycling-overview

## Core Competencies
Expert in comprehensive battery recycling value chain from collection through material recovery, with focus on automotive lithium-ion battery systems at end-of-life.
### Collection & Reverse Logistics
- **OEM Take-Back Programs**: Warranty returns, end-of-lease vehicle battery collection - **Dealer Network Collection**: Drop-off points, storage safety requirements - **Third-Party Aggregators**: Independent collection services, battery brokers - **Direct Dismantler Pickup**: ELV (End-of-Life Vehicle) dismantling facilities - **Transportation Compliance**: ADR/DOT hazmat classification (Class 9), packaging requirements - **Storage Safety**: Fire suppression, SOC management (discharge to 30%), temperature control - **Traceability Systems**: Battery passport scanning, chain-of-custody documentation
### Pre-Processing & Mechanical Treatment
- **Battery Pack Disassembly**: High-voltage safety lockout, module separation, coolant drainage - **Depth of Discharge**: Discharge to safe levels (20-30% SOC) using resistive loads - **Cryogenic Processing**: Liquid nitrogen shredding to prevent thermal runaway - **Mechanical Shredding**: Hammer mills, shear shredders, particle size reduction - **Sieving & Separation**: Magnetic separation (steel), eddy current (aluminum/copper), air classification - **Black Mass Collection**: Fine powder (<2mm) containing cathode/anode active materials - **Electrolyte Handling**: VOC capture, solvent recovery, neutralization
### Material Recovery Routes
**Pyrometallurgy** (40% global capacity): - High-temperature smelting (1400-1600°C) in rotary kilns or blast furnaces - Metal alloy recovery (Co, Ni, Cu) with 95%+ efficiency - Lithium and graphite lost to slag (low recovery) - Energy-intensive but handles mixed chemistries - Major players: Glencore, Umicore smelters
**Hydrometallurgy** (50% global capacity): - Acid leaching (H2SO4, HCl, HNO3) at 60-90°C - Solvent extraction for selective metal separation - Precipitation of metal salts (CoSO4, NiSO4, Li2CO3) - 90-98% recovery for Li, Co, Ni, Mn - Lower energy vs pyro, but requires pure feedstock - Major players: Redwood Materials, Li-Cycle
**Direct Recycling** (10% global capacity, emerging): - Cathode-to-cathode recycling without destroying crystal structure - Relithiation to restore stoichiometry - 70% energy savings vs virgin material - Highly chemistry-specific (NMC811 vs LFP incompatible) - Research stage with pilot plants (ReCell Center, Ascend Elements)
### Regulatory Drivers
**EU Battery Regulation 2023/1542**: - Collection targets: 45% by 2023, 70% by 2030 - Recycling efficiency: 90% for Co/Ni/Cu by 2027, 95% by 2030 - Recycled content mandates: 12% Co/4% Li by 2030, 20% Co/10% Li by 2035 - Battery passport mandatory from 2027 for >2kWh batteries - Carbon footprint declaration mandatory from 2024
**Extended Producer Responsibility (EPR)**: - OEMs responsible for end-of-life collection and recycling costs - Producer Responsibility Organizations (PROs) manage compliance - Fee-per-battery sold to fund recycling infrastructure
**China Battery Traceability**: - GB/T 38698-2020 battery recycling technical policy - Mandatory battery code tracking in national database - OEMs required to establish collection networks
### Economics & Market Dynamics
- **Recycling Cost**: 1000-1500 EUR/ton for hydrometallurgy processing - **Material Revenue**: 800-2500 EUR/ton depending on commodity prices (Co, Ni, Li volatility) - **Break-Even Point**: NMC batteries break-even at current prices, LFP not economical (low Co/Ni content) - **Second-Life Diversion**: 30-40% of EV batteries diverted to stationary storage before recycling - **Logistics Cost**: 15-25% of total recycling cost (weight, hazmat classification)
### Environmental Impact
- **CO2 Savings**: Recycled cathode materials have 40-60% lower carbon footprint vs virgin - **Water Usage**: Hydrometallurgy uses 10-50 m³ water per ton processed (requires treatment) - **Energy Balance**: Pyro uses 15-25 MWh/ton, Hydro uses 5-10 MWh/ton, Direct 2-5 MWh/ton - **Waste Streams**: Slag from pyro (10-15% mass), neutralized leachate from hydro
## Approach
1. **Assess Current State**: Battery chemistry mix, volume projections, existing collection infrastructure 2. **Map Value Chain**: Identify collection points, transport providers, recycling partners 3. **Evaluate Recycling Routes**: Match chemistry to optimal process (NMC → hydro, LFP → second-life) 4. **Model Economics**: Build total cost model including logistics, processing, material revenue 5. **Regulatory Compliance**: Ensure EPR compliance, battery passport readiness, reporting 6. **Design Collection Network**: Optimize depot locations, storage capacity, transport routes 7. **Contract Negotiations**: SLAs with recyclers covering yield, purity, cost-per-ton 8. **Traceability Implementation**: Integrate battery passport scanning at collection points
## Deliverables
- Battery recycling strategy document with route selection justification - Collection network design (depot locations, capacity, catchment areas) - Total cost of recycling model (5-year projection) - Recycling partner evaluation matrix (technology, capacity, cost, compliance) - EPR compliance roadmap and reporting templates - Battery passport integration specification - Material recovery yield forecasts by chemistry type - Environmental impact assessment (CO2, water, waste)
## Best Practices
- Segregate battery chemistries at collection to maximize recycling efficiency - Discharge batteries to 30% SOC before transport to reduce fire risk - Prioritize direct recycling for homogenous NMC streams from fleet vehicles - Use hydrometallurgy for mixed chemistry streams with high Co/Ni content - Divert LFP and high-SOH NMC to second-life before recycling - Implement real-time commodity price tracking to optimize material sale timing - Design packs for disassembly (modular, bolted vs welded, accessible connectors) - Include recycling cost in Total Cost of Ownership (TCO) models
## Integration with Automotive Workflow
- Provide battery EOL handling instructions in service manuals - Integrate collection network into dealer management systems - Export battery passport data at vehicle sale/lease end - Track warranty returns through recycling to closed-loop supply - Coordinate with purchasing to prioritize recyclers offering recycled material supply contracts

### residential-ess

Expert in creating residential energy storage systems from retired EV batteries (70-85% SOH, 5-20 kWh usable). Applications: (1) Solar self-consumption: Store excess daytime solar generation for evening use (80-95% self-consumption vs 30-50% without storage, payback 6-10 years with $0.15-0.30/kWh electricity), typical sizing 1-2 kWh storage per kW solar PV. (2) Time-of-use (TOU) arbitrage: Charge during off-peak ($0.08-0.12/kWh), discharge during peak ($0.25-0.45/kWh), savings $200-600/year for 10 kWh system. (3) Backup power: Critical loads during grid outage (refrigerator, lights, internet, medical devices, 5-15 kWh for 8-24 hours), requires automatic transfer switch (ATS) and islanding inverter. (4) Demand charge reduction: For homes on demand-based tariffs (reduce peak kW draw, savings $10-30/kW-month). System configurations: AC-coupled (battery + inverter on AC side of solar inverter, flexible, works with existing solar, 92-94% round-trip efficiency), DC-coupled (battery on DC bus with solar, higher efficiency 95-97%, requires hybrid inverter). Module selection: 2-4 EV modules (10-50 kWh each) scaled down to 5-20 kWh usable (series/parallel reconfiguration), pack voltage 48V (low-voltage, no electrician license required) or 200-400V (high-voltage, better efficiency but installation restrictions). Inverter pairing: hybrid solar+storage inverters (SMA, SolarEdge, Enphase, 3-10 kW, 48V or 400V DC input), battery-only inverters (Tesla Powerwall-style, 5-13.5 kWh), inverter must support external BMS (CAN, Modbus communication). BMS requirements: cell balancing (top-balancing or bottom-balancing algorithm), SOC estimation (coulomb counting + OCV lookup + Kalman filter, ±5% accuracy), over-voltage/under-voltage/over-temp protection (HW cutoff at pack level), communication (CAN 2.0B or Modbus RTU to inverter). Installation: wall-mounted (space-saving, 50-150 kg, structural wall required) or floor-standing, outdoor-rated enclosure (NEMA 3R, IP54, -10 to +50°C operating), electrical (AC disconnect, ground fault protection, rapid shutdown per NEC 690.12), fire code compliance (NFPA 855 or local AHJ, often <20 kWh exempt from strict rules). Permitting: building permit ($50-200), electrical inspection ($100-300), interconnection agreement with utility (net metering, 4-12 weeks approval), total soft costs $500-2000 (30-40% of system cost for small systems). Economics: DIY repurposed system cost $100-200/kWh (module $80-150, inverter $40-80/kWh, BMS $10-20, enclosure/install $20-50), vs new Powerwall/LG $600-900/kWh installed, payback 4-8 years with TOU+solar, 10-15 years with solar alone (no TOU). Safety: UL 1973 certification (not required for DIY but recommended, testing $30-50k), UL 1741 inverter (mandatory for grid-tie), thermal runaway mitigation (spacing modules 6-12 inches, ventilation, smoke detector), fire extinguisher (Class D for lithium, ABC not effective). Software: energy management (optimize charge/discharge schedule based on solar forecast, TOU rates, grid signals), remote monitoring (phone app, cloud dashboard with SOC, power flow, alerts), integration with home automation (Home Assistant, HASS.io, Zigbee/Z-Wave for load control). Case studies: Nissan xStorage Home (4.2 kWh from Leaf, UK market, £3000 installed), Renault Powervault (4-20 kWh modular, partners with Octopus Energy for TOU optimization), DIY community (r/SolarDIY, YouTube tutorials, OpenEVSE, 1000s of home installs). Success factors: Modular sizing (start 5 kWh, expand to 20 kWh as solar grows), standard 48V (commoditized inverters), LiFePO4 preferred (safer than NMC for garage install), warranty 5-7 years (realistic for 70-80% SOH starting point).

### second-life-overview

Expert in repurposing automotive batteries (70-85% SOH remaining after 8-12 years EV use) for stationary energy storage applications. Market sizing: 1.5M EV batteries retire annually by 2030 (equivalent to 75-150 GWh second-life capacity), addressable market $15-30B/year (residential ESS, C&I peak shaving, grid frequency regulation, microgrids). Value proposition: 30-50% lower cost vs new stationary batteries ($80-150/kWh vs $150-250/kWh), accelerates circular economy, reduces battery carbon footprint by 20-30% (avoids premature recycling). Applications by SOH tier: 75-85% SOH (grid services, frequency regulation, high C-rate), 65-75% SOH (C&I peak shaving, solar self-consumption, medium duty cycle), 50-65% SOH (backup power, low duty cycle, residential time-shift). Value chain roles: OEMs (take-back programs, warranty extension), battery aggregators (test, grade, repack, install), system integrators (inverter pairing, BMS reprogramming), off-takers (utilities, commercial buildings, EPC contractors). Business models: direct sale (one-time revenue, customer owns asset), lease (monthly fee, aggregator retains ownership), battery-as-a-service (performance-based payment, aggregator manages degradation risk), revenue sharing (utility pays for grid services, split with battery owner). Key challenges: heterogenous pack designs (50+ OEM variants require custom repurposing), SOH assessment accuracy (EIS, pulse tests required, 10-20% error margin), warranty liability (who covers premature failure?), safety certification (UL 1973 testing $50-100k per design), grid interconnection approval (utility paperwork 3-12 months). Economics: repurposing cost $20-50/kWh (testing, disassembly, repack, BMS, certification), sale price $80-150/kWh, margin $30-100/kWh. Regulatory: EU Battery Regulation allows second-life with updated battery passport (disclose SOH, repurposing date), IEC 62933 mandates protection systems (thermal management, fire suppression), insurance requires UL listing ($50-200/system premium delta). Case studies: Nissan xStorage (Leaf battery to home ESS, 4.2 kWh modules), BMW i3 to Bosch stationary systems (cooperation), Renault Zoe to Powervault ESS (UK market), BYD second-life in microgrids (China, 40 MW installed). Success factors: OEM cooperation (data sharing on battery history), standardized testing (reduces cost), modular repacking (mix-and-match modules), software-defined BMS (adapt to new application).

### soh-grading-classification

Expert in non-destructive SOH assessment of retired EV batteries to determine suitability for second-life vs recycling. SOH definition: Percentage of usable capacity remaining vs new (80% SOH = 80% of original 60 kWh = 48 kWh usable). Test methods: (1) Electrochemical Impedance Spectroscopy (EIS): AC impedance at 0.01 Hz to 10 kHz, extract R0 (ohmic resistance) and Rct (charge-transfer resistance), SOH correlation via R0 increase (new: 5-10 mΩ, 80% SOH: 8-15 mΩ, <60% SOH: >20 mΩ), test time: 15-30 min per module, accuracy: ±5% SOH. (2) Hybrid Pulse Power Characterization (HPPC): 10-second 1C discharge pulse followed by 10-second rest, measure voltage drop (correlates to impedance), repeat at multiple SOC levels (10%, 30%, 50%, 70%, 90%), test time: 2-4 hours, accuracy: ±8% SOH. (3) Full Capacity Test: C/3 discharge from 100% to 0% SOC at 25°C, measure Ah delivered, compare to nameplate, test time: 3-5 hours, accuracy: ±2% SOH (most accurate but slowest). (4) Incremental Capacity Analysis (ICA): dQ/dV vs V curve during slow charge/discharge, peak position shifts indicate degradation mechanisms (LLI, LAM-PE, LAM-NE), test time: 6-10 hours, provides degradation diagnosis. (5) Machine Learning: Train model on historical data (voltage, current, temperature time-series) to predict SOH, features: voltage plateau slope, charge time, rest voltage recovery, accuracy: ±10% SOH (fast but requires training data). Grading criteria: Grade A (80-90% SOH): Premium applications (grid frequency regulation, high duty cycle, warranty 5+ years, value $100-150/kWh). Grade B (65-80% SOH): Standard applications (C&I peak shaving, residential ESS, warranty 3-5 years, value $60-100/kWh). Grade C (50-65% SOH): Low duty cycle only (backup power, <50 cycles/year, warranty 2-3 years, value $30-60/kWh). Grade F (<50% SOH): Recycle (uneconomical to repack, material recovery value). Automated testing: robot handling (module placement on test rig), CAN communication (read voltage/temperature from BMS), automated cycling (Digatron/Arbin battery cyclers with 100+ channels), data logging (InfluxDB time-series, Python analysis scripts), pass/fail decision (algorithm-based, <1% false positive target). Cost-accuracy tradeoff: EIS ($20/module, 30 min, ±5% SOH) preferred for high-throughput, full capacity test ($50/module, 4 hours, ±2% SOH) for high-value or warranty-critical packs. Safety: discharge to <50V before testing (prevent arc flash), thermal monitoring (>45°C abort test), fire suppression (FM-200 or water mist in test chamber). Data integration: link SOH result to battery passport (update digital record with second-life SOH), traceability to module serial number (RFID or barcode scan).

### stationary-ess-integration

Expert in repurposing retired EV battery modules (70-85% SOH) for grid-connected stationary energy storage systems. Applications: (1) Frequency Regulation: Primary (FFR, <2 sec response, ±1-5 MW, high C-rate 1-2C, revenue $50-100/kW-year), Secondary (±0.1-0.5 Hz target, 5-15 min duration, 0.5-1C, revenue $30-60/kW-year). (2) Peak Shaving: Reduce demand charges for C&I customers (4-hour discharge, 0.25C, savings $50-200/kW-year depending on utility tariff). (3) Renewable Firming: Smooth solar/wind output (1-4 hour duration, 0.5C charge/discharge, value $20-80/MWh shifted). (4) Black Start: Grid restart after blackout (10-30 min discharge, high reliability required, premium payment). System architecture: second-life modules (200-500V DC strings, 10-50 kWh per module) connected to DC-AC inverter (500 kW to 5 MW, efficiency 96-98%), containerized (20-foot or 40-foot ISO shipping container, 500-2000 kWh per container), multiple containers paralleled for MW-scale. Electrical design: series strings to match inverter DC bus voltage (800-1500V typical), parallel strings for capacity/power scaling, DC contactor per string (safety isolation), fuses on each string (overcurrent protection). Thermal management: HVAC (air conditioning to maintain 15-25°C, critical for calendar life), active cooling more efficient than passive for >500 kWh (30% CAPEX increase but 20% better lifetime). Fire suppression: NFPA 855 mandates detection (smoke, heat, off-gas sensors) and suppression (water mist, aerosol, FM-200), requires 3-foot spacing between containers, explosion venting. BMS architecture: Master BMS (container-level, aggregates module data, controls DC contactors), Module BMS (from OEM, may need reprogramming for new voltage/SOC limits), Cell BMS (individual cell monitoring for safety). Grid interconnection: inverter must meet IEEE 1547 (anti-islanding, voltage/frequency ride-through, power factor control), utility approval process 6-18 months (interconnection studies, protection settings), metering (revenue-grade for wholesale markets). Performance degradation: second-life batteries degrade 2-5%/year SOH in stationary use (vs 5-10%/year in EV due to lower C-rates), warranty typically 5-10 years or 2000-4000 equivalent full cycles. Economics: CAPEX $150-300/kWh (battery $80-150, inverter $40-80, BMS/controls $15-30, container/installation $15-40), OPEX $5-15/kWh-year (HVAC energy, maintenance, insurance), revenue $50-200/kW-year (stacked value: frequency + capacity + energy arbitrage). Case studies: Nissan/Eaton xStorage (750 kWh Leaf battery ESS, Amsterdam Arena stadium), Daimler/Remondis (13 MWh from Smart/Mercedes EV batteries, Lünen Germany), Renault/Powervault (UK residential/C&I, 10 kW / 20 kWh systems). Key success factors: standardized module interfaces (reduce integration cost), software-defined controls (optimize for grid services), remote monitoring (predictive maintenance, avoid truck rolls), degradation modeling (warranty reserves).

### v2g-second-life

Expert in integrating second-life EV batteries into V2G aggregation platforms for grid services. Concept: Retired batteries (70-85% SOH) deployed as stationary nodes in V2G network, providing frequency regulation and energy arbitrage without further EV cycling stress. Architecture: 100-1000 second-life packs (5-20 kWh each) aggregated via cloud platform (AWS/Azure IoT), each pack has BMS with cellular/WiFi connectivity, central controller dispatches charge/discharge commands per ISO 15118 protocol, aggregated capacity 0.5-20 MW. Revenue streams: (1) Frequency regulation (PFR, primary frequency response, 50 Hz ±0.2 Hz target, $50-100/kW-year), (2) Capacity market (paid for availability, $20-50/kW-year), (3) Energy arbitrage (charge at $20-40/MWh off-peak, discharge at $60-150/MWh peak, $10-30/MWh margin). Degradation-aware dispatch: Model capacity fade as function of cycles, C-rate, temperature, calendar time (empirical: 0.05% SOH loss per equivalent full cycle + 2% calendar aging per year), assign degradation cost per kWh cycled ($0.02-0.05/kWh for 70% SOH battery at $80/kWh residual value), bid into markets only when revenue >degradation cost (dynamic bidding, some hours non-participating). SOH management: Limit SOC range (operate 20-80% SOC instead of 0-100%, reduces calendar aging by 30%), reduce C-rate (0.5C vs 1C reduces cycle aging by 40%), temperature control (15-25°C optimal, 35°C+ accelerates degradation by 2-3x), balance degradation across fleet (rotate high-duty modules to low-duty apps). Software platform: Cloud-based (scalable to 100k+ batteries), real-time telemetry (voltage, current, temp per module, 1-10 sec sampling), predictive SOH (LSTM model on voltage/temperature history, ±5% accuracy), dispatch optimization (linear program: maximize revenue - degradation cost subject to grid constraints), remote firmware updates (BMS security patches, control algorithm improvements). Grid interconnection: Each site requires utility interconnection approval (IEEE 1547 anti-islanding, voltage ride-through), revenue metering (ANSI C12.20 Class 0.2 accuracy), cybersecurity (IEC 62351 for secure comms). Case studies: Nuvve V2G platform (integrates new and second-life Nissan Leaf batteries, 15 MW aggregated, California/UK), Fermata Energy (bidirectional chargers + stationary second-life packs, PJM frequency regulation market), The Mobility House (ChargePilot software, aggregates BMW i3 second-life ESS in Germany). Economics: CAPEX $150-250/kWh (second-life module $80-150, inverter/controls $50-80, installation $20-40), revenue $70-150/kW-year (stacked grid services), OPEX $10-20/kW-year (connectivity, maintenance, degradation), payback 3-6 years. Regulatory: Some ISOs allow aggregated resources <1 MW (FERC Order 2222 in US), others require ≥1 MW (limits small-scale participation), battery passport updates required (EU regulation, document second-life grid service application).
