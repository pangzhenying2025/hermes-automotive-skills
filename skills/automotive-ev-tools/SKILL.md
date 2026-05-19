---
name: automotive-ev-tools
description: >
  Expert skill in battery pack design for automotive EVs, covering cell selection, module layout, thermal management, and safety analysis. Covers 5 topics across ev-tools domain. Includes 5 skill files covering ASPICE Level 2/3 for software process, ASPICE Level 3, AUTOSAR 4.4, AUTOSAR 4.4 for software architecture, IEC 61851 EV charging systems, IEC 63110 Management of EV charging infrastructure, IPC-2221 PCB design standards, ISO 12405 Lithium-ion battery testing and more.
tags: [automotive, automotive-ev-tools, battery-management, battery-modeling, battery-pack-design, can-bus, cell-balancing, cell-selection, charging-infrastructure, degradation, electrochemical, ev-tools, iso-15118, iso-26262, libresolar, modular-bms, mppt, ocpp, open-hardware, openbms, pybamm, safety-analysis, smart-charging, soc-estimation, stm32, thermal, thermal-management, thingset-protocol, websocket, weight-optimization]
---

# Automotive Ev Tools

5 skill files covering ev-tools domain for automotive software engineering.

## Applicable Standards

- ASPICE Level 2/3 for software process
- ASPICE Level 3
- AUTOSAR 4.4
- AUTOSAR 4.4 for software architecture
- IEC 61851 EV charging systems
- IEC 63110 Management of EV charging infrastructure
- IPC-2221 PCB design standards
- ISO 12405 Lithium-ion battery testing
- ISO 15118 Vehicle-to-Grid communication
- ISO 26262
- ISO 26262 (for automotive variants)
- ISO 26262 ASIL-C/D for BMS safety functions
- ISO 6469-1 Electric safety
- ISO 6469-1 Electric vehicle safety
- OCPP 1.6J (JSON over WebSocket)
- OCPP 2.0.1 (ISO 15118 integration)
- SAE J2464 EV battery abuse testing
- UL 1973 Batteries for stationary applications
- UN ECE R100 Battery safety and crash testing
- UN ECE R100 Battery safety regulations
- USABC Battery Performance Goals
- VDA Battery System Standards

## Use Cases

- EV battery pack architecture design
- Cell selection and benchmarking
- Module and pack mechanical layout
- Thermal management system design
- BMS integration and wiring harness
- Safety analysis (FMEA, FTA, abuse testing)
- Weight and cost optimization
- Modular BMS PCB design and layout
- bq76940/ISL94202 AFE integration
- MPPT solar charging integration
- ThingSet protocol communication
- Load management and DC/DC control
- EV charge point software development
- Central system (CSMS) integration
- Smart charging and load management
- OCPP 1.6J and OCPP 2.0.1 protocol implementation
- Charging session management and billing
- Open-source BMS software architecture
- Cell monitoring and balancing algorithms
- SOC/SOH estimation implementation

## Topics Covered

### Battery Modeling

- pybamm-battery-modeling

### Bms Hardware

- libresolar-modular-bms

### Bms Software

- openbms-integration

### Charging Infrastructure

- ocpp-charging-protocol

### Pack Design

- battery-design-studio

## Constraints

- Backward compatibility with OCPP 1.6J for existing infrastructure
- Billing accuracy requirements (MID-certified meters)
- Certification costs for automotive production use
- Component availability for open-source BOM
- Computational performance for real-time model variants
- Cost target <$100/kWh at pack level
- Crash safety compliance (UN ECE R100, FMVSS 305)
- Firmware memory footprint on STM32L4 (256 KB flash)
- ISO 26262 ASIL-C/D compliance for safety functions
- Measurement accuracy requirements (mV for voltage, 0.1A for current)
- Model complexity vs embedded resource constraints
- Network reliability (cellular coverage, latency, bandwidth)
- PCB manufacturing tolerances for high-voltage creepage
- Package space limitations in vehicle underbody
- Parameter accuracy from limited cell test data

## Required Tools

