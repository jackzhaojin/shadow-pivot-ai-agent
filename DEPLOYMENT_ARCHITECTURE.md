# Shadow Pivot AI Agent - Deployment Architecture

## Overview

The Shadow Pivot AI Agent now uses a **separated deployment approach** with distinct phases for infrastructure and Logic App workflows. This architecture provides better error isolation, cleaner CI/CD management, and allows for independent updates of workflows without infrastructure changes.

## Deployment Sequence

### 1. Bootstrap Phase
**Trigger**: First step in infrastructure deployment
**Purpose**: Ensures Terraform state storage exists

- Creates storage account `shadowpivotterraform` if needed
- Creates container `tfstate` for Terraform state files
- Sets up proper security and access controls

### 2. Infrastructure Deployment Phase
**Trigger**: After bootstrap, via GitHub Actions or manual deployment
**Purpose**: Provisions all Azure resources via Terraform

**Resources Created**:
- ✅ Azure AI Foundry (`shadow-pivot-ai-foundry`)
- ✅ User-Assigned Managed Identity (`shadow-pivot-logic-apps-identity`)
- ✅ Storage Account (`shdwagentstorage`)
- ✅ Storage Queues (`design-gen-q`, `content-gen-q`, `review-q`, `completion-q`)
- ✅ Storage Container (`ai-artifacts`)
- ✅ API Connection (`azurequeues-connection`)
- ✅ **Empty Logic Apps** (`entry-agent-step`, `design-gen-step`, `content-gen-step`, `review-step`)
- ✅ GPT-4 Deployment (`gpt-4-deployment`)
- ✅ RBAC Role Assignments

**Key Points**:
- Logic Apps are created but contain **no workflow definitions**
- All infrastructure dependencies are established
- Managed identity permissions are configured
- API connections are ready for use

### 3. Logic App Workflow Deployment Phase
**Trigger**: Automatically after infrastructure deployment succeeds
**Purpose**: Deploy workflow definitions to the Logic Apps

**Workflow Files Used**:
- `logic-apps/entry/workflow.json` → `entry-agent-step`
- `logic-apps/design-gen/workflow.json` → `design-gen-step`
- `logic-apps/content-gen/workflow.json` → `content-gen-step`
- `logic-apps/review/workflow.json` → `review-step`

**Process**:
1. Verifies infrastructure components exist
2. Retrieves connection parameters from Azure
3. Updates each Logic App with its workflow definition
4. Configures proper connection parameters for Azure AI Foundry and Storage
5. Tests the entry endpoint functionality

## Benefits of Separated Deployment

### 🔧 **Better Error Isolation**
- Infrastructure failures don't affect workflow deployments
- Workflow syntax errors don't block infrastructure provisioning
- Easier to identify and fix issues in specific phases

### 🚀 **Independent Updates**
- Workflow definitions can be updated without Terraform operations
- Infrastructure changes don't require workflow redeployment
- Faster iteration on Logic App workflows

### 📊 **Cleaner CI/CD Management**
- Clear separation of concerns in GitHub Actions
- Better logging and monitoring per phase
- Ability to retry specific phases independently

### 🔄 **Improved Development Workflow**
- Developers can work on workflows without infrastructure changes
- Infrastructure team can manage resources independently
- Better collaboration between teams

## GitHub Actions Workflows

### `.github/workflows/deploy-infra.yml`
- **Triggers**: Push to main branch, manual dispatch
- **Dependencies**: Bootstrap workflow
- **Purpose**: Deploy all infrastructure via Terraform
- **Outputs**: Infrastructure deployment summary

### `.github/workflows/deploy-logicapps.yml`
- **Triggers**: After successful infrastructure deployment, manual dispatch
- **Dependencies**: Infrastructure deployment completion
- **Purpose**: Deploy workflow definitions to Logic Apps
- **Outputs**: Workflow deployment summary and test results

### `.github/workflows/bootstrap-state.yml`
- **Triggers**: Called by deploy-infra workflow
- **Purpose**: Ensure Terraform state storage exists
- **Reusable**: Can be called by other workflows

## Manual Deployment Scripts

Both `deploy.sh` (Linux/macOS) and `deploy.ps1` (Windows) follow the same sequence:

1. **Infrastructure**: Run Terraform to provision resources
2. **Wait**: Allow resources to be fully available (30 seconds)
3. **Workflows**: Update Logic Apps with workflow definitions

## Rollback Strategy

### Infrastructure Issues
- Use Terraform state to rollback infrastructure changes
- Restore from previous Terraform state backup if needed

### Workflow Issues
- Redeploy previous working workflow definitions
- Use Azure Portal to manually fix Logic App configurations
- Restart the workflow deployment phase

## Monitoring and Validation

### Infrastructure Phase
- Terraform plan/apply output
- Azure resource creation logs
- Resource health checks

### Workflow Phase
- Logic App workflow validation
- Connection parameter verification
- Entry endpoint testing
- Queue connectivity testing

## Next Steps

1. **Commit Changes**: All files are updated for the new architecture
2. **Test Deployment**: Push to main branch to test the full sequence
3. **Monitor Workflows**: Watch both GitHub Actions workflows complete
4. **Validate System**: Test the AI pipeline end-to-end
5. **Document Issues**: Report any problems for further optimization

---

**🎯 The Shadow Pivot AI Agent is now architected for enterprise-grade deployment with proper separation of concerns and improved maintainability!**
