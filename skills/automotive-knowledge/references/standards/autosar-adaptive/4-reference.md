# AUTOSAR Adaptive Platform - API Reference

## ara::core - Core Types and Utilities

### Result<T, E>

Error handling type representing either a value or an error.

```cpp
namespace ara::core {

template<typename T, typename E = ErrorCode>
class Result {
public:
    // Constructors
    static Result FromValue(const T& value);
    static Result FromValue(T&& value);
    static Result FromError(const E& error);
    static Result FromError(E&& error);

    // Value access
    bool HasValue() const noexcept;
    const T& Value() const&;
    T&& Value() &&;
    const T& ValueOr(const T& default_value) const&;

    // Error access
    const E& Error() const&;
    E&& Error() &&;

    // Monadic operations
    template<typename F>
    auto Bind(F&& func) -> Result<...>;

    template<typename F>
    auto OrElse(F&& func) -> Result<T, ...>;

    // Inspection
    explicit operator bool() const noexcept;
};

} // namespace ara::core
```

**Usage Examples**:
```cpp
// Returning success
Result<int> Divide(int a, int b) {
    if (b == 0) {
        return Result<int>::FromError(ErrorCode::kInvalidArgument);
    }
    return Result<int>::FromValue(a / b);
}

// Chaining operations
auto result = Divide(10, 2)
    .Bind([](int value) { return Multiply(value, 3); })
    .Bind([](int value) { return Subtract(value, 5); });

// Safe access
if (result.HasValue()) {
    std::cout << result.Value() << std::endl;
}

// Default value
int safe_value = result.ValueOr(0);
```

### Optional<T>

Represents optional values.

```cpp
namespace ara::core {

template<typename T>
class Optional {
public:
    // Constructors
    constexpr Optional() noexcept;
    constexpr Optional(const T& value);
    constexpr Optional(T&& value);

    // Value access
    constexpr bool HasValue() const noexcept;
    constexpr const T& Value() const&;
    constexpr T&& Value() &&;
    constexpr const T& ValueOr(const T& default_value) const&;

    // Modifiers
    void Reset() noexcept;
    template<typename... Args>
    T& Emplace(Args&&... args);

    // Operators
    constexpr explicit operator bool() const noexcept;
    constexpr const T* operator->() const;
    constexpr T* operator->();
};

} // namespace ara::core
```

### ErrorCode

Standardized error representation.

```cpp
namespace ara::core {

class ErrorCode {
public:
    using CodeType = std::int32_t;

    // Constructors
    constexpr ErrorCode(CodeType value, const ErrorDomain& domain) noexcept;

    // Accessors
    constexpr CodeType Value() const noexcept;
    constexpr const ErrorDomain& Domain() const noexcept;
    StringView Message() const noexcept;

    // Comparison
    bool operator==(const ErrorCode& other) const noexcept;
};

// Common error codes
enum class ErrorDomain {
    kCoreError = 0,
    kComError = 1,
    kExecError = 2,
    kPerError = 3
};

// Core error values
enum class CoreErrorCode : ErrorCode::CodeType {
    kInvalidArgument = 1,
    kInvalidMetaModelShortname = 2,
    kInvalidMetaModelPath = 3
};

} // namespace ara::core
```

### Span<T>

Non-owning view of contiguous sequence.

```cpp
namespace ara::core {

template<typename T>
class Span {
public:
    // Constructors
    constexpr Span() noexcept;
    constexpr Span(T* ptr, std::size_t count);
    template<std::size_t N>
    constexpr Span(T (&arr)[N]) noexcept;

    // Element access
    constexpr T& operator[](std::size_t idx) const;
    constexpr T& Front() const;
    constexpr T& Back() const;
    constexpr T* Data() const noexcept;

    // Size
    constexpr std::size_t Size() const noexcept;
    constexpr bool Empty() const noexcept;

    // Iterators
    constexpr iterator begin() const noexcept;
    constexpr iterator end() const noexcept;
};

} // namespace ara::core
```

## ara::com - Communication Management

### Service Discovery

