# Azure IoT Hub Module for Vehicle Fleet Management
# Handles device connectivity, telemetry ingestion, and event processing

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "iot" {
  name     = "${var.project_name}-iot-rg"
  location = var.location
  tags     = var.tags
}

# IoT Hub
resource "azurerm_iothub" "main" {
  name                = "${var.project_name}-iothub"
  resource_group_name = azurerm_resource_group.iot.name
  location            = azurerm_resource_group.iot.location
  sku {
    name     = var.iot_hub_sku_name
    capacity = var.iot_hub_sku_capacity
  }

  # Event Hub endpoints for telemetry
  endpoint {
    type                       = "AzureIotHub.EventHub"
    connection_string          = azurerm_eventhub_authorization_rule.iothub.primary_connection_string
    name                       = "telemetry-endpoint"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    encoding                   = "JSON"
  }

  # Routes
  route {
    name           = "TelemetryRoute"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["telemetry-endpoint"]
    enabled        = true
  }

  fallback_route {
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["events"]
    enabled        = true
  }

  # File upload configuration
  file_upload {
    connection_string  = azurerm_storage_account.iot.primary_connection_string
    container_name     = azurerm_storage_container.file_upload.name
    sas_ttl            = "PT1H"
    notifications      = true
    lock_duration      = "PT1M"
    default_ttl        = "PT1H"
    max_delivery_count = 10
  }

  # Cloud-to-device messaging
  cloud_to_device {
    max_delivery_count = 30
    default_ttl        = "PT1H"

    feedback {
      time_to_live       = "PT1H"
      max_delivery_count = 10
      lock_duration      = "PT30S"
    }
  }

  tags = var.tags
}

# Device Provisioning Service (DPS)
resource "azurerm_iothub_dps" "main" {
  name                = "${var.project_name}-dps"
  resource_group_name = azurerm_resource_group.iot.name
  location            = azurerm_resource_group.iot.location
  allocation_policy   = "Hashed"

  sku {
    name     = "S1"
    capacity = var.dps_sku_capacity
  }

  linked_hub {
    connection_string       = azurerm_iothub.main.connection_string
    location                = azurerm_resource_group.iot.location
    allocation_weight       = 100
    apply_allocation_policy = true
  }

  tags = var.tags
}

# Event Hub Namespace for telemetry processing
resource "azurerm_eventhub_namespace" "telemetry" {
  name                = "${var.project_name}-eventhub-ns"
  location            = azurerm_resource_group.iot.location
  resource_group_name = azurerm_resource_group.iot.name
  sku                 = var.eventhub_sku
  capacity            = var.eventhub_capacity

  auto_inflate_enabled     = var.eventhub_auto_inflate
  maximum_throughput_units = var.eventhub_max_throughput_units

  tags = var.tags
}

# Event Hub for telemetry
resource "azurerm_eventhub" "telemetry" {
  name                = "vehicle-telemetry"
  namespace_name      = azurerm_eventhub_namespace.telemetry.name
  resource_group_name = azurerm_resource_group.iot.name
  partition_count     = var.eventhub_partition_count
  message_retention   = var.eventhub_message_retention

  capture_description {
    enabled  = var.enable_capture
    encoding = "Avro"

    destination {
      name                = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = azurerm_storage_container.capture.name
      storage_account_id  = azurerm_storage_account.iot.id
    }
  }

  tags = var.tags
}

# Event Hub Authorization Rule
resource "azurerm_eventhub_authorization_rule" "iothub" {
  name                = "iothub-sender"
  namespace_name      = azurerm_eventhub_namespace.telemetry.name
  eventhub_name       = azurerm_eventhub.telemetry.name
  resource_group_name = azurerm_resource_group.iot.name
  listen              = false
  send                = true
  manage              = false
}

# Consumer Groups for different processors
resource "azurerm_eventhub_consumer_group" "stream_analytics" {
  name                = "stream-analytics"
  namespace_name      = azurerm_eventhub_namespace.telemetry.name
  eventhub_name       = azurerm_eventhub.telemetry.name
  resource_group_name = azurerm_resource_group.iot.name
}

resource "azurerm_eventhub_consumer_group" "time_series" {
  name                = "time-series-ingestion"
  namespace_name      = azurerm_eventhub_namespace.telemetry.name
  eventhub_name       = azurerm_eventhub.telemetry.name
  resource_group_name = azurerm_resource_group.iot.name
}

# Storage Account for file uploads and capture
resource "azurerm_storage_account" "iot" {
  name                     = lower(replace("${var.project_name}iotst", "/[-_]/", ""))
  resource_group_name      = azurerm_resource_group.iot.name
  location                 = azurerm_resource_group.iot.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.blob_retention_days
    }

    container_delete_retention_policy {
      days = var.blob_retention_days
    }
  }

  tags = var.tags
}

# Storage Container for file uploads
resource "azurerm_storage_container" "file_upload" {
  name                  = "vehicle-file-uploads"
  storage_account_name  = azurerm_storage_account.iot.name
  container_access_type = "private"
}

# Storage Container for Event Hub capture
resource "azurerm_storage_container" "capture" {
  name                  = "telemetry-archive"
  storage_account_name  = azurerm_storage_account.iot.name
  container_access_type = "private"
}

# Stream Analytics Job for real-time processing
resource "azurerm_stream_analytics_job" "telemetry" {
  count                                = var.enable_stream_analytics ? 1 : 0
  name                                 = "${var.project_name}-stream-analytics"
  resource_group_name                  = azurerm_resource_group.iot.name
  location                             = azurerm_resource_group.iot.location
  compatibility_level                  = "1.2"
  data_locale                          = "en-US"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy           = "Adjust"
  output_error_policy                  = "Drop"
  streaming_units                      = var.stream_analytics_units
  transformation_query                 = var.stream_analytics_query

  tags = var.tags
}

# Stream Analytics Input
resource "azurerm_stream_analytics_stream_input_eventhub" "telemetry" {
  count                        = var.enable_stream_analytics ? 1 : 0
  name                         = "telemetry-input"
  stream_analytics_job_name    = azurerm_stream_analytics_job.telemetry[0].name
  resource_group_name          = azurerm_resource_group.iot.name
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.stream_analytics.name
  eventhub_name                = azurerm_eventhub.telemetry.name
  servicebus_namespace         = azurerm_eventhub_namespace.telemetry.name
  shared_access_policy_key     = azurerm_eventhub_namespace.telemetry.default_primary_key
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

# Private Endpoint for IoT Hub
resource "azurerm_private_endpoint" "iothub" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.project_name}-iothub-pe"
  location            = azurerm_resource_group.iot.location
  resource_group_name = azurerm_resource_group.iot.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-iothub-psc"
    private_connection_resource_id = azurerm_iothub.main.id
    is_manual_connection           = false
    subresource_names              = ["iotHub"]
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "iothub" {
  name                       = "${var.project_name}-iothub-diagnostics"
  target_resource_id         = azurerm_iothub.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Connections"
  }

  enabled_log {
    category = "DeviceTelemetry"
  }

  enabled_log {
    category = "C2DCommands"
  }

  enabled_log {
    category = "DeviceIdentityOperations"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
