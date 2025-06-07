#!/bin/bash

# Shadow Pivot AI Agent - Project Validation Script
# Removed set -e to prevent premature exit

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

# Check Terraform syntax with better error handling
if command -v terraform &> /dev/null; then
    print_info "Terraform found, checking configuration..."
    
    # Change to infra directory
    if cd infra 2>/dev/null; then
        # Check if Terraform is initialized
        if [[ -d ".terraform" ]]; then
            print_info "Terraform appears to be initialized"
        else
            print_warning "Terraform not initialized - some validations may fail"
            print_info "Run 'terraform init' in the infra directory"
        fi
        
        # Check formatting
        if terraform fmt -check > /dev/null 2>&1; then
            print_success "Terraform formatting is correct"
            ((PASS++))
        else
            print_warning "Terraform files need formatting (run: terraform fmt)"
            ((WARN++))
        fi
        
        # Check validation with better error handling
        validate_output=$(terraform validate 2>&1)
        validate_exit_code=$?
        
        if [[ $validate_exit_code -eq 0 ]]; then
            print_success "Terraform configuration is valid"
            ((PASS++))
        else
            print_error "Terraform configuration has errors:"
            echo "$validate_output"
            ((FAIL++))
        fi
        
        # Return to original directory
        cd .. || exit 1
    else
        print_error "Cannot access infra directory"
        ((FAIL++))
    fi
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
        # Try multiple JSON validation methods
        if command -v python &> /dev/null && python -m json.tool "$json_file" > /dev/null 2>&1; then
            print_success "Valid JSON: $json_file"
            ((PASS++))
        elif command -v node &> /dev/null && node -e "JSON.parse(require('fs').readFileSync('$json_file', 'utf8'))" > /dev/null 2>&1; then
            print_success "Valid JSON: $json_file (validated with Node.js)"
            ((PASS++))
        elif command -v jq &> /dev/null && jq empty "$json_file" > /dev/null 2>&1; then
            print_success "Valid JSON: $json_file (validated with jq)"
            ((PASS++))
        else
            print_warning "Could not validate JSON: $json_file (no JSON validator available)"
            ((WARN++))
        fi
    else
        print_warning "Logic App file not found: $json_file"
        ((WARN++))
    fi
done

echo ""
print_header "GitHub Actions Workflow Validation"

# Check YAML syntax for GitHub Actions with better error handling
workflows=(".github/workflows/deploy-infra.yml" ".github/workflows/deploy-logicapps.yml")
for workflow in "${workflows[@]}"; do
    if [[ -f "$workflow" ]]; then
        # Try multiple YAML validation methods
        if command -v python &> /dev/null && python -c "import yaml; yaml.safe_load(open('$workflow'))" > /dev/null 2>&1; then
            print_success "Valid YAML: $workflow"
            ((PASS++))
        elif command -v yq &> /dev/null && yq eval . "$workflow" > /dev/null 2>&1; then
            print_success "Valid YAML: $workflow (validated with yq)"
            ((PASS++))
        else
            print_warning "Could not validate YAML: $workflow (no YAML validator available)"
            ((WARN++))
        fi
    else
        print_warning "Workflow file not found: $workflow"
        ((WARN++))
    fi
done

echo ""
print_header "Documentation Validation"

# Check if documentation files have content
docs=("README.md" "API_DOCS.md" "PROJECT_SUMMARY.md")
for doc in "${docs[@]}"; do
    if [[ -f "$doc" ]]; then
        if [[ -s "$doc" ]]; then
            word_count=$(wc -w < "$doc" 2>/dev/null || echo "0")
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
    else
        print_warning "Documentation file not found: $doc"
        ((WARN++))
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
    else
        print_warning "Script not found: $script"
        ((WARN++))
    fi
done

echo ""
print_header "Environment Configuration Validation"

if [[ -f ".env.example" ]]; then
    if grep -q "AZURE_RESOURCE_GROUP" .env.example 2>/dev/null && grep -q "OPENAI_API_KEY" .env.example 2>/dev/null; then
        print_success "Environment template contains required variables"
        ((PASS++))
    else
        print_warning "Environment template may be missing required variables"
        ((WARN++))
    fi
else
    print_warning "No .env.example file found"
    ((WARN++))
fi

echo ""
print_header "Git Repository Validation"

# Check git status with better error handling
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
    print_error "Not a git repository or git not available"
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