#!/bin/bash

# Shadow Pivot AI Agent - Project Validation Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Validation counters
PASS=0
WARN=0
FAIL=0

print_header "Shadow Pivot AI Agent - Project Validation"

echo ""
print_header "File Structure Validation"

# Check critical files
files=(
    "infra/main.tf"
    "infra/variables.tf"
    "infra/outputs.tf"
    "infra/terraform.tfvars"
    ".github/workflows/deploy-infra.yml"
    ".github/workflows/deploy-logicapps.yml"
    "logic-apps/entry/workflow.json"
    "logic-apps/design-gen/workflow.json"
    "logic-apps/content-gen/workflow.json"
    "logic-apps/review/workflow.json"
    "README.md"
    "API_DOCS.md"
    "deploy.sh"
    "deploy.ps1"
    "test.sh"
    ".gitignore"
)

for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "File exists: $file"
        ((PASS++))
    else
        print_error "Missing file: $file"
        ((FAIL++))
    fi
done

echo ""
print_header "Terraform Configuration Validation"

# Check Terraform syntax
if command -v terraform &> /dev/null; then
    cd infra
    if terraform fmt -check > /dev/null 2>&1; then
        print_success "Terraform formatting is correct"
        ((PASS++))
    else
        print_warning "Terraform files need formatting (run: terraform fmt)"
        ((WARN++))
    fi
    
    if terraform validate > /dev/null 2>&1; then
        print_success "Terraform configuration is valid"
        ((PASS++))
    else
        print_error "Terraform configuration has errors"
        terraform validate
        ((FAIL++))
    fi
    cd ..
else
    print_warning "Terraform not installed - skipping validation"
    ((WARN++))
fi

echo ""
print_header "Logic App JSON Validation"

# Check JSON syntax for Logic Apps
logic_apps=("entry" "design-gen" "content-gen" "review")
for app in "${logic_apps[@]}"; do
    json_file="logic-apps/$app/workflow.json"
    if [[ -f "$json_file" ]]; then
        if python -m json.tool "$json_file" > /dev/null 2>&1; then
            print_success "Valid JSON: $json_file"
            ((PASS++))
        else
            print_error "Invalid JSON: $json_file"
            ((FAIL++))
        fi
    fi
done

echo ""
print_header "GitHub Actions Workflow Validation"

# Check YAML syntax for GitHub Actions
workflows=(".github/workflows/deploy-infra.yml" ".github/workflows/deploy-logicapps.yml")
for workflow in "${workflows[@]}"; do
    if [[ -f "$workflow" ]]; then
        if python -c "import yaml; yaml.safe_load(open('$workflow'))" > /dev/null 2>&1; then
            print_success "Valid YAML: $workflow"
            ((PASS++))
        else
            print_error "Invalid YAML: $workflow"
            ((FAIL++))
        fi
    fi
done

echo ""
print_header "Documentation Validation"

# Check if documentation files have content
docs=("README.md" "API_DOCS.md" "PROJECT_SUMMARY.md")
for doc in "${docs[@]}"; do
    if [[ -f "$doc" ]]; then
        if [[ -s "$doc" ]]; then
            word_count=$(wc -w < "$doc")
            if [[ $word_count -gt 100 ]]; then
                print_success "Documentation complete: $doc ($word_count words)"
                ((PASS++))
            else
                print_warning "Documentation may be incomplete: $doc ($word_count words)"
                ((WARN++))
            fi
        else
            print_error "Empty documentation file: $doc"
            ((FAIL++))
        fi
    fi
done

echo ""
print_header "Script Permissions Validation"

# Check if scripts are executable
scripts=("deploy.sh" "test.sh")
for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            print_success "Script is executable: $script"
            ((PASS++))
        else
            print_warning "Script is not executable: $script (run: chmod +x $script)"
            ((WARN++))
        fi
    fi
done

echo ""
print_header "Environment Configuration Validation"

if [[ -f ".env.example" ]]; then
    if grep -q "AZURE_RESOURCE_GROUP" .env.example && grep -q "OPENAI_API_KEY" .env.example; then
        print_success "Environment template contains required variables"
        ((PASS++))
    else
        print_warning "Environment template may be missing required variables"
        ((WARN++))
    fi
fi

echo ""
print_header "Git Repository Validation"

# Check git status
if git status > /dev/null 2>&1; then
    print_success "Git repository is initialized"
    ((PASS++))
    
    # Check if there are any uncommitted changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        print_success "All changes are committed"
        ((PASS++))
    else
        print_warning "There are uncommitted changes"
        ((WARN++))
    fi
else
    print_error "Not a git repository"
    ((FAIL++))
fi

echo ""
print_header "Validation Summary"

total=$((PASS + WARN + FAIL))
echo -e "Total checks: ${BLUE}$total${NC}"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Warnings: ${YELLOW}$WARN${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"

echo ""
if [[ $FAIL -eq 0 ]]; then
    if [[ $WARN -eq 0 ]]; then
        print_success "🎉 Project validation PASSED! Ready for deployment."
        echo ""
        print_info "Next steps:"
        echo "  1. Push to GitHub repository"
        echo "  2. Configure GitHub Secrets for Azure authentication"
        echo "  3. Deploy using GitHub Actions or manual scripts"
        echo "  4. Test the API endpoints"
    else
        print_warning "⚠️  Project validation PASSED with warnings. Review warnings above."
    fi
else
    print_error "❌ Project validation FAILED. Please fix the errors above before deployment."
    exit 1
fi
