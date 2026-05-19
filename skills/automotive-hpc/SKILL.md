---
name: automotive-hpc
description: >
  Automotive Hpc expertise. Covers 5 topics: Autosar Adaptive, Containerization Orchestration, Hypervisor Virtualization, Safety Certification Hpc, Vehicle Compute Platforms.
tags: [automotive, automotive-hpc]
---

# Automotive Hpc

## Autosar Adaptive

# AUTOSAR Adaptive Platform for HPC

**Category:** automotive-hpc
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Comprehensive guide to AUTOSAR Adaptive Platform (AP) for high-performance computing in Software-Defined Vehicles. Covers service-oriented architecture, ara::com communication, execution management, state management, and C++14 framework development.

## Core Competencies

### 1. AUTOSAR Adaptive Architecture

**AUTOSAR Adaptive Platform Stack:**
```
┌─────────────────────────────────────────────────┐
│         Adaptive Applications (C++14)           │
├─────────────────────────────────────────────────┤
│  ara::com  │  ara::exec │  ara::log │  ara::per│
│  ara::diag │  ara::sm   │  ara::ucm │  ara::phm│
├─────────────────────────────────────────────────┤
│          Adaptive Platform Foundation           │
│  - Communication Management (SOME/IP)           │
│  - Execution Management (Process Control)       │
│  - State Management (Function Groups)           │
│  - Update & Config Management                   │
├─────────────────────────────────────────────────┤
│       Operating System (POSIX PSE51)            │
│  - Linux with PREEMPT_RT patch                  │
│  - QNX 7.1 (Safety-certified option)            │
└─────────────────────────────────────────────────┘
```

### 2. Service-Oriented Communication (ara::com)

**Service Interface Definition (ARXML):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<AUTOSAR xmlns="http://autosar.org/schema/r4.0">
    <AR-PACKAGES>
        <AR-PACKAGE>
            <SHORT-NAME>RadarServices</SHORT-NAME>
            <ELEMENTS>
                <!-- Service Interface Definition -->
                <SERVICE-INTERFACE>
                    <SHORT-NAME>RadarFusion</SHORT-NAME>
                    <MAJOR-VERSION>1</MAJOR-VERSION>
                    <MINOR-VERSION>0</MINOR-VERSION>

                    <!-- Events (pub/sub) -->
                    <EVENTS>
                        <VARIABLE-DATA-PROTOTYPE>
                            <SHORT-NAME>ObjectList</SHORT-NAME>
                            <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/ObjectListType</TYPE-TREF>
                        </VARIABLE-DATA-PROTOTYPE>
                        <VARIABLE-DATA-PROTOTYPE>
                            <SHORT-NAME>FreeSpaceMap</SHORT-NAME>
                            <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/FreeSpaceMapType</TYPE-TREF>
                        </VARIABLE-DATA-PROTOTYPE>
                    </EVENTS>

                    <!-- Methods (client/server) -->
                    <METHODS>
                        <CLIENT-SERVER-OPERATION>
                            <SHORT-NAME>SetRadarMode</SHORT-NAME>
                            <ARGUMENTS>
                                <ARGUMENT-DATA-PROTOTYPE>
                                    <SHORT-NAME>mode</SHORT-NAME>
                                    <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/RadarModeType</TYPE-TREF>
                                    <DIRECTION>IN</DIRECTION>
                                </ARGUMENT-DATA-PROTOTYPE>
                                <ARGUMENT-DATA-PROTOTYPE>
                                    <SHORT-NAME>success</SHORT-NAME>
                                    <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/BooleanType</TYPE-TREF>
                                    <DIRECTION>OUT</DIRECTION>
                                </ARGUMENT-DATA-PROTOTYPE>
                            </ARGUMENTS>
                            <POSSIBLE-ERROR-REFS>
                                <POSSIBLE-ERROR-REF DEST="APPLICATION-ERROR">/Errors/InvalidModeError</POSSIBLE-ERROR-REF>
                            </POSSIBLE-ERROR-REFS>
                        </CLIENT-SERVER-OPERATION>
                    </METHODS>

                    <!-- Fields (getter/setter) -->
                    <FIELDS>
                        <FIELD>
                            <SHORT-NAME>RadarStatus</SHORT-NAME>
                            <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/DataTypes/RadarStatusType</TYPE-TREF>
                            <HAS-GETTER>true</HAS-GETTER>
                            <HAS-SETTER>false</HAS-SETTER>
                            <HAS-NOTIFIER>true</HAS-NOTIFIER>
                        </FIELD>
                    </FIELDS>
                </SERVICE-INTERFACE>

                <!-- Service Instance Deployment -->
                <SOMEIP-SERVICE-INSTANCE-TO-MACHINE-MAPPING>
                    <SHORT-NAME>RadarFusionInstance</SHORT-NAME>
                    <COMMUNICATION-CONNECTOR-REF DEST="ETHERNET-COMMUNICATION-CONNECTOR">
                        /Network/EthernetConnector
                    </COMMUNICATION-CONNECTOR-REF>
                    <SERVICE-INTERFACE-DEPLOYMENT-REF DEST="SOMEIP-SERVICE-INTERFACE-DEPLOYMENT">
                        /Deployments/RadarFusionDeployment
                    </SERVICE-INTERFACE-DEPLOYMENT-REF>
                    <SOMEIP-SERVICE-INSTANCE-CONFIG>
                        <SERVICE-ID>0x1234</SERVICE-ID>
                        <INSTANCE-ID>0x0001</INSTANCE-ID>
                        <MAJOR-VERSION>1</MAJOR-VERSION>
                        <MINOR-VERSION>0</MINOR-VERSION>
                        <UDP-PORT>30490</UDP-PORT>
                        <TCP-PORT>30491</TCP-PORT>
                    </SOMEIP-SERVICE-INSTANCE-CONFIG>
                </SOMEIP-SERVICE-INSTANCE-TO-MACHINE-MAPPING>
            </ELEMENTS>
        </AR-PACKAGE>
    </AR-PACKAGES>
</AUTOSAR>
```

**C++14 Service Implementation (Provider):**
```cpp
// radar_fusion_service_impl.hpp
#include <ara/com/types.h>
#include <ara/com/instance_identifier.h>
#include <ara/com/skeleton.h>
#include "radar_fusion_skeleton.h"  // Generated from ARXML

namespace radar {
namespace fusion {

class RadarFusionServiceImpl {
public:
    RadarFusionServiceImpl()
        : skeleton_(ara::com::InstanceIdentifier("RadarFusion/Instance1")) {

        // Register method handler
        skeleton_.SetRadarMode.SetMethodCallHandler(
            [this](const RadarModeType& mode) -> ara::core::Future<SetRadarModeOutput> {
                return HandleSetRadarMode(mode);
            }
        );

        // Offer service on network
        skeleton_.OfferService();
    }

    ~RadarFusionServiceImpl() {
        skeleton_.StopOfferService();
    }

    // Publish object list event (10Hz)
    void PublishObjectList(const ObjectListType& objects) {
        skeleton_.ObjectList.Send(objects);
    }

    // Update field value with notification
    void UpdateRadarStatus(const RadarStatusType& status) {
        skeleton_.RadarStatus.Update(status);
    }

private:
    RadarFusionSkeleton skeleton_;

    ara::core::Future<SetRadarModeOutput> HandleSetRadarMode(const RadarModeType& mode) {
        ara::core::Promise<SetRadarModeOutput> promise;

        if (mode < RadarModeType::MIN || mode > RadarModeType::MAX) {
            // Return application error
            promise.SetError(ara::com::ApplicationErrorDomain::Errc::kInvalidMode);
        } else {
            // Apply mode change
            ApplyRadarMode(mode);

            SetRadarModeOutput output;
            output.success = true;
            promise.set_value(output);
        }

        return promise.get_future();
    }

    void ApplyRadarMode(const RadarModeType& mode) {
        // Hardware-specific mode configuration
        // ...
    }
};

} // namespace fusion
} // namespace radar

