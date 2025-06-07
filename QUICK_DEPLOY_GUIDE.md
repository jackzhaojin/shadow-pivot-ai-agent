# 🚀 Shadow Pivot AI Agent - Quick Deployment Guide

## Ready to Deploy? ✅

Your Shadow Pivot AI Agent is now configured with a **separated deployment architecture**!

## Deployment Sequence Overview

```
1. Bootstrap → 2. Deploy Infrastructure → 3. Deploy Logic App Workflows
```

### What Each Step Does:

**🔧 Bootstrap**
- Creates Terraform state storage if needed
- Sets up secure state management

**🏗️ Deploy Infrastructure** 
- Provisions Azure AI Foundry, Storage, Managed Identity
- Creates empty Logic Apps with proper permissions
- Sets up all Azure resources and connections

**⚡ Deploy Logic App Workflows**
- Automatically triggered after infrastructure
- Deploys workflow definitions from `logic-apps/` folders
- Configures AI Foundry connections and parameters
- Tests the entry endpoint

## How to Deploy

### Option 1: GitHub Actions (Recommended)

1. **Set up GitHub Secrets** (if not already done):
   ```bash
   # Go to your GitHub repository → Settings → Secrets and variables → Actions
   # Add these secrets:
   AZURE_CLIENT_ID=your-service-principal-client-id
   AZURE_SUBSCRIPTION_ID=your-subscription-id  
   AZURE_TENANT_ID=your-tenant-id
   ```

2. **Commit and Push**:
   ```bash
   git add .
   git commit -m "Deploy separated Logic Apps workflow architecture"
   git push origin main
   ```

3. **Monitor Deployment**:
   - Go to GitHub → Actions tab
   - Watch "Deploy Infrastructure" workflow complete
   - Watch "Deploy Logic App Workflows" workflow auto-trigger and complete

### Option 2: Manual Deployment

```bash
# Linux/macOS/WSL
cd /c/code/shadow-pivot-ai-agent
./deploy.sh

# Windows PowerShell
cd c:\code\shadow-pivot-ai-agent
.\deploy.ps1
```

## After Deployment

### 🧪 Test Your AI Agent

```bash
# Get your Logic App trigger URL from Azure Portal, then:
curl -X POST "https://your-logic-app-url" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a business plan for a tech startup",
    "userId": "test-user",
    "sessionId": "test-session"
  }'
```

### 📊 Monitor in Azure Portal

1. **Logic Apps**: Monitor executions and performance
2. **AI Foundry**: Check usage and token consumption  
3. **Storage Queues**: Monitor message flow between steps
4. **Managed Identity**: Verify permissions are working

## Key Improvements in This Architecture

✅ **Better Error Isolation** - Infrastructure and workflow issues are separated  
✅ **Independent Updates** - Update workflows without touching infrastructure  
✅ **Cleaner CI/CD** - Clear separation of deployment phases  
✅ **Enterprise Ready** - Uses Azure AI Foundry with managed identity (no API keys!)  
✅ **Fully Automated** - No manual configuration required  

## Troubleshooting

### If Infrastructure Deployment Fails:
- Check Azure permissions for your service principal
- Verify resource group exists or can be created
- Check Terraform state in Azure Storage

### If Workflow Deployment Fails:
- Verify infrastructure completed successfully first
- Check Logic App exists in Azure Portal
- Validate workflow JSON syntax

### Common Issues:
- **Terraform Provider Registration**: Fixed with `skip_provider_registration = false`
- **Managed Identity Permissions**: Automatically configured via Terraform
- **API Connections**: Automatically created and configured

## Resources Created

**Azure AI Foundry**: `shadow-pivot-ai-foundry`  
**Storage Account**: `shdwagentstorage`  
**Logic Apps**: `entry-agent-step`, `design-gen-step`, `content-gen-step`, `review-step`  
**Managed Identity**: `shadow-pivot-logic-apps-identity`  
**Resource Group**: `ShadowPivot`  

---

## 🎉 You're Ready to Go!

Your Shadow Pivot AI Agent now has enterprise-grade deployment architecture with:
- Separated deployment phases for better maintainability
- Azure AI Foundry integration (no API key management!)
- Comprehensive error handling and monitoring
- Full automation with manual deployment options

**Next Step**: Commit and push to trigger your first deployment! 🚀
