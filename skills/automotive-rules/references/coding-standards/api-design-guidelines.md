# API Design Guidelines for Automotive Systems

> REST and gRPC API design standards for automotive cloud platforms,
> telematics backends, fleet management, and diagnostic services.

## Scope

These guidelines apply to all APIs exposed by automotive backend services,
including vehicle-to-cloud telemetry, OTA update management, fleet
analytics, remote diagnostics, and dealer/service portal integrations.

---

## General Principles

### 1. Contract-First Design

All APIs must be designed contract-first before implementation begins.

- **REST APIs**: OpenAPI 3.1 specification
- **gRPC APIs**: Protocol Buffer `.proto` files
- **Event APIs**: AsyncAPI 2.6 specification

```yaml
# OpenAPI 3.1 - Vehicle Telemetry API
openapi: 3.1.0
info:
  title: Vehicle Telemetry API
  version: 2.1.0
  description: |
    Real-time and historical telemetry data from connected vehicles.
    Supports battery electric vehicles (BEV), hybrid (HEV), and ICE.
  contact:
    name: Connected Vehicle Platform Team
    email: cvp-team@example.com
```

### 2. Versioning Strategy

All APIs must be versioned from day one.

```
# URI versioning (preferred for REST)
GET /api/v2/vehicles/{vin}/telemetry

# Header versioning (alternative)
GET /api/vehicles/{vin}/telemetry
Accept: application/vnd.automotive.v2+json

# gRPC package versioning
package automotive.telemetry.v2;
```

**Rule**: Version increment policy:
- **Major** (v1 -> v2): Breaking changes, removed fields, changed semantics
- **Minor** (v2.1 -> v2.2): New optional fields, new endpoints
- **Patch** (v2.1.0 -> v2.1.1): Bug fixes, documentation updates

**Rule**: Support previous major version for minimum 12 months after
deprecation announcement.

### 3. API Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Base URL | `https://api.{domain}/v{n}` | `https://api.fleet.example.com/v2` |
| Resources | Plural nouns, kebab-case | `/vehicles`, `/battery-packs` |
| Path params | camelCase | `/vehicles/{vehicleId}` |
| Query params | camelCase | `?startTime=...&pageSize=50` |
| Request body | camelCase JSON | `{ "targetSoc": 80 }` |
| Response body | camelCase JSON | `{ "currentSoc": 65.5 }` |
| gRPC services | PascalCase | `TelemetryService` |
| gRPC methods | PascalCase | `GetVehicleTelemetry` |
| Proto fields | snake_case | `battery_soc_percent` |
| Headers | Kebab-Case | `X-Correlation-Id` |

---

## REST API Design

### Resource Hierarchy

```
/api/v2/
  vehicles/
    {vin}/
      telemetry/                    # Real-time telemetry
      telemetry/history             # Historical telemetry
      battery-pack/                 # Battery state
      battery-pack/cells            # Individual cell data
      diagnostics/                  # DTC codes and health
      diagnostics/dtc-codes         # Active fault codes
      location/                     # Current position
      location/trips                # Trip history
      commands/                     # Remote commands
      commands/{commandId}/status   # Command execution status
      software/                     # Software inventory
      software/updates              # Available updates
  fleets/
    {fleetId}/
      vehicles/                     # Fleet vehicle list
      analytics/                    # Fleet-level analytics
      geofences/                    # Geographic boundaries
```

### HTTP Methods

| Method | Use Case | Idempotent | Safe |
|--------|----------|-----------|------|
| GET | Retrieve resource(s) | Yes | Yes |
| POST | Create resource, trigger action | No | No |
| PUT | Full resource replacement | Yes | No |
| PATCH | Partial resource update | No | No |
| DELETE | Remove resource | Yes | No |

### Standard Request/Response Patterns

#### Successful Responses

