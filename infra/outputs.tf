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

# Logic App Outputs
output "entry_logic_app_id" {
  description = "The ID of the entry logic app workflow"
  value       = azurerm_logic_app_workflow.entry.id
}

output "design_gen_logic_app_id" {
  description = "The ID of the design generation logic app workflow"
  value       = azurerm_logic_app_workflow.design_gen.id
}

output "content_gen_logic_app_id" {
  description = "The ID of the content generation logic app workflow"
  value       = azurerm_logic_app_workflow.content_gen.id
}

output "review_logic_app_id" {
  description = "The ID of the review logic app workflow"
  value       = azurerm_logic_app_workflow.review.id
}

output "storage_connection_id" {
  description = "The ID of the storage queues API connection"
  value       = azurerm_api_connection.storage_queues.id
}
