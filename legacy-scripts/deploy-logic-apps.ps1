# Logic Apps Parameter File Manager (PowerShell)
# This script helps manage and deploy Logic Apps with their parameter files

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "validate", "deploy-single", "help")]
    [string]$Command = "deploy"
)

# Configuration
$ResourceGroup = "ShadowPivot"
$Location = "eastus"

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

# Check if user is logged in to Azure
function Test-AzureLogin {
    try {
        $null = az account show 2>$null
        return $true
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'az login' first."
        return $false
    }
}

# Function to process parameter files
function ProcessParameters {
    param(
        [string]$SourceFile,
        [string]$TargetFile,
        [string]$WorkflowName
    )
    
    Write-Status "Processing parameters for $WorkflowName..."
    
    # Get dynamic values from Azure
    $SubscriptionId = az account show --query "id" -o tsv
    $StorageConnectionId = az resource show `
        --resource-group $ResourceGroup `
        --name azurequeues-connection `
        --resource-type Microsoft.Web/connections `
        --query "id" -o tsv
    
    # Copy the template
    Copy-Item $SourceFile $TargetFile
    
    # Read and replace content
    $content = Get-Content $TargetFile -Raw
    $content = $content -replace '\[SUBSCRIPTION_ID\]', $SubscriptionId
    $content = $content -replace '\[RESOURCE_GROUP\]', $ResourceGroup
    $content = $content -replace '\[LOCATION\]', $Location
    $content = $content -replace '\[STORAGE_CONNECTION_ID\]', $StorageConnectionId
    
    # Replace AI-specific placeholders (only for AI workflows)
    if ($WorkflowName -ne "entry") {
        $AIFoundryEndpoint = az cognitiveservices account show `
            --resource-group $ResourceGroup `
            --name shadow-pivot-ai-foundry `
            --query "properties.endpoint" -o tsv
        
        $GPT4DeploymentName = az cognitiveservices account deployment show `
            --resource-group $ResourceGroup `
            --name shadow-pivot-ai-foundry `
            --deployment-name gpt-4-deployment `
            --query "name" -o tsv
        
        $ManagedIdentityClientId = az identity show `
            --resource-group $ResourceGroup `
            --name shadow-pivot-logic-apps-identity `
            --query "clientId" -o tsv
        
        $content = $content -replace '\[AI_FOUNDRY_ENDPOINT\]', $AIFoundryEndpoint
        $content = $content -replace '\[GPT4_DEPLOYMENT_NAME\]', $GPT4DeploymentName
        $content = $content -replace '\[MANAGED_IDENTITY_CLIENT_ID\]', $ManagedIdentityClientId
    }
    
    # Write the processed content
    Set-Content -Path $TargetFile -Value $content -Encoding UTF8
    
    Write-Status "✅ Parameters prepared for $WorkflowName"
}

# Function to deploy a single Logic App
function DeployLogicApp {
    param(
        [string]$WorkflowName,
        [string]$LogicAppName
    )
    
    Write-Status "🚀 Deploying $WorkflowName Logic App workflow..."
    
    # Check if workflow files exist
    $workflowFile = "logic-apps\$WorkflowName\workflow.json"
    $parametersFile = "logic-apps\$WorkflowName\parameters.json"
    
    if (-not (Test-Path $workflowFile)) {
        Write-Error "Workflow file not found: $workflowFile"
        return $false
    }
    
    if (-not (Test-Path $parametersFile)) {
        Write-Error "Parameters file not found: $parametersFile"
        return $false
    }
    
    # Process parameters
    if (-not (Test-Path "temp-params")) {
        New-Item -ItemType Directory -Path "temp-params" | Out-Null
    }
    
    $processedParamsFile = "temp-params\$WorkflowName-parameters.json"
    ProcessParameters $parametersFile $processedParamsFile $WorkflowName
    
    # Deploy the workflow
    az logic workflow update `
        --resource-group $ResourceGroup `
        --name $LogicAppName `
        --definition "@$workflowFile" `
        --parameters "@$processedParamsFile"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✅ $WorkflowName Logic App workflow deployed successfully."
        return $true
    } else {
        Write-Error "❌ Failed to deploy $WorkflowName Logic App workflow."
        return $false
    }
}