```cpp
namespace ara::com {

// Instance identifier
class InstanceIdentifier {
public:
    explicit InstanceIdentifier(StringView instance_id);
    StringView ToString() const;
};

// Instance specifier (from manifest)
class InstanceSpecifier {
public:
    explicit InstanceSpecifier(StringView path);
    static Result<InstanceSpecifier> Create(StringView path);
};

// Service handle
template<typename ServiceInterface>
class ServiceHandle {
public:
    InstanceIdentifier GetInstanceId() const;
    // Internal use by proxies
};

// Find service
template<typename ProxyClass>
using ServiceHandleContainer = std::vector<typename ProxyClass::HandleType>;

template<typename ProxyClass>
class FindServiceHandle {
public:
    using Handler = std::function<void(ServiceHandleContainer<ProxyClass>,
                                       FindServiceHandle)>;

    void SetFindServiceHandler(Handler handler);
};

template<typename ProxyClass>
FindServiceHandle<ProxyClass> FindService(InstanceSpecifier instance);

template<typename ProxyClass>
void StartFindService(FindServiceHandle<ProxyClass> handle,
                     FindServiceHandler mode);

enum class FindServiceHandler {
    kServiceAvailable,      // Callback when service becomes available
    kServiceUnavailable,    // Callback when service becomes unavailable
    kServiceAvailableAndUnavailable  // Both events
};

} // namespace ara::com
```

### Proxy Base Class

```cpp
namespace ara::com {

template<typename ServiceInterface>
class ServiceProxy {
public:
    using HandleType = ServiceHandle<ServiceInterface>;

    // Constructor from service handle
    explicit ServiceProxy(HandleType handle);

    // Service availability
    static FindServiceHandle<ServiceProxy> FindService(
        InstanceSpecifier instance);

    static FindServiceHandle<ServiceProxy> FindService(
        InstanceIdentifier instance);

    // Get current handles
    static ServiceHandleContainer<ServiceProxy> FindService(
        InstanceSpecifier instance,
        FindServiceHandler mode);

protected:
    HandleType GetHandle() const;
};

} // namespace ara::com
```

### Skeleton Base Class

```cpp
namespace ara::com {

template<typename ServiceInterface>
class ServiceSkeleton {
public:
    // Constructor from instance specifier
    explicit ServiceSkeleton(InstanceSpecifier instance,
                            MethodCallProcessingMode mode =
                                MethodCallProcessingMode::kEvent);

    // Service lifecycle
    Result<void> OfferService();
    void StopOfferService();

protected:
    InstanceIdentifier GetInstanceId() const;
};

enum class MethodCallProcessingMode {
    kEvent,      // Method calls processed via event loop
    kPoll        // Application polls for method calls
};

} // namespace ara::com
```

### Method (Proxy Side)

```cpp
namespace ara::com {

template<typename Output, typename... Inputs>
class MethodClient {
public:
    // Synchronous call (blocking)
    Result<Output> operator()(const Inputs&... inputs);

    // Asynchronous call (non-blocking)
    Future<Output> AsyncCall(const Inputs&... inputs);
};

} // namespace ara::com
```

### Method (Skeleton Side)

```cpp
namespace ara::com {

template<typename Output, typename... Inputs>
class MethodServer {
public:
    using Handler = std::function<Future<Output>(const Inputs&...)>;

    // Set method implementation
    void SetMethodCallHandler(Handler handler);

    // For kPoll mode
    bool HasPendingCalls() const;
    void ProcessNextCall();
};

} // namespace ara::com
```

### Event (Proxy Side)

```cpp
namespace ara::com {

template<typename SampleType>
class EventClient {
public:
    // Subscription
    Result<void> Subscribe(std::size_t max_sample_count);
    void Unsubscribe();
    SubscriptionState GetSubscriptionState() const;

    // Reception
    using ReceiveHandler = std::function<void()>;
    Result<void> SetReceiveHandler(ReceiveHandler handler);
    void UnsetReceiveHandler();

    // Sample access
    Result<std::size_t> GetNewSamples(
        std::function<void(SamplePtr<const SampleType>)> f,
        std::size_t max_samples = std::numeric_limits<std::size_t>::max());

    template<typename F>
    Result<SampleContainer<SampleType>> GetNewSamples(F&& f);
};

enum class SubscriptionState {
    kNotSubscribed,
    kSubscribed,
    kSubscriptionPending
};

} // namespace ara::com
```

### Event (Skeleton Side)

