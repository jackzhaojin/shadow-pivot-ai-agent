# User-Assigned Managed Identity for Logic Apps
resource "azurerm_user_assigned_identity" "logic_apps_identity" {
  name                = "shadow-pivot-logic-apps-identity"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
    Purpose     = "Logic Apps AI Foundry authentication"
  }
}

# Azure AI Hub (AI Foundry)
resource "azurerm_cognitive_account" "ai_foundry" {
  name                = "shadow-pivot-ai-foundry"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = "S0"

  # Enable managed identity authentication
  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_apps_identity.id]
  }

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
    Service     = "AI Foundry"
  }
}

# Role assignment: Give the managed identity Cognitive Services User role
resource "azurerm_role_assignment" "ai_foundry_user" {
  scope                = azurerm_cognitive_account.ai_foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.logic_apps_identity.principal_id
}

# AI Model Deployment (GPT-4.1 - Latest 2025 model available in East US)
resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = "gpt-4-deployment"
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id

  model {
    format  = "OpenAI"
    name    = "gpt-4.1"
    version = "2025-04-14"
  }

  scale {
    type     = "Standard"
    capacity = 10
  }
}
