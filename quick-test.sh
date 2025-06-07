#!/bin/bash

# Quick workflow test script
# This runs some basic validation tests on the GitHub Actions workflow

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "🧪 Running quick workflow validation tests..."

# Test 1: Validate workflow syntax with act
print_status "Test 1: Validating workflow syntax..."
if act --list -W .github/workflows/deploy-logicapps.yml > /dev/null 2>&1; then
    print_status "✅ Workflow syntax is valid"
else
    print_error "❌ Workflow syntax validation failed"
    exit 1
fi

# Test 2: Dry run validation
print_status "Test 2: Running dry-run validation..."
if act workflow_dispatch --dryrun -W .github/workflows/deploy-logicapps.yml --secret-file .act-secrets > /dev/null 2>&1; then
    print_status "✅ Dry run passed - all steps are valid"
else
    print_error "❌ Dry run failed"
    exit 1
fi

# Test 3: Check required files exist
print_status "Test 3: Checking required files..."
required_files=(
    ".github/workflows/deploy-logicapps.yml"
    "logic-apps/entry/workflow.json"
    "logic-apps/design-gen/workflow.json"
    "logic-apps/content-gen/workflow.json"
    "logic-apps/review/workflow.json"
)

all_files_exist=true
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        print_status "✅ $file exists"
    else
        print_error "❌ Missing file: $file"
        all_files_exist=false
    fi
done

if [[ "$all_files_exist" == "false" ]]; then
    exit 1
fi

# Test 4: Validate Logic App JSON files
print_status "Test 4: Validating Logic App JSON syntax..."
if command -v jq &> /dev/null; then
    for file in logic-apps/*/workflow.json; do
        if jq . "$file" > /dev/null 2>&1; then
            print_status "✅ $file has valid JSON syntax"
        else
            print_error "❌ $file has invalid JSON syntax"
            exit 1
        fi
    done
else
    print_warning "⚠️ jq not found, skipping JSON validation"
fi

# Test 5: Check for environment variables and secrets
print_status "Test 5: Checking workflow configuration..."
workflow_file=".github/workflows/deploy-logicapps.yml"

# Check for required secrets
required_secrets=("AZURE_CLIENT_ID" "AZURE_SUBSCRIPTION_ID" "AZURE_TENANT_ID")
for secret in "${required_secrets[@]}"; do
    if grep -q "$secret" "$workflow_file"; then
        print_status "✅ Secret reference found: $secret"
    else
        print_warning "⚠️ Secret not referenced: $secret"
    fi
done

# Check for environment variables
if grep -q "RESOURCE_GROUP" "$workflow_file"; then
    print_status "✅ Resource group configuration found"
else
    print_warning "⚠️ Resource group configuration not found"
fi

print_status ""
print_status "🎉 All validation tests passed!"
print_status ""
print_status "🚀 To run the full workflow locally:"
print_status "   ./test-local-workflow.sh"
print_status ""
print_status "🧪 To test individual commands:"
print_status "   act workflow_dispatch -W .github/workflows/deploy-logicapps.yml --secret-file .act-secrets"
print_status ""
print_status "📋 Next steps:"
print_status "   1. Update .act-secrets with real Azure credentials"
print_status "   2. Test deployment in a dev environment"
print_status "   3. Run the workflow in GitHub Actions"