```cpp
namespace ara::com {

template<typename SampleType>
class EventServer {
public:
    // Publishing
    Result<void> Send(const SampleType& data);
    Result<SamplePtr<SampleType>> Allocate();

    // Subscriber management
    std::size_t GetSubscriberCount() const;
};

// Sample pointer with custom allocator
template<typename T>
class SamplePtr {
public:
    T& operator*();
    T* operator->();
    void Send();  // For allocated samples
};

} // namespace ara::com
```

### Field (Proxy Side)

```cpp
namespace ara::com {

template<typename T>
class FieldClient {
public:
    // Getter (if has-getter=true)
    Future<T> Get();

    // Setter (if has-setter=true)
    Future<void> Set(const T& value);

    // Notification subscription (if has-notifier=true)
    Result<void> Subscribe(std::size_t max_sample_count);
    void Unsubscribe();
    Result<void> SetReceiveHandler(std::function<void()> handler);
    Result<std::vector<SamplePtr<const T>>> GetNewSamples();
};

} // namespace ara::com
```

### Field (Skeleton Side)

```cpp
namespace ara::com {

template<typename T>
class FieldServer {
public:
    // Update field value (triggers notification if has-notifier)
    void Update(const T& value);

    // Register setter handler (if has-setter=true)
    using SetHandler = std::function<Future<void>(const T&)>;
    void RegisterSetHandler(SetHandler handler);

    // Register getter handler (if has-getter=true)
    using GetHandler = std::function<Future<T>()>;
    void RegisterGetHandler(GetHandler handler);
};

} // namespace ara::com
```

### E2E Protection

```cpp
namespace ara::com {

enum class E2EStatus {
    kOk,                  // Data valid
    kRepeated,            // Duplicate message
    kWrongSequence,       // Counter gap detected
    kError,               // CRC mismatch
    kNotAvailable,        // No E2E protection configured
    kNoNewData            // Timeout
};

template<typename SampleType>
class E2ESample {
public:
    const SampleType& GetData() const;
    E2EStatus GetE2EStatus() const;
    uint32_t GetCounter() const;
    uint32_t GetCRC() const;
};

} // namespace ara::com
```

## ara::exec - Execution Management

### Execution Client

```cpp
namespace ara::exec {

class ExecutionClient {
public:
    // Get singleton instance
    static Result<ExecutionClient> Create();

    // Report application state
    Result<void> ReportExecutionState(ExecutionState state);

    // Get execution state
    ExecutionState GetExecutionState() const;
};

enum class ExecutionState {
    kRunning,
    kTerminating
};

} // namespace ara::exec
```

### State Management

```cpp
namespace ara::exec {

// Function group states
class StateClient {
public:
    static Result<StateClient> Create();

    // Request state change
    Result<void> SetState(FunctionGroup group, FunctionGroupState state);

    // Get current state
    Result<FunctionGroupState> GetState(FunctionGroup group);
};

class FunctionGroup {
public:
    explicit FunctionGroup(StringView name);
    StringView GetName() const;
};

class FunctionGroupState {
public:
    explicit FunctionGroupState(StringView name);
    StringView GetName() const;
};

} // namespace ara::exec
```

## ara::per - Persistency

### Key-Value Storage

```cpp
namespace ara::per {

class KeyValueStorage {
public:
    // Open storage
    static Result<SharedHandle<KeyValueStorage>> OpenKeyValueStorage(
        StringView storage_name);

    // Set value
    template<typename T>
    Result<void> SetValue(StringView key, const T& value);

    // Get value
    template<typename T>
    Result<T> GetValue(StringView key);

    // Remove key
    Result<void> RemoveKey(StringView key);

    // Check existence
    Result<bool> KeyExists(StringView key);

    // List all keys
    Result<std::vector<String>> GetAllKeys();

    // Synchronize to persistent storage
    Result<void> SyncToStorage();

    // Discard uncommitted changes
    Result<void> DiscardPendingChanges();
};

} // namespace ara::per
```

### File Storage