// Main application
int main() {
    ara::log::InitLogging("RadarFusion", ara::log::LogLevel::kInfo);
    ara::exec::ExecutionClient exec_client;

    // Report Execution State
    exec_client.ReportExecutionState(ara::exec::ExecutionState::kRunning);

    // Create service
    radar::fusion::RadarFusionServiceImpl service;

    // Main processing loop
    while (!ShutdownRequested()) {
        // Process radar data
        auto objects = ProcessRadarData();
        service.PublishObjectList(objects);

        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // Clean shutdown
    exec_client.ReportExecutionState(ara::exec::ExecutionState::kTerminating);
    return 0;
}
```

**C++14 Service Consumer (Proxy):**
```cpp
// adas_controller.cpp
#include <ara/com/proxy.h>
#include "radar_fusion_proxy.h"

namespace adas {

class AdasController {
public:
    AdasController() {
        // Find service instances
        auto find_handle = RadarFusionProxy::StartFindService(
            [this](ara::com::ServiceHandleContainer<RadarFusionProxy::HandleType> handles,
                   ara::com::FindServiceHandle find_handle) {
                this->OnServiceAvailable(std::move(handles));
            }
        );
    }

    void OnServiceAvailable(ara::com::ServiceHandleContainer<RadarFusionProxy::HandleType> handles) {
        if (!handles.empty()) {
            // Create proxy to first available service
            proxy_ = std::make_unique<RadarFusionProxy>(handles[0]);

            // Subscribe to ObjectList event
            proxy_->ObjectList.Subscribe(10 /* queue size */);
            proxy_->ObjectList.SetReceiveHandler(
                [this]() { this->OnObjectListReceived(); }
            );

            // Subscribe to RadarStatus field changes
            proxy_->RadarStatus.Subscribe(1);
            proxy_->RadarStatus.SetReceiveHandler(
                [this]() { this->OnRadarStatusChanged(); }
            );

            // Call method
            SetRadarMode(RadarModeType::LONG_RANGE);
        }
    }

    void OnObjectListReceived() {
        proxy_->ObjectList.GetNewSamples(
            [this](auto sample) {
                // Process object list
                for (const auto& obj : sample->objects) {
                    ProcessDetectedObject(obj);
                }
            }
        );
    }

    void OnRadarStatusChanged() {
        auto status = proxy_->RadarStatus.Get();
        ara::log::LogInfo() << "Radar status: " << status.value();
    }

    void SetRadarMode(RadarModeType mode) {
        // Async method call
        auto future = proxy_->SetRadarMode(mode);

        future.then([](ara::core::Future<SetRadarModeOutput> result) {
            if (result.HasValue()) {
                auto output = result.GetResult();
                if (output.value().success) {
                    ara::log::LogInfo() << "Mode change successful";
                }
            } else {
                auto error = result.GetError();
                ara::log::LogError() << "Mode change failed: " << error;
            }
        });
    }

private:
    std::unique_ptr<RadarFusionProxy> proxy_;

    void ProcessDetectedObject(const ObjectType& obj) {
        // ADAS processing logic
        // ...
    }
};

} // namespace adas
```

### 3. Execution Management (ara::exec)

**Application Manifest (JSON):**
```json
{
  "ApplicationManifest": {
    "shortName": "RadarFusionApp",
    "executableName": "radar_fusion",
    "version": "1.0.0",

    "processDesign": {
      "executable": "/opt/autosar/bin/radar_fusion",
      "arguments": ["--config", "/etc/autosar/radar_fusion.yaml"],
      "environmentVariables": {
        "LD_LIBRARY_PATH": "/opt/autosar/lib",
        "LOG_LEVEL": "INFO"
      }
    },

    "resourceGroups": [
      {
        "name": "RadarFusionResources",
        "cpuCores": [4, 5, 6, 7],
        "memoryMB": 512,
        "priority": 80,
        "schedulingPolicy": "SCHED_FIFO"
      }
    ],

    "startupConfig": {
      "functionGroup": "DrivingMode",
      "startupTimeout": 5000,
      "dependsOn": [
        "SensorAcquisition",
        "NetworkStack"
      ]
    },

    "stateManagement": {
      "functionGroup": "DrivingMode",
      "states": [
        {
          "name": "Startup",
          "timeout": 2000
        },
        {
          "name": "Running",
          "timeout": -1
        },
        {
          "name": "Degraded",
          "timeout": -1
        },
        {
          "name": "Shutdown",
          "timeout": 5000
        }
      ]
    },

    "healthMonitoring": {
      "checkpoints": [
        {
          "name": "DataProcessing",
          "maxInterval": 200
        },
        {
          "name": "NetworkCommunication",
          "maxInterval": 1000
        }
      ],
      "aliveSupervision": {
        "expectedAliveIndications": 10,
        "minInterval": 50,
        "maxInterval": 150
      }
    }
  }
}
```

**Execution Client Implementation:**
```cpp
// execution_manager.cpp
#include <ara/exec/execution_client.h>
#include <ara/exec/state_client.h>
#include <ara/phm/supervised_entity.h>

namespace radar {
namespace exec {

class ExecutionManager {
public:
    ExecutionManager()
        : exec_client_(),
          state_client_(),
          supervised_entity_("RadarFusion") {

        // Register state transition handler
        state_client_.SetStateTransitionHandler(
            [this](ara::exec::StateTransition transition) {
                this->HandleStateTransition(transition);
            }
        );
    }

    void Initialize() {
        // Report to Execution Management that we're starting
        exec_client_.ReportExecutionState(ara::exec::ExecutionState::kRunning);

        // Report checkpoint during initialization
        supervised_entity_.ReportCheckpoint(
            ara::phm::CheckpointIdentifier("Initialization")
        );

        // Load configuration
        LoadConfiguration();

        // Initialize hardware
        InitializeRadarHardware();

        // Start alive supervision
        StartAlivenessMonitoring();
    }

    void Run() {
        while (!shutdown_requested_) {
            // Report alive indication
            supervised_entity_.ReportAlive();

            // Main processing
            ProcessRadarData();

            // Report data processing checkpoint
            supervised_entity_.ReportCheckpoint(
                ara::phm::CheckpointIdentifier("DataProcessing")
            );

            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }

    void Shutdown() {
        // Stop processing
        StopRadarHardware();

        // Report terminating state
        exec_client_.ReportExecutionState(ara::exec::ExecutionState::kTerminating);
    }

private:
    ara::exec::ExecutionClient exec_client_;
    ara::exec::StateClient state_client_;
    ara::phm::SupervisedEntity supervised_entity_;
    std::atomic<bool> shutdown_requested_{false};

    void HandleStateTransition(ara::exec::StateTransition transition) {
        ara::log::LogInfo() << "State transition: "
                           << transition.from_state << " -> "
                           << transition.to_state;

        if (transition.to_state == "Shutdown") {
            shutdown_requested_ = true;
        } else if (transition.to_state == "Degraded") {
            EnterDegradedMode();
        }
    }

    void StartAlivenessMonitoring() {
        // Start thread for periodic alive reporting
        alive_thread_ = std::thread([this]() {
            while (!shutdown_requested_) {
                supervised_entity_.ReportAlive();
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        });
    }

    void ProcessRadarData() {
        // Radar processing logic
    }

    void EnterDegradedMode() {
        // Reduce functionality for degraded operation
        ara::log::LogWarn() << "Entering degraded mode";
    }

    std::thread alive_thread_;
};

} // namespace exec
} // namespace radar

int main() {
    radar::exec::ExecutionManager manager;

    try {
        manager.Initialize();
        manager.Run();
        manager.Shutdown();
    } catch (const std::exception& e) {
        ara::log::LogFatal() << "Fatal error: " << e.what();
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
```

### 4. State Management (ara::sm)

**Function Group State Machine:**
```cpp
// state_machine.cpp
#include <ara/sm/state_client.h>
#include <ara/sm/trigger_out.h>

namespace vehicle {
namespace sm {

enum class VehicleMode {
    OFF,
    STANDBY,
    DRIVING,
    PARKING,
    CHARGING,
    DIAGNOSTIC
};

class VehicleStateManager {
public:
    VehicleStateManager() {
        // Subscribe to function group state changes
        state_client_.SetStateTransitionHandler(
            [this](const ara::sm::FunctionGroupState& state) {
                this->OnStateChange(state);
            }
        );

        // Register trigger providers
        RegisterTriggers();
    }

    void RequestModeChange(VehicleMode target_mode) {
        ara::sm::FunctionGroupState target_state;

        switch (target_mode) {
            case VehicleMode::DRIVING:
                target_state = ara::sm::FunctionGroupState("DrivingMode");
                break;
            case VehicleMode::PARKING:
                target_state = ara::sm::FunctionGroupState("ParkingMode");
                break;
            case VehicleMode::CHARGING:
                target_state = ara::sm::FunctionGroupState("ChargingMode");
                break;
            default:
                ara::log::LogError() << "Invalid mode requested";
                return;
        }

        // Request state transition
        auto result = state_client_.SetState(target_state);
        result.then([target_mode](ara::core::Future<void> future) {
            if (future.has_value()) {
                ara::log::LogInfo() << "Mode change to "
                                   << static_cast<int>(target_mode)
                                   << " successful";
            } else {
                ara::log::LogError() << "Mode change failed: "
                                    << future.GetError().Message();
            }
        });
    }

private:
    ara::sm::StateClient state_client_;
    std::unique_ptr<ara::sm::TriggerOut> ignition_trigger_;
    std::unique_ptr<ara::sm::TriggerOut> charging_trigger_;

    void RegisterTriggers() {
        // Register ignition trigger
        ignition_trigger_ = std::make_unique<ara::sm::TriggerOut>(
            ara::sm::TriggerIdentifier("IgnitionOn")
        );

        // Register charging trigger
        charging_trigger_ = std::make_unique<ara::sm::TriggerOut>(
            ara::sm::TriggerIdentifier("ChargingConnected")
        );
    }

    void OnStateChange(const ara::sm::FunctionGroupState& state) {
        ara::log::LogInfo() << "Function group state changed to: " << state;

        if (state == "DrivingMode") {
            EnableDrivingFunctions();
        } else if (state == "ParkingMode") {
            EnableParkingFunctions();
        } else if (state == "ChargingMode") {
            EnableChargingFunctions();
        }
    }

    void EnableDrivingFunctions() {
        // Activate ADAS, powertrain control, etc.
        ara::log::LogInfo() << "Driving functions enabled";
    }

    void EnableParkingFunctions() {
        // Activate parking assist, surround view, etc.
        ara::log::LogInfo() << "Parking functions enabled";
    }

    void EnableChargingFunctions() {
        // Activate battery management, charging control
        ara::log::LogInfo() << "Charging functions enabled";
    }
};

} // namespace sm
} // namespace vehicle
```

### 5. Platform Health Management (ara::phm)

**Health Monitoring Implementation:**
```cpp
// health_monitor.cpp
#include <ara/phm/recovery_action.h>
#include <ara/phm/health_channel.h>

namespace platform {
namespace health {

class HealthMonitor {
public:
    HealthMonitor() {
        // Create health channels
        sensor_health_ = std::make_unique<ara::phm::HealthChannel>(
            ara::phm::HealthChannelId("SensorHealth")
        );

        computation_health_ = std::make_unique<ara::phm::HealthChannel>(
            ara::phm::HealthChannelId("ComputationHealth")
        );

        // Register recovery actions
        RegisterRecoveryActions();
    }

    void MonitorSensorHealth(const SensorData& data) {
        if (!ValidateSensorData(data)) {
            // Report health status degraded
            sensor_health_->ReportHealthStatus(
                ara::phm::HealthStatus::kDegraded,
                ara::phm::HealthStatusCause::kInvalidData
            );

            // Trigger recovery action
            recovery_action_->Invoke();
        } else {
            sensor_health_->ReportHealthStatus(
                ara::phm::HealthStatus::kOk
            );
        }
    }

    void MonitorComputationLoad() {
        float cpu_usage = GetCPUUsage();
        float memory_usage = GetMemoryUsage();

        if (cpu_usage > 95.0 || memory_usage > 90.0) {
            computation_health_->ReportHealthStatus(
                ara::phm::HealthStatus::kDegraded,
                ara::phm::HealthStatusCause::kResourceExhaustion
            );

            // Reduce processing load
            ReduceComputationLoad();
        }
    }

private:
    std::unique_ptr<ara::phm::HealthChannel> sensor_health_;
    std::unique_ptr<ara::phm::HealthChannel> computation_health_;
    std::unique_ptr<ara::phm::RecoveryAction> recovery_action_;

    void RegisterRecoveryActions() {
        recovery_action_ = std::make_unique<ara::phm::RecoveryAction>(
            ara::phm::RecoveryActionId("SensorRecovery"),
            [this]() {
                // Recovery logic: restart sensor, use fallback data, etc.
                ara::log::LogWarn() << "Executing sensor recovery";
                RestartSensorInterface();
            }
        );
    }

    bool ValidateSensorData(const SensorData& data) {
        return data.timestamp_valid &&
               data.crc_valid &&
               data.alive_counter_sequential;
    }

    void RestartSensorInterface() {
        // Sensor restart logic
    }

    void ReduceComputationLoad() {
        // Temporarily disable non-critical features
    }

    float GetCPUUsage() { return 0.0; }  // Implementation
    float GetMemoryUsage() { return 0.0; }  // Implementation
};

} // namespace health
} // namespace platform
```

## Use Cases

1. **L3+ Autonomous Driving**: ADAS applications using ara::com for sensor fusion
2. **OTA Updates**: ara::ucm for safe software updates with rollback
3. **Zone Controllers**: Service-oriented communication between domain controllers
4. **Cloud Connectivity**: ara::rest for vehicle-to-cloud data exchange

## Automotive Standards

- **AUTOSAR R22-11**: Latest Adaptive Platform specification
- **ISO 26262 ASIL-D**: Safety-critical application development
- **ISO 21434**: Cybersecurity for service communication
- **ASPICE CL3**: Software development process compliance

## Tools Required

- **Vector DaVinci**: ARXML editing and code generation
- **EB tresos AdaptiveCore**: AUTOSAR Adaptive middleware
- **Elektrobit EB corbos**: Adaptive Platform implementation
- **COVESA VSS**: Vehicle Signal Specification integration

## Performance Metrics

- **Service Discovery**: <100ms to find and bind to service
- **Event Throughput**: >10,000 events/sec via SOME/IP
- **Method Call Latency**: <2ms round-trip for local services
- **Memory Footprint**: <50MB for Adaptive Platform runtime

## References

- AUTOSAR Adaptive Platform Release 22-11 Specification
- "AUTOSAR Adaptive Platform Explained" (AUTOSAR Whitepaper)
- ISO 26262-6:2018 Software Development Guidelines
- COVESA Vehicle Signal Specification

---

**Version:** 1.0.0
**Last Updated:** 2026-03-19
**Author:** Automotive Claude Code Agents

---

## Containerization Orchestration

# Containerization and Orchestration for Automotive HPC

**Category:** automotive-hpc
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Comprehensive guide to container technologies and orchestration for automotive HPC platforms. Covers Docker, Podman, Kubernetes for vehicles, application lifecycle management, and OTA container updates with safety considerations.

## Core Competencies

### 1. Automotive Container Architecture

**Why Containers in Automotive:**
- **Rapid Updates**: Deploy new algorithms without full ECU reflash
- **Isolation**: Separate safety-critical from non-critical workloads
- **Portability**: Same container runs on test bench, HIL, and production vehicle
- **Resource Control**: cgroups for CPU/memory limits per ASIL level
- **Versioning**: Atomic rollback for failed updates

**Container vs Traditional ECU:**
```
Traditional ECU:               Containerized Platform:
┌──────────────────┐          ┌─────────────────────────────┐
│   App Binary     │          │ Container 1: ADAS (ASIL-D)  │
│   (Monolithic)   │          │ Container 2: IVI (QM)       │
├──────────────────┤          │ Container 3: Telematics     │
│   AUTOSAR RTE    │          ├─────────────────────────────┤
├──────────────────┤          │ Container Runtime (containerd)│
│   OS (QNX/Linux) │          ├─────────────────────────────┤
│   Bare Metal     │          │ OS (Linux/QNX)              │
└──────────────────┘          └─────────────────────────────┘
Update: Full flash (30min)    Update: Container only (2min)
```

### 2. Container Runtime for Automotive

#### Docker for Development

**Dockerfile for ADAS Application:**
```dockerfile
# Multi-stage build for ADAS perception pipeline
FROM nvcr.io/nvidia/l4t-base:r35.3.1 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    cuda-toolkit-11-4 \
    libeigen3-dev \
    libopencv-dev \
    && rm -rf /var/lib/apt/lists/*

# Build ADAS application
WORKDIR /app
COPY src/ /app/src/
COPY CMakeLists.txt /app/

RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc)

# Runtime stage (minimal image)
FROM nvcr.io/nvidia/l4t-base:r35.3.1

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libopencv-core4.5d \
    libopencv-imgproc4.5d \
    cuda-cudart-11-4 \
    && rm -rf /var/lib/apt/lists/*

# Copy only built artifacts
COPY --from=builder /app/build/adas_perception /usr/local/bin/
COPY --from=builder /app/models/ /opt/models/

# Non-root user for security
RUN useradd -m -u 1000 adas && \
    chown -R adas:adas /opt/models

USER adas

# CUDA device access
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# Health check
HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
    CMD /usr/local/bin/adas_perception --health-check

ENTRYPOINT ["/usr/local/bin/adas_perception"]
CMD ["--config", "/etc/adas/config.yaml"]
```

**Docker Compose for Development Environment:**
```yaml
# docker-compose.yaml - Local ADAS development
version: '3.8'

services:
  # Sensor simulation
  sensor_sim:
    image: autoware/sensor-simulator:latest
    volumes:
      - ./data/rosbag:/data:ro
    networks:
      - vehicle_net
    command: ["--replay", "/data/test_drive.bag"]

  # ADAS perception
  adas_perception:
    build:
      context: .
      dockerfile: Dockerfile
    runtime: nvidia
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - ROS_MASTER_URI=http://sensor_sim:11311
    volumes:
      - ./models:/opt/models:ro
      - ./logs:/var/log/adas:rw
    networks:
      - vehicle_net
    depends_on:
      - sensor_sim
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  # Visualization
  rviz:
    image: osrf/ros:noetic-desktop-full
    environment:
      - DISPLAY=$DISPLAY
      - ROS_MASTER_URI=http://sensor_sim:11311
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
    networks:
      - vehicle_net
    depends_on:
      - adas_perception

networks:
  vehicle_net:
    driver: bridge
```

#### Podman for Production (Rootless & Daemonless)

**Why Podman for Automotive:**
- **Rootless**: Better security, no privileged daemon
- **Systemd Integration**: Native systemd unit generation
- **OCI Compliant**: Compatible with Kubernetes
- **No Daemon**: Reduces attack surface

**Podman Container for Safety-Critical ADAS:**
```bash
#!/bin/bash
# Build and run ADAS container with Podman

# Build image
podman build -t adas-perception:1.0.0 -f Dockerfile.adas .

# Run with systemd integration and resource limits
podman run -d \
  --name adas-safety \
  --security-opt label=type:adas_t \
  --cap-drop=ALL \
  --cap-add=SYS_NICE \
  --cpuset-cpus=4-7 \
  --memory=4G \
  --memory-swap=0 \
  --oom-score-adj=-1000 \
  --device=/dev/nvidia0 \
  --device=/dev/can0 \
  --volume=/etc/adas/config.yaml:/etc/adas/config.yaml:ro,Z \
  --volume=/var/log/adas:/var/log/adas:rw,Z \
  --network=host \
  --restart=on-failure:3 \
  adas-perception:1.0.0

# Generate systemd service
podman generate systemd --new --name adas-safety \
  --restart-policy=always \
  --start-timeout=30 \
  --stop-timeout=10 \
  > /etc/systemd/system/adas-safety.service

systemctl enable adas-safety.service
systemctl start adas-safety.service
```

### 3. Kubernetes for Automotive

**Lightweight Kubernetes Distributions:**
- **K3s**: Minimal Kubernetes (40MB binary) for edge/embedded
- **MicroK8s**: Snap-based, fast cluster setup
- **KubeEdge**: Extends Kubernetes to edge devices

**K3s Installation on Vehicle ECU:**
```bash
#!/bin/bash
# Install K3s on automotive HPC (NVIDIA Orin)

# Install K3s server (control plane + worker)
curl -sfL https://get.k3s.io | sh -s - \
  --disable traefik \
  --disable servicelb \
  --kubelet-arg="cpu-manager-policy=static" \
  --kubelet-arg="topology-manager-policy=single-numa-node" \
  --kubelet-arg="reserved-cpus=0-1" \
  --kubelet-arg="system-reserved=cpu=2,memory=2Gi" \
  --kube-apiserver-arg="feature-gates=CPUManager=true,TopologyManager=true"

# Install NVIDIA GPU device plugin
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/nvidia-device-plugin.yml

# Verify installation
kubectl get nodes
kubectl describe node $(hostname)
```

**ADAS Deployment Manifest:**
```yaml
# adas-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: adas-safety
  labels:
    asil: "d"
    safety-critical: "true"

---
# ConfigMap for ADAS configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: adas-config
  namespace: adas-safety
data:
  config.yaml: |
    perception:
      camera_count: 8
      lidar_enabled: true
      radar_count: 5
      fusion_rate_hz: 10
    planning:
      algorithm: "model_predictive_control"
      horizon_seconds: 5
      safety_margin_meters: 2.0

---
# ADAS Perception Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adas-perception
  namespace: adas-safety
  labels:
    app: adas-perception
    asil: "d"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: adas-perception
  template:
    metadata:
      labels:
        app: adas-perception
        asil: "d"
    spec:
      # Node affinity for HPC cores
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/hpc
                operator: In
                values:
                - "true"

      # Host networking for low-latency CAN/Ethernet
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet

      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault

      containers:
      - name: perception
        image: adas-perception:1.0.0
        imagePullPolicy: IfNotPresent

        # Resource requests/limits (guaranteed QoS)
        resources:
          requests:
            cpu: "4"
            memory: "4Gi"
            nvidia.com/gpu: "1"
          limits:
            cpu: "4"
            memory: "4Gi"
            nvidia.com/gpu: "1"

        # Environment variables
        env:
        - name: CUDA_VISIBLE_DEVICES
          value: "0"
        - name: OMP_NUM_THREADS
          value: "4"

        # Volume mounts
        volumeMounts:
        - name: config
          mountPath: /etc/adas
          readOnly: true
        - name: models
          mountPath: /opt/models
          readOnly: true
        - name: logs
          mountPath: /var/log/adas
        - name: dev-can
          mountPath: /dev/can0

        # Liveness probe
        livenessProbe:
          exec:
            command:
            - /usr/local/bin/health-check
            - --type=liveness
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        # Readiness probe
        readinessProbe:
          exec:
            command:
            - /usr/local/bin/health-check
            - --type=readiness
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3

        # Security capabilities
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
            add:
            - SYS_NICE  # For RT scheduling
          readOnlyRootFilesystem: true

      # Volumes
      volumes:
      - name: config
        configMap:
          name: adas-config
      - name: models
        hostPath:
          path: /opt/adas/models
          type: Directory
      - name: logs
        emptyDir:
          sizeLimit: 1Gi
      - name: dev-can
        hostPath:
          path: /dev/can0
          type: CharDevice

      # Tolerations for dedicated HPC nodes
      tolerations:
      - key: "hpc"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"

      # Priority class for safety-critical workload
      priorityClassName: safety-critical

---
# PriorityClass for ASIL-D workloads
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: safety-critical
value: 1000000
globalDefault: false
description: "Reserved for ASIL-D safety-critical applications"
```

### 4. OTA Container Updates

**Safe OTA Update Strategy:**
```python
#!/usr/bin/env python3
"""
Automotive OTA Container Update Manager
Implements A/B partition scheme for safe rollback
"""

import subprocess
import json
import hashlib
from enum import Enum
from dataclasses import dataclass
from typing import Optional

class UpdateStatus(Enum):
    IDLE = "idle"
    DOWNLOADING = "downloading"
    VALIDATING = "validating"
    INSTALLING = "installing"
    TESTING = "testing"
    COMMITTED = "committed"
    ROLLING_BACK = "rolling_back"
    FAILED = "failed"

@dataclass
class ContainerUpdate:
    name: str
    current_version: str
    target_version: str
    image_url: str
    checksum_sha256: str
    asil_level: str

class OTAUpdateManager:
    def __init__(self):
        self.update_partition = "B"  # A=active, B=update
        self.status = UpdateStatus.IDLE

    def update_container(self, update: ContainerUpdate) -> bool:
        """
        Perform safe OTA container update with rollback capability
        """
        try:
            # 1. Pre-update validation
            if not self.validate_preconditions(update):
                return False

            # 2. Download new container image
            self.status = UpdateStatus.DOWNLOADING
            if not self.download_image(update):
                return False

            # 3. Validate checksum
            self.status = UpdateStatus.VALIDATING
            if not self.verify_checksum(update):
                return False

            # 4. Install to inactive partition
            self.status = UpdateStatus.INSTALLING
            if not self.install_to_partition(update, self.update_partition):
                return False

            # 5. Test new version (smoke test)
            self.status = UpdateStatus.TESTING
            if not self.smoke_test(update):
                self.rollback(update)
                return False

            # 6. Commit update (switch active partition)
            self.status = UpdateStatus.COMMITTED
            self.commit_update(update)

            # 7. Monitor for stability (2 minutes)
            if not self.monitor_stability(update, duration_sec=120):
                self.rollback(update)
                return False

            self.status = UpdateStatus.IDLE
            return True

        except Exception as e:
            self.status = UpdateStatus.FAILED
            print(f"Update failed: {e}")
            self.rollback(update)
            return False

    def validate_preconditions(self, update: ContainerUpdate) -> bool:
        """Check vehicle state before update"""
        # Don't update while driving
        vehicle_speed = self.get_vehicle_speed()
        if vehicle_speed > 0:
            print("Update blocked: Vehicle in motion")
            return False

        # Check battery SOC (>20% for safety)
        if self.get_battery_soc() < 20.0:
            print("Update blocked: Low battery")
            return False

        # Verify parking brake engaged
        if not self.is_parking_brake_engaged():
            print("Update blocked: Parking brake not engaged")
            return False

        return True

    def download_image(self, update: ContainerUpdate) -> bool:
        """Download container image from OTA server"""
        print(f"Downloading {update.name}:{update.target_version}")

        result = subprocess.run([
            'podman', 'pull',
            f'{update.image_url}:{update.target_version}'
        ], capture_output=True, text=True)

        return result.returncode == 0

    def verify_checksum(self, update: ContainerUpdate) -> bool:
        """Verify image integrity"""
        result = subprocess.run([
            'podman', 'image', 'inspect',
            f'{update.image_url}:{update.target_version}',
            '--format', '{{.Id}}'
        ], capture_output=True, text=True)

        image_id = result.stdout.strip()
        # Extract SHA256 from image ID (sha256:abc123...)
        actual_checksum = image_id.split(':')[1][:64]

        if actual_checksum != update.checksum_sha256:
            print(f"Checksum mismatch: {actual_checksum} != {update.checksum_sha256}")
            return False

        return True

    def install_to_partition(self, update: ContainerUpdate, partition: str) -> bool:
        """Install container to inactive partition"""
        # Tag image for specific partition
        subprocess.run([
            'podman', 'tag',
            f'{update.image_url}:{update.target_version}',
            f'{update.name}:partition-{partition}'
        ])

        # Create new container (don't start yet)
        result = subprocess.run([
            'podman', 'create',
            '--name', f'{update.name}-{partition}',
            '--cpuset-cpus', '4-7',
            '--memory', '4G',
            f'{update.name}:partition-{partition}'
        ], capture_output=True, text=True)

        return result.returncode == 0

    def smoke_test(self, update: ContainerUpdate) -> bool:
        """Start container and verify basic functionality"""
        container_name = f'{update.name}-{self.update_partition}'

        # Start container
        subprocess.run(['podman', 'start', container_name])

        # Wait for container to be ready
        import time
        time.sleep(5)

        # Check health endpoint
        result = subprocess.run([
            'podman', 'exec', container_name,
            '/usr/local/bin/health-check'
        ], capture_output=True)

        if result.returncode != 0:
            print("Smoke test failed: Health check returned error")
            subprocess.run(['podman', 'stop', container_name])
            return False

        # For ASIL-D: Run extended validation
        if update.asil_level == "D":
            if not self.asil_d_validation(container_name):
                subprocess.run(['podman', 'stop', container_name])
                return False

        return True

    def commit_update(self, update: ContainerUpdate):
        """Switch active partition"""
        old_container = f'{update.name}-A'
        new_container = f'{update.name}-{self.update_partition}'

        # Stop old version
        subprocess.run(['podman', 'stop', old_container])

        # Rename containers (swap partitions)
        subprocess.run(['podman', 'rename', old_container, f'{update.name}-OLD'])
        subprocess.run(['podman', 'rename', new_container, old_container])

        # Update systemd service to point to new container
        subprocess.run(['systemctl', 'restart', f'{update.name}.service'])

    def monitor_stability(self, update: ContainerUpdate, duration_sec: int) -> bool:
        """Monitor container for crashes/errors after update"""
        import time
        container_name = f'{update.name}-A'

        start_time = time.time()
        while time.time() - start_time < duration_sec:
            # Check if container is still running
            result = subprocess.run([
                'podman', 'inspect',
                '--format', '{{.State.Running}}',
                container_name
            ], capture_output=True, text=True)

            if result.stdout.strip() != 'true':
                print("Container crashed during stability monitoring")
                return False

            # Check error logs
            result = subprocess.run([
                'podman', 'logs', '--tail', '10', container_name
            ], capture_output=True, text=True)

            if 'FATAL' in result.stdout or 'CRITICAL' in result.stdout:
                print("Critical errors detected in logs")
                return False

            time.sleep(10)

        return True

    def rollback(self, update: ContainerUpdate):
        """Rollback to previous version"""
        self.status = UpdateStatus.ROLLING_BACK
        print(f"Rolling back {update.name} to {update.current_version}")

        new_container = f'{update.name}-A'
        old_container = f'{update.name}-OLD'

        # Stop failed new version
        subprocess.run(['podman', 'stop', new_container])

        # Restore old version
        subprocess.run(['podman', 'rename', new_container, f'{update.name}-FAILED'])
        subprocess.run(['podman', 'rename', old_container, new_container])
        subprocess.run(['podman', 'start', new_container])

        # Restore systemd service
        subprocess.run(['systemctl', 'restart', f'{update.name}.service'])

    def asil_d_validation(self, container_name: str) -> bool:
        """Extended validation for ASIL-D containers"""
        # Run safety test suite
        result = subprocess.run([
            'podman', 'exec', container_name,
            '/usr/local/bin/safety-test-suite'
        ], capture_output=True)

        return result.returncode == 0

    # Mock functions for vehicle state
    def get_vehicle_speed(self) -> float:
        return 0.0  # km/h

    def get_battery_soc(self) -> float:
        return 80.0  # %

    def is_parking_brake_engaged(self) -> bool:
        return True

# Example usage
if __name__ == '__main__':
    manager = OTAUpdateManager()

    update = ContainerUpdate(
        name='adas-perception',
        current_version='1.0.0',
        target_version='1.1.0',
        image_url='registry.oem.com/adas-perception',
        checksum_sha256='abc123def456...',
        asil_level='D'
    )

    success = manager.update_container(update)
    print(f"Update {'successful' if success else 'failed'}")
```

### 5. Container Resource Management

**CPU and Memory Isolation:**
```yaml
# cgroup v2 configuration for container resource limits
# /sys/fs/cgroup/adas-perception.slice/cpu.max
# Format: $MAX $PERIOD (microseconds)
400000 100000  # 4 CPUs worth (4 * 100ms = 400ms per 100ms period)

# /sys/fs/cgroup/adas-perception.slice/memory.max
4294967296  # 4 GB

# /sys/fs/cgroup/adas-perception.slice/memory.swap.max
0  # No swap for safety-critical

# /sys/fs/cgroup/adas-perception.slice/cpuset.cpus
4-7  # Pin to CPU cores 4-7

# /sys/fs/cgroup/adas-perception.slice/cpuset.mems
0  # NUMA node 0
```

## Use Cases

1. **Modular ADAS Updates**: Update perception algorithm without touching planning/control
2. **A/B Testing**: Run two algorithm versions side-by-side for validation
3. **Multi-Tenant ECU**: IVI, telematics, and ADAS on single HPC with isolation
4. **CI/CD Integration**: Automated testing and deployment pipeline

## Automotive Standards

- **ISO 26262**: Container isolation for FFI compliance
- **ISO 21434**: Secure container registry and image signing
- **ASPICE CL3**: Container lifecycle management process

## Tools Required

- **Docker/Podman**: Container runtime
- **K3s/MicroK8s**: Lightweight Kubernetes
- **Helm**: Kubernetes package manager
- **Harbor**: Container registry with security scanning
- **Notary**: Container image signing (TUF framework)

## Performance Metrics

- **Container Startup**: <2s for ADAS application
- **Overhead**: <2% CPU, <50MB memory for runtime
- **Update Time**: <5min for full container replacement
- **Rollback Time**: <30s to previous version

## References

- CNCF Automotive Edge Computing Whitepaper
- AGL (Automotive Grade Linux) Container Guidelines
- Kubernetes for Edge Computing (K3s documentation)
- "Containers in Safety-Critical Systems" (SAE Paper)

---

**Version:** 1.0.0
**Last Updated:** 2026-03-19
**Author:** Automotive Claude Code Agents

---

## Hypervisor Virtualization

# Hypervisor Virtualization for Automotive HPC

**Category:** automotive-hpc
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Expert knowledge in automotive hypervisor technologies for High-Performance Computing platforms. Covers QNX Hypervisor, ACRN, Xen, and other automotive-grade virtualization solutions for mixed-criticality systems, safety partitioning, and resource management.

## Core Competencies

### 1. Automotive Hypervisor Technologies

#### QNX Hypervisor 2.2
- Type 1 bare-metal hypervisor for safety-critical systems
- ASIL-D certified for ISO 26262 compliance
- Microkernel architecture with minimal TCB (Trusted Computing Base)
- Hardware virtualization using ARM VE or Intel VT-x/VT-d
- Real-time guarantee preservation across VMs

**QNX Hypervisor Configuration Example:**
```xml
<?xml version="1.0"?>
<system>
    <hypervisor>
        <name>qnx-hypervisor</name>
        <version>2.2</version>
        <scheduler type="partition">
            <major_frame>10ms</major_frame>
        </scheduler>
    </hypervisor>

    <!-- ASIL-D Safety VM for ADAS -->
    <guest id="0" name="safety-vm" asil="D">
        <os>qnx-710</os>
        <vcpus>2</vcpus>
        <memory>2GB</memory>
        <safety_partition>
            <interference_freedom>guaranteed</interference_freedom>
            <watchdog>enabled</watchdog>
            <memory_protection>mpu</memory_protection>
        </safety_partition>
        <schedule>
            <partition_window>6ms</partition_window>
            <priority>255</priority>
        </schedule>
        <devices>
            <pci bus="0" dev="2" func="0" /> <!-- CAN controller -->
            <interrupt line="45" />
        </devices>
    </guest>

    <!-- QM Non-Safety VM for Infotainment -->
    <guest id="1" name="infotainment-vm" asil="QM">
        <os>android-automotive-13</os>
        <vcpus>4</vcpus>
        <memory>4GB</memory>
        <schedule>
            <partition_window>4ms</partition_window>
            <priority>128</priority>
        </schedule>
        <gpu>
            <passthrough device="/dev/gpu0" />
            <sriov vf="1" />
        </gpu>
    </guest>
</system>
```

#### ACRN Hypervisor (Intel)
- Open-source Type 1 hypervisor optimized for IoT and automotive
- Safety VM (Service VM) + User VMs architecture
- Device Model for I/O virtualization
- ACRN-DM (Device Model) for para-virtualized devices
- Real-time VM support for safety workloads

**ACRN Launch Configuration:**
```python
# ACRN VM Launch Script - Safety VM
import sys
import acrn_vm

# Safety VM Configuration (ASIL-D)
safety_vm = acrn_vm.VM({
    'name': 'RTLinux-Safety',
    'vcpu_num': 2,
    'memory_size': '2G',
    'vm_type': 'RTVM',  # Real-time VM
    'lapic_passthrough': True,
    'ivshmem_regions': [
        {
            'name': 'sensor-data-region',
            'size': '64M',
            'shared_with': ['adas-vm', 'gateway-vm']
        }
    ],
    'cpu_affinity': [0, 1],  # Pin to cores 0-1
    'vpci_devices': [
        {'bus': 0, 'dev': 2, 'func': 0, 'type': 'CAN'}
    ],
    'boot_args': 'root=/dev/sda1 rw console=ttyS0 isolcpus=0,1'
})

# Configure virtio devices
safety_vm.add_virtio_net(
    tap_device='tap0',
    mac='52:54:00:12:34:56'
)

safety_vm.add_virtio_blk(
    image_path='/var/vms/safety-rootfs.img'
)

# Launch VM with real-time priority
safety_vm.launch(priority='rt', policy='FIFO')
```

#### Xen Hypervisor (ARM/x86)
- Type 1 hypervisor with strong isolation
- Dom0 (privileged domain) for device drivers
- DomU (unprivileged domains) for guest VMs
- PV (paravirtualization) and HVM (hardware virtual machine) modes
- IOMMU support for device assignment

**Xen VM Configuration (xl toolstack):**
```python
# Xen DomU Configuration - ADAS Processing VM
name = "adas-processing"
type = "hvm"
memory = 4096
vcpus = 4
cpus = "4-7"  # Pin to cores 4-7

# Boot configuration
kernel = "/boot/vmlinuz-rt"
ramdisk = "/boot/initrd.img-rt"
extra = "root=/dev/xvda1 console=hvc0 isolcpus=4-7"

# Virtual devices
disk = [
    'phy:/dev/vg_vms/adas-root,xvda1,w',
    'file:/var/vms/adas-data.img,xvdb,w'
]

vif = ['bridge=xenbr0,mac=00:16:3e:12:34:56']

# PCI passthrough for GPU
pci = ['0000:01:00.0']  # NVIDIA GPU

# IOMMU settings
iommu = 1
permissive = 0

# Virtual framebuffer for display
vfb = ['vnc=1,vnclisten=0.0.0.0']

# Security settings
on_poweroff = 'destroy'
on_reboot = 'restart'
on_crash = 'coredump-restart'
```

### 2. Mixed-Criticality System Design

**ASIL Decomposition and Isolation:**
```cpp
// C++14 - Safety Partition Manager
#include <hypervisor/partition.h>
#include <safety/asil.h>

namespace automotive {
namespace hpc {

class SafetyPartitionManager {
public:
    struct PartitionConfig {
        std::string name;
        ASIL asil_level;
        uint64_t memory_base;
        uint64_t memory_size;
        std::vector<uint32_t> cpu_affinity;
        uint32_t time_slice_us;
        bool interference_free;
    };

    SafetyPartitionManager() : major_frame_us_(10000) {}

    // Create isolated partition for specific ASIL level
    bool CreatePartition(const PartitionConfig& config) {
        // Validate ASIL requirements
        if (config.asil_level >= ASIL::D) {
            if (!ValidateFFI(config)) {
                LOG_ERROR("FFI validation failed for ASIL-D partition");
                return false;
            }
        }

        // Configure MPU/MMU for memory isolation
        if (!ConfigureMemoryProtection(config)) {
            return false;
        }

        // Setup temporal isolation (time partitioning)
        if (!ConfigureTimeSlice(config)) {
            return false;
        }

        // Register partition
        partitions_.push_back(config);
        return true;
    }

    // Freedom From Interference validation
    bool ValidateFFI(const PartitionConfig& config) {
        // Check memory interference
        for (const auto& existing : partitions_) {
            if (MemoryOverlap(config, existing)) {
                return false;
            }
        }

        // Check CPU affinity conflicts
        for (const auto& existing : partitions_) {
            if (CPUAffinityConflict(config, existing)) {
                return false;
            }
        }

        // Validate time budget doesn't exceed major frame
        uint64_t total_time = 0;
        for (const auto& p : partitions_) {
            total_time += p.time_slice_us;
        }
        if (total_time + config.time_slice_us > major_frame_us_) {
            return false;
        }

        return true;
    }

private:
    std::vector<PartitionConfig> partitions_;
    uint64_t major_frame_us_;

    bool ConfigureMemoryProtection(const PartitionConfig& config) {
        // Setup MPU regions for ARM or EPT for x86
        return hypervisor_api::SetMemoryRegion(
            config.memory_base,
            config.memory_size,
            MPU_ATTR_NO_ACCESS_FROM_OTHER_PARTITIONS
        );
    }

    bool ConfigureTimeSlice(const PartitionConfig& config) {
        return hypervisor_api::SetPartitionSchedule(
            config.name,
            config.time_slice_us,
            major_frame_us_,
            SCHEDULE_POLICY_STRICT_PARTITION
        );
    }

    bool MemoryOverlap(const PartitionConfig& a, const PartitionConfig& b) {
        uint64_t a_end = a.memory_base + a.memory_size;
        uint64_t b_end = b.memory_base + b.memory_size;
        return !(a_end <= b.memory_base || b_end <= a.memory_base);
    }

    bool CPUAffinityConflict(const PartitionConfig& a, const PartitionConfig& b) {
        for (auto cpu_a : a.cpu_affinity) {
            for (auto cpu_b : b.cpu_affinity) {
                if (cpu_a == cpu_b && a.asil_level >= ASIL::C && b.asil_level >= ASIL::C) {
                    return true;  // ASIL-C/D partitions cannot share CPUs
                }
            }
        }
        return false;
    }
};

} // namespace hpc
} // namespace automotive
```

### 3. Inter-VM Communication

**IVSHMEM (Inter-VM Shared Memory):**
```cpp
// High-performance zero-copy IPC using shared memory
#include <ivshmem/shared_region.h>
#include <atomic>
#include <cstring>

namespace automotive {
namespace ipc {

// Lock-free ring buffer for inter-VM sensor data
template<typename T, size_t Capacity>
class IVSHMEMRingBuffer {
public:
    explicit IVSHMEMRingBuffer(void* shmem_base)
        : region_(static_cast<SharedRegion*>(shmem_base)) {
        region_->write_idx.store(0, std::memory_order_release);
        region_->read_idx.store(0, std::memory_order_release);
    }

    // Producer: Write sensor data (from sensor VM to ADAS VM)
    bool Push(const T& item) {
        size_t current_write = region_->write_idx.load(std::memory_order_relaxed);
        size_t next_write = (current_write + 1) % Capacity;

        if (next_write == region_->read_idx.load(std::memory_order_acquire)) {
            return false;  // Buffer full
        }

        std::memcpy(&region_->buffer[current_write], &item, sizeof(T));
        region_->write_idx.store(next_write, std::memory_order_release);

        // Signal consumer VM via doorbell interrupt
        SignalDoorbell();
        return true;
    }

    // Consumer: Read sensor data
    bool Pop(T& item) {
        size_t current_read = region_->read_idx.load(std::memory_order_relaxed);

        if (current_read == region_->write_idx.load(std::memory_order_acquire)) {
            return false;  // Buffer empty
        }

        std::memcpy(&item, &region_->buffer[current_read], sizeof(T));
        size_t next_read = (current_read + 1) % Capacity;
        region_->read_idx.store(next_read, std::memory_order_release);
        return true;
    }

private:
    struct SharedRegion {
        std::atomic<size_t> write_idx;
        std::atomic<size_t> read_idx;
        alignas(64) T buffer[Capacity];
    };

    SharedRegion* region_;

    void SignalDoorbell() {
        // Write to doorbell register to trigger interrupt in consumer VM
        volatile uint32_t* doorbell = reinterpret_cast<uint32_t*>(0xFEDC0000);
        *doorbell = 1;
    }
};

// Usage example: Camera frame sharing
struct CameraFrame {
    uint64_t timestamp_us;
    uint32_t frame_id;
    uint32_t width;
    uint32_t height;
    uint8_t data[1920 * 1080 * 3];  // RGB888
};

// In Sensor VM (producer)
void SensorVMMain() {
    void* shmem = MapIVSHMEM("/dev/ivshmem0", 128 * 1024 * 1024);
    IVSHMEMRingBuffer<CameraFrame, 4> frame_queue(shmem);

    while (true) {
        CameraFrame frame = CaptureCamera();
        if (!frame_queue.Push(frame)) {
            LOG_WARN("Frame queue full, dropping frame");
        }
    }
}

// In ADAS VM (consumer)
void ADASVMMain() {
    void* shmem = MapIVSHMEM("/dev/ivshmem0", 128 * 1024 * 1024);
    IVSHMEMRingBuffer<CameraFrame, 4> frame_queue(shmem);

    CameraFrame frame;
    while (true) {
        if (frame_queue.Pop(frame)) {
            ProcessFrameForObjectDetection(frame);
        }
    }
}

} // namespace ipc
} // namespace automotive
```

### 4. Resource Management and Scheduling

**CPU Partitioning and Real-Time Scheduling:**
```python
#!/usr/bin/env python3
"""
HPC Platform Resource Manager
Manages CPU, memory, and I/O bandwidth across VMs
"""

import yaml
from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

class VMType(Enum):
    SAFETY_CRITICAL = "safety_critical"  # ASIL-C/D
    PERFORMANCE = "performance"          # ADAS, autonomous
    GENERAL_PURPOSE = "general_purpose"  # Infotainment, telematics

@dataclass
class CPUAllocation:
    vm_name: str
    physical_cores: List[int]
    vcpu_count: int
    scheduler: str  # 'rt-fifo', 'rt-rr', 'cfs'
    priority: int
    cpu_quota_percent: float

@dataclass
class MemoryAllocation:
    vm_name: str
    size_gb: float
    numa_node: int
    hugepages: bool
    swap_disabled: bool

class HPCResourceManager:
    def __init__(self, platform_config: str):
        with open(platform_config, 'r') as f:
            self.config = yaml.safe_load(f)

        self.total_cores = self.config['platform']['cpu_cores']
        self.total_memory_gb = self.config['platform']['memory_gb']
        self.allocations: Dict[str, Dict] = {}

    def allocate_vm_resources(self, vm_name: str, vm_type: VMType,
                             cpu_cores: int, memory_gb: float):
        """Allocate resources following ASIL requirements"""

        if vm_type == VMType.SAFETY_CRITICAL:
            # ASIL-C/D VMs get dedicated cores
            cpu_alloc = self._allocate_dedicated_cores(vm_name, cpu_cores)
            mem_alloc = self._allocate_locked_memory(vm_name, memory_gb)
        elif vm_type == VMType.PERFORMANCE:
            # Performance VMs get isolated cores with high priority
            cpu_alloc = self._allocate_isolated_cores(vm_name, cpu_cores)
            mem_alloc = self._allocate_hugepages_memory(vm_name, memory_gb)
        else:
            # General purpose VMs share remaining cores
            cpu_alloc = self._allocate_shared_cores(vm_name, cpu_cores)
            mem_alloc = self._allocate_standard_memory(vm_name, memory_gb)

        self.allocations[vm_name] = {
            'type': vm_type,
            'cpu': cpu_alloc,
            'memory': mem_alloc
        }

        return cpu_alloc, mem_alloc

    def _allocate_dedicated_cores(self, vm_name: str, count: int) -> CPUAllocation:
        """Dedicated cores for safety-critical VMs (ASIL-D)"""
        # Allocate from first available cores
        available = self._find_available_cores(count, dedicated=True)

        return CPUAllocation(
            vm_name=vm_name,
            physical_cores=available,
            vcpu_count=count,
            scheduler='rt-fifo',
            priority=99,  # Highest RT priority
            cpu_quota_percent=100.0
        )

    def _allocate_isolated_cores(self, vm_name: str, count: int) -> CPUAllocation:
        """Isolated cores for performance VMs (ADAS)"""
        available = self._find_available_cores(count, dedicated=False)

        return CPUAllocation(
            vm_name=vm_name,
            physical_cores=available,
            vcpu_count=count,
            scheduler='rt-rr',
            priority=50,
            cpu_quota_percent=90.0
        )

    def _allocate_locked_memory(self, vm_name: str, size_gb: float) -> MemoryAllocation:
        """Locked, non-swappable memory for safety VMs"""
        return MemoryAllocation(
            vm_name=vm_name,
            size_gb=size_gb,
            numa_node=0,
            hugepages=True,
            swap_disabled=True
        )

    def generate_systemd_config(self, vm_name: str) -> str:
        """Generate systemd unit file with resource limits"""
        alloc = self.allocations[vm_name]
        cpu = alloc['cpu']
        mem = alloc['memory']

        cores_list = ','.join(map(str, cpu.physical_cores))

        config = f"""
[Unit]
Description={vm_name} Virtual Machine
After=hypervisor.service

[Service]
Type=simple
ExecStart=/usr/bin/qemu-system-x86_64 \\
    -name {vm_name} \\
    -cpu host \\
    -smp {cpu.vcpu_count} \\
    -m {int(mem.size_gb * 1024)}M \\
    -mem-path /dev/hugepages \\
    -mem-prealloc \\
    -rtc base=utc,clock=host \\
    -drive file=/var/vms/{vm_name}.qcow2,if=virtio \\
    -netdev tap,id=net0,ifname=tap-{vm_name},script=no \\
    -device virtio-net-pci,netdev=net0

# CPU affinity
CPUAffinity={cores_list}

# CPU quota ({cpu.cpu_quota_percent}% of allocated cores)
CPUQuota={cpu.cpu_quota_percent * cpu.vcpu_count}%

# Memory limits
MemoryLimit={int(mem.size_gb * 1024)}M
MemorySwapMax=0

# Real-time scheduling (if safety critical)
{"CPUSchedulingPolicy=fifo" if cpu.scheduler == 'rt-fifo' else ""}
{"CPUSchedulingPriority=" + str(cpu.priority) if cpu.scheduler.startswith('rt-') else ""}

# Security
PrivateTmp=yes
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
"""
        return config

# Example usage
if __name__ == '__main__':
    manager = HPCResourceManager('platform_config.yaml')

    # Allocate ASIL-D ADAS VM
    cpu, mem = manager.allocate_vm_resources(
        'adas-safety',
        VMType.SAFETY_CRITICAL,
        cpu_cores=4,
        memory_gb=8.0
    )

    # Generate systemd service
    config = manager.generate_systemd_config('adas-safety')
    with open('/etc/systemd/system/vm-adas-safety.service', 'w') as f:
        f.write(config)

    print(f"Allocated cores {cpu.physical_cores} to ADAS VM")
    print(f"Memory: {mem.size_gb}GB, NUMA node: {mem.numa_node}")
```

## Use Cases

1. **Centralized ADAS Platform**: Run L3+ autonomous driving workloads in safety VMs alongside infotainment in QM VMs
2. **Gateway ECU Consolidation**: Combine multiple network domains (CAN, Ethernet, FlexRay) in isolated VMs
3. **Cockpit Domain Controller**: Instrument cluster, HMI, and Android Automotive on single SoC with GPU sharing
4. **OTA Update Isolation**: Separate update VM from running system for fail-safe updates

## Automotive Standards

- **ISO 26262**: ASIL-D certification for hypervisor TCB
- **ISO 21434**: Cybersecurity isolation between VMs
- **ASPICE CL3**: Process compliance for hypervisor development
- **AUTOSAR Adaptive**: Ara::exec for VM lifecycle management

## Tools Required

- **QNX Momentics IDE**: For QNX Hypervisor development
- **ACRN Configuration Tool**: Web-based hypervisor configurator
- **Xen Orchestra**: Management interface for Xen
- **libvirt/virsh**: VM lifecycle management
- **perf/ftrace**: Performance profiling and latency analysis

## Constraints

- **Real-time Latency**: <100µs interrupt latency for ASIL-D VMs
- **Memory Overhead**: <5% hypervisor overhead
- **FFI Guarantees**: ISO 26262 Part 6 clause 7 compliance
- **Deterministic Scheduling**: WCET guarantees for safety partitions

## Performance Metrics

- **VM Boot Time**: <500ms for safety VM cold boot
- **Context Switch**: <5µs VM-to-VM switch
- **Shared Memory Throughput**: >10GB/s IVSHMEM bandwidth
- **Interrupt Delivery**: <20µs doorbell latency

## References

- QNX Hypervisor 2.2 User Guide
- ACRN Hypervisor Documentation (projectacrn.org)
- Xen ARM Virtualization Extensions
- ISO 26262-6:2018 Clause 7 (Freedom from Interference)
- "Mixed-Criticality Systems on Multi-core" (WATERS 2019)

---

**Version:** 1.0.0
**Last Updated:** 2026-03-19
**Author:** Automotive Claude Code Agents

---

## Safety Certification Hpc

# Safety Certification for Automotive HPC Platforms

**Category:** automotive-hpc
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Comprehensive guide to ISO 26262 safety certification for High-Performance Computing platforms. Covers ASIL-D partitioning, Freedom from Interference (FFI), safety mechanisms, certification strategies, and evidence documentation.

## Core Competencies

### 1. ISO 26262 for HPC Platforms

**ISO 26262 Part 6 - Software Development:**
- **Clause 7**: Freedom From Interference
- **Clause 8**: Software Unit Design and Implementation
- **Clause 9**: Software Unit Testing
- **Clause 10**: Software Integration and Testing

**ASIL Decomposition on HPC:**
```
Single HPC SoC replacing multiple ECUs:
┌─────────────────────────────────────────────┐
│        NVIDIA DRIVE Orin / Snapdragon       │
├─────────────────────────────────────────────┤
│ Partition 1: ADAS (ASIL-D)                  │
│ - Decomposed to: ASIL-B(B) + ASIL-B(B)     │
│ - Dual-core lockstep execution              │
│ - E2E protection for inter-core comm        │
├─────────────────────────────────────────────┤
│ Partition 2: Instrument Cluster (ASIL-A)   │
│ - Warning lamps, speedometer                │
│ - Independent from ADAS partition           │
├─────────────────────────────────────────────┤
│ Partition 3: Infotainment (QM)              │
│ - No safety requirements                    │
│ - Resource limits enforced by hypervisor    │
└─────────────────────────────────────────────┘
```

### 2. ASIL-D Partitioning Strategy

**Hardware Partitioning:**
```cpp
// HPC Safety Partition Configuration
#include <iso26262/partition_manager.h>
#include <iso26262/ffi_validator.h>

namespace safety {
namespace hpc {

enum class ASILLevel {
    QM,   // Quality Management
    A,    // Lowest ASIL
    B,
    C,
    D     // Highest ASIL
};

struct SafetyPartition {
    std::string name;
    ASILLevel asil;
    std::vector<uint32_t> cpu_cores;
    uint64_t memory_base;
    uint64_t memory_size;
    std::vector<uint32_t> allowed_interrupts;
    bool mpu_enabled;
    bool ecc_enabled;
    bool lockstep_enabled;
};

class HPC_SafetyPartitionManager {
public:
    HPC_SafetyPartitionManager() {
        InitializePartitions();
        ValidateFFI();
    }

    void InitializePartitions() {
        // ASIL-D ADAS Partition (decomposed to 2x ASIL-B)
        SafetyPartition adas_partition_1 {
            .name = "ADAS-Perception-1",
            .asil = ASILLevel::B,
            .cpu_cores = {0, 1},  // Lockstep pair
            .memory_base = 0x8000'0000,
            .memory_size = 2ULL * 1024 * 1024 * 1024,  // 2GB
            .allowed_interrupts = {IRQ_CAN0, IRQ_CAMERA0, IRQ_LIDAR},
            .mpu_enabled = true,
            .ecc_enabled = true,
            .lockstep_enabled = true
        };

        SafetyPartition adas_partition_2 {
            .name = "ADAS-Perception-2",
            .asil = ASILLevel::B,
            .cpu_cores = {2, 3},  // Lockstep pair
            .memory_base = 0xC000'0000,
            .memory_size = 2ULL * 1024 * 1024 * 1024,  // 2GB
            .allowed_interrupts = {IRQ_CAN1, IRQ_CAMERA1, IRQ_RADAR},
            .mpu_enabled = true,
            .ecc_enabled = true,
            .lockstep_enabled = true
        };

        // Configure MPU for spatial isolation
        ConfigureMPU(adas_partition_1);
        ConfigureMPU(adas_partition_2);

        // Enable ECC for temporal fault detection
        EnableECC(adas_partition_1);
        EnableECC(adas_partition_2);

        // Configure lockstep cores for fault detection
        ConfigureLockstep(adas_partition_1);
        ConfigureLockstep(adas_partition_2);

        partitions_.push_back(adas_partition_1);
        partitions_.push_back(adas_partition_2);
    }

    void ConfigureMPU(const SafetyPartition& partition) {
        // MPU Configuration for ARM Cortex-A78
        // Region 0: Partition memory (RW, Executable)
        MPU_RegionConfig region_config {
            .base_address = partition.memory_base,
            .size = partition.memory_size,
            .access_permission = MPU_ACCESS_RW_NONE,  // No access from other cores
            .execute_never = false,
            .shareable = false,
            .cacheable = true
        };

        for (auto core : partition.cpu_cores) {
            SetMPURegion(core, 0, region_config);
        }

        // Region 1: Shared communication region (RW, Non-executable)
        MPU_RegionConfig shared_region {
            .base_address = 0xE000'0000,
            .size = 64 * 1024 * 1024,  // 64MB
            .access_permission = MPU_ACCESS_RW_RW,
            .execute_never = true,
            .shareable = true,
            .cacheable = false  // Uncached for inter-partition comm
        };

        for (auto core : partition.cpu_cores) {
            SetMPURegion(core, 1, shared_region);
        }
    }

    void EnableECC(const SafetyPartition& partition) {
        // Enable ECC on LPDDR5 memory for partition
        for (auto core : partition.cpu_cores) {
            // Enable ECC in memory controller
            WriteMemoryControllerReg(
                MEMORY_ECC_ENABLE_REG,
                partition.memory_base,
                partition.memory_size
            );

            // Register ECC error handler
            RegisterECCHandler(core, [partition](uint64_t error_addr) {
                HandleECCError(partition, error_addr);
            });
        }
    }

    void ConfigureLockstep(const SafetyPartition& partition) {
        if (!partition.lockstep_enabled || partition.cpu_cores.size() != 2) {
            return;
        }

        // Configure ARM Split-Lock mode (lockstep)
        uint32_t primary_core = partition.cpu_cores[0];
        uint32_t shadow_core = partition.cpu_cores[1];

        // Enable lockstep mode in SCU (Snoop Control Unit)
        EnableCoreLockstep(primary_core, shadow_core);

        // Configure lockstep comparator
        SetLockstepComparator(primary_core, shadow_core, [](uint32_t core_a, uint32_t core_b) {
            // Lockstep mismatch detected
            LOG_FATAL("Lockstep mismatch between core %d and %d", core_a, core_b);
            TriggerSafeState();
        });
    }

    void ValidateFFI() {
        FFI_Validator validator;

        // Validate spatial interference (memory)
        if (!validator.ValidateMemoryIsolation(partitions_)) {
            throw std::runtime_error("Memory isolation validation failed");
        }

        // Validate temporal interference (CPU time)
        if (!validator.ValidateTemporalIsolation(partitions_)) {
            throw std::runtime_error("Temporal isolation validation failed");
        }

        // Validate interrupt isolation
        if (!validator.ValidateInterruptIsolation(partitions_)) {
            throw std::runtime_error("Interrupt isolation validation failed");
        }

        LOG_INFO("FFI validation passed for all partitions");
    }

private:
    std::vector<SafetyPartition> partitions_;

    static void HandleECCError(const SafetyPartition& partition, uint64_t error_addr) {
        LOG_ERROR("ECC error in partition %s at address 0x%lx",
                  partition.name.c_str(), error_addr);

        // For ASIL-B/D: Trigger safe state
        if (partition.asil >= ASILLevel::B) {
            TriggerSafeState();
        }
    }

    static void TriggerSafeState() {
        // Transition vehicle to safe state
        // - Reduce speed
        // - Activate hazard lights
        // - Pull over
        LOG_FATAL("Entering safe state due to safety partition failure");
        // Implementation depends on vehicle platform
    }

    void SetMPURegion(uint32_t core, uint32_t region, const MPU_RegionConfig& config) {
        // Platform-specific MPU configuration
    }

    void EnableCoreLockstep(uint32_t core_a, uint32_t core_b) {
        // Platform-specific lockstep enable
    }

    void SetLockstepComparator(uint32_t core_a, uint32_t core_b, std::function<void(uint32_t, uint32_t)> handler) {
        // Platform-specific lockstep comparator
    }
};

} // namespace hpc
} // namespace safety
```

### 3. Freedom From Interference (FFI)

**FFI Requirements per ISO 26262-6 Clause 7:**

| Interference Type | Mechanism | ASIL-D Requirement |
|-------------------|-----------|-------------------|
| **Spatial (Memory)** | MPU/MMU | Hardware isolation |
| **Temporal (CPU Time)** | Time partitioning | Guaranteed time slots |
| **Communication** | E2E protection | CRC + alive counter |
| **Peripheral Access** | Access control list | Exclusive device ownership |
| **Interrupt** | Interrupt masking | Per-partition IRQ routing |

**End-to-End (E2E) Protection for Inter-Partition Communication:**
```cpp
// ISO 26262 E2E Profile for Inter-Partition Messages
#include <iso26262/e2e_protection.h>

namespace safety {
namespace e2e {

// E2E Profile 4 (used for AUTOSAR Adaptive)
struct E2E_Profile4_Header {
    uint16_t length;          // Message length
    uint16_t counter;         // Rolling counter (0-65535)
    uint32_t data_id;         // Unique message identifier
    uint32_t crc;             // CRC-32
} __attribute__((packed));

class E2E_Protector {
public:
    E2E_Protector(uint32_t data_id)
        : data_id_(data_id), counter_(0) {}

    // Protect outgoing message
    std::vector<uint8_t> Protect(const std::vector<uint8_t>& payload) {
        std::vector<uint8_t> protected_msg;

        // Construct header
        E2E_Profile4_Header header;
        header.length = static_cast<uint16_t>(payload.size());
        header.counter = counter_++;
        header.data_id = data_id_;

        // Compute CRC over header (excluding CRC field) + payload
        header.crc = ComputeCRC32(header, payload);

        // Serialize header + payload
        protected_msg.resize(sizeof(header) + payload.size());
        std::memcpy(protected_msg.data(), &header, sizeof(header));
        std::memcpy(protected_msg.data() + sizeof(header), payload.data(), payload.size());

        return protected_msg;
    }

    // Check incoming message
    E2E_CheckResult Check(const std::vector<uint8_t>& protected_msg) {
        if (protected_msg.size() < sizeof(E2E_Profile4_Header)) {
            return E2E_CheckResult::ERROR;
        }

        // Deserialize header
        E2E_Profile4_Header header;
        std::memcpy(&header, protected_msg.data(), sizeof(header));

        // Extract payload
        std::vector<uint8_t> payload(
            protected_msg.begin() + sizeof(header),
            protected_msg.end()
        );

        // Verify length
        if (header.length != payload.size()) {
            return E2E_CheckResult::ERROR;
        }

        // Verify CRC
        uint32_t expected_crc = header.crc;
        header.crc = 0;  // Clear CRC field before computation
        uint32_t computed_crc = ComputeCRC32(header, payload);

        if (expected_crc != computed_crc) {
            LOG_ERROR("E2E CRC mismatch: expected 0x%08x, got 0x%08x",
                     expected_crc, computed_crc);
            return E2E_CheckResult::ERROR;
        }

        // Verify counter (detect loss and duplication)
        E2E_CheckResult counter_result = CheckCounter(header.counter);
        if (counter_result != E2E_CheckResult::OK) {
            return counter_result;
        }

        last_valid_counter_ = header.counter;
        return E2E_CheckResult::OK;
    }

private:
    uint32_t data_id_;
    uint16_t counter_;
    uint16_t last_valid_counter_ = 0;

    E2E_CheckResult CheckCounter(uint16_t received_counter) {
        uint16_t expected_counter = (last_valid_counter_ + 1) % 65536;

        if (received_counter == expected_counter) {
            return E2E_CheckResult::OK;
        } else if (received_counter == last_valid_counter_) {
            return E2E_CheckResult::REPEATED;
        } else {
            LOG_WARN("E2E counter gap: expected %d, got %d",
                    expected_counter, received_counter);
            return E2E_CheckResult::WRONG_SEQUENCE;
        }
    }

    uint32_t ComputeCRC32(const E2E_Profile4_Header& header,
                         const std::vector<uint8_t>& payload) {
        // CRC-32/AUTOSAR polynomial: 0xF4ACFB13
        uint32_t crc = 0xFFFFFFFF;

        // CRC over header (excluding CRC field)
        const uint8_t* header_bytes = reinterpret_cast<const uint8_t*>(&header);
        for (size_t i = 0; i < offsetof(E2E_Profile4_Header, crc); ++i) {
            crc = UpdateCRC32(crc, header_bytes[i]);
        }

        // CRC over payload
        for (uint8_t byte : payload) {
            crc = UpdateCRC32(crc, byte);
        }

        return crc ^ 0xFFFFFFFF;
    }

    uint32_t UpdateCRC32(uint32_t crc, uint8_t byte) {
        // CRC-32 table lookup (AUTOSAR polynomial)
        static const uint32_t crc_table[256] = { /* ... */ };
        return (crc >> 8) ^ crc_table[(crc ^ byte) & 0xFF];
    }
};

enum class E2E_CheckResult {
    OK,
    ERROR,
    REPEATED,
    WRONG_SEQUENCE
};

} // namespace e2e
} // namespace safety
```

### 4. Safety Mechanisms for HPC

**Platform-Level Safety Mechanisms:**
```yaml
# ISO 26262 Safety Mechanisms for HPC
safety_mechanisms:
  hardware_level:
    - mechanism: "CPU Lockstep"
      target_fault: "Random hardware faults"
      diagnostic_coverage: 99%
      asil: D

    - mechanism: "ECC on LPDDR5"
      target_fault: "Single-bit memory errors"
      diagnostic_coverage: 99%
      asil: C

    - mechanism: "MPU/MMU Protection"
      target_fault: "Memory corruption"
      diagnostic_coverage: 99%
      asil: D

    - mechanism: "Watchdog Timer"
      target_fault: "Software hang"
      diagnostic_coverage: 90%
      asil: B

  software_level:
    - mechanism: "E2E Protection"
      target_fault: "Communication errors"
      diagnostic_coverage: 99%
      asil: D

    - mechanism: "Diverse Redundancy"
      target_fault: "Systematic software errors"
      diagnostic_coverage: 60%
      asil: C

    - mechanism: "Plausibility Checks"
      target_fault: "Sensor data corruption"
      diagnostic_coverage: 90%
      asil: B

    - mechanism: "Program Flow Monitoring"
      target_fault: "Control flow errors"
      diagnostic_coverage: 90%
      asil: C

  system_level:
    - mechanism: "ASIL Decomposition"
      target_fault: "Single point of failure"
      diagnostic_coverage: N/A
      asil: D

    - mechanism: "Safe State Transition"
      target_fault: "Detected failures"
      diagnostic_coverage: 99%
      asil: D
