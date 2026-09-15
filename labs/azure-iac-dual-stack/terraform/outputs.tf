output "resource_group_name" {
  description = "Resource group containing the Terraform lab."
  value       = azurerm_resource_group.lab.name
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "storage_account_name" {
  description = "Storage account protected by Entra-based data access and subnet restrictions."
  value       = azurerm_storage_account.data.name
}

output "key_vault_name" {
  description = "RBAC-enabled Key Vault name."
  value       = azurerm_key_vault.secrets.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.lab.id
}
