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
terraform plan -var="resource_group_name=$ResourceGroup"
terraform apply -auto-approve -var="resource_group_name=$ResourceGroup"
Set-Location ..

Write-Status "Infrastructure deployment completed. Logic Apps are created but need workflow definitions."

# Wait a moment for resources to be fully available
Write-Status "Waiting 30 seconds for resources to be fully available..."
Start-Sleep -Seconds 30

# Deploy Logic App Workflows (update existing Logic Apps created by Terraform)
Write-Status "Deploying Logic App workflow definitions..."

# Use the parameter-based deployment script
if (Test-Path ".\deploy-logic-apps.ps1") {
    Write-Status "Using parameter-based deployment approach..."
    & ".\deploy-logic-apps.ps1" deploy
} else {
    Write-Error "Parameter-based deployment script not found: .\deploy-logic-apps.ps1"
    Write-Error "Please ensure deploy-logic-apps.ps1 exists in the project root."
    exit 1
}

Write-Status "🎉 Deployment completed successfully!" 
Write-Status "📋 Summary:"
Write-Status "  - Resource Group: $ResourceGroup"
Write-Status "  - Location: $Location"
Write-Status "  - Storage Account: shdwagentstorage"
Write-Status "  - Logic Apps: 4 deployed"

Write-Status "🔗 Next steps:"
Write-Status "  1. Configure API connections in Azure Portal"
Write-Status "  2. Set up OpenAI API key in Key Vault"
Write-Status "  3. Test the entry Logic App endpoint"
Write-Status "  4. Monitor queue processing"
