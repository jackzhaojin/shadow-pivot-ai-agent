variable "resource_group_name" {
  description = "The name of the existing Azure resource group"
  type        = string
}

variable "ai_foundry_location" {
  description = "The Azure region for AI Foundry deployment"
  type        = string
  default     = "East US"
}