```

**Watchdog Supervision:**
```cpp
// Multi-level Watchdog for ASIL-D
#include <watchdog/supervisor.h>

namespace safety {
namespace watchdog {

class ASIL_D_WatchdogSupervisor {
public:
    ASIL_D_WatchdogSupervisor()
        : expected_alive_period_ms_(100),
          window_watchdog_min_ms_(80),
          window_watchdog_max_ms_(120) {

        InitializeHardwareWatchdog();
        InitializeSoftwareWatchdog();
    }

    // Application reports alive
    void ReportAlive(uint32_t partition_id) {
        auto now = std::chrono::steady_clock::now();

        // Check if alive report is within window
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
            now - last_alive_[partition_id]
        ).count();

        if (elapsed < window_watchdog_min_ms_) {
            LOG_ERROR("Watchdog violation: Alive too early (partition %d)", partition_id);
            TriggerWatchdogReset(partition_id);
            return;
        }

        if (elapsed > window_watchdog_max_ms_) {
            LOG_ERROR("Watchdog violation: Alive too late (partition %d)", partition_id);
            TriggerWatchdogReset(partition_id);
            return;
        }

        // Refresh hardware watchdog
        RefreshHardwareWatchdog();

        // Update timestamp
        last_alive_[partition_id] = now;
    }

