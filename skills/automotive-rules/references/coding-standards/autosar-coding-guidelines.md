# AUTOSAR Coding Guidelines

AUTOSAR (AUTomotive Open System ARchitecture) defines standardized software architecture for automotive ECUs. This guide covers coding conventions for both AUTOSAR Classic Platform and Adaptive Platform.

## Platform Overview

| Aspect | Classic Platform | Adaptive Platform |
|--------|-----------------|-------------------|
| Use Case | Real-time control ECUs | High-performance computing ECUs |
| Language | C (MISRA C:2012) | C++ (MISRA C++:2023, C++14) |
| OS | OSEK/VDX, AUTOSAR OS | POSIX-based (Linux, QNX) |
| Communication | CAN, LIN, FlexRay | Ethernet (SOME/IP, DDS) |
| Safety | ASIL B/C/D | ASIL A/B with partitioning |
| Examples | Engine control, brake control | ADAS, automated driving, gateway |

## AUTOSAR Classic Platform

### Naming Conventions

#### Module Names

```c
// Module prefix follows AUTOSAR naming scheme
// Format: <Module>_<API>

// Basic Software (BSW) module examples:
void Can_Init(const Can_ConfigType* Config);
Std_ReturnType CanIf_Transmit(PduIdType TxPduId, const PduInfoType* PduInfoPtr);
void Com_RxIndication(PduIdType RxPduId, const PduInfoType* PduInfoPtr);
void Dem_ReportErrorStatus(Dem_EventIdType EventId, Dem_EventStatusType EventStatus);

// Naming pattern:
// - Module name: PascalCase (Can, CanIf, Com, Dem)
// - Function name: <Module>_<FunctionName> (e.g., Can_Init)
// - Types: <Module>_<TypeName>Type (e.g., Can_ConfigType)
```

#### Software Component (SWC) Naming

```c
// Runnable entity naming
// Format: <ComponentName>_<RunnableName>

// Example: Engine management SWC
void EngMgmt_10msTask(void);
void EngMgmt_IgnitionControlRunnable(void);
void EngMgmt_FuelInjectionRunnable(void);

// Port naming in ARXML and generated code
// Sender-Receiver Port: SR_<PortName>
// Client-Server Port: CS_<PortName>
Std_ReturnType Rte_Read_EngMgmt_SR_EngineSpeed_Value(uint16* data);
Std_ReturnType Rte_Call_EngMgmt_CS_Diagnostics_ReadData(uint8* buffer);
```

#### Configuration Parameters

```c
// Configuration parameter naming
// Format: <Module><ShortName>Config_<ParameterName>

#define CanConfig_CanControllerBaudRate  500  // kbps
#define CanConfig_CanControllerTxBufferCount  32
#define ComConfig_ComIPduCalloutFuncPtrArraySize  10

// Pre-compile configuration
extern const Can_ConfigType CanConfigSet_0;

// Post-build configuration
extern const Com_ConfigType* Com_Config;
```

### File Organization

```
ECU_Project/
├── Appl/                          # Application layer
│   ├── SwComponents/
│   │   ├── EngMgmt/
│   │   │   ├── EngMgmt.c
│   │   │   ├── EngMgmt.h
│   │   │   └── EngMgmt_Cfg.h     # SWC-specific config
│   │   └── BrakeMgmt/
│   └── Main/
│       └── EcuM_Main.c
├── Bsw/                           # Basic Software
│   ├── Can/
│   │   ├── Can.c
│   │   ├── Can.h
│   │   └── Can_Cfg.h
│   ├── CanIf/
│   ├── Com/
│   └── Rte/                       # Runtime Environment (generated)
│       ├── Rte.c
│       ├── Rte.h
│       ├── Rte_EngMgmt.h         # Component-specific RTE header
│       └── Rte_Type.h
├── Config/                        # Configuration files
│   ├── Ecu.arxml                 # System description
│   ├── Can.arxml
│   └── Com.arxml
└── Generated/                     # Tool-generated code
    └── Rte/
```

### API Patterns

#### Initialization Pattern

