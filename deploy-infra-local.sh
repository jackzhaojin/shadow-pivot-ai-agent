#!/bin/bash

# Local Development Terraform Deployment Script
# This script configures and deploys Terraform for local development using Azure CLI authentication

set -e

echo "🚀 Starting Local Terraform Deployment"
echo "======================================"

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged into Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure. Please run 'az login' first."
    exit 1
fi

# Navigate to infrastructure directory
cd "$(dirname "$0")/infra"

echo "📁 Working directory: $(pwd)"
echo "🔧 Authentication: Azure CLI"
echo "📄 Variables file: terraform.tfvars.local"
echo ""

# Initialize Terraform
echo "1️⃣ Initializing Terraform..."
terraform init

# Validate configuration
echo "2️⃣ Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "3️⃣ Planning deployment..."
terraform plan -var-file="terraform.tfvars.local"

# Ask for confirmation
echo ""
read -p "📋 Do you want to apply these changes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "4️⃣ Applying Terraform configuration..."
    terraform apply -var-file="terraform.tfvars.local" -auto-approve
    
    echo ""
    echo "✅ Local deployment completed successfully!"
    echo ""
    echo "📋 Infrastructure Summary:"
    echo "  ✅ Azure AI Foundry: shadow-pivot-ai-foundry"
    echo "  ✅ User-Assigned Managed Identity: shadow-pivot-logic-apps-identity"
    echo "  ✅ Storage Account: shdwagentstorage"
    echo "  ✅ Storage Queues: design-gen-q, content-gen-q, review-q, completion-q"
    echo "  ✅ Storage Container: ai-artifacts"
    echo "  ✅ API Connection: azurequeues-connection"
    echo "  ✅ Logic Apps (empty): entry-agent-step, design-gen-step, content-gen-step, review-step"
    echo "  ✅ GPT-4.1 Deployment: gpt-4-deployment"
    echo ""
    echo "🔗 Next Steps:"
    echo "  1. Deploy Logic App workflows using: ./deploy-logic-apps-local.sh"
    echo "  2. Test the complete AI pipeline"
    echo ""
    echo "📍 Resource Group: ShadowPivot"
    echo "📍 Location: eastus"
    echo "🌐 Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/ShadowPivot"
else
    echo "❌ Deployment cancelled."
    exit 0
fi
