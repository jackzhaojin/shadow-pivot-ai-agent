#!/bin/bash

# Shadow Pivot AI Agent Deployment Script
set -e

echo "🚀 Starting Shadow Pivot AI Agent deployment..."

# Configuration
RESOURCE_GROUP="ShadowPivot"
LOCATION="eastus"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    print_error "You are not logged in to Azure. Please run 'az login' first."
    exit 1
fi

print_status "Checking if resource group exists..."
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    print_warning "Resource group $RESOURCE_GROUP does not exist. Creating it..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
    print_status "Resource group created successfully."
else
    print_status "Resource group $RESOURCE_GROUP already exists."
fi

# Deploy Terraform infrastructure
print_status "Deploying Terraform infrastructure..."
cd infra
terraform init
terraform plan -var="resource_group_name=$RESOURCE_GROUP"
terraform apply -auto-approve -var="resource_group_name=$RESOURCE_GROUP"
cd ..

print_status "Infrastructure deployment completed. Logic Apps are created but need workflow definitions."

# Wait a moment for resources to be fully available
print_status "Waiting 30 seconds for resources to be fully available..."
sleep 30

# Deploy Logic App Workflows (update existing Logic Apps created by Terraform)
print_status "Deploying Logic App workflow definitions..."

logic_apps=("entry" "design-gen" "content-gen" "review")
logic_app_names=("entry-agent-step" "design-gen-step" "content-gen-step" "review-step")

for i in "${!logic_apps[@]}"; do
    app_folder="${logic_apps[$i]}"
    app_name="${logic_app_names[$i]}"
    
    print_status "Deploying workflow for Logic App: $app_name"
    
    if [[ -f "logic-apps/$app_folder/workflow.json" ]]; then
        # Use update instead of create since Terraform already created the Logic Apps
        az logic workflow update \
            --resource-group $RESOURCE_GROUP \
            --name $app_name \
            --definition @logic-apps/$app_folder/workflow.json
        print_status "Logic App workflow $app_name deployed successfully."
    else
        print_warning "Workflow file not found for $app_folder. Skipping..."
    fi
done

print_status "🎉 Deployment completed successfully!"
print_status "📋 Summary:"
print_status "  - Resource Group: $RESOURCE_GROUP"
print_status "  - Location: $LOCATION"
print_status "  - Storage Account: shdwagentstorage"
print_status "  - Logic Apps: ${#logic_app_names[@]} deployed"

print_status "🔗 Next steps:"
print_status "  1. Configure API connections in Azure Portal"
print_status "  2. Set up OpenAI API key in Key Vault"
print_status "  3. Test the entry Logic App endpoint"
print_status "  4. Monitor queue processing"