# Function to validate parameter files
function ValidateParameters {
    Write-Status "🔍 Validating parameter files..."
    
    $workflows = @("entry", "design-gen", "content-gen", "review")
    $allValid = $true
    
    foreach ($workflow in $workflows) {
        $paramFile = "logic-apps\$workflow\parameters.json"
        
        if (Test-Path $paramFile) {
            try {
                Get-Content $paramFile | ConvertFrom-Json | Out-Null
                Write-Status "✅ Valid JSON: $paramFile"
            }
            catch {
                Write-Error "❌ Invalid JSON: $paramFile"
                $allValid = $false
            }
        } else {
            Write-Error "❌ Missing parameter file: $paramFile"
            $allValid = $false
        }
    }
    
    if ($allValid) {
        Write-Status "🎯 All parameter files are valid!"
        return $true
    } else {
        Write-Error "⚠️ Some parameter files have issues. Please fix them before deployment."
        return $false
    }
}

# Main deployment function
function DeployAll {
    Write-Status "🚀 Starting Logic Apps parameter-based deployment..."
    
    # Check Azure login
    if (-not (Test-AzureLogin)) {
        exit 1
    }
    
    # Validate parameter files first
    if (-not (ValidateParameters)) {
        exit 1
    }
    
    # Create temp directory for processed parameters
    if (-not (Test-Path "temp-params")) {
        New-Item -ItemType Directory -Path "temp-params" | Out-Null
    }
    
    # Deploy each Logic App
    $deployments = @(
        @{WorkflowName="entry"; LogicAppName="entry-agent-step"},
        @{WorkflowName="design-gen"; LogicAppName="design-gen-step"},
        @{WorkflowName="content-gen"; LogicAppName="content-gen-step"},
        @{WorkflowName="review"; LogicAppName="review-step"}
    )
    
    $allSuccessful = $true
    foreach ($deployment in $deployments) {
        if (-not (DeployLogicApp $deployment.WorkflowName $deployment.LogicAppName)) {
            $allSuccessful = $false
        }
    }
    
    # Clean up temp files
    Remove-Item "temp-params" -Recurse -Force -ErrorAction SilentlyContinue
    
    if ($allSuccessful) {
        Write-Status "🎉 All Logic App workflows deployed successfully!"
        Write-Status ""
        Write-Status "📋 Deployment Summary:"
        Write-Status "  ✅ Entry Logic App: entry-agent-step"
        Write-Status "  ✅ Design Generation: design-gen-step"
        Write-Status "  ✅ Content Generation: content-gen-step"
        Write-Status "  ✅ Review Logic App: review-step"
        Write-Status ""
        Write-Status "🔗 Next Steps:"
        Write-Status "  1. Test the Logic Apps in Azure Portal"
        Write-Status "  2. Monitor execution history"
        Write-Status "  3. Test the complete AI pipeline"
    } else {
        Write-Error "⚠️ Some deployments failed. Check the output above for details."
        exit 1
    }
}

# Help function
function Show-Help {
    Write-Host "Logic Apps Parameter File Manager (PowerShell)"
    Write-Host ""
    Write-Host "Usage: .\deploy-logic-apps.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  deploy          Deploy all Logic Apps with parameter files"
    Write-Host "  validate        Validate all parameter files"
    Write-Host "  deploy-single   Deploy a single Logic App (interactive)"
    Write-Host "  help           Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy-logic-apps.ps1 deploy                # Deploy all Logic Apps"
    Write-Host "  .\deploy-logic-apps.ps1 validate              # Just validate parameter files"
    Write-Host "  .\deploy-logic-apps.ps1 deploy-single         # Interactive single deployment"
}

# Interactive single deployment
function DeploySelectedLogicApp {
    Write-Host "Available Logic Apps:"
    Write-Host "1. entry (entry-agent-step)"
    Write-Host "2. design-gen (design-gen-step)"
    Write-Host "3. content-gen (content-gen-step)"
    Write-Host "4. review (review-step)"
    Write-Host ""
    
    $choice = Read-Host "Select Logic App to deploy (1-4)"
    
    switch ($choice) {
        "1" { DeployLogicApp "entry" "entry-agent-step" }
        "2" { DeployLogicApp "design-gen" "design-gen-step" }
        "3" { DeployLogicApp "content-gen" "content-gen-step" }
        "4" { DeployLogicApp "review" "review-step" }
        default { Write-Error "Invalid choice" }
    }
}

# Main script logic
switch ($Command) {
    "deploy" {
        DeployAll
    }
    "validate" {
        if (-not (Test-AzureLogin)) {
            exit 1
        }
        ValidateParameters
    }
    "deploy-single" {
        if (-not (Test-AzureLogin)) {
            exit 1
        }
        if (ValidateParameters) {
            DeploySelectedLogicApp
        }
    }
    "help" {
        Show-Help
    }
    default {
        Write-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