    void MonitorLoop() {
        while (running_) {
            auto now = std::chrono::steady_clock::now();

            // Check each partition
            for (const auto& [partition_id, last_alive] : last_alive_) {
                auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                    now - last_alive
                ).count();

                if (elapsed > window_watchdog_max_ms_) {
                    LOG_ERROR("Watchdog timeout: Partition %d not responding", partition_id);
                    TriggerWatchdogReset(partition_id);
                }
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }

private:
    uint32_t expected_alive_period_ms_;
    uint32_t window_watchdog_min_ms_;
    uint32_t window_watchdog_max_ms_;
    std::map<uint32_t, std::chrono::steady_clock::time_point> last_alive_;
    bool running_ = true;

    void InitializeHardwareWatchdog() {
        // Configure external watchdog IC (e.g., TI TPS3840)
        // Timeout: 200ms
        ConfigureExternalWatchdog(200);
    }

    void InitializeSoftwareWatchdog() {
        // Start monitoring thread
        std::thread([this]() { MonitorLoop(); }).detach();
    }

    void RefreshHardwareWatchdog() {
        // Toggle watchdog input pin
        ToggleWatchdogPin();
    }

    void TriggerWatchdogReset(uint32_t partition_id) {
        LOG_FATAL("Triggering watchdog reset for partition %d", partition_id);

        // Option 1: Reset only the partition (if hypervisor supports it)
        ResetPartition(partition_id);

        // Option 2: Reset entire ECU (if ASIL-D requires it)
        // TriggerECUReset();
    }

    void ConfigureExternalWatchdog(uint32_t timeout_ms) {
        // Platform-specific
    }

    void ToggleWatchdogPin() {
        // Platform-specific
    }

    void ResetPartition(uint32_t partition_id) {
        // Platform-specific
    }
};

} // namespace watchdog
} // namespace safety
```

### 5. Safety Certification Process

**ISO 26262 V-Model for HPC:**
```
Development (Left side):          Verification (Right side):
┌──────────────────────────┐     ┌──────────────────────────┐
│ System Requirements      │────>│ System Integration Test  │
│ (ASIL-D ADAS)            │     │ (HIL, Vehicle)           │
└──────────────────────────┘     └──────────────────────────┘
        │                                   ▲
        ▼                                   │
