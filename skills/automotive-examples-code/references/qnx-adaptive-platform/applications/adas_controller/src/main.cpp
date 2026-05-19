/**
 * @file main.cpp
 * @brief ADAS Controller Application - Reference Implementation
 *
 * Demonstrates:
 * - Service discovery and consumption (ara::com Proxy)
 * - Event subscription
 * - Real-time processing (20ms cycle)
 * - Execution management (ara::exec)
 * - Logging (ara::log)
 *
 * @copyright Copyright (c) 2026 Automotive Reference Implementation
 * @license Apache 2.0
 *
 * Platform: QNX Neutrino 7.1+
 * Real-time: SCHED_FIFO priority 80
 */

#include "ara/exec/execution_client.h"
#include "ara/log/logger.h"
#include "ara/com/com_error_domain.h"
#include "radar_proxy.h"
#include "camera_proxy.h"
#include "vehicle_dynamics_proxy.h"
#include "adas_commands_skeleton.h"

#include <signal.h>
#include <sched.h>
#include <sys/neutrino.h>
#include <sys/mman.h>
#include <thread>
#include <chrono>
#include <atomic>
#include <memory>
#include <vector>

namespace {
    std::atomic<bool> g_shutdown_requested{false};

    void SignalHandler(int sig) {
        if (sig == SIGTERM || sig == SIGINT) {
            g_shutdown_requested.store(true);
        }
    }

    /**
     * @brief Lock memory to prevent paging (real-time requirement)
     */
    void LockMemoryForRealtime() {
        if (mlockall(MCL_CURRENT | MCL_FUTURE) == -1) {
            throw std::runtime_error("Failed to lock memory");
        }

        // Pre-fault stack to avoid page faults in real-time path
        constexpr size_t STACK_SIZE = 256 * 1024;  // 256 KB
        volatile char stack[STACK_SIZE];
        for (size_t i = 0; i < STACK_SIZE; i += 4096) {
            stack[i] = 0;
        }
    }

    /**
     * @brief Set real-time scheduling priority
     *
     * @param priority Priority level (1-99, higher = more priority)
     */
    void SetRealtimePriority(int priority) {
        struct sched_param param;
        param.sched_priority = priority;

        if (sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
            throw std::runtime_error("Failed to set real-time priority");
        }
    }
}

/**
 * @brief ADAS Controller main class
 *
 * Fuses radar and camera data to detect potential collisions
 * and issue warnings/interventions.
 */
class AdasController {
public:
    AdasController()
        : logger_("AdasController"),
          exec_client_(),
          cycle_time_(std::chrono::milliseconds(20)),  // 50 Hz
          running_(false),
          collision_warning_distance_(15.0f),  // meters
          collision_warning_velocity_(-5.0f) { // m/s (approaching)
    }

