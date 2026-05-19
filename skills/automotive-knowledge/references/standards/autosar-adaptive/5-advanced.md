# AUTOSAR Adaptive Platform - Advanced Topics

## Platform Health Management (PHM)

PHM monitors application health, detects failures, and coordinates recovery actions across the platform.

### Health Supervision Architecture

```
┌─────────────────────────────────────────────┐
│          Applications                        │
│  ┌──────┐  ┌──────┐  ┌──────┐              │
│  │ App1 │  │ App2 │  │ App3 │              │
│  └──┬───┘  └──┬───┘  └──┬───┘              │
│     │         │         │                    │
│     └─────────┴─────────┘                    │
│            ↓ Checkpoints                     │
└─────────────────────────────────────────────┘
         ↓ Health Status
┌─────────────────────────────────────────────┐
│   Platform Health Management                 │
│   - Global Supervision                       │
│   - Recovery Actions                         │
│   - State Coordination                       │
└─────────────────────────────────────────────┘
         ↓ State Changes
┌─────────────────────────────────────────────┐
│   State Management (ara::exec)               │
│   - Function Groups                          │
│   - State Machines                           │
└─────────────────────────────────────────────┘
```

### Supervision Types Implementation

#### Alive Supervision

Application must report "alive" periodically within expected supervision cycle.

```cpp
#include <ara/phm/supervisioned_entity.h>
#include <ara/phm/health_channel.h>

class RobustApplication {
public:
    void Initialize() {
        // Create supervised entity
        auto se_result = ara::phm::SupervisionedEntity::Create(
            ara::core::InstanceSpecifier("MyApp/SupervisedEntity"));

        if (se_result.HasValue()) {
            supervised_entity_ = std::move(se_result.Value());

            // Create health channel for alive supervision
            auto channel_result = supervised_entity_->CreateHealthChannel(
                ara::core::InstanceSpecifier("MyApp/AliveChannel"));

            if (channel_result.HasValue()) {
                alive_channel_ = std::move(channel_result.Value());
            }
        }
    }

    void Run() {
        while (running_) {
            // Report alive within supervision cycle (e.g., every 100ms)
            auto result = alive_channel_->ReportCheckpoint(
                ara::phm::CheckpointId::kAlive);

            if (!result.HasValue()) {
                logger_.LogError() << "Failed to report alive";
            }

            ProcessWork();
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
        }
    }

private:
    std::unique_ptr<ara::phm::SupervisionedEntity> supervised_entity_;
    std::unique_ptr<ara::phm::HealthChannel> alive_channel_;
};
```

**Manifest Configuration**:
```json
{
  "AliveSupervision": {
    "shortName": "AliveChannel",
    "expectedAliveIndications": 10,
    "expectedSupervisionCycle": 100,
    "maxMargin": 10,
    "minMargin": 10,
    "supervisionMode": "ALIVE"
  }
}
```

#### Deadline Supervision

Operation must complete within specified time limit.

```cpp
class DataProcessor {
public:
    void ProcessData(const SensorData& data) {
        // Report start of supervised operation
        auto start_result = deadline_channel_->ReportCheckpoint(
            ara::phm::CheckpointId(1));  // Start checkpoint

        // Perform processing
        auto processed = HeavyComputation(data);

        // Report completion
        auto end_result = deadline_channel_->ReportCheckpoint(
            ara::phm::CheckpointId(2));  // End checkpoint

        if (!end_result.HasValue()) {
            logger_.LogWarn() << "Deadline supervision reporting failed";
        }
    }

private:
    std::unique_ptr<ara::phm::HealthChannel> deadline_channel_;
};
```

**Manifest Configuration**:
```json
{
  "DeadlineSupervision": {
    "shortName": "ProcessingDeadline",
    "transitions": [
      {
        "sourceCheckpoint": 1,
        "targetCheckpoint": 2,
        "minDeadline": 10,
        "maxDeadline": 100
      }
    ],
    "supervisionMode": "DEADLINE"
  }
}
```

#### Logical Supervision

Application-specific health checks based on internal state.

