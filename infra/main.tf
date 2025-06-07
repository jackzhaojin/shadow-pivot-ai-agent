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
  # Remote state backend
  backend "azurerm" {
    resource_group_name  = "ShadowPivot"
    storage_account_name = "shadowpivotterraform"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  # Hybrid authentication: CLI for local development, OIDC for CI/CD
  # Environment variables in CI/CD will automatically enable OIDC authentication
  use_cli  = var.use_cli_auth
  use_msi  = false
  use_oidc = var.use_oidc_auth

  # Enable automatic resource provider registration
  # This requires subscription-level permissions for the service principal
  skip_provider_registration = false
}

# Data sources
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}
