# Azure IoT Hub Module

Terraform module for deploying Azure IoT Hub infrastructure for vehicle fleet management.

## Features

- **Azure IoT Hub**: Device connectivity with MQTT/AMQP/HTTPS protocols
- **Device Provisioning Service (DPS)**: Zero-touch device provisioning
- **Event Hub**: Scalable telemetry ingestion with auto-inflate
- **Stream Analytics**: Real-time telemetry processing
- **Storage Account**: File uploads and Event Hub capture
- **Private Endpoints**: Secure network connectivity
- **Monitoring**: Diagnostic settings and Log Analytics integration

## Architecture

```
┌──────────────┐
│   Vehicles   │
└──────┬───────┘
       │ MQTT/AMQP
┌──────▼───────────────┐
│  Device Provisioning │
│      Service (DPS)   │
└──────┬───────────────┘
       │
┌──────▼───────────┐      ┌───────────────────┐
│   Azure IoT Hub  │─────>│   Event Hub       │
│                  │      │   (Telemetry)     │
└──────┬───────────┘      └────────┬──────────┘
       │                           │
       │ File Upload        ┌──────▼──────────────┐
       │                    │ Stream Analytics    │
       │                    │ (Real-time)         │
       │                    └──────┬──────────────┘
┌──────▼───────────┐               │
│ Blob Storage     │               │
│ - File Uploads   │<──────────────┘
│ - Archive        │
└──────────────────┘
```

## Usage

```hcl
module "iot_hub" {
  source = "../../modules/iot-hub"

  project_name = "vehicle-fleet"
  location     = "eastus"

  # IoT Hub Configuration
  iot_hub_sku_name     = "S1"
  iot_hub_sku_capacity = 2

  # Event Hub Configuration
  eventhub_sku                 = "Standard"
  eventhub_capacity            = 4
  eventhub_auto_inflate        = true
  eventhub_max_throughput_units = 20
  eventhub_partition_count     = 8
  eventhub_message_retention   = 7
  enable_capture               = true

  # Stream Analytics
  enable_stream_analytics  = true
  stream_analytics_units   = 6
  stream_analytics_query   = file("${path.module}/stream-analytics-query.sql")

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "automotive-iot"
  }
}
```

## Scaling Guidelines

### IoT Hub SKU Selection

| SKU | Max Messages/Day | Use Case | Cost/Unit/Month |
|-----|------------------|----------|-----------------|
| **F1** | 8,000 | Development/Testing | Free |
| **S1** | 400,000 | Small fleets (< 10K vehicles) | $25 |
| **S2** | 6,000,000 | Medium fleets (10K-100K vehicles) | $250 |
| **S3** | 300,000,000 | Large fleets (> 100K vehicles) | $2,500 |

**Formula**: `(Vehicles × Messages/sec × 86400) / Messages/Day/Unit`

Example: 10,000 vehicles × 1 msg/sec = 864M msgs/day → 3× S3 units

### Event Hub Throughput Units

| Throughput Units | Ingress | Egress | Use Case |
|------------------|---------|--------|----------|
| **1-2** | 1-2 MB/s | 2-4 MB/s | < 5K vehicles |
| **4-8** | 4-8 MB/s | 8-16 MB/s | 5K-20K vehicles |
| **10-20** | 10-20 MB/s | 20-40 MB/s | 20K-100K vehicles |

Enable **auto-inflate** for variable workloads.

### Stream Analytics Units

| Streaming Units | Processing | Latency | Use Case |
|-----------------|------------|---------|----------|
| **1-3** | Basic aggregations | < 5s | Simple queries |
| **6-12** | Complex joins | < 10s | Multi-source joins |
| **18+** | ML inference | < 3s | Real-time anomaly detection |

## Security Best Practices

1. **Private Endpoints**: Enable for production environments
2. **Managed Identity**: Use for Stream Analytics → Storage access
3. **DPS Enrollment Groups**: Organize devices by vehicle model
4. **Certificate-based Auth**: Prefer X.509 over SAS tokens
5. **Network Rules**: Restrict IoT Hub to known IP ranges

## Cost Optimization

1. **Right-size SKU**: Start with S1, scale up based on metrics
2. **Event Hub Capture**: Archive to Cool/Archive storage tier
3. **Stream Analytics**: Use tumbling windows to reduce SU consumption
4. **Blob Lifecycle**: Transition old data to Archive tier
5. **Reserved Capacity**: Commit to 1-3 years for 65% discount

## Monitoring

Key metrics to monitor:

- **IoT Hub**: Connected devices, message count, throttling errors
- **Event Hub**: Incoming messages, incoming bytes, throttled requests
- **Stream Analytics**: Watermark delay, input/output events, errors
- **Storage**: Transaction count, egress bandwidth

## Examples

See `../../examples/vehicle-fleet/` for complete deployment example.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | n/a | yes |
| location | Azure region | string | "eastus" | no |
| iot_hub_sku_name | IoT Hub SKU (F1, S1, S2, S3) | string | "S1" | no |
| iot_hub_sku_capacity | IoT Hub capacity | number | 1 | no |
| eventhub_sku | Event Hub SKU | string | "Standard" | no |
| eventhub_capacity | Event Hub throughput units | number | 2 | no |
| enable_stream_analytics | Enable Stream Analytics | bool | true | no |

See `variables.tf` for complete list.

## Outputs

| Name | Description |
|------|-------------|
| iot_hub_hostname | IoT Hub hostname for device connections |
| dps_id_scope | DPS ID scope for provisioning |
| eventhub_name | Event Hub name for telemetry |
| storage_account_name | Storage account name |

See `outputs.tf` for complete list.

## References

- [Azure IoT Hub Documentation](https://docs.microsoft.com/en-us/azure/iot-hub/)
- [Device Provisioning Service](https://docs.microsoft.com/en-us/azure/iot-dps/)
- [Event Hubs Documentation](https://docs.microsoft.com/en-us/azure/event-hubs/)
- [Stream Analytics Query Language](https://docs.microsoft.com/en-us/stream-analytics-query/stream-analytics-query-language-reference)
