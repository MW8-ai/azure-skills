provider "azurerm" {
  features {}

  # Storage data operations should use Microsoft Entra ID rather than Shared Key.
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}
