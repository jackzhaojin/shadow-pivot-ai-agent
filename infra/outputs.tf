output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_connection_string" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "design_gen_queue_name" {
  description = "The name of the design generation queue"
  value       = azurerm_storage_queue.design_gen_q.name
}

output "content_gen_queue_name" {
  description = "The name of the content generation queue"
  value       = azurerm_storage_queue.content_gen_q.name
}

output "review_queue_name" {
  description = "The name of the review queue"
  value       = azurerm_storage_queue.review_q.name
}

output "completion_queue_name" {
  description = "The name of the completion queue"
  value       = azurerm_storage_queue.completion_q.name
}

output "ai_artifacts_container_name" {
  description = "The name of the AI artifacts storage container"
  value       = azurerm_storage_container.ai_artifacts.name
}