┌──────────────────────────┐     ┌──────────────────────────┐
│ Software Architecture    │────>│ Software Integration Test│
│ (Partition Design)       │     │ (SIL, Test Bench)        │
└──────────────────────────┘     └──────────────────────────┘
        │                                   ▲
        ▼                                   │
┌──────────────────────────┐     ┌──────────────────────────┐
│ Software Detailed Design │────>│ Software Unit Test       │
│ (C++ Modules)            │     │ (GoogleTest, Coverage)   │
└──────────────────────────┘     └──────────────────────────┘
        │                                   ▲
        ▼                                   │
┌──────────────────────────┐              │
│ Implementation (Code)    │──────────────┘
└──────────────────────────┘
```

**Safety Case Artifacts:**
```python
#!/usr/bin/env python3
"""
Safety Case Evidence Generator for HPC Platform
Generates artifacts required for ISO 26262 certification
"""

from dataclasses import dataclass
from typing import List
from datetime import datetime

@dataclass
class SafetyRequirement:
    req_id: str
    description: str
    asil: str
    source: str  # ISO 26262 clause

@dataclass
class SafetyMechanism:
    mechanism_id: str
    name: str
    target_fault: str
    diagnostic_coverage: float
    verification_method: str

@dataclass
class TestCase:
    test_id: str
    requirement_id: str
    test_method: str  # Unit, Integration, System
    pass_criteria: str
    result: str  # PASS/FAIL
    evidence_path: str

