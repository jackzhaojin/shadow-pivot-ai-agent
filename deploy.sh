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

# Import existing workflow deployments to avoid duplication errors
terraform import azurerm_resource_group_template_deployment.entry_workflow $RESOURCE_GROUP/entry-agent-step-workflow >/dev/null 2>&1 || print_warning "Entry workflow deployment not found - it will be created"
terraform import azurerm_resource_group_template_deployment.design_gen_workflow $RESOURCE_GROUP/design-gen-step-workflow >/dev/null 2>&1 || print_warning "Design gen workflow deployment not found - it will be created"
terraform import azurerm_resource_group_template_deployment.content_gen_workflow $RESOURCE_GROUP/content-gen-step-workflow >/dev/null 2>&1 || print_warning "Content gen workflow deployment not found - it will be created"
terraform import azurerm_resource_group_template_deployment.review_workflow $RESOURCE_GROUP/review-step-workflow >/dev/null 2>&1 || print_warning "Review workflow deployment not found - it will be created"

terraform plan -var="resource_group_name=$RESOURCE_GROUP"
terraform apply -auto-approve -var="resource_group_name=$RESOURCE_GROUP"
cd ..

print_status "🎉 Deployment completed successfully!"
print_status "📋 Summary:"
print_status "  - Resource Group: $RESOURCE_GROUP"
print_status "  - Location: $LOCATION"
print_status "  - Storage Account: shdwagentstorage"
print_status "  - Logic Apps: All workflows deployed with definitions"

print_status "🔗 Next steps:"
print_status "  1. Test the entry Logic App endpoint"
print_status "  2. Monitor executions in Azure Portal"
print_status "  3. Check AI Foundry usage in Azure AI Studio"
print_status "  4. Monitor queue processing"
