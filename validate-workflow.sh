#!/bin/bash

# Simple GitHub Actions Workflow Validation Script
# This validates the workflow without running it

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

WORKFLOW_FILE=".github/workflows/deploy-logicapps.yml"

print_status "🔍 Validating GitHub Actions workflow: $WORKFLOW_FILE"

# Check if workflow file exists
if [[ ! -f "$WORKFLOW_FILE" ]]; then
    print_error "Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

# Validate YAML syntax
if command -v yq &> /dev/null; then
    print_status "✅ Validating YAML syntax..."
    if yq eval '.' "$WORKFLOW_FILE" > /dev/null; then
        print_status "✅ YAML syntax is valid"
    else
        print_error "❌ YAML syntax error found"
        exit 1
    fi
else
    print_warning "⚠️ yq not found. Install with: pip install yq"
fi

# Check for required secrets
print_status "🔐 Checking for required secrets..."
required_secrets=(
    "AZURE_CLIENT_ID"
    "AZURE_SUBSCRIPTION_ID" 
    "AZURE_TENANT_ID"
)

for secret in "${required_secrets[@]}"; do
    if grep -q "$secret" "$WORKFLOW_FILE"; then
        print_status "✅ Found reference to secret: $secret"
    else
        print_warning "⚠️ Secret not found in workflow: $secret"
    fi
done

# Check for Logic App workflow files
print_status "📄 Checking for Logic App workflow files..."
workflow_files=(
    "logic-apps/entry/workflow.json"
    "logic-apps/design-gen/workflow.json"
    "logic-apps/content-gen/workflow.json"
    "logic-apps/review/workflow.json"
)

for file in "${workflow_files[@]}"; do
    if [[ -f "$file" ]]; then
        print_status "✅ Found workflow file: $file"
        
        # Validate JSON if jq is available
        if command -v jq &> /dev/null; then
            if jq . "$file" > /dev/null 2>&1; then
                print_status "  ✅ JSON syntax is valid"
            else
                print_error "  ❌ JSON syntax error in $file"
            fi
        fi
    else
        print_error "❌ Missing workflow file: $file"
    fi
done

# Extract and display workflow info
print_status "📋 Workflow Information:"
if command -v yq &> /dev/null; then
    name=$(yq eval '.name' "$WORKFLOW_FILE")
    print_status "  Name: $name"
    
    triggers=$(yq eval '.on | keys | join(", ")' "$WORKFLOW_FILE")
    print_status "  Triggers: $triggers"
    
    jobs=$(yq eval '.jobs | keys | join(", ")' "$WORKFLOW_FILE")
    print_status "  Jobs: $jobs"
fi

print_status "✅ Workflow validation completed!"

# Provide testing suggestions
echo ""
print_status "🧪 Testing suggestions:"
echo "1. Use 'act' to run the workflow locally (see test-local-workflow.sh)"
echo "2. Test individual Azure CLI commands manually"
echo "3. Validate Logic App JSON files with Azure CLI:"
echo "   az logic workflow validate --definition @logic-apps/entry/workflow.json"
echo "4. Test workflow with workflow_dispatch trigger in GitHub"
