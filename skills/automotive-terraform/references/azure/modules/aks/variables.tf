# Azure AKS Module Variables

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

# AKS Cluster Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel (none, patch, stable, rapid, node-image)"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.automatic_channel_upgrade)
    error_message = "Must be one of: none, patch, stable, rapid, node-image"
  }
}

variable "sku_tier" {
  description = "AKS SKU tier (Free, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "Must be Free, Standard, or Premium"
  }
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# System Node Pool Configuration
variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "system_node_pool_node_count" {
  description = "Number of nodes in system node pool"
  type        = number
  default     = 3
}

variable "system_node_pool_enable_autoscaling" {
  description = "Enable autoscaling for system node pool"
  type        = bool
  default     = true
}

variable "system_node_pool_min_count" {
  description = "Minimum nodes for system node pool autoscaling"
  type        = number
  default     = 3
}

variable "system_node_pool_max_count" {
  description = "Maximum nodes for system node pool autoscaling"
  type        = number
  default     = 10
}

variable "system_node_pool_os_disk_size_gb" {
  description = "OS disk size for system node pool"
  type        = number
  default     = 128
}

# User Node Pool Configuration
variable "create_user_node_pool" {
  description = "Create user node pool for application workloads"
  type        = bool
  default     = true
}

variable "user_node_pool_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D8s_v3"
}

variable "user_node_pool_node_count" {
  description = "Number of nodes in user node pool"
  type        = number
  default     = 3
}

variable "user_node_pool_enable_autoscaling" {
  description = "Enable autoscaling for user node pool"
  type        = bool
  default     = true
}

variable "user_node_pool_min_count" {
  description = "Minimum nodes for user node pool autoscaling"
  type        = number
  default     = 3
}

variable "user_node_pool_max_count" {
  description = "Maximum nodes for user node pool autoscaling"
  type        = number
  default     = 20
}

variable "user_node_pool_os_disk_size_gb" {
  description = "OS disk size for user node pool"
  type        = number
  default     = 256
}

variable "user_node_pool_taints" {
  description = "Taints for user node pool"
  type        = list(string)
  default     = []
}

# Spot Instance Node Pool Configuration
variable "create_spot_node_pool" {
  description = "Create spot instance node pool for batch workloads"
  type        = bool
  default     = false
}

variable "spot_node_pool_vm_size" {
  description = "VM size for spot node pool"
  type        = string
  default     = "Standard_D8s_v3"
}

variable "spot_node_pool_node_count" {
  description = "Number of nodes in spot node pool"
  type        = number
  default     = 1
}

variable "spot_node_pool_enable_autoscaling" {
  description = "Enable autoscaling for spot node pool"
  type        = bool
  default     = true
}

variable "spot_node_pool_min_count" {
  description = "Minimum nodes for spot node pool autoscaling"
  type        = number
  default     = 0
}

variable "spot_node_pool_max_count" {
  description = "Maximum nodes for spot node pool autoscaling"
  type        = number
  default     = 10
}

variable "spot_node_pool_os_disk_size_gb" {
  description = "OS disk size for spot node pool"
  type        = number
  default     = 128
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (-1 for on-demand price)"
  type        = number
  default     = -1
}

# Network Configuration
variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin (azure, kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Must be azure or kubenet"
  }
}

variable "network_policy" {
  description = "Network policy (calico, azure)"
  type        = string
  default     = "calico"

  validation {
    condition     = contains(["calico", "azure", ""], var.network_policy)
    error_message = "Must be calico, azure, or empty"
  }
}

variable "dns_service_ip" {
  description = "DNS service IP address"
  type        = string
  default     = "10.0.64.10"
}

variable "service_cidr" {
  description = "Service CIDR range"
  type        = string
  default     = "10.0.64.0/19"
}

variable "load_balancer_outbound_ip_count" {
  description = "Number of outbound IPs for load balancer"
  type        = number
  default     = 1
}

# Container Registry Configuration
variable "create_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_sku" {
  description = "ACR SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "Must be Basic, Standard, or Premium"
  }
}

variable "acr_geo_replications" {
  description = "ACR geo-replication configuration"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = []
}

# Monitoring Configuration
variable "enable_log_analytics" {
  description = "Enable Log Analytics workspace and Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

# Add-ons Configuration
variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = true
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider"
  type        = bool
  default     = true
}

# Azure AD RBAC Configuration
variable "enable_azure_ad_rbac" {
  description = "Enable Azure AD RBAC for cluster access"
  type        = bool
  default     = true
}

variable "azure_ad_admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

# Maintenance Window Configuration
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    allowed = list(object({
      day   = string
      hours = list(number)
    }))
  })
  default = null
}
