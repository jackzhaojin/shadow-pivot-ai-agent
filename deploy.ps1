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

# Deploy Logic Apps
Write-Status "Deploying Logic Apps..."

$logicApps = @(
    @{folder="entry"; name="entry-agent-step"},
    @{folder="design-gen"; name="design-gen-step"},
    @{folder="content-gen"; name="content-gen-step"},
    @{folder="review"; name="review-step"}
)

foreach ($app in $logicApps) {
    $appFolder = $app.folder
    $appName = $app.name
    
    Write-Status "Deploying Logic App: $appName"
    
    $workflowPath = "logic-apps\$appFolder\workflow.json"
    if (Test-Path $workflowPath) {
        az logic workflow create `
            --resource-group $ResourceGroup `
            --name $appName `
            --definition "@$workflowPath" `
            --location $Location `
            --force-create | Out-Null
        Write-Status "Logic App $appName deployed successfully."
    } else {
        Write-Warning "Workflow file not found for $appFolder. Skipping..."
    }
}

Write-Status "🎉 Deployment completed successfully!" 
Write-Status "📋 Summary:"
Write-Status "  - Resource Group: $ResourceGroup"
Write-Status "  - Location: $Location"
Write-Status "  - Storage Account: shdwagentstorage"
Write-Status "  - Logic Apps: $($logicApps.Count) deployed"

Write-Status "🔗 Next steps:"
Write-Status "  1. Configure API connections in Azure Portal"
Write-Status "  2. Set up OpenAI API key in Key Vault"
Write-Status "  3. Test the entry Logic App endpoint"
Write-Status "  4. Monitor queue processing"
