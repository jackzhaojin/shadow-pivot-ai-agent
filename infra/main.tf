terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
  
  # Use OIDC authentication in CI/CD
  use_cli = false
  use_msi = false
  use_oidc = true
  
  # Disable automatic resource provider registration
  # This is needed when the service principal doesn't have subscription-level permissions
  resource_provider_registrations = "none"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "main" {
  name                     = "shdwagentstorage"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_queue" "design_gen_q" {
  name                 = "design-gen-q"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_queue" "content_gen_q" {
  name                 = "content-gen-q"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_queue" "review_q" {
  name                 = "review-q"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_queue" "completion_q" {
  name                 = "completion-q"
  storage_account_name = azurerm_storage_account.main.name
}

# Storage container for blob storage
resource "azurerm_storage_container" "ai_artifacts" {
  name                  = "ai-artifacts"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