    /**
     * @brief Initialize ADAS controller
     *
     * - Finds required services (radar, camera, vehicle dynamics)
     * - Creates service proxies
     * - Subscribes to events
     * - Offers ADAS command service
     */
    void Initialize() {
        logger_.LogInfo() << "Initializing ADAS Controller";

        exec_client_.ReportExecutionState(
            ara::exec::ExecutionState::kInitializing);

        try {
            // Find radar service
            auto radar_handles = saft::radar::RadarProxy::FindService(
                ara::com::InstanceIdentifier("RadarFront"));

            if (radar_handles.empty()) {
                throw std::runtime_error("Radar service not found");
            }

            radar_proxy_ = std::make_unique<saft::radar::RadarProxy>(
                radar_handles[0]);

            logger_.LogInfo() << "Connected to radar service";

            // Subscribe to radar events
            radar_proxy_->TargetDetected.Subscribe(
                [this](const auto& target) {
                    OnRadarTargetDetected(target);
                });

            radar_proxy_->TargetDetected.SetReceiveHandler(
                [this]() {
                    ProcessRadarEvents();
                });

            // Find camera service (optional for this example)
            auto camera_handles = saft::camera::CameraProxy::FindService(
                ara::com::InstanceIdentifier("CameraFront"));

            if (!camera_handles.empty()) {
                camera_proxy_ = std::make_unique<saft::camera::CameraProxy>(
                    camera_handles[0]);
                logger_.LogInfo() << "Connected to camera service";
            } else {
                logger_.LogWarn() << "Camera service not available";
            }

            // Find vehicle dynamics service
            auto vehicle_handles = saft::vehicle::VehicleDynamicsProxy::FindService(
                ara::com::InstanceIdentifier("Main"));

            if (!vehicle_handles.empty()) {
                vehicle_proxy_ = std::make_unique<saft::vehicle::VehicleDynamicsProxy>(
                    vehicle_handles[0]);
                logger_.LogInfo() << "Connected to vehicle dynamics service";
            } else {
                logger_.LogWarn() << "Vehicle dynamics service not available";
            }

            // Offer ADAS commands service
            adas_service_ = std::make_unique<saft::adas::AdasCommandsSkeleton>(
                ara::com::InstanceIdentifier("Main"));

            auto result = adas_service_->OfferService();
            if (!result.HasValue()) {
                throw std::runtime_error("Failed to offer ADAS service");
            }

            logger_.LogInfo() << "ADAS service offered";

        } catch (const std::exception& e) {
            logger_.LogError() << "Initialization failed: " << e.what();
            throw;
        }

        logger_.LogInfo() << "ADAS Controller initialized successfully";
    }

    /**
     * @brief Main processing loop
     *
     * Runs at 50 Hz (20ms cycle time) with real-time priority.
     */
    void Run() {
        logger_.LogInfo() << "Starting ADAS Controller main loop";

        exec_client_.ReportExecutionState(
            ara::exec::ExecutionState::kRunning);

        running_.store(true);

        auto next_cycle = std::chrono::steady_clock::now();

        while (running_.load() && !g_shutdown_requested.load()) {
            auto cycle_start = std::chrono::steady_clock::now();

            // Process one ADAS cycle
            ProcessCycle();

            // Calculate next cycle time
            next_cycle += cycle_time_;

            // Check for cycle overrun
            auto cycle_end = std::chrono::steady_clock::now();
            auto cycle_duration = std::chrono::duration_cast<std::chrono::microseconds>(
                cycle_end - cycle_start);

            if (cycle_duration > cycle_time_) {
                logger_.LogWarn() << "Cycle overrun: " << cycle_duration.count()
                                 << " us (limit: " << cycle_time_.count() << " us)";
            }

            // Sleep until next cycle
            std::this_thread::sleep_until(next_cycle);
        }

        logger_.LogInfo() << "ADAS Controller main loop stopped";
    }

    /**
     * @brief Graceful shutdown
     */
    void Shutdown() {
        logger_.LogInfo() << "Shutting down ADAS Controller";

        exec_client_.ReportExecutionState(
            ara::exec::ExecutionState::kShuttingDown);

        running_.store(false);

        // Stop offering service
        if (adas_service_) {
            adas_service_->StopOfferService();
        }

        // Disconnect from services
        radar_proxy_.reset();
        camera_proxy_.reset();
        vehicle_proxy_.reset();

        logger_.LogInfo() << "ADAS Controller shutdown complete";
    }

private:
    /**
     * @brief Process one ADAS cycle
     *
     * Fuses sensor data and makes control decisions.
     */
    void ProcessCycle() {
        // Get current vehicle speed
        float vehicle_speed = 0.0f;
        if (vehicle_proxy_) {
            auto speed_future = vehicle_proxy_->GetSpeed();
            vehicle_speed = speed_future.get();
        }

        // Get radar targets
        if (radar_proxy_) {
            auto targets_future = radar_proxy_->GetTargets(10);
            auto targets = targets_future.get();

            // Process targets for collision warning
            for (const auto& target : targets) {
                ProcessTarget(target, vehicle_speed);
            }
        }

        // TODO: Fuse with camera data for enhanced detection
        // TODO: Implement path planning and trajectory prediction
    }