```c
// Standard AUTOSAR initialization sequence
void EcuM_Init(void) {
    // 1. Initialize MCU driver
    Mcu_Init(&McuConfigSet_0);
    Mcu_InitClock(MCU_CLOCK_SETTING_0);
    while (Mcu_GetPllStatus() != MCU_PLL_LOCKED) {
        // Wait for PLL lock
    }
    Mcu_DistributePllClock();

    // 2. Initialize OS (non-returning call)
    StartOS(OSDEFAULTAPPMODE);
}

// Module initialization (typical pattern)
void Can_Init(const Can_ConfigType* Config) {
    // Parameter validation
    #if (CAN_DEV_ERROR_DETECT == STD_ON)
    if (Config == NULL_PTR) {
        Det_ReportError(CAN_MODULE_ID, CAN_INSTANCE_ID, CAN_INIT_SID, CAN_E_PARAM_POINTER);
        return;
    }
    #endif

    // Save configuration pointer
    Can_ConfigPtr = Config;

    // Initialize module state
    Can_ModuleState = CAN_READY;

    // Initialize hardware
    for (uint8 controller = 0; controller < CAN_CONTROLLER_COUNT; controller++) {
        Can_InitController(controller, &Config->CanController[controller]);
    }
}
```

#### Error Handling Pattern

```c
// AUTOSAR return type: Std_ReturnType
typedef uint8 Std_ReturnType;
#define E_OK     ((Std_ReturnType)0x00)
#define E_NOT_OK ((Std_ReturnType)0x01)

// Standard error reporting via DET (Development Error Tracer)
#include "Det.h"

Std_ReturnType CanIf_Transmit(PduIdType TxPduId, const PduInfoType* PduInfoPtr) {
    // Development error detection
    #if (CANIF_DEV_ERROR_DETECT == STD_ON)
    if (CanIf_ModuleState != CANIF_INITIALIZED) {
        Det_ReportError(CANIF_MODULE_ID, CANIF_INSTANCE_ID,
                       CANIF_TRANSMIT_SID, CANIF_E_UNINIT);
        return E_NOT_OK;
    }

    if (TxPduId >= CANIF_NUMBER_OF_TX_PDUS) {
        Det_ReportError(CANIF_MODULE_ID, CANIF_INSTANCE_ID,
                       CANIF_TRANSMIT_SID, CANIF_E_INVALID_TXPDUID);
        return E_NOT_OK;
    }

    if (PduInfoPtr == NULL_PTR) {
        Det_ReportError(CANIF_MODULE_ID, CANIF_INSTANCE_ID,
                       CANIF_TRANSMIT_SID, CANIF_E_PARAM_POINTER);
        return E_NOT_OK;
    }
    #endif

    // Actual transmission logic
    return CanIf_TransmitInternal(TxPduId, PduInfoPtr);
}
```

### RTE Callback Naming

```c
// Server runnable entity (implements operation)
// Pattern: <ComponentName>_<PortName>_<OperationName>

Std_ReturnType DiagMgr_DiagnosticPort_ReadDataByIdentifier(
    uint16 DataId,
    uint8* DataBuffer,
    uint8* DataLength
) {
    // Implementation
    return E_OK;
}

// Mode switch notification
// Pattern: <ComponentName>_OnModeSwitch_<ModeDeclarationGroup>

void EngMgmt_OnModeSwitch_VehicleMode(
    Rte_ModeType_VehicleMode previousMode,
    Rte_ModeType_VehicleMode currentMode
) {
    if (currentMode == RTE_MODE_VehicleMode_RUNNING) {
        // Start engine control
        EngMgmt_StartControl();
    }
}

// Data received callback (SR port)
// Pattern: Rte_Runnable_<ComponentName>_<RunnableName>

void Rte_Runnable_EngMgmt_OnSpeedUpdate(void) {
    uint16 speed;
    if (Rte_Read_EngMgmt_SR_VehicleSpeed_Value(&speed) == RTE_E_OK) {
        EngMgmt_ProcessSpeed(speed);
    }
}
```

### Port Interface Naming (ARXML)

