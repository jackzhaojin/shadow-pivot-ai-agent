terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
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
  skip_provider_registration = true
}

# Data sources
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}
