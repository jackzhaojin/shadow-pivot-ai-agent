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

# AI Foundry Outputs
output "ai_foundry_endpoint" {
  description = "The endpoint URL for Azure AI Foundry"
  value       = azurerm_cognitive_account.ai_foundry.endpoint
}

output "ai_foundry_name" {
  description = "The name of the Azure AI Foundry resource"
  value       = azurerm_cognitive_account.ai_foundry.name
}

output "managed_identity_client_id" {
  description = "The client ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.logic_apps_identity.client_id
}

output "managed_identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.logic_apps_identity.principal_id
}

output "gpt4_deployment_name" {
  description = "The name of the GPT-4 deployment in AI Foundry"
  value       = azurerm_cognitive_deployment.gpt4.name
}

# Logic App Workflow Deployment Outputs
output "entry_workflow_deployment_id" {
  description = "The ID of the entry workflow ARM template deployment"
  value       = azurerm_resource_group_template_deployment.entry_workflow.id
}

output "design_gen_workflow_deployment_id" {
  description = "The ID of the design generation workflow ARM template deployment"
  value       = azurerm_resource_group_template_deployment.design_gen_workflow.id
}

output "content_gen_workflow_deployment_id" {
  description = "The ID of the content generation workflow ARM template deployment"
  value       = azurerm_resource_group_template_deployment.content_gen_workflow.id
}

output "review_workflow_deployment_id" {
  description = "The ID of the review workflow ARM template deployment"
  value       = azurerm_resource_group_template_deployment.review_workflow.id
}

# Logic App Trigger URLs (from ARM template deployments)
output "entry_logic_app_trigger_url" {
  description = "The trigger URL for the entry logic app"
  value       = jsondecode(azurerm_resource_group_template_deployment.entry_workflow.output_content).triggerUrl.value
  sensitive   = true
}

output "design_gen_logic_app_trigger_url" {
  description = "The trigger URL for the design generation logic app"
  value       = jsondecode(azurerm_resource_group_template_deployment.design_gen_workflow.output_content).triggerUrl.value
  sensitive   = true
}

output "content_gen_logic_app_trigger_url" {
  description = "The trigger URL for the content generation logic app"
  value       = jsondecode(azurerm_resource_group_template_deployment.content_gen_workflow.output_content).triggerUrl.value
  sensitive   = true
}

output "review_logic_app_trigger_url" {
  description = "The trigger URL for the review logic app"
  value       = jsondecode(azurerm_resource_group_template_deployment.review_workflow.output_content).triggerUrl.value
  sensitive   = true
}
