# Azure Kubernetes Service (AKS) Module
# Managed Kubernetes cluster for vehicle fleet applications

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
resource "azurerm_resource_group" "aks" {
  name     = "${var.project_name}-aks-rg"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = "${var.project_name}-aks-logs"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.project_name}-aks-identity"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  tags                = var.tags
}

# Azure Container Registry
resource "azurerm_container_registry" "aks" {
  count               = var.create_acr ? 1 : 0
  name                = lower(replace("${var.project_name}acr", "/[-_]/", ""))
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = var.acr_sku
  admin_enabled       = false

  dynamic "georeplications" {
    for_each = var.acr_geo_replications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = var.tags
    }
  }

  tags = var.tags
}

# Role Assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.create_acr ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.aks[0].id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "${var.project_name}-aks"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.project_name}-aks-nodes-rg"

  automatic_channel_upgrade = var.automatic_channel_upgrade
  sku_tier                  = var.sku_tier

  # Default System Node Pool
  default_node_pool {
    name                 = "system"
    vm_size              = var.system_node_pool_vm_size
    node_count           = var.system_node_pool_node_count
    enable_auto_scaling  = var.system_node_pool_enable_autoscaling
    min_count            = var.system_node_pool_enable_autoscaling ? var.system_node_pool_min_count : null
    max_count            = var.system_node_pool_enable_autoscaling ? var.system_node_pool_max_count : null
    os_disk_size_gb      = var.system_node_pool_os_disk_size_gb
    os_disk_type         = "Managed"
    vnet_subnet_id       = var.vnet_subnet_id
    zones                = var.availability_zones
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }

    tags = var.tags
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"

    dynamic "load_balancer_profile" {
      for_each = var.network_plugin == "azure" ? [1] : []
      content {
        managed_outbound_ip_count = var.load_balancer_outbound_ip_count
      }
    }
  }

  # Azure Monitor Integration
  dynamic "oms_agent" {
    for_each = var.enable_log_analytics ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
    }
  }

  # Azure Policy Add-on
  dynamic "azure_policy_enabled" {
    for_each = var.enable_azure_policy ? [1] : []
    content {
      enabled = true
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  # Azure Active Directory RBAC
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_rbac ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.azure_ad_admin_group_object_ids
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# User Node Pool for Application Workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                 = var.create_user_node_pool ? 1 : 0
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_pool_vm_size
  node_count            = var.user_node_pool_node_count
  enable_auto_scaling   = var.user_node_pool_enable_autoscaling
  min_count             = var.user_node_pool_enable_autoscaling ? var.user_node_pool_min_count : null
  max_count             = var.user_node_pool_enable_autoscaling ? var.user_node_pool_max_count : null
  os_disk_size_gb       = var.user_node_pool_os_disk_size_gb
  vnet_subnet_id        = var.vnet_subnet_id
  zones                 = var.availability_zones

  node_labels = {
    "workload" = "application"
  }

  node_taints = var.user_node_pool_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Spot Instance Node Pool for batch workloads
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.create_spot_node_pool ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.spot_node_pool_vm_size
  node_count            = var.spot_node_pool_node_count
  enable_auto_scaling   = var.spot_node_pool_enable_autoscaling
  min_count             = var.spot_node_pool_enable_autoscaling ? var.spot_node_pool_min_count : null
  max_count             = var.spot_node_pool_enable_autoscaling ? var.spot_node_pool_max_count : null
  os_disk_size_gb       = var.spot_node_pool_os_disk_size_gb
  vnet_subnet_id        = var.vnet_subnet_id
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = var.spot_max_price

  node_labels = {
    "workload"            = "batch"
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.enable_log_analytics ? 1 : 0
  name                       = "${var.project_name}-aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
