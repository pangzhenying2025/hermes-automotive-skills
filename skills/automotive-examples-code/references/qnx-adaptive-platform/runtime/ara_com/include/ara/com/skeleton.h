/**
 * @file skeleton.h
 * @brief AUTOSAR Adaptive Platform ara::com Skeleton (Service Provider) base class
 *
 * @copyright Copyright (c) 2026 Automotive Reference Implementation
 * @license Apache 2.0
 *
 * Platform: QNX Neutrino 7.1+
 * Implementation: Uses QNX channels for local IPC, SOME/IP for remote
 */

#pragma once

#include "ara/com/types.h"
#include "ara/core/result.h"
#include <sys/neutrino.h>
#include <sys/dispatch.h>
#include <functional>
#include <thread>
#include <atomic>
#include <map>
#include <mutex>

namespace ara {
namespace com {

/**
 * @brief Base class for service skeletons (providers)
 *
 * Implements QNX channel-based IPC for method calls, events, and fields.
 * Derived classes are generated from ARXML service interface definitions.
 */
class SkeletonBase {
public:
    /**
     * @brief Construct skeleton with instance identifier
     *
     * @param instance Unique instance identifier for this service
     * @param service_id Numeric service ID (from ARXML)
     */
    explicit SkeletonBase(const InstanceIdentifier& instance,
                         uint16_t service_id);

    /**
     * @brief Destructor - stops service offering
     */
    virtual ~SkeletonBase();

    // Non-copyable, non-movable
    SkeletonBase(const SkeletonBase&) = delete;
    SkeletonBase& operator=(const SkeletonBase&) = delete;
    SkeletonBase(SkeletonBase&&) = delete;
    SkeletonBase& operator=(SkeletonBase&&) = delete;

    /**
     * @brief Start offering the service
     *
     * Creates QNX channel, registers with service registry,
     * and starts message processing thread.
     *
     * @return Result<void> Success or error code
     */
    ara::core::Result<void> OfferService();

    /**
     * @brief Stop offering the service
     *
     * Unregisters from service registry and stops message processing.
     */
    void StopOfferService();

    /**
     * @brief Get current service discovery state
     */
    ServiceDiscoveryState GetServiceDiscoveryState() const {
        return state_.load();
    }

protected:
    /**
     * @brief Send event notification to all subscribers
     *
     * @param event_id Event identifier (from ARXML)
     * @param payload Serialized event data
     */
    void SendEventNotification(uint16_t event_id,
                              const std::vector<uint8_t>& payload);

    /**
     * @brief Update field value and notify subscribers
     *
     * @param field_id Field identifier (from ARXML)
     * @param value Pointer to field value
     * @param size Size of field value in bytes
     */
    void NotifyFieldChange(uint16_t field_id,
                          const void* value,
                          size_t size);

    /**
     * @brief Register method handler
     *
     * Derived classes register method implementations.
     *
     * @param method_id Method identifier (from ARXML)
     * @param handler Function to handle method calls
     */
    using MethodHandler = std::function<std::vector<uint8_t>(
        const std::vector<uint8_t>& request)>;

    void RegisterMethodHandler(uint16_t method_id,
                              MethodHandler handler);

    /**
     * @brief Get instance identifier
     */
    const InstanceIdentifier& GetInstanceIdentifier() const {
        return instance_;
    }

    /**
     * @brief Get service ID
     */
    uint16_t GetServiceId() const { return service_id_; }

    /**
     * @brief Get instance ID (derived from instance identifier)
     */
    uint16_t GetInstanceId() const { return instance_id_; }

private:
    /**
     * @brief Message processing thread main loop
     */
    void ProcessMessages();

    /**
     * @brief Handle incoming method call
     *
     * @param rcvid Receive ID for reply
     * @param msg Incoming message
     */
    void HandleMethodCall(int rcvid, const qnx_ipc::Message& msg);

    /**
     * @brief Handle field getter request
     *
     * @param rcvid Receive ID for reply
     * @param msg Incoming message
     */
    void HandleFieldGet(int rcvid, const qnx_ipc::Message& msg);

    /**
     * @brief Handle field setter request
     *
     * @param rcvid Receive ID for reply
     * @param msg Incoming message
     */
    void HandleFieldSet(int rcvid, const qnx_ipc::Message& msg);

    /**
     * @brief Register service with vsomeip service registry
     */
    void RegisterServiceInstance();

    /**
     * @brief Unregister service from registry
     */
    void UnregisterServiceInstance();

    // Member variables
    InstanceIdentifier instance_;
    uint16_t service_id_;
    uint16_t instance_id_;  // Derived from instance_ string
    int channel_id_;        // QNX channel for receiving messages
    dispatch_t* dispatch_ctx_;
    std::atomic<ServiceDiscoveryState> state_;

    // Message processing
    std::thread process_thread_;
    std::atomic<bool> running_;

    // Method handlers
    std::map<uint16_t, MethodHandler> method_handlers_;
    std::mutex handlers_mutex_;

    // Event subscriptions (client connection IDs)
    struct EventSubscription {
        int connection_id;
        uint16_t event_id;
    };
    std::vector<EventSubscription> event_subscriptions_;
    std::mutex subscriptions_mutex_;

    // Field values (for getter/notification)
    struct FieldValue {
        std::vector<uint8_t> data;
        std::vector<int> subscriber_coids;  // Connection IDs
    };
    std::map<uint16_t, FieldValue> field_values_;
    std::mutex fields_mutex_;
};

/**
 * @brief Event wrapper for skeleton events
 *
 * Provides Send() method to emit events to subscribers.
 */
template <typename EventDataType>
class SkeletonEvent {
public:
    /**
     * @brief Construct event
     *
     * @param skeleton Parent skeleton instance
     * @param event_id Event identifier from ARXML
     */
    SkeletonEvent(SkeletonBase* skeleton, uint16_t event_id)
        : skeleton_(skeleton), event_id_(event_id) {}

    /**
     * @brief Send event to all subscribers
     *
     * @param data Event data to send
     */
    void Send(const EventDataType& data) {
        // Serialize data
        std::vector<uint8_t> payload = Serialize(data);

        // Send via skeleton
        skeleton_->SendEventNotification(event_id_, payload);
    }

private:
    /**
     * @brief Serialize event data
     *
     * Override in generated code for specific types.
     */
    std::vector<uint8_t> Serialize(const EventDataType& data);

    SkeletonBase* skeleton_;
    uint16_t event_id_;
};

/**
 * @brief Field wrapper for skeleton fields
 *
 * Provides getter/setter with automatic change notification.
 */
template <typename FieldDataType>
class SkeletonField {
public:
    /**
     * @brief Construct field
     *
     * @param skeleton Parent skeleton instance
     * @param field_id Field identifier from ARXML
     */
    SkeletonField(SkeletonBase* skeleton, uint16_t field_id)
        : skeleton_(skeleton), field_id_(field_id) {}

    /**
     * @brief Update field value
     *
     * Triggers notification to all subscribers.
     *
     * @param value New field value
     */
    void Update(const FieldDataType& value) {
        std::lock_guard<std::mutex> lock(mutex_);
        value_ = value;

        // Notify subscribers
        skeleton_->NotifyFieldChange(field_id_, &value_, sizeof(value_));
    }

    /**
     * @brief Get current field value
     */
    FieldDataType Get() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return value_;
    }

private:
    SkeletonBase* skeleton_;
    uint16_t field_id_;
    FieldDataType value_;
    mutable std::mutex mutex_;
};

} // namespace com
} // namespace ara
