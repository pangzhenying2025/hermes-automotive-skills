# AUTOSAR Adaptive Platform - Detailed Implementation Guide

## Service Development Workflow

### Step 1: Define Service Interface

Create service interface description (ARXML or JSON):

```xml
<!-- BatteryMonitor.arxml -->
<SERVICE-INTERFACE>
  <SHORT-NAME>BatteryMonitor</SHORT-NAME>
  <MAJOR-VERSION>1</MAJOR-VERSION>
  <MINOR-VERSION>0</MINOR-VERSION>

  <METHODS>
    <CLIENT-SERVER-OPERATION>
      <SHORT-NAME>GetCellVoltages</SHORT-NAME>
      <ARGUMENTS>
        <ARGUMENT-DATA-PROTOTYPE>
          <SHORT-NAME>voltages</SHORT-NAME>
          <TYPE-TREF>/DataTypes/VoltageArray</TYPE-TREF>
          <DIRECTION>OUT</DIRECTION>
        </ARGUMENT-DATA-PROTOTYPE>
      </ARGUMENTS>
      <POSSIBLE-ERROR-REFS>
        <POSSIBLE-ERROR-REF>/Errors/SensorFailure</POSSIBLE-ERROR-REF>
      </POSSIBLE-ERROR-REFS>
    </CLIENT-SERVER-OPERATION>
  </METHODS>

  <EVENTS>
    <VARIABLE-DATA-PROTOTYPE>
      <SHORT-NAME>CriticalAlarm</SHORT-NAME>
      <TYPE-TREF>/DataTypes/AlarmData</TYPE-TREF>
    </VARIABLE-DATA-PROTOTYPE>
  </EVENTS>

  <FIELDS>
    <FIELD>
      <SHORT-NAME>BatteryTemperature</SHORT-NAME>
      <TYPE-TREF>/DataTypes/Temperature</TYPE-TREF>
      <HAS-GETTER>true</HAS-GETTER>
      <HAS-SETTER>false</HAS-SETTER>
      <HAS-NOTIFIER>true</HAS-NOTIFIER>
    </FIELD>
  </FIELDS>
</SERVICE-INTERFACE>
```

### Step 2: Generate Skeleton and Proxy

Use AUTOSAR code generator to create C++ skeleton and proxy classes from interface definition:

```bash
# Example using Vector DaVinci Generator
generator --input BatteryMonitor.arxml \
          --output src/generated \
          --language cpp \
          --binding someip
```

Generated files:
```
src/generated/
├── battery_monitor_skeleton.h
├── battery_monitor_skeleton.cpp
├── battery_monitor_proxy.h
├── battery_monitor_proxy.cpp
└── battery_monitor_types.h
```

### Step 3: Implement Service Skeleton

Server-side implementation:

```cpp
// battery_monitor_service.h
#include "generated/battery_monitor_skeleton.h"
#include <ara/log/logger.h>
#include <memory>
#include <vector>

class BatteryMonitorService {
public:
    BatteryMonitorService();
    ~BatteryMonitorService();

    void Initialize();
    void Run();
    void Shutdown();

private:
    // Service skeleton instance
    std::unique_ptr<BatteryMonitorSkeleton> skeleton_;

    // Logger
    ara::log::Logger& logger_;

    // Method handler implementations
    ara::core::Future<GetCellVoltagesOutput> GetCellVoltagesHandler();

    // Field update logic
    void UpdateTemperatureField();

    // Event trigger logic
    void CheckAndPublishAlarms();

    // Internal state
    std::vector<double> cell_voltages_;
    double current_temperature_;
    bool running_;
};
```

