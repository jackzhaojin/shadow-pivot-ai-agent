# API Connection for Azure Storage Queues
resource "azurerm_api_connection" "storage_queues" {
  name                = "azurequeues-connection"
  resource_group_name = data.azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.main.location}/managedApis/azurequeues"

  parameter_values = {
    storageaccount = azurerm_storage_account.main.name
    sharedkey      = azurerm_storage_account.main.primary_access_key
  }

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
  }
}

# Logic App - Entry Step
resource "azurerm_logic_app_workflow" "entry" {
  name                = "entry-agent-step"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
    Step        = "entry"
  }
}

# Logic App - Design Generation Step
resource "azurerm_logic_app_workflow" "design_gen" {
  name                = "design-gen-step"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
    Step        = "design-gen"
  }
}

# Logic App - Content Generation Step
resource "azurerm_logic_app_workflow" "content_gen" {
  name                = "content-gen-step"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
    Step        = "content-gen"
  }
}

# Logic App - Review Step
resource "azurerm_logic_app_workflow" "review" {
  name                = "review-step"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "production"
    Project     = "shadow-pivot-ai-agent"
    Step        = "review"
  }
}
