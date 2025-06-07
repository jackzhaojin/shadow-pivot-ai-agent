# Shadow Pivot AI Agent Deployment Script (PowerShell)
param(
    [string]$ResourceGroup = "ShadowPivot",
    [string]$Location = "eastus"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Shadow Pivot AI Agent deployment..." -ForegroundColor Green

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Azure CLI is installed
try {
    az --version | Out-Null
    Write-Status "Azure CLI is installed"
} catch {
    Write-Error "Azure CLI is not installed. Please install it first."
    exit 1
}

# Check if Terraform is installed
try {
    terraform version | Out-Null
    Write-Status "Terraform is installed"
} catch {
    Write-Error "Terraform is not installed. Please install it first."
    exit 1
}

# Check if user is logged in to Azure
try {
    az account show | Out-Null
    Write-Status "User is logged in to Azure"
} catch {
    Write-Error "You are not logged in to Azure. Please run 'az login' first."
    exit 1
}

# Check if resource group exists
Write-Status "Checking if resource group exists..."
try {
    az group show --name $ResourceGroup | Out-Null
    Write-Status "Resource group $ResourceGroup already exists."
} catch {
    Write-Warning "Resource group $ResourceGroup does not exist. Creating it..."
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Status "Resource group created successfully."
}

# Deploy Terraform infrastructure
Write-Status "Deploying Terraform infrastructure..."
Set-Location infra
terraform init

# Import existing workflow deployments to avoid duplication errors
terraform import azurerm_resource_group_template_deployment.entry_workflow "$ResourceGroup/entry-agent-step-workflow" *> $null 2>&1; if(!$?) { Write-Warning "Entry workflow deployment not found - it will be created" }
terraform import azurerm_resource_group_template_deployment.design_gen_workflow "$ResourceGroup/design-gen-step-workflow" *> $null 2>&1; if(!$?) { Write-Warning "Design gen workflow deployment not found - it will be created" }
terraform import azurerm_resource_group_template_deployment.content_gen_workflow "$ResourceGroup/content-gen-step-workflow" *> $null 2>&1; if(!$?) { Write-Warning "Content gen workflow deployment not found - it will be created" }
terraform import azurerm_resource_group_template_deployment.review_workflow "$ResourceGroup/review-step-workflow" *> $null 2>&1; if(!$?) { Write-Warning "Review workflow deployment not found - it will be created" }

terraform plan -var="resource_group_name=$ResourceGroup"
terraform apply -auto-approve -var="resource_group_name=$ResourceGroup"
Set-Location ..

Write-Status "🎉 Deployment completed successfully!" 
Write-Status "📋 Summary:"
Write-Status "  - Resource Group: $ResourceGroup"
Write-Status "  - Location: $Location"
Write-Status "  - Storage Account: shdwagentstorage"
Write-Status "  - Logic Apps: All workflows deployed with definitions"

Write-Status "🔗 Next steps:"
Write-Status "  1. Test the entry Logic App endpoint"
Write-Status "  2. Monitor executions in Azure Portal"
Write-Status "  3. Check AI Foundry usage in Azure AI Studio"
Write-Status "  4. Monitor queue processing"