```cpp
// battery_monitor_service.cpp
#include "battery_monitor_service.h"
#include <ara/exec/execution_client.h>
#include <chrono>
#include <thread>

BatteryMonitorService::BatteryMonitorService()
    : logger_(ara::log::CreateLogger("BTMS", "Battery Monitor Service"))
{
}

void BatteryMonitorService::Initialize() {
    logger_.LogInfo() << "Initializing Battery Monitor Service";

    // Create skeleton with instance identifier
    ara::core::InstanceSpecifier instanceSpec("BatteryMonitor/PPort");
    skeleton_ = std::make_unique<BatteryMonitorSkeleton>(instanceSpec);

    // Register method handler
    skeleton_->GetCellVoltages.SetMethodCallHandler(
        [this]() {
            return this->GetCellVoltagesHandler();
        }
    );

    // Initialize field with current value
    skeleton_->BatteryTemperature.Update(current_temperature_);

    // Offer service (make discoverable)
    skeleton_->OfferService();

    logger_.LogInfo() << "Service offered successfully";
}

ara::core::Future<GetCellVoltagesOutput>
BatteryMonitorService::GetCellVoltagesHandler() {
    logger_.LogDebug() << "GetCellVoltages called";

    // Read from hardware or internal state
    if (cell_voltages_.empty()) {
        // Return error
        ara::core::ErrorCode error(ErrorDomain::kApplicationError,
                                   ErrorCode::kSensorFailure);
        return ara::core::Future<GetCellVoltagesOutput>::FromError(error);
    }

    // Prepare output
    GetCellVoltagesOutput output;
    output.voltages = cell_voltages_;

    // Return successful result
    return ara::core::Future<GetCellVoltagesOutput>::FromValue(output);
}

void BatteryMonitorService::UpdateTemperatureField() {
    // Read temperature from sensor
    double new_temp = ReadTemperatureSensor();

    // Update only if changed significantly
    if (std::abs(new_temp - current_temperature_) > 0.5) {
        current_temperature_ = new_temp;

        // Update field (triggers notification to subscribers)
        skeleton_->BatteryTemperature.Update(current_temperature_);

        logger_.LogDebug() << "Temperature updated: " << current_temperature_;
    }
}

void BatteryMonitorService::CheckAndPublishAlarms() {
    // Check for critical conditions
    for (size_t i = 0; i < cell_voltages_.size(); ++i) {
        if (cell_voltages_[i] > 4.25 || cell_voltages_[i] < 2.5) {
            // Create alarm data
            AlarmData alarm;
            alarm.cell_id = i;
            alarm.voltage = cell_voltages_[i];
            alarm.severity = AlarmSeverity::kCritical;
            alarm.timestamp = std::chrono::system_clock::now();

            // Publish event
            skeleton_->CriticalAlarm.Send(alarm);

            logger_.LogWarn() << "Critical alarm for cell " << i
                             << ": " << cell_voltages_[i] << "V";
        }
    }
}

void BatteryMonitorService::Run() {
    running_ = true;

    while (running_) {
        // Periodic updates (10 Hz)
        UpdateTemperatureField();
        CheckAndPublishAlarms();

        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

void BatteryMonitorService::Shutdown() {
    logger_.LogInfo() << "Shutting down Battery Monitor Service";

    running_ = false;

    // Stop offering service
    skeleton_->StopOfferService();

    skeleton_.reset();
}

// Main entry point
int main() {
    // Initialize Execution Management
    auto exec_client = ara::exec::ExecutionClient::Create();
    exec_client->ReportExecutionState(ara::exec::ExecutionState::kRunning);

    // Create and run service
    BatteryMonitorService service;
    service.Initialize();
    service.Run();
    service.Shutdown();

    return 0;
}
```

### Step 4: Implement Service Proxy (Client)

Client-side implementation:

```cpp
// battery_monitor_client.h
#include "generated/battery_monitor_proxy.h"
#include <ara/log/logger.h>
#include <memory>

class BatteryMonitorClient {
public:
    BatteryMonitorClient();
    ~BatteryMonitorClient();

    void Initialize();
    void Run();
    void Shutdown();

private:
    // Service proxy instance
    std::unique_ptr<BatteryMonitorProxy> proxy_;

    // Logger
    ara::log::Logger& logger_;

    // Service discovery
    void FindService();
    void OnServiceAvailable(ara::com::ServiceHandleContainer<BatteryMonitorProxy::HandleType> services);

    // Method call example
    void RequestCellVoltages();

    // Event subscription example
    void SubscribeToAlarms();
    void OnAlarmReceived(const AlarmData& alarm);

    // Field subscription example
    void SubscribeToTemperature();
    void OnTemperatureChanged(double temperature);

    bool service_available_;
};
```