```xml
<!-- Sender-Receiver Interface -->
<SENDER-RECEIVER-INTERFACE>
  <SHORT-NAME>SR_VehicleSpeed</SHORT-NAME>
  <DATA-ELEMENTS>
    <VARIABLE-DATA-PROTOTYPE>
      <SHORT-NAME>Value</SHORT-NAME>
      <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/uint16</TYPE-TREF>
    </VARIABLE-DATA-PROTOTYPE>
  </DATA-ELEMENTS>
</SENDER-RECEIVER-INTERFACE>

<!-- Client-Server Interface -->
<CLIENT-SERVER-INTERFACE>
  <SHORT-NAME>CS_DiagnosticService</SHORT-NAME>
  <OPERATIONS>
    <CLIENT-SERVER-OPERATION>
      <SHORT-NAME>ReadDataByIdentifier</SHORT-NAME>
      <ARGUMENTS>
        <ARGUMENT-DATA-PROTOTYPE>
          <SHORT-NAME>DataId</SHORT-NAME>
          <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/uint16</TYPE-TREF>
          <DIRECTION>IN</DIRECTION>
        </ARGUMENT-DATA-PROTOTYPE>
        <ARGUMENT-DATA-PROTOTYPE>
          <SHORT-NAME>Data</SHORT-NAME>
          <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/uint8_array</TYPE-TREF>
          <DIRECTION>OUT</DIRECTION>
        </ARGUMENT-DATA-PROTOTYPE>
      </ARGUMENTS>
    </CLIENT-SERVER-OPERATION>
  </OPERATIONS>
</CLIENT-SERVER-INTERFACE>
```

## AUTOSAR Adaptive Platform

### Namespace Conventions

```cpp
// AUTOSAR ara (Adaptive Runtime Architecture) namespace structure
namespace ara {
    namespace com {   // Communication Management
        class ServiceProxy;
        class ServiceSkeleton;
    }

    namespace exec {  // Execution Management
        class ExecutionClient;
    }

    namespace log {   // Logging
        class Logger;
    }

    namespace core {  // Core types and error handling
        class Result;
        class ErrorCode;
    }

    namespace diag {  // Diagnostics
        class DiagnosticClient;
    }
}

// Application-specific namespace
namespace oem {
    namespace adas {
        class CameraFusion;
        class ObjectDetection;
    }
}
```

### Service Interface Naming

```cpp
// Service interface definition (generated from .arxml)
namespace ara::com::example {

// Service Interface: Radar Detection Service
class RadarDetectionServiceInterface {
public:
    // Event naming: <EventName>Event
    ara::com::Event<DetectedObjectList> DetectedObjectsEvent;

    // Field naming: <FieldName>Field
    ara::com::Field<SensorStatus> SensorStatusField;

    // Method naming: <MethodName>
    ara::core::Result<void> CalibrateRadar(CalibrationParams params);

    virtual ~RadarDetectionServiceInterface() = default;
};

// Service Proxy (client side)
class RadarDetectionServiceProxy : public RadarDetectionServiceInterface {
public:
    // Factory method naming
    static ara::core::Result<RadarDetectionServiceProxy> FindService(
        ara::com::InstanceIdentifier instance
    );

    // Event subscription
    void SubscribeDetectedObjectsEvent(
        std::function<void(const DetectedObjectList&)> callback,
        size_t maxSampleCount = 1
    );
};

// Service Skeleton (server side)
class RadarDetectionServiceSkeleton : public RadarDetectionServiceInterface {
public:
    // Constructor with instance identifier
    explicit RadarDetectionServiceSkeleton(
        ara::com::InstanceIdentifier instance,
        ara::com::MethodCallProcessingMode mode = ara::com::MethodCallProcessingMode::kEvent
    );

    // Offer service
    void OfferService();

    // Event update
    void UpdateDetectedObjects(const DetectedObjectList& objects);
};

} // namespace ara::com::example
```

### Execution Management Naming

```cpp
// Process naming in manifest
// Format: /oem/<domain>/<process_name>

namespace oem::adas {

class CameraFusionProcess {
public:
    // State reporting
    void ReportExecutionState(ara::exec::ExecutionState state);

    // Deterministic client pattern
    ara::core::Result<void> SetExecutionState(
        ara::exec::ExecutionState state
    );

private:
    ara::exec::ExecutionClient exec_client_;
    ara::log::Logger logger_;
};

// Process entry point
int main(int argc, char* argv[]) {
    // Initialize Adaptive AUTOSAR runtime
    ara::core::Initialize();

    // Create logger with application ID
    ara::log::Logger logger = ara::log::CreateLogger(
        "CFUS",  // 4-character application ID
        "Camera Fusion Process"
    );

    logger.LogInfo() << "Starting Camera Fusion Process";

    // Report state to Execution Management
    ara::exec::ExecutionClient exec_client;
    exec_client.ReportExecutionState(ara::exec::ExecutionState::kRunning);

    // Main processing loop
    CameraFusionProcess process;
    process.Run();

    // Cleanup
    exec_client.ReportExecutionState(ara::exec::ExecutionState::kTerminating);
    ara::core::Deinitialize();

    return 0;
}

} // namespace oem::adas
```

