locals {
  compact_name  = replace("${var.project_name}${var.environment}", "-", "")
  unique_suffix = substr(md5("${data.azurerm_client_config.current.subscription_id}-${var.project_name}-${var.environment}-tf"), 0, 6)

  names = {
    resource_group = "rg-${var.project_name}-${var.environment}-tf"
    vnet           = "vnet-${var.project_name}-${var.environment}-tf"
    subnet         = "snet-workload"
    nsg            = "nsg-${var.project_name}-${var.environment}-workload"
    identity       = "id-${var.project_name}-${var.environment}-tf"
    log_analytics  = "log-${var.project_name}-${var.environment}-tf"
    key_vault      = substr("kv-${var.project_name}-${var.environment}-${local.unique_suffix}", 0, 24)
    storage        = substr("st${local.compact_name}${local.unique_suffix}", 0, 24)
  }

  tags = {
    application = var.project_name
    environment = var.environment
    owner       = var.owner
    managedBy   = "terraform"
    purpose     = "portfolio-iac-lab"
  }
}