```cpp
// battery_monitor_client.cpp
#include "battery_monitor_client.h"

BatteryMonitorClient::BatteryMonitorClient()
    : logger_(ara::log::CreateLogger("BTMC", "Battery Monitor Client")),
      service_available_(false)
{
}

void BatteryMonitorClient::Initialize() {
    logger_.LogInfo() << "Initializing Battery Monitor Client";

    FindService();
}

void BatteryMonitorClient::FindService() {
    logger_.LogInfo() << "Searching for Battery Monitor service";

    // Start service discovery
    ara::core::InstanceSpecifier instanceSpec("BatteryMonitor/RPort");

    auto findHandle = ara::com::FindService<BatteryMonitorProxy>(instanceSpec);

    // Set callback for when services are found
    findHandle.SetFindServiceHandler(
        [this](auto services, auto findHandle) {
            this->OnServiceAvailable(services);
        }
    );

    ara::com::StartFindService(findHandle,
                               ara::com::FindServiceHandler::kServiceAvailable);
}

void BatteryMonitorClient::OnServiceAvailable(
    ara::com::ServiceHandleContainer<BatteryMonitorProxy::HandleType> services) {

    if (services.size() == 0) {
        logger_.LogWarn() << "No Battery Monitor service found";
        return;
    }

    logger_.LogInfo() << "Found " << services.size() << " service instance(s)";

    // Create proxy for first available service
    proxy_ = std::make_unique<BatteryMonitorProxy>(services[0]);
    service_available_ = true;

    // Subscribe to events and fields
    SubscribeToAlarms();
    SubscribeToTemperature();

    logger_.LogInfo() << "Connected to Battery Monitor service";
}

void BatteryMonitorClient::RequestCellVoltages() {
    if (!service_available_) {
        logger_.LogWarn() << "Service not available";
        return;
    }

    logger_.LogDebug() << "Requesting cell voltages";

    // Call method (returns Future)
    auto future = proxy_->GetCellVoltages();

    // Wait for response (blocking)
    auto result = future.GetResult();

    if (result.HasValue()) {
        auto voltages = result.Value().voltages;
        logger_.LogInfo() << "Received " << voltages.size() << " cell voltages";

        for (size_t i = 0; i < voltages.size(); ++i) {
            logger_.LogDebug() << "Cell " << i << ": " << voltages[i] << "V";
        }
    } else {
        logger_.LogError() << "Method call failed: " << result.Error();
    }
}

void BatteryMonitorClient::SubscribeToAlarms() {
    logger_.LogInfo() << "Subscribing to critical alarms";

    // Set event receive handler
    proxy_->CriticalAlarm.SetReceiveHandler(
        [this]() {
            proxy_->CriticalAlarm.GetNewSamples(
                [this](auto sample) {
                    this->OnAlarmReceived(*sample);
                }
            );
        }
    );

    // Subscribe to event
    proxy_->CriticalAlarm.Subscribe(10);  // Max 10 samples in queue
}

void BatteryMonitorClient::OnAlarmReceived(const AlarmData& alarm) {
    logger_.LogWarn() << "Critical alarm received: Cell " << alarm.cell_id
                     << " at " << alarm.voltage << "V";

    // Take action based on alarm severity
    if (alarm.severity == AlarmSeverity::kCritical) {
        // Emergency response
        HandleCriticalAlarm(alarm);
    }
}

void BatteryMonitorClient::SubscribeToTemperature() {
    logger_.LogInfo() << "Subscribing to temperature field";

    // Set field update handler
    proxy_->BatteryTemperature.SetReceiveHandler(
        [this]() {
            auto result = proxy_->BatteryTemperature.GetNewSamples(1);
            if (result.HasValue() && result.Value().size() > 0) {
                this->OnTemperatureChanged(result.Value()[0]);
            }
        }
    );

    // Subscribe to field notifications
    proxy_->BatteryTemperature.Subscribe(1);

    // Also get current value immediately
    auto current = proxy_->BatteryTemperature.Get();
    if (current.HasValue()) {
        logger_.LogInfo() << "Current temperature: " << current.Value() << "°C";
    }
}

void BatteryMonitorClient::OnTemperatureChanged(double temperature) {
    logger_.LogDebug() << "Temperature updated: " << temperature << "°C";

    // Check against thresholds
    if (temperature > 60.0) {
        logger_.LogWarn() << "High temperature warning";
    }
}

void BatteryMonitorClient::Run() {
    while (true) {
        if (service_available_) {
            RequestCellVoltages();
        }

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
}

void BatteryMonitorClient::Shutdown() {
    logger_.LogInfo() << "Shutting down Battery Monitor Client";

    if (proxy_) {
        // Unsubscribe from events
        proxy_->CriticalAlarm.Unsubscribe();
        proxy_->BatteryTemperature.Unsubscribe();

        proxy_.reset();
    }
}
```

## E2E Protection Implementation

### Enable E2E in Manifest

```json
{
  "ServiceInterface": "BatteryMonitor",
  "Events": [
    {
      "EventName": "CriticalAlarm",
      "E2EProfile": "Profile4",
      "E2EConfiguration": {
        "DataIdMode": "16bit",
        "DataId": 42,
        "CounterOffset": 0,
        "CRCOffset": 4,
        "MaxDeltaCounter": 5
      }
    }
  ]
}
```

### Skeleton E2E Protection

```cpp
// E2E protection happens automatically in generated skeleton
skeleton_->CriticalAlarm.Send(alarm);
// Framework adds:
// - Counter (incremented for each send)
// - CRC-32 calculated over payload
// - Timestamp (optional)
```

### Proxy E2E Validation