```json
// GET /api/v2/vehicles/{vin}/telemetry
// 200 OK
{
  "data": {
    "vin": "WBA12345678901234",
    "timestamp": "2025-03-19T14:30:00.000Z",
    "battery": {
      "socPercent": 72.5,
      "sohPercent": 96.2,
      "voltageV": 398.4,
      "currentA": -12.3,
      "temperatureCelsius": 28.5,
      "chargingStatus": "DISCHARGING"
    },
    "drivetrain": {
      "speedKmh": 85.2,
      "torqueNm": 145.0,
      "powerKw": 42.3
    }
  },
  "metadata": {
    "requestId": "req-a1b2c3d4",
    "processingTimeMs": 23
  }
}
```

#### Collection Responses with Pagination

```json
// GET /api/v2/vehicles?fleetId=fleet-001&pageSize=20&pageToken=abc123
// 200 OK
{
  "data": [
    { "vin": "WBA12345678901234", "model": "iX3", "status": "ONLINE" },
    { "vin": "WBA98765432109876", "model": "i4", "status": "OFFLINE" }
  ],
  "pagination": {
    "pageSize": 20,
    "nextPageToken": "def456",
    "totalCount": 1847
  },
  "metadata": {
    "requestId": "req-e5f6g7h8",
    "processingTimeMs": 45
  }
}
```

#### Error Responses

```json
// 422 Unprocessable Entity
{
  "error": {
    "code": "INVALID_VIN_FORMAT",
    "message": "The provided VIN does not conform to ISO 3779 format.",
    "target": "vin",
    "details": [
      {
        "code": "VIN_CHECK_DIGIT_INVALID",
        "message": "Check digit at position 9 is incorrect.",
        "target": "vin[8]"
      }
    ],
    "traceId": "trace-x1y2z3",
    "timestamp": "2025-03-19T14:30:00.000Z",
    "documentationUrl": "https://docs.api.example.com/errors/INVALID_VIN_FORMAT"
  }
}
```

### HTTP Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST creating a resource |
| 202 | Accepted | Async operation accepted (remote commands) |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Malformed request syntax |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | State conflict (e.g., duplicate VIN) |
| 422 | Unprocessable | Valid syntax but invalid semantics |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Error | Unexpected server failure |
| 503 | Service Unavailable | Maintenance or overload |

---

## gRPC API Design

### Service Definition

```protobuf
syntax = "proto3";
package automotive.telemetry.v2;

import "google/protobuf/timestamp.proto";

// Vehicle telemetry data service
service TelemetryService {
  // Get current telemetry snapshot for a vehicle
  rpc GetTelemetry(GetTelemetryRequest)
      returns (GetTelemetryResponse);

  // Stream real-time telemetry updates
  rpc StreamTelemetry(StreamTelemetryRequest)
      returns (stream TelemetryEvent);

  // Batch upload telemetry from vehicle gateway
  rpc UploadTelemetry(stream TelemetryBatch)
      returns (UploadTelemetryResponse);

  // Get historical telemetry with time range
  rpc GetTelemetryHistory(GetTelemetryHistoryRequest)
      returns (GetTelemetryHistoryResponse);
}

message GetTelemetryRequest {
  string vin = 1;
  repeated string signal_names = 2;  // Empty = all signals
}

message BatteryTelemetry {
  float soc_percent = 1;
  float soh_percent = 2;
  float voltage_v = 3;
  float current_a = 4;
  float temperature_celsius = 5;
  ChargingStatus charging_status = 6;
}

enum ChargingStatus {
  CHARGING_STATUS_UNSPECIFIED = 0;
  CHARGING_STATUS_IDLE = 1;
  CHARGING_STATUS_CHARGING = 2;
  CHARGING_STATUS_DISCHARGING = 3;
  CHARGING_STATUS_BALANCING = 4;
  CHARGING_STATUS_ERROR = 5;
}
```

### Proto Style Rules

- Every enum must have an `UNSPECIFIED = 0` value
- Use `repeated` instead of custom list wrappers
- Use `google.protobuf.Timestamp` for time fields
- Use `google.protobuf.Duration` for time intervals
- Field numbers 1-15 use 1 byte (reserve for frequent fields)
- Never reuse or change field numbers (use `reserved`)
- Add comments for every message, field, and RPC method