    /**
     * @brief Process single radar target for collision risk
     *
     * @param target Radar target data
     * @param ego_speed Own vehicle speed (m/s)
     */
    void ProcessTarget(const saft::radar::RadarTarget& target,
                      float ego_speed) {
        // Calculate relative velocity
        float relative_velocity = target.velocity - ego_speed;

        // Check for collision risk
        if (target.distance < collision_warning_distance_ &&
            relative_velocity < collision_warning_velocity_) {

            // Target is close and approaching
            float time_to_collision = target.distance / std::abs(relative_velocity);

            if (time_to_collision < 2.0f) {  // Less than 2 seconds
                IssueCollisionWarning(target, time_to_collision);
            }

            if (time_to_collision < 0.5f) {  // Less than 0.5 seconds
                RequestEmergencyBraking(target, time_to_collision);
            }
        }
    }

    /**
     * @brief Event handler for radar target detection
     */
    void OnRadarTargetDetected(const saft::radar::RadarTarget& target) {
        logger_.LogDebug() << "Radar target detected: ID=" << target.id
                          << " distance=" << target.distance
                          << " velocity=" << target.velocity;

        // Process target immediately (event-driven path)
        // Note: Also processed in main cycle (time-driven path)
        // for redundancy
    }

    /**
     * @brief Process radar event queue
     */
    void ProcessRadarEvents() {
        // Process all pending radar events
        while (auto sample = radar_proxy_->TargetDetected.GetNewSamples()) {
            OnRadarTargetDetected(*sample);
        }
    }

    /**
     * @brief Issue collision warning to driver
     *
     * @param target Threatening target
     * @param ttc Time to collision (seconds)
     */
    void IssueCollisionWarning(const saft::radar::RadarTarget& target,
                              float ttc) {
        logger_.LogWarn() << "COLLISION WARNING: Target " << target.id
                         << " at " << target.distance << "m"
                         << " TTC=" << ttc << "s";

        // Send warning via ADAS service
        if (adas_service_) {
            adas_service_->SendCollisionWarning(target.distance,
                                               target.velocity,
                                               ttc);
        }

        // TODO: Trigger HMI warning (visual/audio)
        // TODO: Pre-tension seat belts
    }

    /**
     * @brief Request emergency braking intervention
     *
     * @param target Imminent collision target
     * @param ttc Time to collision (seconds)
     */
    void RequestEmergencyBraking(const saft::radar::RadarTarget& target,
                                float ttc) {
        logger_.LogError() << "EMERGENCY BRAKING: Target " << target.id
                          << " at " << target.distance << "m"
                          << " TTC=" << ttc << "s";

        // Send emergency braking command
        if (adas_service_) {
            adas_service_->RequestEmergencyBraking(target.distance, ttc);
        }

        // TODO: Interface with brake actuator
        // TODO: Log safety event
    }

    // Member variables
    ara::log::Logger logger_;
    ara::exec::ExecutionClient exec_client_;

    std::chrono::milliseconds cycle_time_;
    std::atomic<bool> running_;

    // Service proxies (consumers)
    std::unique_ptr<saft::radar::RadarProxy> radar_proxy_;
    std::unique_ptr<saft::camera::CameraProxy> camera_proxy_;
    std::unique_ptr<saft::vehicle::VehicleDynamicsProxy> vehicle_proxy_;

    // Service skeleton (provider)
    std::unique_ptr<saft::adas::AdasCommandsSkeleton> adas_service_;

    // Configuration parameters
    float collision_warning_distance_;
    float collision_warning_velocity_;
};

/**
 * @brief Main entry point
 */
int main(int argc, char* argv[]) {
    // Install signal handlers
    signal(SIGTERM, SignalHandler);
    signal(SIGINT, SignalHandler);

    try {
        // Configure for real-time operation
        LockMemoryForRealtime();
        SetRealtimePriority(80);  // High priority (1-99 scale)

        // Create and initialize ADAS controller
        AdasController controller;
        controller.Initialize();

        // Run main loop
        controller.Run();

        // Graceful shutdown
        controller.Shutdown();

    } catch (const std::exception& e) {
        ara::log::Logger logger("AdasController");
        logger.LogFatal() << "Fatal error: " << e.what();
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