```cpp
class SensorMonitor {
public:
    void MonitorSensors() {
        bool all_sensors_ok = true;

        for (auto& sensor : sensors_) {
            if (!sensor.IsHealthy()) {
                all_sensors_ok = false;
                logger_.LogWarn() << "Sensor " << sensor.GetId()
                                 << " unhealthy";
            }
        }

        // Report logical supervision result
        if (all_sensors_ok) {
            logical_channel_->ReportCheckpoint(
                ara::phm::CheckpointId::kLogicalOk);
        } else {
            logical_channel_->ReportCheckpoint(
                ara::phm::CheckpointId::kLogicalError);
        }
    }

private:
    std::unique_ptr<ara::phm::HealthChannel> logical_channel_;
    std::vector<Sensor> sensors_;
};
```

### Recovery Actions

PHM triggers recovery when supervision fails.

**Recovery Strategies**:

1. **Process Restart**: Restart failed application
2. **Function Group Restart**: Restart group of related applications
3. **Machine Restart**: Reboot entire ECU
4. **Safe State**: Enter degraded safe operation mode

**Manifest Configuration**:
```json
{
  "RecoveryViaApplicationAction": {
    "shortName": "RestartApp",
    "recoveryAction": "RESTART_PROCESS",
    "maxNumberOfRetries": 3,
    "retryInterval": 1000
  },
  "RecoveryViaFunctionGroupState": {
    "shortName": "EnterSafeMode",
    "functionGroup": "DrivingMode",
    "targetState": "SafeState"
  }
}
```

## Update and Configuration Management (UCM)

UCM manages software updates, including OTA (Over-The-Air) updates for Adaptive applications.

### Update Package Structure

```
update_package.swp
├── manifest.json          # Package metadata
├── applications/
│   ├── BatteryMgmt_v2.0/
│   │   ├── executable
│   │   ├── manifest.json
│   │   └── signatures/
│   └── ADAS_v1.5/
│       ├── executable
│       └── manifest.json
├── configurations/
│   ├── network_config.json
│   └── calibration_data.bin
└── signature.p7s          # Package signature
```

### UCM Client API

```cpp
#include <ara/ucm/update_client.h>

class SoftwareUpdateManager {
public:
    void Initialize() {
        auto ucm_result = ara::ucm::UpdateClient::Create();
        if (ucm_result.HasValue()) {
            ucm_client_ = std::move(ucm_result.Value());
        }
    }

    void InstallUpdate(const std::string& package_path) {
        logger_.LogInfo() << "Starting software update";

        // Transfer update package
        auto transfer_result = ucm_client_->TransferStart(package_path);
        if (!transfer_result.HasValue()) {
            logger_.LogError() << "Transfer failed";
            return;
        }

        auto transfer_id = transfer_result.Value();

        // Monitor transfer progress
        MonitorTransfer(transfer_id);

        // Activate update (may require reboot)
        auto activate_result = ucm_client_->Activate(transfer_id);
        if (activate_result.HasValue()) {
            logger_.LogInfo() << "Update activated successfully";

            // Finish update
            ucm_client_->Finish(transfer_id);
        }
    }

    void RollbackUpdate(ara::ucm::TransferId transfer_id) {
        // Rollback to previous version
        auto result = ucm_client_->Rollback(transfer_id);
        if (result.HasValue()) {
            logger_.LogInfo() << "Rollback successful";
        }
    }

private:
    void MonitorTransfer(ara::ucm::TransferId id) {
        ara::ucm::TransferState state;
        do {
            auto state_result = ucm_client_->GetTransferState(id);
            if (state_result.HasValue()) {
                state = state_result.Value();
                logger_.LogDebug() << "Transfer progress: "
                                  << state.progress_percent << "%";
            }
            std::this_thread::sleep_for(std::chrono::seconds(1));
        } while (state.state != ara::ucm::TransferStateType::kTransferred);
    }

    std::unique_ptr<ara::ucm::UpdateClient> ucm_client_;
};
```

### Update Verification

**Security Checks**:
1. Package signature verification (cryptographic)
2. Application signature verification
3. Version compatibility check
4. Dependency resolution
5. Rollback capability verification

```cpp
// UCM performs these checks internally
// Application can query verification status
auto verify_result = ucm_client_->VerifyUpdate(transfer_id);
if (verify_result.HasValue()) {
    auto status = verify_result.Value();
    if (status.signature_valid &&
        status.dependencies_satisfied &&
        status.version_compatible) {
        ProceedWithActivation();
    }
}
```

## Identity and Access Management (IAM)

IAM provides authentication and authorization for adaptive applications and service communication.

### Authentication

