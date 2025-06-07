#!/bin/bash

# Logic Apps Parameter File Manager
# This script helps manage and deploy Logic Apps with their parameter files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
RESOURCE_GROUP="ShadowPivot"
LOCATION="eastus"

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Function to process parameter files
process_parameters() {
    local source_file="$1"
    local target_file="$2"
    local workflow_name="$3"
    
    print_status "Processing parameters for $workflow_name..."
    
    # Get dynamic values from Azure
    SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
    STORAGE_CONNECTION_ID=$(az resource show \
        --resource-group $RESOURCE_GROUP \
        --name azurequeues-connection \
        --resource-type Microsoft.Web/connections \
        --query "id" -o tsv)
    
    # Copy the template and replace placeholders
    cp "$source_file" "$target_file"
    
    # Replace common placeholders
    sed -i "s|\[SUBSCRIPTION_ID\]|$SUBSCRIPTION_ID|g" "$target_file"
    sed -i "s|\[RESOURCE_GROUP\]|$RESOURCE_GROUP|g" "$target_file"
    sed -i "s|\[LOCATION\]|$LOCATION|g" "$target_file"
    sed -i "s|\[STORAGE_CONNECTION_ID\]|$STORAGE_CONNECTION_ID|g" "$target_file"
    
    # Replace AI-specific placeholders (only for AI workflows)
    if [[ "$workflow_name" != "entry" ]]; then
        AI_FOUNDRY_ENDPOINT=$(az cognitiveservices account show \
            --resource-group $RESOURCE_GROUP \
            --name shadow-pivot-ai-foundry \
            --query "properties.endpoint" -o tsv)
        
        GPT4_DEPLOYMENT_NAME=$(az cognitiveservices account deployment show \
            --resource-group $RESOURCE_GROUP \
            --name shadow-pivot-ai-foundry \
            --deployment-name gpt-4-deployment \
            --query "name" -o tsv)
        
        MANAGED_IDENTITY_CLIENT_ID=$(az identity show \
            --resource-group $RESOURCE_GROUP \
            --name shadow-pivot-logic-apps-identity \
            --query "clientId" -o tsv)
        
        sed -i "s|\[AI_FOUNDRY_ENDPOINT\]|$AI_FOUNDRY_ENDPOINT|g" "$target_file"
        sed -i "s|\[GPT4_DEPLOYMENT_NAME\]|$GPT4_DEPLOYMENT_NAME|g" "$target_file"
        sed -i "s|\[MANAGED_IDENTITY_CLIENT_ID\]|$MANAGED_IDENTITY_CLIENT_ID|g" "$target_file"
    fi
    
    print_status "✅ Parameters prepared for $workflow_name"
}

# Function to deploy a single Logic App
deploy_logic_app() {
    local workflow_name="$1"
    local logic_app_name="$2"
    
    print_status "🚀 Deploying $workflow_name Logic App workflow..."
    
    # Check if workflow files exist
    if [[ ! -f "logic-apps/$workflow_name/workflow.json" ]]; then
        print_error "Workflow file not found: logic-apps/$workflow_name/workflow.json"
        return 1
    fi
    
    if [[ ! -f "logic-apps/$workflow_name/parameters.json" ]]; then
        print_error "Parameters file not found: logic-apps/$workflow_name/parameters.json"
        return 1
    fi
    
    # Process parameters
    mkdir -p temp-params
    process_parameters "logic-apps/$workflow_name/parameters.json" "temp-params/$workflow_name-parameters.json" "$workflow_name"
    
    # Deploy the workflow
    az logic workflow update \
        --resource-group $RESOURCE_GROUP \
        --name $logic_app_name \
        --definition @logic-apps/$workflow_name/workflow.json \
        --parameters @temp-params/$workflow_name-parameters.json
    
    print_status "✅ $workflow_name Logic App workflow deployed successfully."
}

# Function to validate parameter files
validate_parameters() {
    print_status "🔍 Validating parameter files..."
    
    local workflows=("entry" "design-gen" "content-gen" "review")
    local all_valid=true
    
    for workflow in "${workflows[@]}"; do
        local param_file="logic-apps/$workflow/parameters.json"
        
        if [[ -f "$param_file" ]]; then
            # Use node to validate JSON instead of jq
            if node -e "JSON.parse(require('fs').readFileSync('$param_file', 'utf8'))" 2>/dev/null; then
                print_status "✅ Valid JSON: $param_file"
            else
                print_error "❌ Invalid JSON: $param_file"
                all_valid=false
            fi
        else
            print_error "❌ Missing parameter file: $param_file"
            all_valid=false
        fi
    done
    
    if [[ "$all_valid" == "true" ]]; then
        print_status "🎯 All parameter files are valid!"
    else
        print_error "⚠️ Some parameter files have issues. Please fix them before deployment."
        exit 1
    fi
}

# Main deployment function
main() {
    print_status "🚀 Starting Logic Apps parameter-based deployment..."
    
    # Validate parameter files first
    validate_parameters
    
    # Create temp directory for processed parameters
    mkdir -p temp-params
    
    # Deploy each Logic App
    deploy_logic_app "entry" "entry-agent-step"
    deploy_logic_app "design-gen" "design-gen-step"
    deploy_logic_app "content-gen" "content-gen-step"
    deploy_logic_app "review" "review-step"
    
    # Clean up temp files
    rm -rf temp-params
    
    print_status "🎉 All Logic App workflows deployed successfully!"
    print_status ""
    print_status "📋 Deployment Summary:"
    print_status "  ✅ Entry Logic App: entry-agent-step"
    print_status "  ✅ Design Generation: design-gen-step"
    print_status "  ✅ Content Generation: content-gen-step"
    print_status "  ✅ Review Logic App: review-step"
    print_status ""
    print_status "🔗 Next Steps:"
    print_status "  1. Test the Logic Apps in Azure Portal"
    print_status "  2. Monitor execution history"
    print_status "  3. Test the complete AI pipeline"
}

# Help function
show_help() {
    echo "Logic Apps Parameter File Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy          Deploy all Logic Apps with parameter files"
    echo "  validate        Validate all parameter files"
    echo "  deploy-single   Deploy a single Logic App (interactive)"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                # Deploy all Logic Apps"
    echo "  $0 validate              # Just validate parameter files"
    echo "  $0 deploy-single         # Interactive single deployment"
}

# Interactive single deployment
deploy_single() {
    echo "Available Logic Apps:"
    echo "1. entry (entry-agent-step)"
    echo "2. design-gen (design-gen-step)"
    echo "3. content-gen (content-gen-step)"
    echo "4. review (review-step)"
    echo ""
    read -p "Select Logic App to deploy (1-4): " choice
    
    case $choice in
        1) deploy_logic_app "entry" "entry-agent-step" ;;
        2) deploy_logic_app "design-gen" "design-gen-step" ;;
        3) deploy_logic_app "content-gen" "content-gen-step" ;;
        4) deploy_logic_app "review" "review-step" ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        main
        ;;
    validate)
        validate_parameters
        ;;
    deploy-single)
        validate_parameters
        deploy_single
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