- ANSYS or Star-CCM+ for CFD/FEA
- Battery cycler for charge/discharge testing
- Battery emulator (Keysight Scienlab, Digatron)
- CATIA or SolidWorks for CAD
- CI/CD for automated model validation
- Certificate management tools
- Git and CI/CD for version control
- Git for version control of parameter sets
- JTAGICE3 or ST-Link for debugging
- Jupyter Notebook for interactive modeling
- KiCad 7.0+ for PCB design
- Lab equipment for cell testing
- MATLAB/Simulink for battery modeling
- MATLAB/Simulink for model export
- OCPP client library (C++, Java, Python)


## Instructions

### battery-design-studio

## Core Competencies

Expert in automotive battery pack design from requirements definition through production validation, including cell selection, module layout, thermal management, safety analysis, and cost optimization.

### Battery Pack Design Process

1. **Requirements Definition**:
- Vehicle application (BEV, PHEV, HEV)
- Energy requirement (kWh) for target range (e.g., 75 kWh for 300 km)
- Power requirement (kW) for acceleration and regen braking
- Voltage architecture (400V vs 800V)
- Package constraints (underbody vs tunnel vs rear floor)
- Lifetime target (8 years, 160,000 km, 70% SOH retention)
- Cost target ($/kWh at pack level)

2. **Cell Selection**:
- **Chemistry**: NMC811 (high energy), NMC622 (balanced), LFP (cost/safety)
- **Form factor**: Cylindrical (18650, 21700, 4680), pouch, prismatic
- **Supplier benchmarking**: LG Chem, CATL, Panasonic, Samsung SDI, BYD
- **Energy density**: 250-300 Wh/kg at cell level
- **Power density**: 3-5 kW/kg for PHEV, 1-2 kW/kg for BEV
- **Cycle life**: 1000-3000 cycles to 80% capacity
- **Cost**: Target <$100/kWh at pack level
- **Thermal characteristics**: Heat capacity, thermal conductivity
- **Safety**: Nail penetration, overcharge, short-circuit, thermal runaway propagation

3. **Module Design**:
- **Topology**: Series-parallel configuration (e.g., 96S2P for 400V, 192S1P for 800V)
- **Mechanical structure**: Module housing, cell retention, compression
- **Electrical connections**: Busbar design, welding vs bolted, current distribution
- **Thermal interface**: Cooling plate, thermal pads, gap fillers
- **Voltage sensing**: Tap points for BMS, wire harness routing
- **Balancing**: Passive vs active balancing accessibility
- **Serviceability**: Module replacement strategy

4. **Pack Integration**:
- **Enclosure**: Aluminum or steel housing, IP67 rating, crash structure
- **Battery management system**: Master BMS board, slave modules, wiring
- **High-voltage distribution**: Main contactors, fuses, HV interlock loop
- **Thermal system**: Coolant manifold, pump, radiator, heater
- **Mounting**: Bolted to vehicle underbody, rubber isolation for vibration
- **Cable harness**: High-voltage power cables, low-voltage CAN/sensors
- **Safety devices**: Venting, thermal fuses, fire barriers

### Thermal Management Design

- **Cooling strategies**:
- **Liquid cooling**: Glycol/water coolant through cold plates (most common for EV)
- **Air cooling**: Fan-driven airflow between cells (used for PHEV, lower cost)
- **Immersion cooling**: Dielectric fluid for ultra-fast charging (emerging)
- **Heat pipes**: Passive thermal spreading for temperature uniformity

- **Thermal simulation**: ANSYS Fluent, Star-CCM+, COMSOL for CFD analysis
- Worst-case scenarios: Fast charging (3C rate), highway driving at 45C ambient
- Objectives: Keep max cell temp <45C, delta T across pack <5C
- Coolant flow rate and pressure drop optimization

- **Heating for cold weather**: PTC heater or heat pump integration
- Warm battery to >0C before charge acceptance
- Cabin heat recovery to battery thermal loop

### Safety Analysis

- **FMEA (Failure Modes and Effects Analysis)**:
- Cell failures: Internal short, thermal runaway, venting
- BMS failures: Sensor faults, contactor weld, firmware bugs
- Thermal failures: Coolant leak, pump failure, blocked flow
- Mechanical failures: Module retention, connector loosening, vibration damage

- **FTA (Fault Tree Analysis)**:
- Top event: Thermal runaway propagation to full pack
- Contributing events: Cell defect + overcharge + cooling failure
- Mitigation: Firewall between modules, early fault detection, contactor trip