```cpp
#include <ara/iam/identity.h>
#include <ara/iam/authenticator.h>

class SecureService {
public:
    void Initialize() {
        // Get authenticator instance
        auto auth_result = ara::iam::Authenticator::Create();
        if (auth_result.HasValue()) {
            authenticator_ = std::move(auth_result.Value());
        }

        // Register authentication handler
        skeleton_->SetAuthenticationHandler(
            [this](ara::iam::Identity caller_id) {
                return this->AuthenticateClient(caller_id);
            }
        );
    }

private:
    bool AuthenticateClient(ara::iam::Identity caller_id) {
        // Verify client identity
        auto verify_result = authenticator_->Verify(caller_id);

        if (verify_result.HasValue() && verify_result.Value()) {
            logger_.LogInfo() << "Client authenticated: "
                             << caller_id.ToString();
            return true;
        }

        logger_.LogWarn() << "Authentication failed for: "
                         << caller_id.ToString();
        return false;
    }

    std::unique_ptr<ara::iam::Authenticator> authenticator_;
};
```

### Authorization (RBAC)

Role-Based Access Control for service methods.

```cpp
#include <ara/iam/authorizer.h>

class BatteryControlService {
public:
    void SetupAuthorization() {
        // Get authorizer
        auto auth_result = ara::iam::Authorizer::Create();
        authorizer_ = std::move(auth_result.Value());

        // Configure method permissions
        skeleton_->SetChargeControl.SetAuthorizationHandler(
            [this](ara::iam::Identity caller) {
                return this->AuthorizeChargeControl(caller);
            }
        );
    }

private:
    bool AuthorizeChargeControl(ara::iam::Identity caller) {
        // Check if caller has "BatteryOperator" role
        ara::iam::Permission required_permission(
            "battery.control.charge");

        auto check_result = authorizer_->CheckPermission(
            caller, required_permission);

        if (check_result.HasValue() && check_result.Value()) {
            logger_.LogInfo() << "Authorized: " << caller.ToString();
            return true;
        }

        logger_.LogWarn() << "Access denied for: " << caller.ToString();
        return false;
    }

    std::unique_ptr<ara::iam::Authorizer> authorizer_;
};
```

**IAM Manifest Configuration**:
```json
{
  "IAM": {
    "roles": [
      {
        "name": "BatteryOperator",
        "permissions": [
          "battery.control.charge",
          "battery.control.discharge",
          "battery.monitoring.read"
        ]
      },
      {
        "name": "BatteryViewer",
        "permissions": [
          "battery.monitoring.read"
        ]
      }
    ],
    "identityToRoleMapping": [
      {
        "identity": "ControllerApp",
        "roles": ["BatteryOperator"]
      },
      {
        "identity": "DashboardApp",
        "roles": ["BatteryViewer"]
      }
    ]
  }
}
```

## Multi-Binding Communication

Support multiple transport protocols simultaneously for same service.

### Scenario: SOME/IP + DDS

Service offers both SOME/IP (for legacy ECUs) and DDS (for high-performance applications).

**Service Instance Manifest**:
```json
{
  "ServiceInstanceManifest": {
    "shortName": "SensorFusion_Multi",
    "serviceInterface": "SensorFusion",
    "providedServiceInstances": [
      {
        "bindingType": "SOMEIP",
        "someipBinding": {
          "serviceId": 100,
          "instanceId": 1
        },
        "networkEndpoint": {
          "ipAddress": "192.168.1.10",
          "port": 30501,
          "protocol": "UDP"
        }
      },
      {
        "bindingType": "DDS",
        "ddsBinding": {
          "topicName": "SensorFusionData",
          "qosProfile": "HighReliability"
        },
        "domainId": 0
      }
    ]
  }
}
```

**Proxy Discovery**:
```cpp
// Client discovers service regardless of binding
auto find_handle = ara::com::FindService<SensorFusionProxy>(
    ara::core::InstanceSpecifier("SensorFusion/RPort"));

// Framework selects best available binding
// Priority configurable in manifest
```

## Safety-Security Integration

Combining ISO 26262 (safety) and ISO 21434 (security) requirements.

### Safety-Critical Service with Security

