/**
 * @file skeleton.cpp
 * @brief AUTOSAR Adaptive Platform ara::com Skeleton implementation for QNX
 *
 * @copyright Copyright (c) 2026 Automotive Reference Implementation
 * @license Apache 2.0
 */

#include "ara/com/skeleton.h"
#include "ara/log/logger.h"
#include <sys/neutrino.h>
#include <sys/dispatch.h>
#include <sys/netmgr.h>
#include <errno.h>
#include <cstring>
#include <sstream>
#include <iomanip>

namespace ara {
namespace com {

namespace {
    // Convert instance identifier string to 16-bit instance ID
    uint16_t GenerateInstanceId(const std::string& instance_str) {
        std::hash<std::string> hasher;
        return static_cast<uint16_t>(hasher(instance_str) & 0xFFFF);
    }

    // Logger for ara::com
    ara::log::Logger& GetLogger() {
        static ara::log::Logger logger("ara.com.skeleton");
        return logger;
    }
}

SkeletonBase::SkeletonBase(const InstanceIdentifier& instance,
                           uint16_t service_id)
    : instance_(instance),
      service_id_(service_id),
      instance_id_(GenerateInstanceId(instance.ToString())),
      channel_id_(-1),
      dispatch_ctx_(nullptr),
      state_(ServiceDiscoveryState::kNotOffered),
      running_(false) {

    GetLogger().LogDebug() << "SkeletonBase created: service_id="
                           << service_id_ << " instance="
                           << instance_.ToString();
}

SkeletonBase::~SkeletonBase() {
    StopOfferService();
}

ara::core::Result<void> SkeletonBase::OfferService() {
    if (state_.load() == ServiceDiscoveryState::kOffered) {
        return ara::core::Result<void>::FromError(
            ara::core::ErrorCode::kAlreadyOffered);
    }

    // Create QNX channel for receiving messages
    channel_id_ = ChannelCreate(0);
    if (channel_id_ == -1) {
        GetLogger().LogError() << "Failed to create QNX channel: "
                              << strerror(errno);
        return ara::core::Result<void>::FromError(
            ara::core::ErrorCode::kChannelCreateFailed);
    }

    GetLogger().LogInfo() << "Created QNX channel: " << channel_id_
                         << " for service " << service_id_;

    // Create dispatch context for message handling
    dispatch_ctx_ = dispatch_create_channel(channel_id_,
                                            DISPATCH_FLAG_NOLOCK);
    if (dispatch_ctx_ == nullptr) {
        ChannelDestroy(channel_id_);
        channel_id_ = -1;
        return ara::core::Result<void>::FromError(
            ara::core::ErrorCode::kDispatchCreateFailed);
    }

    // Register service instance with vsomeip registry
    RegisterServiceInstance();

    // Start message processing thread
    running_.store(true);
    process_thread_ = std::thread([this]() {
        ProcessMessages();
    });

    state_.store(ServiceDiscoveryState::kOffered);

    GetLogger().LogInfo() << "Service offered: " << service_id_
                         << " instance " << instance_.ToString();

    return ara::core::Result<void>();
}

void SkeletonBase::StopOfferService() {
    if (state_.load() == ServiceDiscoveryState::kNotOffered) {
        return;
    }

    GetLogger().LogInfo() << "Stopping service: " << service_id_;

    // Stop message processing
    running_.store(false);

    // Send pulse to unblock MsgReceive
    if (channel_id_ != -1) {
        int coid = ConnectAttach(ND_LOCAL_NODE, 0, channel_id_,
                                _NTO_SIDE_CHANNEL, 0);
        if (coid != -1) {
            MsgSendPulse(coid, -1, 0, 0);
            ConnectDetach(coid);
        }
    }

    if (process_thread_.joinable()) {
        process_thread_.join();
    }

    // Unregister from service registry
    UnregisterServiceInstance();

    // Cleanup dispatch context
    if (dispatch_ctx_ != nullptr) {
        dispatch_destroy(dispatch_ctx_);
        dispatch_ctx_ = nullptr;
    }

    // Destroy channel
    if (channel_id_ != -1) {
        ChannelDestroy(channel_id_);
        channel_id_ = -1;
    }

    state_.store(ServiceDiscoveryState::kStopped);

    GetLogger().LogInfo() << "Service stopped: " << service_id_;
}

void SkeletonBase::SendEventNotification(uint16_t event_id,
                                        const std::vector<uint8_t>& payload) {
    if (payload.size() > qnx_ipc::MAX_PAYLOAD_SIZE) {
        GetLogger().LogError() << "Event payload too large: " << payload.size();
        return;
    }

    std::lock_guard<std::mutex> lock(subscriptions_mutex_);

    // Send to all subscribers
    for (const auto& sub : event_subscriptions_) {
        if (sub.event_id != event_id) {
            continue;
        }

        // Prepare message
        qnx_ipc::Message msg;
        msg.header.msg_type = qnx_ipc::MSG_TYPE_EVENT;
        msg.header.service_id = service_id_;
        msg.header.instance_id = instance_id_;
        msg.header.method_id = event_id;
        msg.header.request_id = 0;
        msg.header.payload_size = payload.size();
        msg.header.reserved = 0;

        std::memcpy(msg.payload, payload.data(), payload.size());

        // Send pulse notification (asynchronous)
        int result = MsgSend(sub.connection_id, &msg,
                           sizeof(qnx_ipc::MessageHeader) + payload.size(),
                           nullptr, 0);

        if (result == -1) {
            GetLogger().LogWarn() << "Failed to send event to subscriber: "
                                 << strerror(errno);
        }
    }
}

void SkeletonBase::NotifyFieldChange(uint16_t field_id,
                                     const void* value,
                                     size_t size) {
    if (size > qnx_ipc::MAX_PAYLOAD_SIZE) {
        GetLogger().LogError() << "Field value too large: " << size;
        return;
    }

    std::lock_guard<std::mutex> lock(fields_mutex_);

    // Update stored field value
    auto& field = field_values_[field_id];
    field.data.resize(size);
    std::memcpy(field.data.data(), value, size);

    // Notify all subscribers
    for (int coid : field.subscriber_coids) {
        qnx_ipc::Message msg;
        msg.header.msg_type = qnx_ipc::MSG_TYPE_FIELD_NOTIFY;
        msg.header.service_id = service_id_;
        msg.header.instance_id = instance_id_;
        msg.header.method_id = field_id;
        msg.header.request_id = 0;
        msg.header.payload_size = size;
        msg.header.reserved = 0;

        std::memcpy(msg.payload, value, size);

        int result = MsgSend(coid, &msg,
                           sizeof(qnx_ipc::MessageHeader) + size,
                           nullptr, 0);

        if (result == -1) {
            GetLogger().LogWarn() << "Failed to notify field subscriber: "
                                 << strerror(errno);
        }
    }
}

void SkeletonBase::RegisterMethodHandler(uint16_t method_id,
                                        MethodHandler handler) {
    std::lock_guard<std::mutex> lock(handlers_mutex_);
    method_handlers_[method_id] = std::move(handler);

    GetLogger().LogDebug() << "Registered method handler: method_id="
                           << method_id;
}

void SkeletonBase::ProcessMessages() {
    GetLogger().LogInfo() << "Message processing started for channel "
                         << channel_id_;

    qnx_ipc::Message msg;
    struct _msg_info msg_info;

    while (running_.load()) {
        // Receive message (blocking)
        int rcvid = MsgReceive(channel_id_, &msg, sizeof(msg), &msg_info);

        if (rcvid == -1) {
            if (errno == EINTR) {
                continue;  // Interrupted, retry
            }
            GetLogger().LogError() << "MsgReceive failed: " << strerror(errno);
            break;
        }

        if (rcvid == 0) {
            // Pulse received (used for shutdown signal)
            continue;
        }

        // Process message based on type
        switch (msg.header.msg_type) {
        case qnx_ipc::MSG_TYPE_METHOD_CALL:
            HandleMethodCall(rcvid, msg);
            break;

        case qnx_ipc::MSG_TYPE_FIELD_GET:
            HandleFieldGet(rcvid, msg);
            break;

        case qnx_ipc::MSG_TYPE_FIELD_SET:
            HandleFieldSet(rcvid, msg);
            break;

        default:
            GetLogger().LogWarn() << "Unknown message type: "
                                 << msg.header.msg_type;
            MsgError(rcvid, ENOSYS);
            break;
        }
    }

    GetLogger().LogInfo() << "Message processing stopped";
}

void SkeletonBase::HandleMethodCall(int rcvid, const qnx_ipc::Message& msg) {
    uint16_t method_id = msg.header.method_id;

    GetLogger().LogDebug() << "Method call: method_id=" << method_id
                           << " request_id=" << msg.header.request_id;

    std::lock_guard<std::mutex> lock(handlers_mutex_);

    auto it = method_handlers_.find(method_id);
    if (it == method_handlers_.end()) {
        GetLogger().LogWarn() << "No handler for method: " << method_id;
        MsgError(rcvid, ENOSYS);
        return;
    }

    // Extract request payload
    std::vector<uint8_t> request(msg.payload,
                                msg.payload + msg.header.payload_size);

    // Call method handler
    std::vector<uint8_t> response;
    try {
        response = it->second(request);
    } catch (const std::exception& e) {
        GetLogger().LogError() << "Method handler exception: " << e.what();
        MsgError(rcvid, EIO);
        return;
    }

    // Send reply
    if (response.size() > qnx_ipc::MAX_PAYLOAD_SIZE) {
        GetLogger().LogError() << "Response too large: " << response.size();
        MsgError(rcvid, E2BIG);
        return;
    }

    qnx_ipc::Message reply_msg;
    reply_msg.header.msg_type = qnx_ipc::MSG_TYPE_METHOD_REPLY;
    reply_msg.header.service_id = service_id_;
    reply_msg.header.instance_id = instance_id_;
    reply_msg.header.method_id = method_id;
    reply_msg.header.request_id = msg.header.request_id;
    reply_msg.header.payload_size = response.size();
    reply_msg.header.reserved = 0;

    std::memcpy(reply_msg.payload, response.data(), response.size());

    int result = MsgReply(rcvid, EOK, &reply_msg,
                         sizeof(qnx_ipc::MessageHeader) + response.size());

    if (result == -1) {
        GetLogger().LogError() << "MsgReply failed: " << strerror(errno);
    }
}

void SkeletonBase::HandleFieldGet(int rcvid, const qnx_ipc::Message& msg) {
    uint16_t field_id = msg.header.method_id;

    GetLogger().LogDebug() << "Field get: field_id=" << field_id;

    std::lock_guard<std::mutex> lock(fields_mutex_);

    auto it = field_values_.find(field_id);
    if (it == field_values_.end()) {
        GetLogger().LogWarn() << "Unknown field: " << field_id;
        MsgError(rcvid, ENOENT);
        return;
    }

    // Send field value
    qnx_ipc::Message reply_msg;
    reply_msg.header.msg_type = qnx_ipc::MSG_TYPE_FIELD_GET;
    reply_msg.header.service_id = service_id_;
    reply_msg.header.instance_id = instance_id_;
    reply_msg.header.method_id = field_id;
    reply_msg.header.request_id = msg.header.request_id;
    reply_msg.header.payload_size = it->second.data.size();
    reply_msg.header.reserved = 0;

    std::memcpy(reply_msg.payload, it->second.data.data(),
               it->second.data.size());

    MsgReply(rcvid, EOK, &reply_msg,
            sizeof(qnx_ipc::MessageHeader) + it->second.data.size());
}

void SkeletonBase::HandleFieldSet(int rcvid, const qnx_ipc::Message& msg) {
    uint16_t field_id = msg.header.method_id;

    GetLogger().LogDebug() << "Field set: field_id=" << field_id;

    std::lock_guard<std::mutex> lock(fields_mutex_);

    auto& field = field_values_[field_id];
    field.data.resize(msg.header.payload_size);
    std::memcpy(field.data.data(), msg.payload, msg.header.payload_size);

    // Acknowledge
    MsgReply(rcvid, EOK, nullptr, 0);

    // Notify subscribers (without lock to avoid deadlock)
    // Note: In production, use separate notification thread
}

void SkeletonBase::RegisterServiceInstance() {
    // Register with vsomeip service registry
    // Implementation depends on vsomeip integration

    GetLogger().LogInfo() << "Registered service instance: "
                         << "service_id=" << service_id_
                         << " instance_id=" << instance_id_
                         << " channel_id=" << channel_id_;

    // TODO: Call vsomeip API to advertise service
    // vsomeip::runtime::get()->offer_service(service_id_, instance_id_);
}

void SkeletonBase::UnregisterServiceInstance() {
    GetLogger().LogInfo() << "Unregistered service instance: "
                         << service_id_;

    // TODO: Call vsomeip API to stop advertising
    // vsomeip::runtime::get()->stop_offer_service(service_id_, instance_id_);
}

} // namespace com
} // namespace ara