class SafetyCaseGenerator:
    def __init__(self, project_name: str):
        self.project_name = project_name
        self.requirements: List[SafetyRequirement] = []
        self.mechanisms: List[SafetyMechanism] = []
        self.test_cases: List[TestCase] = []

    def add_requirement(self, req: SafetyRequirement):
        self.requirements.append(req)

    def add_safety_mechanism(self, mech: SafetyMechanism):
        self.mechanisms.append(mech)

    def add_test_case(self, test: TestCase):
        self.test_cases.append(test)

    def generate_safety_case(self, output_file: str):
        """Generate comprehensive safety case document"""
        with open(output_file, 'w') as f:
            f.write(f"# Safety Case for {self.project_name}\n\n")
            f.write(f"Generated: {datetime.now().isoformat()}\n\n")

            # Section 1: Safety Requirements
            f.write("## 1. Safety Requirements\n\n")
            f.write("| Req ID | Description | ASIL | Source |\n")
            f.write("|--------|-------------|------|--------|\n")
            for req in self.requirements:
                f.write(f"| {req.req_id} | {req.description} | {req.asil} | {req.source} |\n")

            # Section 2: Safety Mechanisms
            f.write("\n## 2. Safety Mechanisms\n\n")
            f.write("| Mechanism ID | Name | Target Fault | DC | Verification |\n")
            f.write("|--------------|------|--------------|----|--------------|\n")
            for mech in self.mechanisms:
                f.write(f"| {mech.mechanism_id} | {mech.name} | {mech.target_fault} | "
                       f"{mech.diagnostic_coverage*100:.0f}% | {mech.verification_method} |\n")

            # Section 3: Verification Results
            f.write("\n## 3. Verification Results\n\n")
            f.write("| Test ID | Requirement | Method | Pass Criteria | Result | Evidence |\n")
            f.write("|---------|-------------|--------|---------------|--------|----------|\n")
            for test in self.test_cases:
                f.write(f"| {test.test_id} | {test.requirement_id} | {test.test_method} | "
                       f"{test.pass_criteria} | {test.result} | {test.evidence_path} |\n")

            # Section 4: Traceability Matrix
            f.write("\n## 4. Requirements Traceability\n\n")
            self._generate_traceability_matrix(f)

            # Section 5: FMEA Results
            f.write("\n## 5. Failure Modes and Effects Analysis\n\n")
            self._generate_fmea_table(f)

    def _generate_traceability_matrix(self, f):
        f.write("| Requirement | Safety Mechanism | Test Cases | Coverage |\n")
        f.write("|-------------|------------------|------------|----------|\n")

        for req in self.requirements:
            # Find related mechanisms
            mechanisms = [m.mechanism_id for m in self.mechanisms]

            # Find related tests
            tests = [t.test_id for t in self.test_cases if t.requirement_id == req.req_id]

            coverage = f"{len(tests)} tests" if tests else "No coverage"
            f.write(f"| {req.req_id} | {', '.join(mechanisms[:2])} | "
                   f"{', '.join(tests[:3])} | {coverage} |\n")

    def _generate_fmea_table(self, f):
        f.write("| Failure Mode | Effect | Severity | Detection | Mitigation |\n")
        f.write("|--------------|--------|----------|-----------|------------|\n")
        f.write("| CPU core failure | Loss of ADAS | S3 | Lockstep | Redundant partition |\n")
        f.write("| Memory corruption | Data integrity | S3 | ECC | CRC checks |\n")
        f.write("| Hypervisor fault | System crash | S3 | Watchdog | Safe state |\n")

