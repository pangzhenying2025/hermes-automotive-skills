# Azure IoT Hub Module Variables

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# IoT Hub Configuration
variable "iot_hub_sku_name" {
  description = "IoT Hub SKU (F1, S1, S2, S3)"
  type        = string
  default     = "S1"

  validation {
    condition     = contains(["F1", "S1", "S2", "S3"], var.iot_hub_sku_name)
    error_message = "IoT Hub SKU must be F1, S1, S2, or S3"
  }
}

variable "iot_hub_sku_capacity" {
  description = "IoT Hub capacity (number of units)"
  type        = number
  default     = 1
}

# Device Provisioning Service
variable "dps_sku_capacity" {
  description = "DPS capacity (number of units)"
  type        = number
  default     = 1
}

# Event Hub Configuration
variable "eventhub_sku" {
  description = "Event Hub namespace SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "eventhub_capacity" {
  description = "Event Hub namespace capacity (throughput units)"
  type        = number
  default     = 2
}

variable "eventhub_auto_inflate" {
  description = "Enable auto-inflate for Event Hub"
  type        = bool
  default     = true
}

variable "eventhub_max_throughput_units" {
  description = "Maximum throughput units for auto-inflate"
  type        = number
  default     = 10
}

variable "eventhub_partition_count" {
  description = "Number of partitions for Event Hub"
  type        = number
  default     = 4
}

variable "eventhub_message_retention" {
  description = "Message retention in days"
  type        = number
  default     = 7
}

variable "enable_capture" {
  description = "Enable Event Hub capture to storage"
  type        = bool
  default     = true
}

# Storage Configuration
variable "storage_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "GRS"
}

variable "blob_retention_days" {
  description = "Blob soft delete retention in days"
  type        = number
  default     = 30
}

# Stream Analytics Configuration
variable "enable_stream_analytics" {
  description = "Enable Stream Analytics for real-time processing"
  type        = bool
  default     = true
}

variable "stream_analytics_units" {
  description = "Number of streaming units for Stream Analytics"
  type        = number
  default     = 3
}

variable "stream_analytics_query" {
  description = "Stream Analytics query for telemetry processing"
  type        = string
  default     = <<QUERY
SELECT
    System.Timestamp() AS EventTime,
    IoTHub.ConnectionDeviceId AS DeviceId,
    VehicleId,
    Latitude,
    Longitude,
    Speed,
    BatteryLevel,
    Temperature
INTO
    [telemetry-output]
FROM
    [telemetry-input]
QUERY
}

# Private Endpoint Configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for IoT Hub"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = ""
}
