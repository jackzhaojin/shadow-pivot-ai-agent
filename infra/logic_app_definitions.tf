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

  # Function to process parameters.json files and replace placeholders
  processed_parameters = {
    entry = {}

    design_gen = {
      "$connections" = {
        value = local.storage_connection_params
      }
      ai_foundry_endpoint = {
        value = local.ai_foundry_endpoint
      }
      gpt4_deployment_name = {
        value = local.gpt4_deployment_name
      }
      managed_identity_client_id = {
        value = local.managed_identity_client_id
      }
    }

    content_gen = {
      "$connections" = {
        value = local.storage_connection_params
      }
      ai_foundry_endpoint = {
        value = local.ai_foundry_endpoint
      }
      gpt4_deployment_name = {
        value = local.gpt4_deployment_name
      }
      managed_identity_client_id = {
        value = local.managed_identity_client_id
      }
    }

    review = {
      "$connections" = {
        value = local.storage_connection_params
      }
      ai_foundry_endpoint = {
        value = local.ai_foundry_endpoint
      }
      gpt4_deployment_name = {
        value = local.gpt4_deployment_name
      }
      managed_identity_client_id = {
        value = local.managed_identity_client_id
      }
    }
  }
}

# Entry Logic App Workflow Definition Deployment
resource "azurerm_resource_group_template_deployment" "entry_workflow" {
  name                = "entry-agent-step-workflow"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      workflowName = {
        type         = "string"
        defaultValue = "entry-agent-step"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [{
      type       = "Microsoft.Logic/workflows"
      apiVersion = "2017-07-01"
      name       = "[parameters('workflowName')]"
      location   = "[parameters('location')]"
      properties = {
        definition = jsondecode(file("${path.module}/../logic-apps/entry/workflow.json"))
        parameters = local.processed_parameters.entry
      }
      }
    ]
    outputs = {
      triggerUrl = {
        type  = "string"
        value = "[listCallbackURL(concat(resourceId('Microsoft.Logic/workflows', parameters('workflowName')), '/triggers/manual'), '2017-07-01').value]"
      }
    }
  })

  parameters_content = jsonencode({
    workflowName = {
      value = "entry-agent-step"
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
  name                = "design-gen-step-workflow"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      workflowName = {
        type         = "string"
        defaultValue = "design-gen-step"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [{
      type       = "Microsoft.Logic/workflows"
      apiVersion = "2017-07-01"
      name       = "[parameters('workflowName')]"
      location   = "[parameters('location')]"
      properties = {
        definition = jsondecode(file("${path.module}/../logic-apps/design-gen/workflow.json"))
        parameters = local.processed_parameters.design_gen
      }
      }
    ]
    outputs = {
      triggerUrl = {
        type  = "string"
        value = "[listCallbackURL(concat(resourceId('Microsoft.Logic/workflows', parameters('workflowName')), '/triggers/manual'), '2017-07-01').value]"
      }
    }
  })

  parameters_content = jsonencode({
    workflowName = {
      value = "design-gen-step"
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
  name                = "content-gen-step-workflow"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      workflowName = {
        type         = "string"
        defaultValue = "content-gen-step"
      }
      location = {
        type         = "string"
        defaultValue = local.location
      }
    }
    resources = [{
      type       = "Microsoft.Logic/workflows"
      apiVersion = "2017-07-01"
      name       = "[parameters('workflowName')]"
      location   = "[parameters('location')]"
      properties = {
        definition = jsondecode(file("${path.module}/../logic-apps/content-gen/workflow.json"))
        parameters = local.processed_parameters.content_gen
      }
      }
    ]
    outputs = {
      triggerUrl = {
        type  = "string"
        value = "[listCallbackURL(concat(resourceId('Microsoft.Logic/workflows', parameters('workflowName')), '/triggers/manual'), '2017-07-01').value]"
      }
    }
  })

  parameters_content = jsonencode({
    workflowName = {
      value = "content-gen-step"
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
  name                = "review-step-workflow"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      workflowName = {
        type         = "string"
        defaultValue = "review-step"
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
        name       = "[parameters('workflowName')]"
        location   = "[parameters('location')]"
        properties = {
          definition = jsondecode(file("${path.module}/../logic-apps/review/workflow.json"))
          parameters = local.processed_parameters.review
        }
      }
    ]
    outputs = {
      triggerUrl = {
        type  = "string"
        value = "[listCallbackURL(concat(resourceId('Microsoft.Logic/workflows', parameters('workflowName')), '/triggers/manual'), '2017-07-01').value]"
      }
    }
  })

  parameters_content = jsonencode({
    workflowName = {
      value = "review-step"
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
