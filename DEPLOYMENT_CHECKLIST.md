# 🚀 Shadow Pivot AI Agent - Deployment Checklist

## Pre-Deployment Requirements

### ✅ Azure Setup
- [ ] Azure subscription with sufficient permissions
- [ ] Resource group `ShadowPivot` exists (or will be created)
- [ ] Azure CLI installed and configured (`az login`)
- [ ] Service Principal created for GitHub Actions (if using automated deployment)

### ✅ GitHub Setup (for automated deployment)
- [ ] Repository pushed to GitHub
- [ ] GitHub Secrets configured:
  - [ ] `AZURE_CLIENT_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID` 
  - [ ] `AZURE_TENANT_ID`

### ✅ Local Development Setup
- [ ] Terraform installed (`terraform --version`)
- [ ] Azure CLI installed (`az --version`)
- [ ] Git configured with your credentials

## Deployment Options

### Option 1: Automated Deployment (Recommended)
```bash
# 1. Push to GitHub main branch
git push origin main

# 2. Monitor GitHub Actions workflows in sequence:
#    Step 1: Deploy Infrastructure (includes bootstrap)
#    Step 2: Deploy Logic App Workflows (auto-triggered)

# 3. Check workflow completion
# - Go to GitHub repository > Actions tab
# - Verify "Deploy Infrastructure" completed successfully
# - Verify "Deploy Logic App Workflows" completed successfully
```

### Deployment Sequence Details
The automated deployment follows this sequence:
1. **Bootstrap**: Creates Terraform state storage (if needed)
2. **Infrastructure Deployment**: 
   - Provisions all Azure resources via Terraform
   - Creates empty Logic Apps with proper identity assignments
   - Sets up storage, AI Foundry, and API connections
3. **Workflow Deployment**:
   - Automatically triggered after infrastructure deployment
   - Deploys workflow definitions to Logic Apps
   - Configures proper connection parameters
   - Tests entry endpoint functionality

### Option 2: Manual Deployment
```bash
# Linux/macOS
./deploy.sh

# Windows PowerShell
.\deploy.ps1
```

## Post-Deployment Configuration

### 🔧 Azure Portal Configuration
1. **Configure API Connections**:
   - Navigate to Logic Apps in Azure Portal
   - For each Logic App, configure Azure Queue Storage connections
   - Authorize connections with storage account credentials

2. **Set Up OpenAI Integration**:
   - Create Azure Key Vault (optional but recommended)
   - Store OpenAI API key securely
   - Update Logic Apps to reference the API key

3. **Enable Monitoring**:
   - Configure Application Insights for Logic Apps
   - Set up alerts for failed executions
   - Enable diagnostic logging

### 🧪 Testing & Validation
```bash
# 1. Update test script with your Logic App URL
# Edit test.sh and set LOGIC_APP_URL variable

# 2. Run comprehensive tests
./test.sh

# 3. Manual API test
curl -X POST "https://your-logic-app-url" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a business plan for a tech startup",
    "userId": "test-user",
    "sessionId": "test-session"
  }'
```

## Verification Steps

### ✅ Infrastructure Verification
- [ ] Storage account `shdwagentstorage` created
- [ ] All 4 queues exist: `design-gen-q`, `content-gen-q`, `review-q`, `completion-q`
- [ ] Storage container `ai-artifacts` created
- [ ] All Logic Apps deployed and active

### ✅ Functionality Verification
- [ ] Entry Logic App responds to HTTP requests
- [ ] Messages are queued properly
- [ ] AI processing workflows execute
- [ ] Final results are stored/returned

### ✅ Monitoring & Alerts
- [ ] Logic App execution history shows successful runs
- [ ] Queue message processing is working
- [ ] Error handling triggers appropriately
- [ ] Performance metrics are being collected

## Troubleshooting Common Issues

### 🔧 Logic App Connection Issues
```bash
# Check Logic App status
az logic workflow show --resource-group ShadowPivot --name entry-agent-step

# View execution history
az logic workflow run list --resource-group ShadowPivot --name entry-agent-step
```

### 🔧 Queue Processing Issues
```bash
# Check queue message counts
az storage queue list --account-name shdwagentstorage

# Peek at queue messages
az storage message peek --queue-name design-gen-q --account-name shdwagentstorage
```

### 🔧 Terraform Issues
```bash
# Validate configuration
cd infra
terraform validate

# Check current state
terraform show

# Force refresh if needed
terraform refresh
```

## Security Hardening (Production)

### 🔒 Recommended Security Measures
- [ ] Enable private endpoints for Storage Account
- [ ] Implement API authentication for Logic App triggers
- [ ] Use Azure Key Vault for all secrets
- [ ] Enable Azure AD authentication
- [ ] Configure network security groups
- [ ] Enable audit logging

### 🔒 Data Protection
- [ ] Configure data retention policies
- [ ] Implement data encryption at rest
- [ ] Set up backup and disaster recovery
- [ ] Review and minimize access permissions

## Performance Optimization

### ⚡ Scaling Considerations
- [ ] Monitor Logic App execution times
- [ ] Adjust queue polling intervals
- [ ] Consider parallel processing for high-volume scenarios
- [ ] Implement caching for repeated requests
- [ ] Monitor OpenAI API rate limits

## Maintenance Tasks

### 🔄 Regular Maintenance
- [ ] Monitor queue message counts and processing times
- [ ] Review Logic App execution logs weekly
- [ ] Update Logic App workflows as needed
- [ ] Monitor Azure costs and optimize resources
- [ ] Keep documentation updated

---

## 🎉 Success Criteria

The deployment is successful when:
- ✅ All Azure resources are created and active
- ✅ Logic Apps respond to HTTP requests
- ✅ Messages flow through all pipeline stages
- ✅ AI processing completes successfully
- ✅ Results are stored/returned as expected
- ✅ Monitoring and alerting are functional

## 📞 Support & Documentation

- **Project Documentation**: See `README.md`, `API_DOCS.md`, `PROJECT_SUMMARY.md`
- **Azure Documentation**: https://docs.microsoft.com/azure/
- **Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/azurerm/
- **Logic Apps Documentation**: https://docs.microsoft.com/azure/logic-apps/