### Communication Patterns

```cpp
// Service discovery and subscription pattern
namespace oem::adas {

class ObjectFusion {
public:
    void Initialize() {
        // Find radar service
        auto result = ara::com::RadarDetectionServiceProxy::FindService(
            ara::com::InstanceIdentifier("RadarFront")
        );

        if (result.HasValue()) {
            radar_proxy_ = std::move(result.Value());

            // Subscribe to detected objects event
            radar_proxy_.SubscribeDetectedObjectsEvent(
                [this](const DetectedObjectList& objects) {
                    OnRadarObjectsReceived(objects);
                },
                10  // Queue up to 10 samples
            );
        } else {
            logger_.LogError() << "Failed to find radar service: "
                              << result.Error().Message();
        }
    }

private:
    void OnRadarObjectsReceived(const DetectedObjectList& objects) {
        logger_.LogDebug() << "Received " << objects.size() << " objects from radar";
        FuseWithCameraData(objects);
    }

    ara::com::RadarDetectionServiceProxy radar_proxy_;
    ara::log::Logger logger_;
};

// Service provider pattern
class RadarSensorAdapter {
public:
    RadarSensorAdapter()
        : skeleton_(ara::com::InstanceIdentifier("RadarFront"))
        , logger_(ara::log::CreateLogger("RADR", "Radar Sensor Adapter"))
    {
        // Register method handlers
        skeleton_.RegisterCalibrateRadarHandler(
            [this](const CalibrationParams& params) {
                return HandleCalibration(params);
            }
        );

        // Offer service
        skeleton_.OfferService();
        logger_.LogInfo() << "Radar service offered";
    }

    void PublishDetectedObjects(const DetectedObjectList& objects) {
        // Update event field
        skeleton_.UpdateDetectedObjects(objects);
    }

private:
    ara::core::Result<void> HandleCalibration(const CalibrationParams& params) {
        logger_.LogInfo() << "Calibration requested";
        // Perform calibration
        return ara::core::Result<void>::FromValue();
    }

    ara::com::RadarDetectionServiceSkeleton skeleton_;
    ara::log::Logger logger_;
};

} // namespace oem::adas
```

### Error Handling (ara::core)

```cpp
// AUTOSAR Adaptive error handling using ara::core::Result
namespace oem::adas {

// Error domain definition
enum class CameraFusionErrc : ara::core::ErrorDomain::CodeType {
    kCalibrationFailed = 1,
    kInvalidImageFormat = 2,
    kProcessingTimeout = 3
};

class CameraFusionErrorDomain : public ara::core::ErrorDomain {
public:
    using Errc = CameraFusionErrc;

    constexpr CameraFusionErrorDomain() noexcept
        : ErrorDomain(0x8000000000001234ULL) {}  // Unique domain ID

    char const* Name() const noexcept override {
        return "CameraFusion";
    }

    char const* Message(CodeType errorCode) const noexcept override {
        switch (static_cast<Errc>(errorCode)) {
            case Errc::kCalibrationFailed:
                return "Camera calibration failed";
            case Errc::kInvalidImageFormat:
                return "Invalid image format received";
            case Errc::kProcessingTimeout:
                return "Image processing timeout";
            default:
                return "Unknown error";
        }
    }
};

constexpr CameraFusionErrorDomain g_cameraFusionErrorDomain;

// Using Result type for error handling
ara::core::Result<ProcessedImage> ProcessCameraImage(const RawImage& image) {
    if (!ValidateImageFormat(image)) {
        return ara::core::Result<ProcessedImage>::FromError(
            ara::core::ErrorCode(
                CameraFusionErrc::kInvalidImageFormat,
                g_cameraFusionErrorDomain
            )
        );
    }

    auto processed = ApplyProcessing(image);
    if (!processed.has_value()) {
        return ara::core::Result<ProcessedImage>::FromError(
            ara::core::ErrorCode(
                CameraFusionErrc::kProcessingTimeout,
                g_cameraFusionErrorDomain
            )
        );
    }

    return ara::core::Result<ProcessedImage>::FromValue(processed.value());
}

// Error handling at call site
void ProcessImages() {
    auto result = ProcessCameraImage(raw_image);

    if (result.HasValue()) {
        auto processed = result.Value();
        PublishProcessedImage(processed);
    } else {
        logger_.LogError() << "Image processing failed: "
                          << result.Error().Message();
        // Handle error appropriately
    }
}

} // namespace oem::adas
```