```cpp
proxy_->CriticalAlarm.SetReceiveHandler([this]() {
    proxy_->CriticalAlarm.GetNewSamples(
        [](auto sample) {
            // Check E2E status
            auto e2e_status = sample.GetE2EStatus();

            if (e2e_status == ara::com::E2EStatus::kOk) {
                // Data valid, use it
                ProcessAlarm(*sample);
            } else if (e2e_status == ara::com::E2EStatus::kRepeated) {
                // Duplicate message, ignore
            } else if (e2e_status == ara::com::E2EStatus::kWrongSequence) {
                // Message lost, handle gap
                logger_.LogWarn() << "Message loss detected";
            } else {
                // CRC error or timeout
                logger_.LogError() << "E2E validation failed";
            }
        }
    );
});
```

## Persistency Usage

### Key-Value Storage

```cpp
#include <ara/per/key_value_storage.h>

class ConfigurationManager {
public:
    void SaveConfiguration() {
        // Open storage
        auto storage = ara::per::OpenKeyValueStorage("VehicleConfig");

        if (storage.HasValue()) {
            auto kv = storage.Value();

            // Store simple types
            kv->SetValue("MaxSpeed", 120);
            kv->SetValue("VehicleId", std::string("VIN123456"));
            kv->SetValue("CalibrationDate", std::chrono::system_clock::now());

            // Store complex types (serialized)
            CalibrationData cal_data = GetCalibrationData();
            kv->SetValue("CalibrationData", SerializeToBytes(cal_data));

            // Synchronize to persistent storage
            kv->SyncToStorage();
        }
    }

    void LoadConfiguration() {
        auto storage = ara::per::OpenKeyValueStorage("VehicleConfig");

        if (storage.HasValue()) {
            auto kv = storage.Value();

            auto max_speed = kv->GetValue<int>("MaxSpeed");
            if (max_speed.HasValue()) {
                logger_.LogInfo() << "Max speed: " << max_speed.Value();
            }

            auto vehicle_id = kv->GetValue<std::string>("VehicleId");
            // ... use values
        }
    }
};
```

### File Storage

```cpp
#include <ara/per/file_storage.h>

class LogFileManager {
public:
    void WriteLog(const std::string& message) {
        auto storage = ara::per::OpenFileStorage("ApplicationLogs");

        if (storage.HasValue()) {
            auto fs = storage.Value();

            // Open file for append
            auto file = fs->OpenFileWriteOnly("application.log",
                                              ara::per::OpenMode::kAppend);

            if (file.HasValue()) {
                std::string timestamp = GetTimestamp();
                std::string log_entry = timestamp + " " + message + "\n";

                file.Value()->Write(
                    reinterpret_cast<const ara::core::Byte*>(log_entry.data()),
                    log_entry.size()
                );
            }
        }
    }

    std::vector<std::string> ReadLogs() {
        std::vector<std::string> logs;
        auto storage = ara::per::OpenFileStorage("ApplicationLogs");

        if (storage.HasValue()) {
            auto fs = storage.Value();
            auto file = fs->OpenFileReadOnly("application.log");

            if (file.HasValue()) {
                auto size = file.Value()->GetSize();
                std::vector<ara::core::Byte> buffer(size);

                file.Value()->Read(buffer.data(), size);

                // Parse buffer into lines
                std::string content(buffer.begin(), buffer.end());
                logs = SplitLines(content);
            }
        }

        return logs;
    }
};
```

## Deployment Configuration

### Service Instance Deployment

```json
{
  "ServiceInstanceDeployments": [
    {
      "ServiceInstance": "BatteryMonitor_1",
      "ServiceInterface": "BatteryMonitor",
      "InstanceId": "101",
      "EventDeployments": [
        {
          "Event": "CriticalAlarm",
          "TransportProtocol": "SOME/IP-UDP",
          "Port": 30501,
          "Serialization": "SOME/IP"
        }
      ],
      "MethodDeployments": [
        {
          "Method": "GetCellVoltages",
          "TransportProtocol": "SOME/IP-TCP",
          "Port": 30502
        }
      ]
    }
  ]
}
```

### Machine Deployment

```json
{
  "ProcessToMachineMapping": [
    {
      "Process": "BatteryManagementProcess",
      "Machine": "ECU_Battery",
      "Design": {
        "ApplicationEntries": [
          {
            "Application": "BatteryMonitorService",
            "ExecutablePath": "/opt/apps/battery_monitor",
            "StartupConfig": {
              "StartupOption": "Automatic",
              "FunctionGroup": "DrivingMode"
            }
          }
        ]
      }
    }
  ]
}
```

## Next Steps

- **Level 4**: Complete API reference for all ara:: namespaces
- **Level 5**: Advanced topics - multi-binding, identity management, update and configuration management

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: AUTOSAR Adaptive Platform developers implementing services