- **Abuse testing per SAE J2464**:
- Mechanical: Crush, nail penetration, drop
- Electrical: Overcharge, over-discharge, short-circuit
- Thermal: Oven exposure, thermal shock
- Pass criteria: No fire or explosion

- **Crash safety per UN ECE R100**:
- Frontal, side, rear, pole impact crash simulations
- HV interlock integrity, post-crash isolation verification
- Physical barriers to protect battery from intrusion

### Weight and Cost Optimization

- **Mass breakdown**:
- Cells: 60-70% of pack weight
- Module structure: 10-15%
- Pack enclosure: 10-15%
- BMS and wiring: 5-10%
- Thermal system: 5-10%

- **Cost breakdown** ($/kWh):
- Cells: 70-80% of pack cost
- Module assembly: 5-10%
- Pack integration: 5-10%
- BMS: 5-10%
- Thermal management: 3-5%

- **Optimization strategies**:
- Cell-to-pack (CTP) architecture: Eliminate modules, integrate cells directly
- Structural battery pack: Pack enclosure as load-bearing chassis component
- Standardized modules: Platform sharing across vehicle models
- Lightweighting: Aluminum vs steel, optimized ribbing, topology optimization

## Approach

1. **Concept phase**: Define pack energy/power, voltage, package space
2. **Cell benchmarking**: Test candidate cells for performance, safety, cost
3. **Preliminary design**: CAD layout of modules and pack, thermal simulation
4. **Detailed design**: Drawings for enclosure, busbar, coolant plate, BMS integration
5. **Prototype build**: Assemble alpha pack, install in test vehicle
6. **Validation testing**: Thermal, vibration, crash, abuse, durability
7. **Design refinement**: Iterate based on test results
8. **Production release**: Final drawings, BOM, assembly process, quality plan

## Deliverables

- Battery pack specification (energy, power, voltage, weight, cost, life)
- Cell selection report with benchmarking data
- CAD models (CATIA, SolidWorks) of module and pack
- Thermal simulation results (CFD, transient analysis)
- Electrical schematics (HV distribution, BMS wiring)
- Safety analysis (FMEA, FTA, abuse test reports)
- Bill of Materials (BOM) with cost estimate
- Manufacturing assembly instructions and test plan

## Best Practices

- **Design for manufacturing (DFM)**: Minimize manual assembly, automate welding
- **Design for serviceability (DFS)**: Module replacement without full pack disassembly
- **Design for recycling**: Material separation, labeled plastics, reusable structure
- **Concurrent engineering**: Involve BMS, thermal, safety teams early
- **Digital twin**: Build simulation model in parallel with physical pack
- **Benchmarking**: Teardown competitor packs (Tesla, GM, VW) for best practices

## Integration with Vehicle Development

- **Packaging**: Coordinate with vehicle design for underbody space, ground clearance
- **Electrical**: HV interlock loop, isolation monitoring, DC/DC converter
- **Thermal**: Integrate battery chiller with cabin HVAC system
- **Crash**: Collaborate with safety team on crash structures and intrusion barriers
- **Diagnostics**: CAN communication to instrument cluster for SOC/range display
- **Charging**: DC fast charge thermal constraints, preconditioning strategy

## Tools and Software

- **CAD**: CATIA V5/3DX, SolidWorks for mechanical design
- **CFD**: ANSYS Fluent, Star-CCM+ for thermal simulation
- **FEA**: ANSYS Mechanical, Abaqus for structural and crash analysis
- **Electrical**: AutoCAD Electrical, Zuken E3.series for schematics
- **Battery modeling**: MATLAB/Simulink, PyBaMM for electrochemical simulation
- **Cost modeling**: aPriori, Boothroyd Dewhurst DFM for cost estimation

### libresolar-modular-bms

## Core Competencies

Expert in LibreSolar modular open-source battery management system, covering hardware design, firmware development, and system integration for automotive EV and stationary energy storage.

### LibreSolar BMS Architecture

- **Modular topology**: Stackable boards for 3S to 15S per module, daisy-chained to 400S+
- **AFE chips**: TI bq76940 (5S), bq76930 (10S), bq76920 (15S), Renesas ISL94202
- **STM32 microcontroller**: STM32L452 or STM32G431 for low-power operation
- **Communication**: CAN, UART, I2C for multi-module systems
- **ThingSet protocol**: Standardized data model for battery parameters and control

### Hardware Design Features

