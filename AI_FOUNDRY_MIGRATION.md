# Migration to Azure AI Foundry - Summary

## Overview
Successfully migrated from OpenAI API to Azure AI Foundry with User-Assigned Managed Identity authentication.

## Changes Made

### 1. Infrastructure Changes (`infra/`)

#### New File: `ai_foundry.tf`
- **User-Assigned Managed Identity**: Created for Logic Apps authentication
- **Azure Cognitive Services Account**: OpenAI-compatible endpoint 
- **GPT-4 Model Deployment**: Deployed GPT-4 model with 10 capacity units
- **RBAC Assignment**: Granted "Cognitive Services User" role to the managed identity

#### Updated Files:
- **`variables.tf`**: Removed `openai_api_key`, added `ai_foundry_location`
- **`logic_apps.tf`**: Added managed identity assignment to all Logic App workflows
- **`outputs.tf`**: Added AI Foundry endpoint, deployment name, and managed identity information
- **`workflow_deployment.tf`**: Updated to pass AI Foundry parameters instead of API key
- **`terraform.tfvars`**: Removed OpenAI API key reference

### 2. Logic App Workflow Changes

Updated all three AI workflows (`design-gen`, `content-gen`, `review`) to use:
- **Azure AI Foundry endpoints** instead of OpenAI API
- **ActiveDirectoryOAuth authentication** with managed identity
- **Proper API version** (2024-02-01) for Azure OpenAI Service
- **Azure Cognitive Services audience** for authentication scope

### 3. GitHub Actions Changes

#### Updated: `.github/workflows/deploy-infra.yml`
- **Removed OpenAI API key dependency** from Terraform plan and apply commands
- **Simplified deployment** - no more secrets required for OpenAI

## Security Improvements

### Before (OpenAI API)
- ❌ API key stored in GitHub Secrets
- ❌ API key passed to Logic Apps as parameter
- ❌ Bearer token authentication to external service

### After (Azure AI Foundry + UMI)
- ✅ **No API keys** - fully managed identity based
- ✅ **Azure AD authentication** with proper RBAC
- ✅ **Principle of least privilege** - Cognitive Services User role only
- ✅ **Integrated with Azure security** - no external dependencies

## API Endpoint Changes

### Before
```
https://api.openai.com/v1/chat/completions
Authorization: Bearer {openai_api_key}
```

### After  
```
{ai_foundry_endpoint}/openai/deployments/{gpt4_deployment_name}/chat/completions?api-version=2024-02-01
Authentication: ActiveDirectoryOAuth with managed identity
```

## Deployment Process

1. **Terraform creates** all infrastructure including AI Foundry and managed identity
2. **Role assignments** automatically grant necessary permissions
3. **Logic App workflows** are updated with AI Foundry parameters
4. **No manual configuration** required - fully automated

## Benefits

- **Enhanced Security**: No API key management
- **Cost Optimization**: Azure AI Foundry pricing models
- **Better Integration**: Native Azure service integration
- **Compliance**: Meets enterprise security requirements
- **Simplified Operations**: No secret rotation needed

## Next Steps

1. Commit and push changes to trigger deployment
2. Monitor Logic App executions in Azure Portal
3. Verify AI Foundry usage in Azure AI Studio
4. Remove any remaining OpenAI API key references from documentation

## Rollback Plan

If needed, rollback is possible by:
1. Reverting workflow JSON files to use OpenAI endpoints
2. Re-adding OpenAI API key variable to Terraform
3. Updating GitHub Actions to pass the API key
4. Removing AI Foundry resources (optional)