```cpp
class SafetyControlService {
public:
    void Initialize() {
        // Safety: E2E protection for data integrity
        ConfigureE2EProtection();

        // Security: Authentication and encryption
        ConfigureSecurity();

        // Safety: PHM supervision
        SetupHealthSupervision();
    }

private:
    void ConfigureE2EProtection() {
        // E2E Profile 4 (CRC-32) for safety
        // Configured in manifest
    }

    void ConfigureSecurity() {
        // Enable TLS for SOME/IP
        // Require client authentication
        skeleton_->EnableSecureConnection(
            ara::com::SecurityLevel::kAuthenticatedEncrypted);

        // Set authentication handler
        skeleton_->SetAuthenticationHandler(
            [this](ara::iam::Identity id) {
                return VerifyClientCertificate(id);
            }
        );
    }

    void SetupHealthSupervision() {
        // Alive supervision with tight deadlines
        supervised_entity_->CreateHealthChannel(
            ara::core::InstanceSpecifier("Safety/AliveChannel"));

        // Deadline supervision for critical operations
        supervised_entity_->CreateHealthChannel(
            ara::core::InstanceSpecifier("Safety/DeadlineChannel"));
    }

    bool VerifyClientCertificate(ara::iam::Identity caller) {
        // Check certificate against safety-critical whitelist
        // Ensure caller is safety-certified component
        return certificate_validator_.VerifySafetyCert(caller);
    }
};
```

**Manifest Integration**:
```json
{
  "SafetyAndSecurityConfig": {
    "e2eProtection": {
      "profile": "Profile4",
      "dataId": 42
    },
    "secureConnection": {
      "tlsVersion": "1.3",
      "cipherSuites": ["TLS_AES_256_GCM_SHA384"],
      "requireClientCert": true
    },
    "healthSupervision": {
      "aliveSupervision": {
        "expectedCycle": 50,
        "maxMargin": 5
      },
      "deadlineSupervision": {
        "maxDeadline": 100
      }
    },
    "asil": "ASIL-D",
    "cybersecurityLevel": "CAL3"
  }
}
```

## Deterministic Execution (Time-Sensitive Networking)

Ensuring deterministic timing for real-time safety functions.

### Time Synchronization

```cpp
#include <ara/tsync/synchronized_time_base.h>

class RealtimeController {
public:
    void Initialize() {
        // Get synchronized time base (e.g., gPTP)
        auto timebase_result = ara::tsync::SynchronizedTimeBase::Create(
            ara::core::InstanceSpecifier("GlobalTime/gPTP"));

        if (timebase_result.HasValue()) {
            timebase_ = std::move(timebase_result.Value());
        }
    }

    void ExecuteCyclicControl() {
        while (running_) {
            // Get synchronized timestamp
            auto now_result = timebase_->GetCurrentTime();
            if (now_result.HasValue()) {
                auto timestamp = now_result.Value();

                // Schedule next execution at precise time
                auto next_cycle = timestamp + cycle_time_;
                SleepUntil(next_cycle);

                // Execute control algorithm
                PerformControl();
            }
        }
    }

private:
    std::unique_ptr<ara::tsync::SynchronizedTimeBase> timebase_;
    ara::core::Duration cycle_time_{std::chrono::milliseconds(10)};
};
```

### SOME/IP-SD with TSN

Configuration for time-sensitive service discovery:

```json
{
  "TSNConfiguration": {
    "serviceDiscovery": {
      "offerDelay": 0,
      "offerCyclicDelay": 1000,
      "ttl": 3
    },
    "streamReservation": {
      "trafficClass": 6,
      "vlanId": 100,
      "maxLatency": 2000,
      "maxFrameSize": 1500
    }
  }
}
```

## Best Practices Summary

### Performance Optimization

1. **Zero-copy communication**: Use `SamplePtr::Allocate()` for event publishing
2. **Minimize serialization**: Use efficient binary protocols (SOME/IP)
3. **Connection pooling**: Reuse TCP connections for methods
4. **Event batching**: Group multiple samples in single transmission

### Security Hardening

1. **Principle of least privilege**: Grant minimal required permissions
2. **Defense in depth**: Layer E2E + TLS + authentication
3. **Audit logging**: Log all security-relevant events
4. **Secure boot**: Verify UCM update signatures

### Safety Assurance

1. **Redundant supervision**: Combine alive + deadline + logical
2. **Graceful degradation**: Define safe states for failures
3. **Diagnostic coverage**: Monitor E2E error rates
4. **Fail-operational**: Implement recovery before fail-safe

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Senior AUTOSAR Adaptive architects, safety/security engineers
