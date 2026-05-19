/**
 * @file types.h
 * @brief AUTOSAR Adaptive Platform ara::com common types
 *
 * @copyright Copyright (c) 2026 Automotive Reference Implementation
 * @license Apache 2.0
 *
 * Platform: QNX Neutrino 7.1+
 * Standard: AUTOSAR Adaptive Platform R23-11
 */

#pragma once

#include <cstdint>
#include <string>
#include <memory>
#include <vector>

namespace ara {
namespace com {

/**
 * @brief Service instance identifier
 *
 * Uniquely identifies a service instance within the system.
 * Format: "InstanceName" or "InstanceName:InstanceId"
 */
class InstanceIdentifier {
public:
    explicit InstanceIdentifier(const std::string& identifier)
        : identifier_(identifier) {}

    const std::string& ToString() const { return identifier_; }

    bool operator==(const InstanceIdentifier& other) const {
        return identifier_ == other.identifier_;
    }

    bool operator<(const InstanceIdentifier& other) const {
        return identifier_ < other.identifier_;
    }

private:
    std::string identifier_;
};

/**
 * @brief Service instance handle
 *
 * Opaque handle returned by FindService, used to create Proxy instances.
 */
class ServiceHandleType {
public:
    ServiceHandleType(uint16_t service_id, uint16_t instance_id, int channel_id)
        : service_id_(service_id),
          instance_id_(instance_id),
          channel_id_(channel_id) {}

    uint16_t GetServiceId() const { return service_id_; }
    uint16_t GetInstanceId() const { return instance_id_; }
    int GetChannelId() const { return channel_id_; }

    bool operator==(const ServiceHandleType& other) const {
        return service_id_ == other.service_id_ &&
               instance_id_ == other.instance_id_;
    }

private:
    uint16_t service_id_;
    uint16_t instance_id_;
    int channel_id_;  // QNX channel ID for local IPC
};

/**
 * @brief Service instance container
 *
 * Container type for ServiceHandleType returned by FindService.
 */
template <typename T>
using ServiceHandleContainer = std::vector<T>;

/**
 * @brief Sample pointer for event data
 *
 * Shared pointer to event data received via subscription.
 */
template <typename SampleType>
using SamplePtr = std::shared_ptr<const SampleType>;

/**
 * @brief Communication binding types
 */
enum class CommunicationBinding {
    kLocal,    ///< QNX IPC (channels, message passing)
    kTcp,      ///< TCP over Ethernet
    kUdp,      ///< UDP over Ethernet
    kSomeIp    ///< SOME/IP protocol
};

/**
 * @brief Service discovery state
 */
enum class ServiceDiscoveryState {
    kNotOffered,      ///< Service not yet offered
    kOffered,         ///< Service actively offered
    kStopped          ///< Service offering stopped
};

/**
 * @brief Method call result
 */
enum class MethodCallResult {
    kSuccess,
    kTimeout,
    kServiceNotAvailable,
    kInvalidArguments,
    kApplicationError
};

/**
 * @brief Event subscription state
 */
enum class SubscriptionState {
    kNotSubscribed,
    kSubscriptionPending,
    kSubscribed
};

/**
 * @brief QNX-specific message types for ara::com IPC
 */
namespace qnx_ipc {

constexpr uint16_t MSG_TYPE_METHOD_CALL = 0x0100;
constexpr uint16_t MSG_TYPE_METHOD_REPLY = 0x0101;
constexpr uint16_t MSG_TYPE_EVENT = 0x0200;
constexpr uint16_t MSG_TYPE_FIELD_GET = 0x0300;
constexpr uint16_t MSG_TYPE_FIELD_SET = 0x0301;
constexpr uint16_t MSG_TYPE_FIELD_NOTIFY = 0x0302;

/**
 * @brief Message header for QNX channel communication
 */
struct MessageHeader {
    uint16_t msg_type;      ///< Message type (method, event, field)
    uint16_t service_id;    ///< Service identifier
    uint16_t instance_id;   ///< Instance identifier
    uint16_t method_id;     ///< Method/Event/Field identifier
    uint32_t request_id;    ///< Request ID (for async calls)
    uint32_t payload_size;  ///< Payload data size in bytes
    uint32_t reserved;      ///< Reserved for future use
};

static_assert(sizeof(MessageHeader) == 20, "MessageHeader must be 20 bytes");

/**
 * @brief Maximum payload size for QNX messages
 */
constexpr size_t MAX_PAYLOAD_SIZE = 65536;  // 64 KB

/**
 * @brief Complete message structure
 */
struct Message {
    MessageHeader header;
    uint8_t payload[MAX_PAYLOAD_SIZE];
};

} // namespace qnx_ipc

} // namespace com
} // namespace ara
