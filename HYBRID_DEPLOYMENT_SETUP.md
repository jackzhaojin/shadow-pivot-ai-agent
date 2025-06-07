# Hybrid Terraform Deployment Setup

This project now supports both **local development** and **CI/CD deployment** using environment-specific configurations.

## 🏗️ Architecture Overview

### Authentication Methods
- **Local Development**: Azure CLI authentication (`az login`)
- **GitHub Actions CI/CD**: OIDC (OpenID Connect) authentication with service principal

### Configuration Files
- `terraform.tfvars.local` - Local development variables (CLI auth)
- `terraform.tfvars.cicd` - CI/CD variables (OIDC auth)
- `variables.tf` - Authentication method variables

## 🖥️ Local Development

### Prerequisites
1. **Azure CLI**: Install and login
   ```bash
   # Install Azure CLI (if not installed)
   winget install Microsoft.AzureCLI
   
   # Login to Azure
   az login
   
   # Verify login and set subscription
   az account show
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform**: Install Terraform
   ```bash
   # Install Terraform (if not installed)
   winget install Hashicorp.Terraform
   ```

### Local Deployment
```bash
# Option 1: Use the deployment script (recommended)
./deploy-infra-local.sh

# Option 2: Manual deployment
cd infra
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars.local"
terraform apply -var-file="terraform.tfvars.local"
```

### Local Configuration
The `terraform.tfvars.local` file configures:
- `use_cli_auth = true` - Enable Azure CLI authentication
- `use_oidc_auth = false` - Disable OIDC authentication
- Resource group and location settings

## 🚀 CI/CD Deployment (GitHub Actions)

### Automatic Deployment
The deployment happens automatically when:
- Code is pushed to the `main` branch
- Manually triggered via GitHub Actions UI

### CI/CD Configuration
The `terraform.tfvars.cicd` file configures:
- `use_cli_auth = false` - Disable Azure CLI authentication
- `use_oidc_auth = true` - Enable OIDC authentication
- Resource group and location settings

### GitHub Secrets Required
Ensure these secrets are configured in your GitHub repository:
- `AZURE_CLIENT_ID` - Service principal client ID
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

## 🔧 Provider Configuration

The hybrid authentication is implemented in `main.tf`:

```hcl
provider "azurerm" {
  features {}

  # Hybrid authentication: CLI for local development, OIDC for CI/CD
  # Environment variables in CI/CD will automatically enable OIDC authentication
  use_cli  = var.use_cli_auth
  use_msi  = false
  use_oidc = var.use_oidc_auth

  # Enable automatic resource provider registration
  skip_provider_registration = false
}
```

## 📁 File Structure

```
infra/
├── main.tf                    # Provider configuration with hybrid auth
├── variables.tf               # Authentication method variables
├── terraform.tfvars.local    # Local development config (CLI auth)
├── terraform.tfvars.cicd     # CI/CD config (OIDC auth)
├── ai_foundry.tf             # AI Foundry resources
├── logic_apps.tf             # Logic Apps resources
├── storage.tf                # Storage resources
└── outputs.tf                # Output values

.github/workflows/
└── deploy-infra.yml          # CI/CD workflow (uses OIDC)

deploy-infra-local.sh         # Local deployment script
```

## 🔄 Workflow Comparison

| Feature | Local Development | CI/CD |
|---------|-------------------|-------|
| Authentication | Azure CLI | OIDC |
| Variables File | `terraform.tfvars.local` | `terraform.tfvars.cicd` |
| Execution | Manual/Script | Automatic |
| Environment Variables | Not required | Required |
| State Backend | Shared (Azure Storage) | Shared (Azure Storage) |

## 🔒 Security Considerations

### Local Development
- Uses your personal Azure CLI credentials
- Inherits your Azure RBAC permissions
- Credentials stored securely by Azure CLI

### CI/CD
- Uses service principal with minimal required permissions
- OIDC eliminates need for long-lived secrets
- Environment variables set by GitHub Actions

## 🚨 Important Notes

1. **State File**: Both local and CI/CD share the same Terraform state file in Azure Storage
2. **Variable Files**: The `terraform.tfvars.local` file is safe to commit as it contains no sensitive data
3. **Permissions**: Ensure your local account and the service principal have appropriate Azure permissions
4. **Coordination**: Be careful when multiple developers work locally to avoid state conflicts

## 🔧 Troubleshooting

### Local Issues
```bash
# Check Azure CLI login
az account show

# Check Terraform version
terraform version

# Re-initialize if needed
cd infra && terraform init -upgrade
```

### CI/CD Issues
- Verify GitHub secrets are correctly configured
- Check service principal permissions
- Review GitHub Actions logs for specific errors

## 🎯 Next Steps

1. Test local deployment: `./deploy-infra-local.sh`
2. Commit changes to trigger CI/CD deployment
3. Deploy Logic Apps using the respective workflows
4. Monitor deployments in Azure Portal