## Prohibited Patterns

### Classic Platform

```c
// PROHIBITED: Global variables without prefix
int speed;  // WRONG

// CORRECT: Module-prefixed global
static uint16 EngMgmt_Speed;

// PROHIBITED: Magic numbers
if (value > 100) {  // WRONG
    // ...
}

// CORRECT: Named constants
#define ENGMGMT_MAX_RPM_VALUE  8000U
if (value > ENGMGMT_MAX_RPM_VALUE) {
    // ...
}

// PROHIBITED: Multiple returns in single function (ASIL D)
uint16 Calculate(uint16 input) {
    if (input == 0) {
        return 0;  // WRONG for ASIL D
    }
    return input * 2;
}

// CORRECT: Single exit point
uint16 Calculate(uint16 input) {
    uint16 result = 0U;

    if (input != 0U) {
        result = input * 2U;
    }

    return result;  // Single exit
}

// PROHIBITED: Function pointers without typedef
void RegisterCallback(void (*callback)(uint8));  // WRONG

// CORRECT: Typedef for function pointer
typedef void (*EngMgmt_CallbackType)(uint8 event);
void RegisterCallback(EngMgmt_CallbackType callback);
```

### Adaptive Platform

```cpp
// PROHIBITED: Raw pointers for ownership
class SensorManager {
    RadarSensor* sensor_;  // WRONG: unclear ownership

public:
    void Initialize() {
        sensor_ = new RadarSensor();  // WRONG: manual memory management
    }
};

// CORRECT: Smart pointers for ownership
class SensorManager {
    std::unique_ptr<RadarSensor> sensor_;

public:
    void Initialize() {
        sensor_ = std::make_unique<RadarSensor>();
    }
};

// PROHIBITED: Exceptions in ASIL C/D code
void ProcessData() {
    throw std::runtime_error("Error");  // WRONG for safety code
}

// CORRECT: ara::core::Result for error handling
ara::core::Result<void> ProcessData() {
    if (error_condition) {
        return ara::core::Result<void>::FromError(error_code);
    }
    return ara::core::Result<void>::FromValue();
}

// PROHIBITED: Direct service instantiation
void Initialize() {
    auto service = new RadarServiceProxy();  // WRONG
}

// CORRECT: Service discovery pattern
void Initialize() {
    auto result = RadarServiceProxy::FindService(instance_id);
    if (result.HasValue()) {
        service_ = std::move(result.Value());
    }
}
```

## ARXML Naming Conventions

### System Description Elements

```xml
<!-- Package naming: /Company/Domain/Subsystem -->
<AR-PACKAGE>
  <SHORT-NAME>OEM_ADAS_CameraFusion</SHORT-NAME>
</AR-PACKAGE>

<!-- Software Component Type: <Domain><Function>SwComponentType -->
<APPLICATION-SW-COMPONENT-TYPE>
  <SHORT-NAME>AdasCameraFusionSwComponentType</SHORT-NAME>
</APPLICATION-SW-COMPONENT-TYPE>

<!-- Internal Behavior: <ComponentName>InternalBehavior -->
<SWC-INTERNAL-BEHAVIOR>
  <SHORT-NAME>AdasCameraFusionInternalBehavior</SHORT-NAME>
</SWC-INTERNAL-BEHAVIOR>

<!-- Runnable: <Function>Runnable -->
<RUNNABLE-ENTITY>
  <SHORT-NAME>ProcessImagesRunnable</SHORT-NAME>
  <MINIMUM-START-INTERVAL>0.02</MINIMUM-START-INTERVAL> <!-- 20ms -->
  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>
</RUNNABLE-ENTITY>

<!-- Port Prototype: <Direction>_<InterfaceName> -->
<P-PORT-PROTOTYPE>
  <SHORT-NAME>PP_DetectedObjects</SHORT-NAME>
  <PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
    /Interfaces/SR_DetectedObjects
  </PROVIDED-INTERFACE-TREF>
</P-PORT-PROTOTYPE>

<R-PORT-PROTOTYPE>
  <SHORT-NAME>RP_CameraImage</SHORT-NAME>
  <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
    /Interfaces/SR_CameraImage
  </REQUIRED-INTERFACE-TREF>
</R-PORT-PROTOTYPE>
```

