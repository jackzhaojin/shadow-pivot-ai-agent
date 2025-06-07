# Parameter-Based Logic Apps Deployment Guide

## Overview

This project now uses a **parameter-based deployment approach** for Logic Apps, following Azure best practices. Instead of embedding complex JSON parameters directly in deployment commands or GitHub Actions workflows, we use separate parameter files that are processed at deployment time.

## Benefits

✅ **Maintainable**: Parameters are separated from code  
✅ **Error-Resistant**: No complex inline JSON syntax  
✅ **Version Controlled**: Parameter files are tracked in git  
✅ **Environment-Specific**: Easy to customize for different environments  
✅ **Azure Best Practice**: Follows recommended deployment patterns  

## File Structure

```
logic-apps/
├── entry/
│   ├── parameters.json      # Parameter file with placeholders
│   └── workflow.json        # Logic App workflow definition
├── design-gen/
│   ├── parameters.json      # Parameter file with placeholders
│   └── workflow.json        # Logic App workflow definition
├── content-gen/
│   ├── parameters.json      # Parameter file with placeholders
│   └── workflow.json        # Logic App workflow definition
└── review/
    ├── parameters.json      # Parameter file with placeholders
    └── workflow.json        # Logic App workflow definition
```

## Parameter File Format

Each `parameters.json` file uses placeholder tokens that are replaced at deployment time:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "$connections": {
      "value": {
        "azurequeues": {
          "connectionId": "/subscriptions/[SUBSCRIPTION_ID]/resourceGroups/[RESOURCE_GROUP]/providers/Microsoft.Web/connections/azurequeues-connection",
          "connectionName": "azurequeues",
          "id": "/subscriptions/[SUBSCRIPTION_ID]/providers/Microsoft.Web/locations/[LOCATION]/managedApis/azurequeues"
        }
      }
    },
    "ai_foundry_endpoint": {
      "value": "[AI_FOUNDRY_ENDPOINT]"
    },
    "gpt4_deployment_name": {
      "value": "[GPT4_DEPLOYMENT_NAME]"
    },
    "managed_identity_client_id": {
      "value": "[MANAGED_IDENTITY_CLIENT_ID]"
    }
  }
}
```

## Placeholder Tokens

| Placeholder | Description | Example Value |
|-------------|-------------|---------------|
| `[SUBSCRIPTION_ID]` | Azure subscription ID | `12345678-1234-1234-1234-123456789012` |
| `[RESOURCE_GROUP]` | Azure resource group name | `ShadowPivot` |
| `[LOCATION]` | Azure region | `eastus` |
| `[STORAGE_CONNECTION_ID]` | Storage account connection resource ID | `/subscriptions/.../connections/azurequeues-connection` |
| `[AI_FOUNDRY_ENDPOINT]` | AI Foundry service endpoint | `https://shadow-pivot-ai-foundry.openai.azure.com/` |
| `[GPT4_DEPLOYMENT_NAME]` | GPT-4 model deployment name | `gpt-4-deployment` |
| `[MANAGED_IDENTITY_CLIENT_ID]` | Managed identity client ID | `87654321-4321-4321-4321-210987654321` |

## Deployment Methods

### 1. Local Deployment (Bash)

```bash
# Validate parameter files
./deploy-logic-apps.sh validate

# Deploy all Logic Apps
./deploy-logic-apps.sh deploy

# Deploy a single Logic App (interactive)
./deploy-logic-apps.sh deploy-single
```

### 2. Local Deployment (PowerShell)

```powershell
# Validate parameter files
.\deploy-logic-apps.ps1 validate

# Deploy all Logic Apps
.\deploy-logic-apps.ps1 deploy

# Deploy a single Logic App (interactive)
.\deploy-logic-apps.ps1 deploy-single
```

### 3. Full Infrastructure + Logic Apps

```bash
# Deploy everything (infrastructure + workflows)
./deploy.sh
```

### 4. GitHub Actions (Automated)

The GitHub Actions workflow automatically:
1. Validates infrastructure exists
2. Retrieves dynamic Azure resource values
3. Processes parameter files with actual values
4. Deploys Logic App workflows
5. Verifies deployments

## How It Works

### Parameter Processing Flow

1. **Template Files**: Parameter files contain placeholder tokens
2. **Dynamic Value Retrieval**: Scripts query Azure for current resource values
3. **Token Replacement**: Placeholders are replaced with actual values
4. **Temporary Files**: Processed parameters are saved to `temp-params/`
5. **Deployment**: Azure CLI uses the processed parameter files
6. **Cleanup**: Temporary files are removed

### GitHub Actions Integration

```yaml
- name: Prepare Parameter Files
  run: |
    # Create temp directory
    mkdir -p temp-params
    
    # Process each parameter file
    process_parameters "logic-apps/entry/parameters.json" "temp-params/entry-parameters.json" "entry"
    
    # Replace placeholders with actual Azure values
    sed -i "s|\[SUBSCRIPTION_ID\]|${{ secrets.AZURE_SUBSCRIPTION_ID }}|g" "$target_file"
    # ... more replacements ...

- name: Deploy Logic App
  run: |
    az logic workflow update \
      --resource-group $RESOURCE_GROUP \
      --name entry-agent-step \
      --definition @logic-apps/entry/workflow.json \
      --parameters @temp-params/entry-parameters.json
```

## Validation and Testing

### Validate Parameter Files

```bash
# Check JSON syntax
./deploy-logic-apps.sh validate

# Run comprehensive tests
./test-parameter-deployment.sh
```

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Invalid JSON syntax | Run validation to identify syntax errors |
| Missing placeholder replacement | Check if all required Azure resources exist |
| Permission errors | Ensure Azure CLI is logged in with proper permissions |
| Resource not found | Verify infrastructure is deployed first |

## Migration from Inline Parameters

The old approach used inline JSON parameters:

```bash
# OLD: Error-prone inline parameters
az logic workflow update \
  --parameters '{"$connections":{"value":{"azurequeues":{"connectionId":"..."}}}}'
```

The new approach uses parameter files:

```bash
# NEW: Clean parameter file approach
az logic workflow update \
  --parameters @temp-params/workflow-parameters.json
```

## Best Practices

1. **Always validate** parameter files before deployment
2. **Use the deployment scripts** rather than manual Azure CLI commands
3. **Keep parameter files in version control**
4. **Test changes** in a development environment first
5. **Monitor deployments** in Azure Portal
6. **Review logs** for troubleshooting

## Troubleshooting

### Common Commands

```bash
# Check Azure login status
az account show

# List Logic Apps
az logic workflow list --resource-group ShadowPivot

# Check Logic App status
az logic workflow show --resource-group ShadowPivot --name entry-agent-step

# View deployment logs
az monitor activity-log list --resource-group ShadowPivot
```

### Log Files

- GitHub Actions logs: Available in the Actions tab
- Azure Portal: Logic Apps > Run History
- Local deployment: Terminal output

## Additional Resources

- [Azure Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [Azure CLI Logic Apps Reference](https://docs.microsoft.com/en-us/cli/azure/logic/workflow)
- [ARM Template Parameters](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameters)

---

**Note**: This parameter-based approach significantly improves the maintainability and reliability of Logic Apps deployments while following Azure best practices.