- **PCB layout**:
- 4-layer board with dedicated analog ground plane
- Kelvin sensing for accurate cell voltage measurement
- High-current traces (50A+) with thermal reliefs
- Creepage/clearance per IEC 60664 for HV isolation

- **Cell monitoring**:
- Differential voltage measurement (mV accuracy)
- Balancing FETs (100 mA passive balancing per cell)
- Temperature sensing via NTC thermistors (8 channels)
- External current sensor interface (hall effect or shunt)

- **Protection circuits**:
- High-side and low-side MOSFET drivers for main contactors
- Pre-charge resistor circuit for capacitor inrush limiting
- Fuse or circuit breaker coordination
- Reverse polarity protection on all connectors

- **Power supply**:
- Isolated DC/DC converter for microcontroller power
- LDO regulators for AFE chip supply
- Battery voltage range: 12V to 800V pack support

### Firmware Features

- **State machine**: Idle -> Pre-charge -> Normal -> Fault handling
- **SOC estimation**: Coulomb counting with OCV calibration
- **Balancing logic**: Configurable thresholds and algorithms
- **MPPT charging**: Perturb & Observe algorithm for solar input
- **Load management**: DC/DC converter control, inverter enable/disable
- **Data logging**: Circular buffer with CAN/UART export
- **Configuration**: ThingSet commands for runtime parameter adjustment

### ThingSet Protocol

- **Data model**: Hierarchical structure for battery parameters
- `/battery/voltage`, `/battery/current`, `/battery/soc`
- `/cells/voltages`, `/cells/temperatures`
- `/config/limits/voltage_max`, `/config/limits/current_charge_max`

- **Transport layers**: CAN, UART, LoRaWAN for remote monitoring
- **Request/Response**: JSON-style commands for diagnostics
- **Pub/Sub**: Periodic broadcast of telemetry data

### MPPT Solar Charging

- **Algorithm**: Perturb & Observe with adaptive step size
- **Input voltage range**: 12V to 150V solar panel input
- **Efficiency**: >95% at rated power
- **CC-CV transition**: Constant current to constant voltage charging
- **Temperature compensation**: Adjust charge voltage by -3 mV/C/cell

### Load Management

- **DC/DC converters**: Buck/boost control for 12V/24V/48V loads
- **Inverter interface**: Enable signal based on SOC and load demand
- **Priority load shedding**: Disconnect non-critical loads at low SOC
- **Power limiting**: Reduce output power when battery temperature high

## Approach

1. **Hardware Selection**: Choose AFE chip based on cell count (bq76940 for 12S, ISL94202 for 15S)
2. **PCB Design**: Layout in KiCad with LibreSolar reference design as baseline
3. **BOM Sourcing**: Select automotive-grade components (AEC-Q100 for ICs, -40 to 125C rating)
4. **Firmware Porting**: Clone LibreSolar firmware repo, configure for hardware variant
5. **Calibration**: Measure voltage/current sensor gains and offsets
6. **Integration**: Connect to solar MPPT, DC/DC converter, CAN bus
7. **Validation**: Run charge/discharge cycles, verify protection triggers
8. **Enclosure Design**: IP65-rated housing for automotive/outdoor use

## Deliverables

- KiCad PCB design files (.kicad_pcb, .kicad_sch) with Gerbers
- Bill of Materials (BOM) with Mouser/Digikey part numbers
- Firmware source code (C/C++ for STM32) with build instructions
- ThingSet configuration files (.yaml) for data model
- Assembly instructions and test procedures
- Enclosure CAD files (.step) with mounting brackets
- Validation test report (charge/discharge, protection, temperature)

## Best Practices

- **Open-source licensing**: Hardware under CERN-OHL-P, firmware under Apache 2.0
- **Community engagement**: Contribute improvements back to LibreSolar GitHub
- **Modular design**: Keep modules under 15S for safety and repairability
- **Thermal management**: Heatsink for balancing FETs, airflow for high-current paths
- **EMC compliance**: Shielded CAN cables, ferrite beads, proper grounding
- **Safety testing**: Fault injection (over-voltage, over-current, short-circuit)
- **Documentation**: Schematic annotations, silkscreen labels, wiring diagrams

## Integration with Automotive EV Systems

