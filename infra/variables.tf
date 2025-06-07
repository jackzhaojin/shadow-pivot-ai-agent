variable "resource_group_name" {
  description = "The name of the existing Azure resource group"
  type        = string
}

variable "ai_foundry_location" {
  description = "The Azure region for AI Foundry deployment"
  type        = string
  default     = "East US"
}

# Authentication method variables for hybrid deployment
variable "use_cli_auth" {
  description = "Use Azure CLI authentication (for local development)"
  type        = bool
  default     = true
}

variable "use_oidc_auth" {
  description = "Use OIDC authentication (for CI/CD)"
  type        = bool
  default     = false
}