# Example usage
if __name__ == '__main__':
    generator = SafetyCaseGenerator("ADAS HPC Platform")

    # Add requirements
    generator.add_requirement(SafetyRequirement(
        req_id="SR-001",
        description="FFI between ASIL-D and QM partitions",
        asil="D",
        source="ISO 26262-6:7.4.2"
    ))

    generator.add_requirement(SafetyRequirement(
        req_id="SR-002",
        description="Diagnostic coverage >99% for hardware faults",
        asil="D",
        source="ISO 26262-5:8.4.3"
    ))

    # Add safety mechanisms
    generator.add_safety_mechanism(SafetyMechanism(
        mechanism_id="SM-001",
        name="CPU Lockstep",
        target_fault="Random hardware faults in CPU",
        diagnostic_coverage=0.99,
        verification_method="Fault injection testing"
    ))

    generator.add_safety_mechanism(SafetyMechanism(
        mechanism_id="SM-002",
        name="Memory ECC",
        target_fault="Single-bit memory errors",
        diagnostic_coverage=0.99,
        verification_method="ECC error injection"
    ))

    # Add test cases
    generator.add_test_case(TestCase(
        test_id="TC-001",
        requirement_id="SR-001",
        test_method="Integration Test",
        pass_criteria="No memory access violations detected",
        result="PASS",
        evidence_path="test_results/tc001_ffi_validation.log"
    ))

    # Generate safety case document
    generator.generate_safety_case("safety_case.md")
    print("Safety case generated: safety_case.md")
```

## Use Cases

1. **ASIL-D ADAS Platform Certification**: Certify perception/planning on HPC SoC
2. **Zonal Controller Safety**: Multi-ASIL partitioning for zone ECU
3. **OTA Update Safety**: Demonstrate safe software updates without re-certification
4. **Mixed-Criticality Cockpit**: ASIL-A cluster + QM IVI on single platform

## Automotive Standards

- **ISO 26262-6:2018**: Software development at the component level
- **ISO 26262-8:2018**: Supporting processes (safety analysis)
- **ISO 26262-9:2018**: ASIL-oriented and safety-oriented analyses
- **ISO 26262-11:2018**: Application of ISO 26262 to semiconductors

## Tools Required

- **medini analyze**: FMEA and FTA tool
- **LDRA**: Static analysis and unit test (TÜV certified)
- **Vector CANoe**: HIL testing with fault injection
- **QNX Safety Hypervisor**: Pre-certified hypervisor (ASIL-D)

## Performance Metrics

- **Diagnostic Coverage**: >99% for ASIL-D single-point faults
- **Fault Latency**: <10ms detection and reaction time
- **Safe State Transition**: <100ms from fault detection to safe state
- **MPU Overhead**: <1% CPU utilization

## References

- ISO 26262-6:2018 Software Development
- "Safety Certification for Multi-Core Automotive Systems" (SAE Paper 2020-01-0729)
- NVIDIA DRIVE OS Safety Manual
- QNX Hypervisor 2.2 Safety Manual (ISO 26262 ASIL-D)

---

**Version:** 1.0.0
**Last Updated:** 2026-03-19
**Author:** Automotive Claude Code Agents

---

## Vehicle Compute Platforms

# Vehicle Central Compute Platforms

**Category:** automotive-hpc
**Version:** 1.0.0
**Maturity:** production
**Complexity:** advanced

## Overview

Comprehensive guide to automotive High-Performance Computing (HPC) SoC platforms for Software-Defined Vehicles. Covers NVIDIA DRIVE, Qualcomm Snapdragon Ride, NXP S32 family, performance benchmarks, thermal management, and power budgets.

## HPC Platform Comparison

### Platform Overview Table

| Platform | CPU | GPU | NPU/AI | Memory | TOPS | TDP | Use Case |
|----------|-----|-----|--------|--------|------|-----|----------|
| **NVIDIA DRIVE Orin** | 12-core ARM Cortex-A78AE | Ampere GPU (2048 CUDA) | 2x DLA | 32GB LPDDR5 | 254 | 60W | L3+ AD, ADAS |
| **NVIDIA DRIVE Thor** | 16-core Grace CPU | Ada GPU | NvDLA v3 | 128GB | 2000 | 300W | L4/L5 AD |
| **Qualcomm Snapdragon Ride** | 8-core Kryo 780 | Adreno 740 | Hexagon 780 | 64GB LPDDR5 | 700 | 65W | ADAS, Cockpit |
| **NXP S32G3** | 8-core Cortex-A53 | PowerVR | - | 16GB DDR4 | - | 12W | Gateway, ADAS |
| **NXP S32Z/E** | 16-core Cortex-R52 | - | - | 8GB DDR4 | - | 20W | Safety Domain |
| **Renesas R-Car V4H** | 8-core Cortex-A76 | IMG PowerVR | CNN-IP | 32GB LPDDR4X | 80 | 40W | ADAS, Cockpit |
| **Intel Atom x7000RE** | 8-core x86 | Xe GPU | VPU | 32GB LPDDR5 | 60 | 35W | IVI, Telematics |

---

## 1. NVIDIA DRIVE Platform

### NVIDIA DRIVE Orin

**Specifications:**
- **CPU**: 12-core ARM Cortex-A78AE (ISO 26262 ASIL-D)
- **GPU**: NVIDIA Ampere architecture, 2048 CUDA cores, RT cores
- **DLA**: 2x Deep Learning Accelerators (70 TOPS each)
- **AI Performance**: 254 TOPS INT8
- **Memory**: 32GB LPDDR5, 204.8 GB/s bandwidth
- **Video**: 8x 4K60 cameras, H.265 encode/decode
- **Interfaces**: 16-lane PCIe Gen4, 10GbE, CAN-FD
- **Safety**: ISO 26262 ASIL-D, lockstep CPU cores

**DRIVE OS Software Stack:**
```
┌─────────────────────────────────────────────┐
│      Autonomous Driving Applications        │
├─────────────────────────────────────────────┤
│  DriveWorks SDK (Perception, Planning)      │
│  - Object detection, tracking, fusion       │
│  - Path planning, behavior prediction       │
├─────────────────────────────────────────────┤
│  CUDA, TensorRT, cuDNN (AI Inference)       │
├─────────────────────────────────────────────┤
│  DRIVE OS (Linux + RTOS)                    │
│  - Safety partition (QNX/Integrity)         │
│  - Performance partition (Ubuntu)           │
├─────────────────────────────────────────────┤
│  Hypervisor (NVIDIA vGPU)                   │
└─────────────────────────────────────────────┘
```

**DriveWorks Example - Object Detection:**
```cpp
// NVIDIA DriveWorks - YOLO Object Detection on Orin
#include <dw/core/Context.h>
#include <dw/sensors/camera/Camera.h>
#include <dw/object/Detector.h>
#include <dw/dnn/DNN.h>

namespace nvidia {
namespace adas {

class ObjectDetector {
public:
    ObjectDetector() {
        // Initialize DriveWorks context
        dwContextParameters ctx_params{};
        ctx_params.enableCudaLogging = true;
        dwInitialize(&context_, DW_VERSION, &ctx_params);

        // Load DNN model (YOLO) optimized for Orin
        dwDNNModelHandle_t model;
        dwDNN_initializeTensorFlowModel(&model, "/models/yolo_v5_fp16.trt", context_);

        // Create object detector
        dwObjectDetectorParams detector_params{};
        detector_params.maxNumObjects = 100;
        detector_params.enableTracking = true;
        dwObjectDetector_initialize(&detector_, model, context_);

        // Initialize camera
        dwSensorParams camera_params{};
        camera_params.protocol = "camera.gmsl";
        camera_params.parameters = "device=0,output-format=yuv420";
        dwSAL_createSensor(&camera_, camera_params, sal_);
    }

    void ProcessFrame() {
        // Capture camera frame
        dwCameraFrameHandle_t frame;
        dwSensorCamera_getImage(&frame, DW_CAMERA_OUTPUT_CUDA_YUV420, camera_);

        // Run object detection on DLA
        dwObjectArray detected_objects;
        dwObjectDetector_processDeviceAsync(&detected_objects, frame, detector_);

        // Wait for DLA completion
        dwObjectDetector_processDeviceSync(detector_);

        // Process detected objects
        for (uint32_t i = 0; i < detected_objects.size; ++i) {
            const auto& obj = detected_objects.objects[i];
            ProcessDetection(obj);
        }

        // Release frame
        dwSensorCamera_returnImage(&frame, camera_);
    }

    void ProcessDetection(const dwObject& obj) {
        std::cout << "Object: " << GetClassLabel(obj.classLabel)
                  << " Confidence: " << obj.confidence
                  << " BBox: (" << obj.box.x << "," << obj.box.y << ","
                  << obj.box.width << "," << obj.box.height << ")"
                  << std::endl;
    }

    ~ObjectDetector() {
        dwObjectDetector_release(detector_);
        dwSAL_releaseSensor(camera_);
        dwRelease(context_);
    }

private:
    dwContextHandle_t context_;
    dwSALHandle_t sal_;
    dwSensorHandle_t camera_;
    dwObjectDetectorHandle_t detector_;

    std::string GetClassLabel(uint32_t label) {
        static const std::vector<std::string> labels = {
            "car", "truck", "pedestrian", "bicycle", "motorcycle"
        };
        return labels[label];
    }
};

} // namespace adas
} // namespace nvidia

int main() {
    nvidia::adas::ObjectDetector detector;

    // Process at 30Hz
    while (true) {
        detector.ProcessFrame();
        std::this_thread::sleep_for(std::chrono::milliseconds(33));
    }

    return 0;
}
```

**Performance Benchmarks (NVIDIA Orin):**
```yaml
# Orin Performance Profile
model: NVIDIA DRIVE AGX Orin
soc: Parker

benchmarks:
  yolo_v5_detection:
    precision: FP16
    input: 1920x1080
    accelerator: DLA
    throughput: 60 FPS
    latency: 16ms
    power: 15W

  resnet50_classification:
    precision: INT8
    input: 224x224
    accelerator: DLA
    throughput: 2000 FPS
    latency: 0.5ms
    power: 8W

  pointpillar_lidar:
    precision: FP16
    points: 100K
    accelerator: GPU
    throughput: 30 FPS
    latency: 33ms
    power: 25W

  end_to_end_perception:
    cameras: 8x 4K
    lidar: 64-beam
    radar: 4x continental
    total_latency: 80ms
    total_power: 55W
    tops_utilized: 180
```

### NVIDIA DRIVE Thor

**Next-Generation Platform (2025+):**
- **2000 TOPS AI Performance**: 8x Orin capability
- **Unified Architecture**: Single chip for all vehicle computing
- **Grace CPU**: ARM Neoverse V2 cores
- **Ada GPU**: Latest RTX architecture
- **Consolidated**: Replaces 6-8 ECUs with single SoC

**Thor Use Cases:**
```python
# NVIDIA DRIVE Thor - Consolidated Architecture
platform = {
    'soc': 'NVIDIA DRIVE Thor',
    'consolidated_functions': [
        {
            'domain': 'Autonomous Driving',
            'workloads': ['Perception', 'Planning', 'Control'],
            'tops_allocated': 1200,
            'safety_level': 'ASIL-D'
        },
        {
            'domain': 'ADAS',
            'workloads': ['ACC', 'LKA', 'AEB', 'Parking'],
            'tops_allocated': 300,
            'safety_level': 'ASIL-B'
        },
        {
            'domain': 'Cockpit',
            'workloads': ['IVI', 'Cluster', 'HUD', 'Cameras'],
            'tops_allocated': 200,
            'safety_level': 'QM'
        },
        {
            'domain': 'Body/Comfort',
            'workloads': ['Lighting', 'HVAC', 'Access'],
            'tops_allocated': 50,
            'safety_level': 'QM'
        },
        {
            'domain': 'Connectivity',
            'workloads': ['Telematics', 'V2X', 'OTA'],
            'tops_allocated': 50,
            'safety_level': 'QM'
        }
    ],
    'isolation': 'Hardware virtualization + Hypervisor',
    'total_power': '300W @ peak, 150W @ typical'
}
```

---

## 2. Qualcomm Snapdragon Ride Platform

**Snapdragon Ride Flex SoC:**
- **CPU**: Kryo 780 (ARM Cortex-A78 based), 8 cores @ 3.0 GHz
- **GPU**: Adreno 740 (Vulkan, OpenCL)
- **AI**: Hexagon 780 DSP, 700 TOPS INT8
- **ISP**: Spectra 18-bit triple ISP, 12x cameras
- **Connectivity**: 5G modem, C-V2X, Wi-Fi 6E
- **Safety**: ISO 26262 ASIL-D support

**Snapdragon Software Stack:**
```cpp
// Qualcomm SNPE (Snapdragon Neural Processing Engine)
#include <SNPE/SNPE.hpp>
#include <SNPE/SNPEFactory.hpp>
#include <DlContainer/IDlContainer.hpp>