---

## Authentication and Authorization

### OAuth 2.0 / OpenID Connect

```
# Authorization flow for service-to-service
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=fleet-management-service
&client_secret={secret}
&scope=vehicles.telemetry.read vehicles.commands.write
```

### Scope Definitions

| Scope | Access Level | Example Consumer |
|-------|-------------|-----------------|
| `vehicles.telemetry.read` | Read telemetry data | Analytics dashboard |
| `vehicles.telemetry.write` | Upload telemetry | Vehicle gateway |
| `vehicles.commands.write` | Send remote commands | Mobile app |
| `vehicles.diagnostics.read` | Read fault codes | Service portal |
| `vehicles.software.admin` | Manage OTA updates | OTA platform |
| `fleet.manage` | Full fleet management | Fleet operator |

### API Key Rules

- API keys for identification, not authentication
- Always pair with OAuth tokens for authorization
- Rotate keys every 90 days
- Rate limit per API key independently
- Never embed keys in mobile apps or frontend code

---

## Rate Limiting

```
# Rate limit headers in every response
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 742
X-RateLimit-Reset: 1679234400
Retry-After: 30
```

### Default Rate Limits

| Tier | Requests/min | Burst | Use Case |
|------|-------------|-------|----------|
| Vehicle Gateway | 600 | 100 | Telemetry upload |
| Fleet Portal | 300 | 50 | Dashboard queries |
| Mobile App | 120 | 20 | Driver interactions |
| Partner API | 60 | 10 | Third-party access |

---

## Automotive-Specific Patterns

### VIN Validation

```
# VIN must conform to ISO 3779
# 17 characters: [A-HJ-NPR-Z0-9]{17}
# Position 9 is check digit (North America)
# Validate before processing any vehicle request
```

### Signal Naming Convention

Follow the Vehicle Signal Specification (VSS) naming:

```
Vehicle.Powertrain.Battery.StateOfCharge.Current
Vehicle.Powertrain.Battery.Voltage
Vehicle.Chassis.Axle.Row1.Wheel.Left.Tire.Pressure
Vehicle.Body.Lights.Beam.Low.IsOn
```

### Coordinate System

- Use WGS84 (EPSG:4326) for all geographic coordinates
- Latitude: -90 to +90 degrees, 7 decimal places minimum
- Longitude: -180 to +180 degrees, 7 decimal places minimum
- Altitude: meters above WGS84 ellipsoid
- Heading: 0-359.9 degrees from true north

### Time Handling

- All timestamps in UTC ISO 8601 format
- Millisecond precision minimum for telemetry
- Include timezone offset only for display, never for storage
- Vehicle time synchronized via NTP/GNSS
- Handle clock skew: accept timestamps within +/- 5 minutes

---

## API Documentation Requirements

Every API must have:

1. **OpenAPI/Proto specification file** in version control
2. **Getting started guide** with authentication setup
3. **Code examples** in at least Python, Java, and cURL
4. **Changelog** with every version documenting breaking changes
5. **SLA documentation** with availability and latency targets
6. **Error catalog** with every error code, cause, and resolution

---

## Review Checklist

- [ ] Contract defined before implementation (OpenAPI/Proto)
- [ ] API versioned from v1 with clear upgrade path
- [ ] Resources named as plural nouns in kebab-case
- [ ] Standard HTTP status codes used correctly
- [ ] Pagination implemented for all collection endpoints
- [ ] Error responses follow standard error schema
- [ ] Authentication via OAuth 2.0 with appropriate scopes
- [ ] Rate limiting configured per consumer tier
- [ ] VIN validation on all vehicle-scoped endpoints
- [ ] Timestamps in UTC ISO 8601 with millisecond precision
- [ ] gRPC enums have UNSPECIFIED zero value
- [ ] API documentation complete with examples
- [ ] Breaking changes follow deprecation policy
- [ ] Correlation/trace IDs propagated through all calls
