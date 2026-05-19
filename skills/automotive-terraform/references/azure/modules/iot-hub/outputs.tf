# Azure IoT Hub Module Outputs

output "iot_hub_id" {
  description = "IoT Hub resource ID"
  value       = azurerm_iothub.main.id
}

output "iot_hub_name" {
  description = "IoT Hub name"
  value       = azurerm_iothub.main.name
}

output "iot_hub_hostname" {
  description = "IoT Hub hostname for device connections"
  value       = azurerm_iothub.main.hostname
}

output "iot_hub_connection_string" {
  description = "IoT Hub connection string (sensitive)"
  value       = azurerm_iothub.main.connection_string
  sensitive   = true
}

output "dps_id" {
  description = "Device Provisioning Service ID"
  value       = azurerm_iothub_dps.main.id
}

output "dps_name" {
  description = "Device Provisioning Service name"
  value       = azurerm_iothub_dps.main.name
}

output "dps_id_scope" {
  description = "DPS ID scope for device provisioning"
  value       = azurerm_iothub_dps.main.id_scope
}

output "eventhub_namespace_id" {
  description = "Event Hub namespace ID"
  value       = azurerm_eventhub_namespace.telemetry.id
}

output "eventhub_namespace_name" {
  description = "Event Hub namespace name"
  value       = azurerm_eventhub_namespace.telemetry.name
}

output "eventhub_name" {
  description = "Event Hub name for telemetry"
  value       = azurerm_eventhub.telemetry.name
}

output "eventhub_connection_string" {
  description = "Event Hub connection string (sensitive)"
  value       = azurerm_eventhub_namespace.telemetry.default_primary_connection_string
  sensitive   = true
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.iot.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.iot.name
}

output "storage_account_primary_connection_string" {
  description = "Storage account primary connection string (sensitive)"
  value       = azurerm_storage_account.iot.primary_connection_string
  sensitive   = true
}

output "stream_analytics_job_id" {
  description = "Stream Analytics job ID"
  value       = var.enable_stream_analytics ? azurerm_stream_analytics_job.telemetry[0].id : ""
}

output "stream_analytics_job_name" {
  description = "Stream Analytics job name"
  value       = var.enable_stream_analytics ? azurerm_stream_analytics_job.telemetry[0].name : ""
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.iot.name
}

output "resource_group_location" {
  description = "Resource group location"
  value       = azurerm_resource_group.iot.location
}