namespace qualcomm {
namespace adas {

class SNPEInference {
public:
    SNPEInference(const std::string& model_path) {
        // Load DLC (Deep Learning Container)
        container_ = zdl::DlContainer::IDlContainer::open(model_path);

        // Build SNPE network
        zdl::SNPE::SNPEBuilder builder(container_.get());

        // Configure runtime (DSP > GPU > CPU)
        builder.setRuntimeProcessorOrder({
            zdl::DlSystem::Runtime_t::DSP,
            zdl::DlSystem::Runtime_t::GPU,
            zdl::DlSystem::Runtime_t::CPU
        });

        // Set performance profile
        builder.setPerformanceProfile(
            zdl::DlSystem::PerformanceProfile_t::SUSTAINED_HIGH_PERFORMANCE
        );

        // Build network
        snpe_ = builder.build();

        if (snpe_ == nullptr) {
            throw std::runtime_error("Failed to build SNPE network");
        }
    }

    std::vector<float> Infer(const std::vector<float>& input) {
        // Create input tensor
        auto input_shape = snpe_->getInputDimensions();
        zdl::DlSystem::ITensor* input_tensor =
            zdl::SNPE::SNPEFactory::getTensorFactory().createTensor(input_shape);

        // Copy input data
        std::copy(input.begin(), input.end(),
                  input_tensor->begin());

        // Execute inference on Hexagon DSP
        snpe_->execute(input_tensor, output_map_);

        // Extract output
        zdl::DlSystem::ITensor* output_tensor =
            output_map_.getTensor(output_map_.getTensorNames()[0]);

        std::vector<float> output(output_tensor->begin(), output_tensor->end());
        return output;
    }

private:
    std::unique_ptr<zdl::DlContainer::IDlContainer> container_;
    std::unique_ptr<zdl::SNPE::SNPE> snpe_;
    zdl::DlSystem::TensorMap output_map_;
};

} // namespace adas
} // namespace qualcomm
```

**Snapdragon Performance:**
```yaml
snapdragon_ride_flex:
  ai_performance: 700 TOPS INT8
  camera_support: 12x simultaneous
  display_output: 4x 4K60

  benchmark_results:
    mobilenet_v2:
      precision: INT8
      accelerator: Hexagon DSP
      throughput: 5000 FPS
      latency: 0.2ms
      power: 3W

    efficientdet_d2:
      precision: FP16
      accelerator: Adreno GPU
      throughput: 45 FPS
      latency: 22ms
      power: 12W

    lane_detection:
      model: Ultra-Fast-Lane
      accelerator: Hexagon DSP
      throughput: 90 FPS
      latency: 11ms
      power: 5W
```

---

## 3. NXP S32 Platform Family

### NXP S32G3 (Gateway & Vehicle Networking)

**Specifications:**
- **CPU**: 8-core ARM Cortex-A53 @ 1.0 GHz
- **Networking**: 8x Ethernet (up to 10GbE), 16x CAN-FD
- **Memory**: Up to 16GB DDR4
- **Safety**: ISO 26262 ASIL-B lockstep cores
- **HSE**: Hardware Security Engine for secure boot

**S32G3 Gateway Application:**
```cpp
// NXP S32G - Secure Gateway with HSE
#include <s32g/hse_interface.h>
#include <s32g/netc_driver.h>

namespace nxp {
namespace gateway {

class SecureGateway {
public:
    SecureGateway() {
        // Initialize Hardware Security Engine
        InitializeHSE();

        // Configure NETC (Network Controller)
        InitializeNetworking();
    }

    void InitializeHSE() {
        // HSE firmware installation
        HSE_InstallFirmware(hse_firmware_bin, firmware_size);

        // Configure secure boot
        HSE_ConfigureSecureBoot({
            .enable_secure_boot = true,
            .key_store = HSE_KEY_STORE_RAM,
            .boot_auth_algorithm = HSE_AUTH_SCHEME_RSA2048
        });

        // Setup MAC authentication for CAN/Ethernet
        HSE_ConfigureMACGeneration(HSE_MAC_ALGO_CMAC_AES128);
    }

    void InitializeNetworking() {
        // Configure 10GbE for zonal architecture
        NETC_ConfigureEthernet({
            .port = NETC_PORT_0,
            .speed = NETC_SPEED_10G,
            .mode = NETC_MODE_SWITCH,
            .vlan_support = true,
            .time_sync = NETC_PTP_SLAVE  // IEEE 1588 PTP
        });

        // Configure CAN-FD gateway
        NETC_ConfigureCANGateway({
            .can_ports = {NETC_CAN_0, NETC_CAN_1, NETC_CAN_2},
            .routing_rules = LoadRoutingTable(),
            .frame_authentication = true  // Use HSE for MAC
        });
    }

    void RouteMessage(const CANMessage& msg) {
        // Authenticate incoming CAN message using HSE
        if (!AuthenticateMessage(msg)) {
            LogSecurityEvent("Invalid CAN message authentication");
            return;
        }

        // Route to appropriate network
        auto route = routing_table_.Lookup(msg.id);
        if (route.target_network == NetworkType::ETHERNET) {
            ForwardToEthernet(msg, route.target_address);
        } else if (route.target_network == NetworkType::CAN) {
            ForwardToCAN(msg, route.target_bus);
        }
    }

private:
    bool AuthenticateMessage(const CANMessage& msg) {
        // Extract MAC from message
        uint8_t received_mac[16];
        ExtractMAC(msg, received_mac);

        // Compute expected MAC using HSE
        uint8_t expected_mac[16];
        HSE_ComputeMAC(msg.data, msg.length, expected_mac);

        return std::memcmp(received_mac, expected_mac, 16) == 0;
    }

    void ForwardToEthernet(const CANMessage& msg, uint32_t target_ip) {
        // Encapsulate CAN in SOME/IP or DDS
        EthernetFrame frame = EncapsulateCANInSOMEIP(msg);
        NETC_SendEthernetFrame(NETC_PORT_0, frame);
    }

    RoutingTable routing_table_;
};

} // namespace gateway
} // namespace nxp
```

### NXP S32Z/E (Real-Time & Safety)

**Specifications:**
- **CPU**: 16-core ARM Cortex-R52 @ 800 MHz (lockstep pairs)
- **Safety**: ISO 26262 ASIL-D
- **Real-Time**: Deterministic execution, hardware semaphores
- **Use Cases**: Safety domain controller, real-time control

---

## 4. Thermal Management

**Thermal Control Strategy:**
```python
#!/usr/bin/env python3
"""
HPC Thermal Management for Automotive
Prevents thermal throttling while maintaining performance
"""

import time
from dataclasses import dataclass
from typing import List

@dataclass
class ThermalZone:
    name: str
    sensor_path: str
    trip_points: List[int]  # [warning, critical, shutdown]
    cooling_devices: List[str]

class ThermalManager:
    def __init__(self):
        self.zones = {
            'cpu': ThermalZone(
                name='CPU Package',
                sensor_path='/sys/class/thermal/thermal_zone0/temp',
                trip_points=[85, 95, 105],  # °C
                cooling_devices=['cpu_fan', 'cpu_freq']
            ),
            'gpu': ThermalZone(
                name='GPU Core',
                sensor_path='/sys/class/thermal/thermal_zone1/temp',
                trip_points=[80, 90, 100],
                cooling_devices=['gpu_fan', 'gpu_freq']
            ),
            'dla': ThermalZone(
                name='DLA Accelerator',
                sensor_path='/sys/class/thermal/thermal_zone2/temp',
                trip_points=[85, 95, 105],
                cooling_devices=['system_fan', 'dla_throttle']
            )
        }

    def monitor_and_control(self):
        """Main thermal control loop (1Hz)"""
        while True:
            for zone_name, zone in self.zones.items():
                temp = self.read_temperature(zone)

                if temp >= zone.trip_points[2]:
                    # Shutdown threshold
                    self.emergency_shutdown(zone)
                elif temp >= zone.trip_points[1]:
                    # Critical: aggressive throttling
                    self.apply_aggressive_cooling(zone)
                elif temp >= zone.trip_points[0]:
                    # Warning: moderate throttling
                    self.apply_moderate_cooling(zone)
                else:
                    # Normal: restore performance
                    self.restore_performance(zone)

            time.sleep(1.0)

    def read_temperature(self, zone: ThermalZone) -> float:
        """Read temperature from sysfs (in milli-degrees)"""
        with open(zone.sensor_path, 'r') as f:
            temp_millidegrees = int(f.read().strip())
        return temp_millidegrees / 1000.0

    def apply_aggressive_cooling(self, zone: ThermalZone):
        """Critical temperature: max cooling"""
        print(f"CRITICAL: {zone.name} at {self.read_temperature(zone)}°C")

        # Set fan to 100%
        self.set_fan_speed('system_fan', 100)

        # Reduce CPU/GPU frequency to 50%
        if 'cpu_freq' in zone.cooling_devices:
            self.set_frequency_limit('cpu', 0.5)
        if 'gpu_freq' in zone.cooling_devices:
            self.set_frequency_limit('gpu', 0.5)

        # Throttle DLA workload
        if 'dla_throttle' in zone.cooling_devices:
            self.throttle_dla_workload(0.5)

    def apply_moderate_cooling(self, zone: ThermalZone):
        """Warning temperature: moderate cooling"""
        print(f"WARNING: {zone.name} at {self.read_temperature(zone)}°C")

        # Set fan to 70%
        self.set_fan_speed('system_fan', 70)

        # Reduce frequency to 80%
        if 'cpu_freq' in zone.cooling_devices:
            self.set_frequency_limit('cpu', 0.8)
        if 'gpu_freq' in zone.cooling_devices:
            self.set_frequency_limit('gpu', 0.8)

    def restore_performance(self, zone: ThermalZone):
        """Normal temperature: full performance"""
        # Fan at baseline (40%)
        self.set_fan_speed('system_fan', 40)

        # Restore full frequency
        self.set_frequency_limit('cpu', 1.0)
        self.set_frequency_limit('gpu', 1.0)
        self.throttle_dla_workload(1.0)

    def set_fan_speed(self, fan: str, percent: int):
        """Set fan PWM duty cycle"""
        pwm_path = f'/sys/class/hwmon/hwmon0/{fan}'
        with open(pwm_path, 'w') as f:
            f.write(str(int(255 * percent / 100)))

    def set_frequency_limit(self, component: str, ratio: float):
        """Set frequency scaling governor"""
        if component == 'cpu':
            path = '/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq'
            max_freq = 2400000  # 2.4 GHz
        elif component == 'gpu':
            path = '/sys/class/drm/card0/device/pp_dpm_sclk'
            max_freq = 1500000  # 1.5 GHz

        target_freq = int(max_freq * ratio)
        with open(path, 'w') as f:
            f.write(str(target_freq))

    def throttle_dla_workload(self, ratio: float):
        """Reduce DLA workload by skipping frames"""
        # Application-level throttling
        pass

    def emergency_shutdown(self, zone: ThermalZone):
        """Emergency thermal shutdown"""
        print(f"EMERGENCY SHUTDOWN: {zone.name} exceeded safe limits")
        # Trigger graceful shutdown
        import subprocess
        subprocess.run(['systemctl', 'poweroff'])

if __name__ == '__main__':
    manager = ThermalManager()
    manager.monitor_and_control()
```

## Power Budget Management

**Platform Power Profiles:**
```yaml
# Power management for NVIDIA Orin in production vehicle
orin_power_budget:
  max_tdp: 60W
  cooling: Liquid cold plate (0.2 °C/W)

  power_states:
    parking_mode:
      cpu_cores: 2
      cpu_freq: 1.2 GHz
      gpu_active: false
      dla_active: false
      power: 8W
      use_case: "Parking assist, surround view"

    driving_mode:
      cpu_cores: 12
      cpu_freq: 2.2 GHz
      gpu_active: true
      dla_active: true
      dla_utilization: 80%
      power: 45W
      use_case: "Full ADAS, L3 autonomous"

    charging_mode:
      cpu_cores: 4
      cpu_freq: 1.8 GHz
      gpu_active: false
      dla_active: false
      power: 15W
      use_case: "OTA updates, diagnostics"

  power_optimization:
    - "Dynamic Voltage Frequency Scaling (DVFS)"
    - "Clock gating for idle IP blocks"
    - "DLA preferred over GPU (5x power efficiency)"
    - "Camera ISP pipeline optimization"
```

## Use Cases

1. **L3+ Autonomous Driving**: NVIDIA Orin for sensor fusion and path planning
2. **Zonal Architecture Gateway**: NXP S32G3 for network consolidation
3. **Cockpit Domain Controller**: Qualcomm Snapdragon Ride for IVI + cluster
4. **Safety Domain**: NXP S32Z/E for ASIL-D real-time control

## References

- NVIDIA DRIVE Orin Product Brief
- Qualcomm Snapdragon Ride Platform Overview
- NXP S32 Automotive Platform Family
- "Automotive SoC Benchmarks" (MLPerf Inference)

---

**Version:** 1.0.0
**Last Updated:** 2026-03-19
**Author:** Automotive Claude Code Agents
