variable "resource_group_name" {
  description = "The name of the existing Azure resource group"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API Key for Logic Apps"
  type        = string
  sensitive   = true
  default     = ""
}
