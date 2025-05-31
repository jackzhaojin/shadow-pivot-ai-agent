# Local references to workflow JSON files
locals {
  entry_workflow       = file("${path.module}/../logic-apps/entry/workflow.json")
  design_gen_workflow  = file("${path.module}/../logic-apps/design-gen/workflow.json")
  content_gen_workflow = file("${path.module}/../logic-apps/content-gen/workflow.json")
  review_workflow      = file("${path.module}/../logic-apps/review/workflow.json")
}

# Null resource to update workflow definitions after Logic Apps are created
resource "null_resource" "update_logic_app_workflows" {
  depends_on = [
    azurerm_logic_app_workflow.entry,
    azurerm_logic_app_workflow.design_gen,
    azurerm_logic_app_workflow.content_gen,
    azurerm_logic_app_workflow.review,
    azurerm_api_connection.storage_queues,
    azurerm_cognitive_account.ai_foundry,
    azurerm_cognitive_deployment.gpt4
  ]

  # Trigger when workflow files change
  triggers = {
    entry_workflow_content       = filesha256("${path.module}/../logic-apps/entry/workflow.json")
    design_gen_workflow_content  = filesha256("${path.module}/../logic-apps/design-gen/workflow.json")
    content_gen_workflow_content = filesha256("${path.module}/../logic-apps/content-gen/workflow.json")
    review_workflow_content      = filesha256("${path.module}/../logic-apps/review/workflow.json")
    connection_id                = azurerm_api_connection.storage_queues.id
    ai_foundry_endpoint          = azurerm_cognitive_account.ai_foundry.endpoint
    gpt4_deployment_name         = azurerm_cognitive_deployment.gpt4.name
    managed_identity_client_id   = azurerm_user_assigned_identity.logic_apps_identity.client_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Updating Logic App workflows with AI Foundry parameters..."
      
      # Common parameters for all workflows
      AI_FOUNDRY_ENDPOINT="${azurerm_cognitive_account.ai_foundry.endpoint}"
      GPT4_DEPLOYMENT_NAME="${azurerm_cognitive_deployment.gpt4.name}"
      MANAGED_IDENTITY_CLIENT_ID="${azurerm_user_assigned_identity.logic_apps_identity.client_id}"
      STORAGE_CONNECTION_ID="${azurerm_api_connection.storage_queues.id}"
      
      # Update Entry Logic App
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.entry.name} \
        --definition @${path.module}/../logic-apps/entry/workflow.json \
        --parameters '{
          "$connections": {
            "value": {
              "azurequeues": {
                "connectionId": "'$STORAGE_CONNECTION_ID'",
                "connectionName": "azurequeues",
                "id": "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.main.location}/managedApis/azurequeues"
              }
            }
          }
        }' || echo "Entry workflow update failed"

      # Update Design Gen Logic App with AI Foundry parameters
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.design_gen.name} \
        --definition @${path.module}/../logic-apps/design-gen/workflow.json \
        --parameters '{
          "$connections": {
            "value": {
              "azurequeues": {
                "connectionId": "'$STORAGE_CONNECTION_ID'",
                "connectionName": "azurequeues", 
                "id": "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.main.location}/managedApis/azurequeues"
              }
            }
          },
          "ai_foundry_endpoint": {
            "value": "'$AI_FOUNDRY_ENDPOINT'"
          },
          "gpt4_deployment_name": {
            "value": "'$GPT4_DEPLOYMENT_NAME'"
          },
          "managed_identity_client_id": {
            "value": "'$MANAGED_IDENTITY_CLIENT_ID'"
          }
        }' || echo "Design Gen workflow update failed"

      # Update Content Gen Logic App with AI Foundry parameters
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.content_gen.name} \
        --definition @${path.module}/../logic-apps/content-gen/workflow.json \
        --parameters '{
          "$connections": {
            "value": {
              "azurequeues": {
                "connectionId": "'$STORAGE_CONNECTION_ID'",
                "connectionName": "azurequeues",
                "id": "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.main.location}/managedApis/azurequeues"
              }
            }
          },
          "ai_foundry_endpoint": {
            "value": "'$AI_FOUNDRY_ENDPOINT'"
          },
          "gpt4_deployment_name": {
            "value": "'$GPT4_DEPLOYMENT_NAME'"
          },
          "managed_identity_client_id": {
            "value": "'$MANAGED_IDENTITY_CLIENT_ID'"
          }
        }' || echo "Content Gen workflow update failed"

      # Update Review Logic App with AI Foundry parameters
      az logic workflow update \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_logic_app_workflow.review.name} \
        --definition @${path.module}/../logic-apps/review/workflow.json \
        --parameters '{
          "$connections": {
            "value": {
              "azurequeues": {
                "connectionId": "'$STORAGE_CONNECTION_ID'",
                "connectionName": "azurequeues",
                "id": "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.main.location}/managedApis/azurequeues"
              }
            }
          },
          "ai_foundry_endpoint": {
            "value": "'$AI_FOUNDRY_ENDPOINT'"
          },
          "gpt4_deployment_name": {
            "value": "'$GPT4_DEPLOYMENT_NAME'"
          },
          "managed_identity_client_id": {
            "value": "'$MANAGED_IDENTITY_CLIENT_ID'"
          }
        }' || echo "Review workflow update failed"

      echo "Logic App workflow definitions updated successfully with AI Foundry parameters!"
    EOT
  }
}
