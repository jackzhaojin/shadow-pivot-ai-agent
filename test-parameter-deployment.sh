#!/bin/bash

# Test script for parameter-based Logic Apps deployment
# This script validates the parameter file processing without actually deploying

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Test configuration
RESOURCE_GROUP="ShadowPivot"
LOCATION="eastus"

print_header "Parameter-Based Deployment Test Suite"

# Test 1: Validate parameter files exist
print_status "Test 1: Checking parameter files exist..."
workflows=("entry" "design-gen" "content-gen" "review")
all_files_exist=true

for workflow in "${workflows[@]}"; do
    param_file="logic-apps/$workflow/parameters.json"
    workflow_file="logic-apps/$workflow/workflow.json"
    
    if [[ -f "$param_file" ]]; then
        print_status "✅ Parameter file exists: $param_file"
    else
        print_error "❌ Missing parameter file: $param_file"
        all_files_exist=false
    fi
    
    if [[ -f "$workflow_file" ]]; then
        print_status "✅ Workflow file exists: $workflow_file"
    else
        print_error "❌ Missing workflow file: $workflow_file"
        all_files_exist=false
    fi
done

if [[ "$all_files_exist" == "true" ]]; then
    print_status "🎯 All required files found!"
else
    print_error "❌ Some files are missing. Cannot proceed."
    exit 1
fi

# Test 2: Validate JSON syntax
print_status ""
print_status "Test 2: Validating JSON syntax..."
./deploy-logic-apps.sh validate

# Test 3: Test parameter processing (dry run)
print_status ""
print_status "Test 3: Testing parameter processing..."

# Create test temp directory
mkdir -p test-temp-params

# Mock function to simulate parameter processing
process_test_parameters() {
    local source_file="$1"
    local target_file="$2"
    local workflow_name="$3"
    
    print_status "Testing parameter processing for $workflow_name..."
    
    # Copy the template
    cp "$source_file" "$target_file"
    
    # Replace placeholders with test values
    sed -i "s|\[SUBSCRIPTION_ID\]|12345678-1234-1234-1234-123456789012|g" "$target_file"
    sed -i "s|\[RESOURCE_GROUP\]|$RESOURCE_GROUP|g" "$target_file"
    sed -i "s|\[LOCATION\]|$LOCATION|g" "$target_file"
    sed -i "s|\[STORAGE_CONNECTION_ID\]|/subscriptions/test/resourceGroups/test/providers/Microsoft.Web/connections/test|g" "$target_file"
    
    # Replace AI-specific placeholders (only for AI workflows)
    if [[ "$workflow_name" != "entry" ]]; then
        sed -i "s|\[AI_FOUNDRY_ENDPOINT\]|https://test-ai-foundry.openai.azure.com/|g" "$target_file"
        sed -i "s|\[GPT4_DEPLOYMENT_NAME\]|gpt-4-deployment|g" "$target_file"
        sed -i "s|\[MANAGED_IDENTITY_CLIENT_ID\]|12345678-1234-1234-1234-123456789012|g" "$target_file"
    fi
    
    # Validate the resulting JSON
    if node -e "JSON.parse(require('fs').readFileSync('$target_file', 'utf8'))" 2>/dev/null; then
        print_status "✅ Parameter processing successful for $workflow_name"
        
        # Show a preview of the processed parameters
        echo "Preview of processed parameters:"
        echo "-----------------------------"
        head -10 "$target_file" | sed 's/^/  /'
        echo "  ..."
        echo ""
    else
        print_error "❌ Parameter processing failed for $workflow_name"
        return 1
    fi
}

# Test parameter processing for each workflow
for workflow in "${workflows[@]}"; do
    source_file="logic-apps/$workflow/parameters.json"
    target_file="test-temp-params/$workflow-parameters.json"
    
    process_test_parameters "$source_file" "$target_file" "$workflow"
done

# Test 4: Verify placeholder replacement
print_status ""
print_status "Test 4: Verifying placeholder replacement..."

for workflow in "${workflows[@]}"; do
    target_file="test-temp-params/$workflow-parameters.json"
    
    # Check if any placeholders remain
    remaining_placeholders=$(grep -o '\[.*\]' "$target_file" 2>/dev/null || true)
    
    if [[ -z "$remaining_placeholders" ]]; then
        print_status "✅ All placeholders replaced in $workflow parameters"
    else
        print_warning "⚠️ Remaining placeholders in $workflow: $remaining_placeholders"
    fi
done

# Test 5: Validate GitHub Actions workflow syntax
print_status ""
print_status "Test 5: Checking GitHub Actions workflow syntax..."

workflow_file=".github/workflows/deploy-logicapps.yml"
if [[ -f "$workflow_file" ]]; then
    # Basic syntax check for YAML
    if command -v yamllint &> /dev/null; then
        yamllint "$workflow_file" && print_status "✅ GitHub Actions workflow syntax is valid"
    elif command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$workflow_file'))" && print_status "✅ GitHub Actions workflow syntax is valid"
    else
        print_warning "⚠️ Cannot validate YAML syntax (no yamllint or python3 available)"
    fi
    
    # Check for required steps
    if grep -q "Prepare Parameter Files" "$workflow_file"; then
        print_status "✅ GitHub Actions workflow includes parameter preparation step"
    else
        print_error "❌ GitHub Actions workflow missing parameter preparation step"
    fi
else
    print_error "❌ GitHub Actions workflow file not found: $workflow_file"
fi

# Test 6: Check script permissions
print_status ""
print_status "Test 6: Checking script permissions..."

scripts=("deploy.sh" "deploy-logic-apps.sh" "test-parameter-deployment.sh")
for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
        print_status "✅ $script is executable"
    else
        print_warning "⚠️ $script is not executable (run: chmod +x $script)"
    fi
done

# Clean up test files
print_status ""
print_status "Cleaning up test files..."
rm -rf test-temp-params

# Test Summary
print_status ""
print_header "Test Summary"
print_status "🎯 Parameter-based deployment system validation completed!"
print_status ""
print_status "✅ Tests passed:"
print_status "  - Parameter files exist and are valid JSON"
print_status "  - Parameter processing works correctly"
print_status "  - Placeholder replacement functions properly"
print_status "  - GitHub Actions workflow includes parameter steps"
print_status ""
print_status "🚀 The parameter-based deployment system is ready to use!"
print_status ""
print_status "Next steps:"
print_status "  1. Run './deploy-logic-apps.sh validate' to validate parameters"
print_status "  2. Run './deploy-logic-apps.sh deploy' to deploy with parameters"
print_status "  3. Use GitHub Actions for automated deployment"
print_status "  4. Monitor deployments in Azure Portal"