- **CAN bus**: Broadcast SOC/SOH to VCU using J1939 or custom DBC
- **Charger interface**: Pilot signal (J1772, CCS) for AC/DC charging
- **Motor inverter**: Current limit and enable signal
- **Thermal system**: Request coolant pump when cell temp > 40C
- **Diagnostics**: UDS protocol access via CAN for service tools

## LibreSolar Ecosystem

- **LibreSolar Charge Controller**: MPPT solar charger with ThingSet
- **LibreSolar Data Manager**: Cloud-based monitoring dashboard
- **LibreSolar DC Nanogrid**: 48V DC distribution for off-grid systems
- **Community forums**: Active support on GitHub discussions and Discord

## Safety Considerations

- **Isolation monitoring**: Detect pack-to-chassis faults
- **Fusing strategy**: Per-module fuses for parallel strings
- **Thermal runaway detection**: dT/dt monitoring with alarm
- **Fail-safe shutdown**: Open contactors on firmware watchdog timeout
- **Field serviceability**: Modular replacement without full pack disassembly

### ocpp-charging-protocol

## Core Competencies

Expert in Open Charge Point Protocol (OCPP) implementation for electric vehicle charging infrastructure, covering charge point firmware, central system integration, and smart charging orchestration.

### OCPP Protocol Versions

