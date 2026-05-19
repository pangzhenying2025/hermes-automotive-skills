# Azure Cosmos DB Module (MongoDB API)
# Multi-region, globally distributed database for vehicle telemetry

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
resource "azurerm_resource_group" "cosmos" {
  name     = "${var.project_name}-cosmos-rg"
  location = var.location
  tags     = var.tags
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-cosmos"
  location            = azurerm_resource_group.cosmos.location
  resource_group_name = azurerm_resource_group.cosmos.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  # Multi-region configuration
  enable_automatic_failover = var.enable_automatic_failover
  enable_multiple_write_locations = var.enable_multiple_write_locations

  # Consistency policy
  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.max_interval_in_seconds
    max_staleness_prefix    = var.max_staleness_prefix
  }

  # Geographic locations
  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  # Capabilities
  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  # Backup configuration
  backup {
    type                = var.backup_type
    interval_in_minutes = var.backup_type == "Periodic" ? var.backup_interval_in_minutes : null
    retention_in_hours  = var.backup_type == "Periodic" ? var.backup_retention_in_hours : null
    storage_redundancy  = var.backup_type == "Periodic" ? var.backup_storage_redundancy : null
  }

  # Network rules
  is_virtual_network_filter_enabled = var.enable_virtual_network_filter
  public_network_access_enabled     = var.public_network_access_enabled

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.subnet_id
      ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
    }
  }

  ip_range_filter = var.ip_range_filter

  # Advanced threat protection
  enable_advanced_threat_protection = var.enable_advanced_threat_protection

  # Analytical storage
  analytical_storage_enabled = var.enable_analytical_storage

  # Free tier
  enable_free_tier = var.enable_free_tier

  tags = var.tags
}

# MongoDB Database
resource "azurerm_cosmosdb_mongo_database" "main" {
  name                = var.database_name
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name

  # Throughput configuration
  dynamic "autoscale_settings" {
    for_each = var.database_autoscale_enabled ? [1] : []
    content {
      max_throughput = var.database_max_throughput
    }
  }

  throughput = var.database_autoscale_enabled ? null : var.database_throughput
}

# MongoDB Collections
resource "azurerm_cosmosdb_mongo_collection" "telemetry" {
  name                = "telemetry"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  # Shard key for horizontal partitioning
  shard_key = "vehicleId"

  # Throughput configuration
  dynamic "autoscale_settings" {
    for_each = var.collection_autoscale_enabled ? [1] : []
    content {
      max_throughput = var.telemetry_collection_max_throughput
    }
  }

  throughput = var.collection_autoscale_enabled ? null : var.telemetry_collection_throughput

  # Indexes
  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys   = ["vehicleId", "timestamp"]
    unique = false
  }

  index {
    keys   = ["timestamp"]
    unique = false
  }

  # TTL index for automatic data expiration
  index {
    keys   = ["_ts"]
    unique = false
  }

  default_ttl_seconds = var.telemetry_ttl_seconds

  # Analytical storage
  analytical_storage_ttl = var.enable_analytical_storage ? var.analytical_storage_ttl : null
}

resource "azurerm_cosmosdb_mongo_collection" "devices" {
  name                = "devices"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  shard_key = "deviceId"

  dynamic "autoscale_settings" {
    for_each = var.collection_autoscale_enabled ? [1] : []
    content {
      max_throughput = var.devices_collection_max_throughput
    }
  }

  throughput = var.collection_autoscale_enabled ? null : var.devices_collection_throughput

  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys   = ["deviceId"]
    unique = true
  }

  index {
    keys   = ["vehicleId"]
    unique = false
  }

  index {
    keys   = ["status"]
    unique = false
  }
}

resource "azurerm_cosmosdb_mongo_collection" "events" {
  name                = "events"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  shard_key = "vehicleId"

  dynamic "autoscale_settings" {
    for_each = var.collection_autoscale_enabled ? [1] : []
    content {
      max_throughput = var.events_collection_max_throughput
    }
  }

  throughput = var.collection_autoscale_enabled ? null : var.events_collection_throughput

  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys   = ["vehicleId", "eventType", "timestamp"]
    unique = false
  }

  index {
    keys   = ["eventType"]
    unique = false
  }

  index {
    keys   = ["severity"]
    unique = false
  }

  default_ttl_seconds = var.events_ttl_seconds
}

# Private Endpoint
resource "azurerm_private_endpoint" "cosmos" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.project_name}-cosmos-pe"
  location            = azurerm_resource_group.cosmos.location
  resource_group_name = azurerm_resource_group.cosmos.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-cosmos-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["MongoDB"]
  }

  tags = var.tags
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "cosmos" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.cosmos.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  count                 = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                  = "${var.project_name}-cosmos-dns-link"
  resource_group_name   = azurerm_resource_group.cosmos.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "cosmos" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = azurerm_cosmosdb_account.main.name
  zone_name           = azurerm_private_dns_zone.cosmos[0].name
  resource_group_name = azurerm_resource_group.cosmos.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.cosmos[0].private_service_connection[0].private_ip_address]
  tags                = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "${var.project_name}-cosmos-diagnostics"
  target_resource_id         = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "MongoRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_log {
    category = "ControlPlaneRequests"
  }

  metric {
    category = "Requests"
    enabled  = true
  }
}