```cpp
namespace ara::per {

class FileStorage {
public:
    // Open storage
    static Result<SharedHandle<FileStorage>> OpenFileStorage(
        StringView storage_name);

    // File operations
    Result<SharedHandle<ReadAccessor>> OpenFileReadOnly(StringView file_path);
    Result<SharedHandle<ReadWriteAccessor>> OpenFileReadWrite(
        StringView file_path);
    Result<SharedHandle<ReadWriteAccessor>> OpenFileWriteOnly(
        StringView file_path,
        OpenMode mode = OpenMode::kTruncate);

    // File management
    Result<bool> FileExists(StringView file_path);
    Result<void> DeleteFile(StringView file_path);
    Result<std::vector<String>> GetAllFileNames();

    // Synchronization
    Result<void> SyncToStorage();
};

enum class OpenMode {
    kTruncate,  // Overwrite existing file
    kAppend     // Append to existing file
};

class ReadAccessor {
public:
    Result<std::size_t> Read(Byte* data, std::size_t size);
    Result<std::size_t> GetSize();
    Result<void> SetPosition(std::int64_t position);
    Result<std::int64_t> GetPosition();
};

class ReadWriteAccessor : public ReadAccessor {
public:
    Result<std::size_t> Write(const Byte* data, std::size_t size);
};

} // namespace ara::per
```

## ara::log - Logging

### Logger Interface

```cpp
namespace ara::log {

class Logger {
public:
    // Get logger instance
    static Result<Logger> CreateLogger(StringView ctx_id,
                                       StringView ctx_description);

    // Log with severity
    LogStream LogFatal();
    LogStream LogError();
    LogStream LogWarn();
    LogStream LogInfo();
    LogStream LogDebug();
    LogStream LogVerbose();

    // Check if level is enabled
    bool IsFatalEnabled() const noexcept;
    bool IsErrorEnabled() const noexcept;
    bool IsWarnEnabled() const noexcept;
    bool IsInfoEnabled() const noexcept;
    bool IsDebugEnabled() const noexcept;
    bool IsVerboseEnabled() const noexcept;
};

class LogStream {
public:
    // Stream operators for various types
    LogStream& operator<<(bool value);
    LogStream& operator<<(std::int32_t value);
    LogStream& operator<<(std::uint32_t value);
    LogStream& operator<<(double value);
    LogStream& operator<<(StringView value);

    // Additional context
    LogStream& WithLocation(StringView file, int line);
    LogStream& WithTag(StringView tag);

    // Destructor flushes log
    ~LogStream();
};

} // namespace ara::log
```

**Usage**:
```cpp
auto logger = ara::log::CreateLogger("MYAPP", "My Application");

logger.Value().LogInfo() << "Application started";
logger.Value().LogError() << "Error code: " << error_code;
logger.Value().LogDebug().WithLocation(__FILE__, __LINE__)
    << "Debug info";
```

## Manifest Schema Reference

### Service Interface Manifest

```json
{
  "ServiceInterface": {
    "shortName": "string",
    "majorVersion": "integer",
    "minorVersion": "integer",
    "methods": [
      {
        "shortName": "string",
        "arguments": [
          {
            "shortName": "string",
            "dataType": "typeReference",
            "direction": "IN | OUT | INOUT"
          }
        ],
        "possibleErrors": ["errorReference"]
      }
    ],
    "events": [
      {
        "shortName": "string",
        "dataType": "typeReference"
      }
    ],
    "fields": [
      {
        "shortName": "string",
        "dataType": "typeReference",
        "hasGetter": "boolean",
        "hasSetter": "boolean",
        "hasNotifier": "boolean"
      }
    ]
  }
}
```

### Service Instance Manifest

```json
{
  "ServiceInstanceManifest": {
    "shortName": "string",
    "serviceInterface": "interfaceReference",
    "instanceId": "string (format: 0-65535)",
    "providedServiceInstance": {
      "someipBinding": {
        "serviceId": "integer (0-65535)",
        "majorVersion": "integer",
        "minorVersion": "integer",
        "eventGroups": [
          {
            "eventGroupId": "integer",
            "events": ["eventReference"]
          }
        ],
        "methodDeployments": [
          {
            "method": "methodReference",
            "methodId": "integer (0-32767)"
          }
        ],
        "eventDeployments": [
          {
            "event": "eventReference",
            "eventId": "integer (0-32767)"
          }
        ]
      },
      "networkEndpoint": {
        "ipv4Address": "string",
        "transportProtocol": "TCP | UDP",
        "port": "integer (1-65535)"
      }
    }
  }
}
```

## Next Steps

- **Level 5**: Advanced topics including PHM, UCM, IAM, security integration

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: AUTOSAR Adaptive developers needing API reference