- **OCPP 1.6J** (most widely deployed):
- JSON messages over WebSocket (secure wss:// or plain ws://)
- Core profile: Boot, heartbeat, authorize, start/stop transaction, meter values
- Smart charging profile: Charging profiles, composite schedules
- Reservation profile: Reserve charging connector
- Firmware management profile: Remote firmware updates

- **OCPP 2.0.1** (emerging standard):
- Enhanced security with ISO 15118 Plug & Charge
- Device model for advanced configuration
- Improved smart charging with detailed power schedules
- Display messages for driver interaction
- Tariff and cost information
- Data transfer extensions

### Charge Point Architecture

- **Hardware components**:
- Charging controller (STM32, NXP S32, Raspberry Pi)
- Power electronics (AC EVSE or DC fast charger)
- Energy meter (MID-certified for billing)
- RFID reader for user authentication
- Display and HMI (status LEDs, LCD/touchscreen)
- Connectivity (Ethernet, 4G LTE, WiFi)

- **Software stack**:
- OCPP client library (C++, Java, Python)
- WebSocket client with TLS/SSL
- Local authorization cache (RFID whitelist)
- Transaction logging and persistence
- Real-time clock and time synchronization (NTP)
- Watchdog and fault recovery

### OCPP Message Flow

- **Initialization**:
1. BootNotification: Charge point registers with CSMS
2. CSMS responds with Accepted/Pending/Rejected + heartbeat interval
3. GetConfiguration: CSMS retrieves charge point settings
4. ChangeConfiguration: CSMS sets parameters (e.g., MeterValueSampleInterval)

- **Authentication**:
1. Authorize: Send RFID tag ID to CSMS
2. CSMS checks user account status, responds with Accepted/Blocked/Invalid
3. Local authorization: If offline, check cached ID list

- **Charging session**:
1. StartTransaction: Report connector ID, RFID tag, meter start value, timestamp
2. CSMS responds with transaction ID
3. MeterValues: Periodic energy/power measurements during charging
4. StopTransaction: Report meter stop value, stop reason, transaction data
5. CSMS responds with acknowledgment

- **Smart charging**:
1. SetChargingProfile: CSMS sends power limit schedule (kW vs time)
2. Charge point applies composite schedule from all active profiles
3. GetCompositeSchedule: Query effective charging limit
4. ClearChargingProfile: Remove expired or superseded profiles

- **Firmware management**:
1. UpdateFirmware: CSMS provides firmware URL and install time
2. Charge point downloads firmware, verifies checksum
3. FirmwareStatusNotification: Downloaded -> Installing -> Installed
4. Reboot and resume operation

### Central System (CSMS) Integration

- **Backend architecture**:
- WebSocket server farm (Node.js, Spring Boot, Go)
- Database: PostgreSQL for transactions, MongoDB for device state
- Message queue: RabbitMQ or Kafka for async processing
- Load balancer: NGINX or AWS ALB for charge point connections
- Cache: Redis for session state and authorization lists

- **Business logic**:
- User management: Accounts, RFID cards, payment methods
- Tariff engine: Time-of-use pricing, demand charges, subscription plans
- Load management: Distribute available power across charge points
- Reporting: Energy delivered, utilization, revenue analytics
- Notifications: SMS/email for session start/stop, faults

- **Third-party integrations**:
- Payment gateways: Stripe, PayPal, credit card processing
- Roaming networks: Hubject, Gireve for cross-operator access
- Fleet management: API for fleet operator dashboards
- Grid operators: Demand response signals, grid services

### Smart Charging Implementation

- **Use cases**:
- **Peak shaving**: Limit charging power during high electricity demand periods
- **Solar integration**: Maximize charging when PV generation is high
- **Load balancing**: Share building power capacity across charge points
- **TOU optimization**: Charge when electricity is cheapest
- **V2G (Vehicle-to-Grid)**: Discharge EV battery to grid (OCPP 2.0.1 + ISO 15118)

- **Charging profile types**:
- **ChargePointMaxProfile**: Absolute limit on charge point power
- **TxDefaultProfile**: Default profile for new transactions
- **TxProfile**: Per-transaction specific schedule

- **Example**: Limit charge point to 11 kW between 6 PM and 10 PM
```json
{
"chargingProfileId": 1,
"stackLevel": 0,
"chargingProfilePurpose": "ChargePointMaxProfile",
"chargingProfileKind": "Recurring",
"recurrencyKind": "Daily",
"chargingSchedule": {
"startSchedule": "2026-03-19T18:00:00Z",
"duration": 14400,
"chargingRateUnit": "W",
"chargingSchedulePeriod": [
{"startPeriod": 0, "limit": 11000}
]
}
}
```

### Security Considerations

- **Transport security**:
- Use wss:// (WebSocket Secure) with TLS 1.2+
- Certificate-based authentication for charge points
- Firewall rules to restrict CSMS access

- **Authentication**:
- RFID local authorization list with expiry dates
- Central authorization with offline fallback
- ISO 15118 Plug & Charge with certificate provisioning (OCPP 2.0.1)

- **Data integrity**:
- MID-certified energy meters for legal billing
- Signed meter values (OCPP 2.0.1) to prevent tampering
- Transaction logs with cryptographic hash

- **Firmware security**:
- Signed firmware images with public key verification
- Secure boot to prevent malicious code execution

## Approach

1. **Requirements**: Define charge point type (AC/DC), power rating, connectivity
2. **OCPP version selection**: Choose 1.6J for compatibility or 2.0.1 for advanced features
3. **Client implementation**: Integrate OCPP library (e.g., Steve, Open Charge Point Protocol C++ library)
4. **CSMS setup**: Deploy backend (SteVe open-source CSMS, or commercial solution)
5. **Configuration**: Set charge point parameters (heartbeat, meter sampling, timezone)
6. **Testing**: OCPP compliance testing with protocol analyzer
7. **Deployment**: Field installation, cellular/Ethernet connectivity, cloud registration
8. **Monitoring**: Dashboard for charge point status, sessions, revenue

## Deliverables

- OCPP client firmware for charge point (C/C++/Python)
- WebSocket client configuration (URL, credentials, TLS certificates)
- CSMS integration API documentation
- Smart charging profile definitions (JSON)
- Test reports (OCPP compliance, connectivity, performance)
- User manual for charge point operation and troubleshooting
- Backend dashboard for fleet management

## Best Practices

- **Offline resilience**: Cache authorization list, queue transactions, sync when online
- **Idempotency**: Handle duplicate messages (retransmission after network failure)
- **Clock synchronization**: Use NTP or CSMS time sync for accurate timestamps
- **Logging**: Persistent storage of OCPP messages for debugging and audit
- **Error handling**: Retry with exponential backoff, graceful degradation
- **Over-the-air updates**: Remote firmware update without site visit
- **Monitoring**: Heartbeat monitoring, alert on offline charge points

## Integration with EV and Grid

- **ISO 15118**: Plug & Charge, encrypted communication, bidirectional power flow
- **IEC 61851**: Control pilot signal (PWM duty cycle for current limit)
- **OpenADR**: Demand response integration for grid services
- **Modbus/DNP3**: Integration with building energy management systems
- **OCPI**: Roaming protocol for cross-network charging access

## OCPP Ecosystem

- **Open-source CSMS**: SteVe, OCPP Central System
- **Commercial CSMS**: ChargeLab, Driivz, Greenlots, EVBox Everon
- **Testing tools**: OCPP compliance tester, Wireshark WebSocket analyzer
- **Standards bodies**: Open Charge Alliance (OCA), CharIN for ISO 15118

### openbms-integration

## Core Competencies

Expert in OpenBMS open-source battery management system architecture, algorithms, and integration for automotive lithium-ion battery packs.

### OpenBMS Architecture

- **Hardware abstraction layer**: Support for multiple AFE (Analog Front-End) chips
- TI BQ76xxx series, NXP MC33xxx, Maxim MAX17xxx, Renesas ISL94xxx
- SPI/I2C communication drivers with error handling
- Configurable cell count (12S to 400S+ for EV packs)

- **Cell monitoring subsystem**:
- Voltage measurement with mV accuracy
- Current sensing (pack current via hall sensor/shunt)
- Temperature monitoring (NTC thermistors per module)
- Isolation resistance monitoring (IMD integration)

- **Balancing control**:
- Passive balancing (dissipative resistor-based)
- Active balancing (capacitor/inductor energy transfer)
- Balancing strategy: top-balancing vs bottom-balancing
- Energy efficiency tracking and optimization

- **State estimation algorithms**:
- **SOC (State of Charge)**: Coulomb counting + OCV lookup + Kalman filter
- **SOH (State of Health)**: Capacity estimation from aging models
- **SOP (State of Power)**: Current limit calculation based on voltage/temp
- **SOE (State of Energy)**: Available energy for range prediction

- **Safety monitoring**:
- Over-voltage/under-voltage protection per cell
- Over-current/over-temperature shutdown
- Short-circuit detection and response
- Thermal runaway early warning (dT/dt monitoring)
- Insulation fault detection (positive/negative to chassis)

- **CAN communication**:
- Standard 500 kbps automotive CAN bus
- J1939 or custom protocol for BMS broadcast messages
- Transmit: SOC, SOH, voltage, current, temperature, faults
- Receive: Charge/discharge enable, power limits from VCU

### OpenBMS Configuration

- **Cell chemistry profiles**: NMC, NCA, LFP voltage curves and limits
- **Pack topology**: Series/parallel configuration (e.g., 96S2P for 350V pack)
- **Thermal limits**: Charge (0-45C), discharge (-20-60C), storage temp
- **Current limits**: Continuous/peak charge/discharge by temperature zone
- **Balancing thresholds**: Start balancing at X mV delta, stop at Y mV
- **SOC calibration**: OCV relaxation time, coulombic efficiency correction

## Approach

1. **Hardware Selection**: Choose AFE chip and microcontroller (STM32, NXP S32K, Infineon Aurix)
2. **OpenBMS Port**: Adapt HAL drivers for selected hardware platform
3. **Configuration**: Define pack parameters (cell count, chemistry, limits) in YAML/JSON config
4. **Algorithm Tuning**: Calibrate SOC lookup table from cell OCV tests, tune Kalman filter Q/R matrices
5. **CAN Database**: Create DBC file for BMS messages (voltage, current, SOC, faults)
6. **Safety Validation**: FMEA analysis, fault injection testing, protective function verification
7. **Integration Testing**: Connect to motor controller and charger via CAN, verify charge/discharge cycles
8. **Certification Support**: Generate ISO 26262 safety case artifacts

## Deliverables

- OpenBMS firmware build for target hardware (STM32 .elf, S32K .srec)
- Configuration files (pack topology, chemistry, limits)
- CAN database (.dbc) with BMS message definitions
- Calibration data (SOC-OCV lookup, balancing thresholds)
- Test reports (cell monitoring accuracy, balancing efficiency, safety response time)
- Safety documentation (FMEA, FTA, safety concept)
- User manual and commissioning guide

## Best Practices

- **Modular design**: Separate AFE drivers, algorithms, and communication layers
- **Unit testing**: Test SOC algorithm with synthetic current profiles
- **HIL validation**: Use battery emulator (Keysight Scienlab, Digatron) for system test
- **Fault injection**: Simulate cell failures, sensor faults, CAN bus errors
- **Code review**: Follow MISRA-C 2012 for automotive safety
- **Version control**: Git-based workflow with CI/CD for firmware builds
- **Calibration database**: Track parameter changes per pack variant

## Integration with Vehicle Systems

- **VCU (Vehicle Control Unit)**: Power request arbitration, drive mode selection
- **Charger**: CC-CV profile control, charge termination logic
- **Motor inverter**: Torque limit based on BMS power capability
- **Thermal management**: Request active cooling/heating when needed
- **Diagnostics**: UDS protocol for fault code readout and parameter access

## Safety Considerations

- **Redundant measurements**: Dual voltage sensing for ASIL-D compliance
- **Watchdog timer**: Independent monitoring of BMS microcontroller
- **Fail-safe defaults**: Contactors open on BMS fault
- **Fault logging**: Persistent storage of fault history with timestamps
- **Field updates**: Secure bootloader for over-the-air firmware updates

### pybamm-battery-modeling

## Core Competencies

Expert in physics-based battery modeling using PyBaMM (Python Battery Mathematical Modeling) framework for automotive lithium-ion battery systems.

### PyBaMM Model Types

- **SPM (Single Particle Model)**: Fast simplified model for real-time estimation
- **SPMe (SPM with electrolyte)**: Adds electrolyte dynamics for better accuracy
- **DFN (Doyle-Fuller-Newman)**: Full pseudo-2D electrochemical model
- **Newman-Tobias**: Thermal effects coupling with electrochemical behavior
- **Equivalent Circuit Models**: Empirical models for parameter identification

### Parameter Sets

- **Cell chemistry**: NMC811, NMC622, LFP, NCA parameter databases
- **Geometric parameters**: Electrode thickness, porosity, particle radius
- **Transport properties**: Diffusivity, conductivity, transference number
- **Kinetic parameters**: Exchange current density, activation energies
- **Thermal parameters**: Heat capacity, thermal conductivity, convection

### Degradation Modeling

- **SEI (Solid Electrolyte Interphase) growth**: Capacity fade mechanisms
- **Lithium plating**: Fast charge safety limits
- **Particle cracking**: Mechanical degradation from cycling
- **Loss of lithium inventory (LLI)**: Irreversible capacity loss
- **Loss of active material (LAM)**: Electrode degradation
- **Electrolyte decomposition**: Impedance rise modeling

### Thermal Coupling

- **Heat generation sources**: Joule heating, entropic heat, reaction heat
- **1D/2D/3D thermal models**: Lumped vs distributed temperature
- **Cooling system integration**: Liquid cooling, air cooling, heat pipes
- **Thermal runaway prediction**: Abuse condition simulation
- **Temperature-dependent parameters**: Arrhenius relationships

## Approach

1. **Model Selection**: Choose appropriate model complexity (SPM for real-time, DFN for design)
2. **Parameterization**: Extract/calibrate parameters from cell datasheets or lab tests
3. **Experiment Protocol Definition**: Drive cycles (WLTC, US06), charging profiles (CC-CV, fast charge)
4. **Simulation Execution**: Run PyBaMM solver with adaptive time-stepping
5. **Validation**: Compare simulation vs lab data (voltage, current, temperature, SOC)
6. **Sensitivity Analysis**: Identify critical parameters affecting performance
7. **Degradation Forecast**: Predict capacity fade and power fade over lifetime
8. **Model Export**: Generate C-code or Simulink blocks for HIL/SIL integration

## Deliverables

- PyBaMM model scripts (.py) with documented parameter sets
- Simulation results (voltage curves, temperature profiles, SOC trajectories)
- Parameter sensitivity analysis reports
- Degradation prediction curves (capacity vs cycles/time)
- Exported models for real-time execution (FMU, C-code, Simulink)
- Validation reports comparing simulation vs experimental data
- Thermal management recommendations

## Best Practices

- Use version-controlled parameter sets aligned with cell supplier data
- Validate models at multiple C-rates and temperatures before deployment
- Document all assumptions (1D vs 3D thermal, SEI model choice)
- Run convergence studies on mesh refinement for DFN models
- Compare multiple degradation mechanisms (SEI + plating + cracking)
- Include uncertainty quantification for parameter estimation

## Integration with Automotive Workflow

- Export models to MATLAB/Simulink for AUTOSAR integration
- Generate lookup tables for embedded BMS SOC/SOH estimation
- Interface with Vector CANoe for virtual ECU testing
- Provide calibration data for production BMS algorithms
- Support HIL rig configuration with battery emulator models