### Configuration Naming

```xml
<!-- ECU Instance: <ECU_Name>EcuInstance -->
<ECU-INSTANCE>
  <SHORT-NAME>FrontCameraEcuInstance</SHORT-NAME>
  <COM-CONFIG-GW-TIME-BASE>0.001</COM-CONFIG-GW-TIME-BASE>
</ECU-INSTANCE>

<!-- System Signal: SYS_<SignalName> -->
<SYSTEM-SIGNAL>
  <SHORT-NAME>SYS_VehicleSpeed</SHORT-NAME>
  <DYNAMIC-LENGTH>false</DYNAMIC-LENGTH>
</SYSTEM-SIGNAL>

<!-- I-PDU: IPDU_<Sender>_<Message> -->
<I-PDU>
  <SHORT-NAME>IPDU_Gateway_VehicleDynamics</SHORT-NAME>
  <LENGTH>8</LENGTH>
  <I-PDU-TIMING-SPECIFICATION>
    <CYCLIC-TIMING>
      <TX-MODE>
        <TRANSMISSION-MODE-TRUE-TIMING>
          <PERIOD>0.01</PERIOD> <!-- 10ms -->
        </TRANSMISSION-MODE-TRUE-TIMING>
      </TX-MODE>
    </CYCLIC-TIMING>
  </I-PDU-TIMING-SPECIFICATION>
</I-PDU>
```

## Tool Integration

### DaVinci Configurator Conventions

```c
// Generated configuration structure naming
// Pattern: <Module>_Config_<ConfigSet>

extern const Can_ConfigType Can_Config_CanConfigSet_0;
extern const Com_ConfigType Com_Config_ComConfigSet;

// Generated hook function naming
// Pattern: <Module>_<Hook>_<ComponentName>

void Com_TxIPduCallout_IPDU_Gateway_VehicleDynamics(PduIdType PduId, PduInfoType* PduInfoPtr);
void Com_RxIPduCallout_IPDU_Engine_Status(PduIdType PduId, const PduInfoType* PduInfoPtr);
```

### RTE Generator Conventions

```c
// Generated RTE API naming
// Pattern: Rte_<Operation>_<Component>_<Port>_<Element>

// Read sender-receiver data
Std_ReturnType Rte_Read_EngMgmt_RP_VehicleSpeed_Value(uint16* data);

// Write sender-receiver data
Std_ReturnType Rte_Write_EngMgmt_PP_EngineRPM_Value(uint16 data);

// Call client-server operation
Std_ReturnType Rte_Call_EngMgmt_RP_Diagnostics_ReadData(uint16 did, uint8* buffer);

// Mode switch interface
Std_ReturnType Rte_Switch_EngMgmt_PP_EngineMode_Mode(Rte_ModeType_EngineMode mode);
```

## Build and Configuration Management

### Naming for Configuration Variants

```
Config/
├── Config_EV/           # Electric vehicle variant
│   ├── Can_Cfg.arxml
│   └── Com_Cfg.arxml
├── Config_HEV/          # Hybrid electric variant
│   ├── Can_Cfg.arxml
│   └── Com_Cfg.arxml
└── Config_ICE/          # Internal combustion engine variant
    ├── Can_Cfg.arxml
    └── Com_Cfg.arxml
```

### Version Identification

```c
// Module version information (standardized)
#define CAN_VENDOR_ID           (30U)  // AUTOSAR vendor ID
#define CAN_MODULE_ID           (80U)  // AUTOSAR module ID
#define CAN_AR_RELEASE_MAJOR_VERSION    (4U)
#define CAN_AR_RELEASE_MINOR_VERSION    (4U)
#define CAN_AR_RELEASE_REVISION_VERSION (0U)
#define CAN_SW_MAJOR_VERSION    (2U)
#define CAN_SW_MINOR_VERSION    (1U)
#define CAN_SW_PATCH_VERSION    (0U)
```

## References

- AUTOSAR Classic Platform Release R22-11
- AUTOSAR Adaptive Platform Release R22-11
- AUTOSAR C++14 Coding Guidelines
- AUTOSAR Naming Conventions Specification
- AUTOSAR Software Component Template (SWS)
- AUTOSAR Runtime Environment Specification (SWS)
