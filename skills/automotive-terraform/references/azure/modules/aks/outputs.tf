# Azure AKS Module Outputs

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config" {
  description = "Kubernetes configuration (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (sensitive)"
  value       = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate (sensitive)"
  value       = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  sensitive   = true
}

output "client_key" {
  description = "Client key (sensitive)"
  value       = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Kubelet managed identity object ID"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Kubelet managed identity client ID"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
}

output "node_resource_group" {
  description = "AKS node resource group name"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "acr_id" {
  description = "Azure Container Registry ID"
  value       = var.create_acr ? azurerm_container_registry.aks[0].id : null
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = var.create_acr ? azurerm_container_registry.aks[0].name : null
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = var.create_acr ? azurerm_container_registry.aks[0].login_server : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.aks[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.aks[0].name : null
}

output "system_node_pool_name" {
  description = "System node pool name"
  value       = azurerm_kubernetes_cluster.aks.default_node_pool[0].name
}

output "user_node_pool_name" {
  description = "User node pool name"
  value       = var.create_user_node_pool ? azurerm_kubernetes_cluster_node_pool.user[0].name : null
}

output "spot_node_pool_name" {
  description = "Spot node pool name"
  value       = var.create_spot_node_pool ? azurerm_kubernetes_cluster_node_pool.spot[0].name : null
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.aks.name
}

output "resource_group_location" {
  description = "Resource group location"
  value       = azurerm_resource_group.aks.location
}
