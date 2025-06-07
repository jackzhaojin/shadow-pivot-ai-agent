# Logic App Workflow Definitions using ARM Template Deployments
# This approach allows us to deploy complete Logic App workflow definitions with parameters

# Local values for parameters
locals {
  # Common subscription and resource group info
  subscription_id = data.azurerm_client_config.current.subscription_id
  resource_group  = data.azurerm_resource_group.main.name
  location        = data.azurerm_resource_group.main.location

  # Connection parameters for all Logic Apps
  storage_connection_id = azurerm_api_connection.storage_queues.id
  storage_connection_params = {
    azurequeues = {
      connectionId   = azurerm_api_connection.storage_queues.id
      connectionName = azurerm_api_connection.storage_queues.name
      id             = "/subscriptions/${local.subscription_id}/providers/Microsoft.Web/locations/${local.location}/managedApis/azurequeues"
    }
  }

  # AI Foundry parameters for AI workflows
  ai_foundry_endpoint        = azurerm_cognitive_account.ai_foundry.endpoint
  gpt4_deployment_name       = azurerm_cognitive_deployment.gpt4.name
  managed_identity_client_id = azurerm_user_assigned_identity.logic_apps_identity.client_id
}

# Entry Logic App Workflow Definition Deployment
resource "azurerm_resource_group_template_deployment" "entry_workflow" {
  name                = "entry-workflow-deployment"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      logicAppName = {
        type         = "string"
        defaultValue = "entry-agent-step"
      }
      storageConnectionId = {
        type = "string"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2017-07-01"
        name       = "[parameters('logicAppName')]"
        location   = "[parameters('location')]"
        properties = {
          definition = jsondecode(file("${path.module}/../logic-apps/entry/workflow.json"))
          parameters = {
            "$connections" = {
              defaultValue = {}
              type         = "Object"
            }
          }
        }
      }
    ]
  })

  parameters_content = jsonencode({
    logicAppName = {
      value = "entry-agent-step"
    }
    storageConnectionId = {
      value = local.storage_connection_id
    }
    location = {
      value = local.location
    }
  })

  depends_on = [
    azurerm_logic_app_workflow.entry,
    azurerm_api_connection.storage_queues
  ]
}

# Design Generation Logic App Workflow Definition Deployment
resource "azurerm_resource_group_template_deployment" "design_gen_workflow" {
  name                = "design-gen-workflow-deployment"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      logicAppName = {
        type         = "string"
        defaultValue = "design-gen-step"
      }
      storageConnectionId = {
        type = "string"
      }
      aiFoundryEndpoint = {
        type = "string"
      }
      gpt4DeploymentName = {
        type = "string"
      }
      managedIdentityClientId = {
        type = "string"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2017-07-01"
        name       = "[parameters('logicAppName')]"
        location   = "[parameters('location')]"
        properties = {
          definition = jsondecode(file("${path.module}/../logic-apps/design-gen/workflow.json"))
          parameters = {
            "$connections" = {
              defaultValue = {}
              type         = "Object"
            }
          }
        }
      }
    ]
  })

  parameters_content = jsonencode({
    logicAppName = {
      value = "design-gen-step"
    }
    storageConnectionId = {
      value = local.storage_connection_id
    }
    aiFoundryEndpoint = {
      value = local.ai_foundry_endpoint
    }
    gpt4DeploymentName = {
      value = local.gpt4_deployment_name
    }
    managedIdentityClientId = {
      value = local.managed_identity_client_id
    }
    location = {
      value = local.location
    }
  })

  depends_on = [
    azurerm_logic_app_workflow.design_gen,
    azurerm_api_connection.storage_queues,
    azurerm_cognitive_account.ai_foundry,
    azurerm_cognitive_deployment.gpt4
  ]
}

# Content Generation Logic App Workflow Definition Deployment
resource "azurerm_resource_group_template_deployment" "content_gen_workflow" {
  name                = "content-gen-workflow-deployment"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      logicAppName = {
        type         = "string"
        defaultValue = "content-gen-step"
      }
      storageConnectionId = {
        type = "string"
      }
      aiFoundryEndpoint = {
        type = "string"
      }
      gpt4DeploymentName = {
        type = "string"
      }
      managedIdentityClientId = {
        type = "string"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2017-07-01"
        name       = "[parameters('logicAppName')]"
        location   = "[parameters('location')]"
        properties = {
          definition = jsondecode(file("${path.module}/../logic-apps/content-gen/workflow.json"))
          parameters = {
            "$connections" = {
              defaultValue = {}
              type         = "Object"
            }
          }
        }
      }
    ]
  })

  parameters_content = jsonencode({
    logicAppName = {
      value = "content-gen-step"
    }
    storageConnectionId = {
      value = local.storage_connection_id
    }
    aiFoundryEndpoint = {
      value = local.ai_foundry_endpoint
    }
    gpt4DeploymentName = {
      value = local.gpt4_deployment_name
    }
    managedIdentityClientId = {
      value = local.managed_identity_client_id
    }
    location = {
      value = local.location
    }
  })

  depends_on = [
    azurerm_logic_app_workflow.content_gen,
    azurerm_api_connection.storage_queues,
    azurerm_cognitive_account.ai_foundry,
    azurerm_cognitive_deployment.gpt4
  ]
}

# Review Logic App Workflow Definition Deployment
resource "azurerm_resource_group_template_deployment" "review_workflow" {
  name                = "review-workflow-deployment"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      logicAppName = {
        type         = "string"
        defaultValue = "review-step"
      }
      storageConnectionId = {
        type = "string"
      }
      aiFoundryEndpoint = {
        type = "string"
      }
      gpt4DeploymentName = {
        type = "string"
      }
      managedIdentityClientId = {
        type = "string"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2017-07-01"
        name       = "[parameters('logicAppName')]"
        location   = "[parameters('location')]"
        properties = {
          definition = jsondecode(file("${path.module}/../logic-apps/review/workflow.json"))
          parameters = {
            "$connections" = {
              defaultValue = {}
              type         = "Object"
            }
          }
        }
      }
    ]
  })

  parameters_content = jsonencode({
    logicAppName = {
      value = "review-step"
    }
    storageConnectionId = {
      value = local.storage_connection_id
    }
    aiFoundryEndpoint = {
      value = local.ai_foundry_endpoint
    }
    gpt4DeploymentName = {
      value = local.gpt4_deployment_name
    }
    managedIdentityClientId = {
      value = local.managed_identity_client_id
    }
    location = {
      value = local.location
    }
  })

  depends_on = [
    azurerm_logic_app_workflow.review,
    azurerm_api_connection.storage_queues,
    azurerm_cognitive_account.ai_foundry,
    azurerm_cognitive_deployment.gpt4
  ]
}
