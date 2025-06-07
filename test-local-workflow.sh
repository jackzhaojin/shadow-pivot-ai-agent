#!/bin/bash

# Local GitHub Actions Workflow Testing Script using 'act'
# This script tests the actual deploy-logicapps.yml workflow locally

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

# Check if act is installed
if ! command -v act &> /dev/null; then
    print_error "act is not installed. Installing it now..."
    
    # Install act based on OS
    case "$(uname -s)" in
        Linux*)
            print_status "Installing act on Linux..."
            curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
            ;;
        Darwin*)
            print_status "Installing act on macOS..."
            if command -v brew &> /dev/null; then
                brew install act
            else
                print_error "Homebrew not found. Please install homebrew first or install act manually."
                exit 1
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            print_status "Installing act on Windows..."
            if command -v choco &> /dev/null; then
                choco install act-cli
            elif command -v winget &> /dev/null; then
                winget install nektos.act
            else
                print_error "Please install act manually from: https://github.com/nektos/act"
                print_status "Or use chocolatey: choco install act-cli"
                print_status "Or use winget: winget install nektos.act"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS. Please install act manually from: https://github.com/nektos/act"
            exit 1
            ;;
    esac
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running."
    print_status "Docker is required to run GitHub Actions workflows locally with act."
    print_status ""
    print_status "To start Docker:"
    print_status "  1. Open Docker Desktop from Start Menu"
    print_status "  2. Wait for Docker to start (usually takes 30-60 seconds)"
    print_status "  3. Or run: 'Docker Desktop.exe' from command line"
    print_status ""
    print_status "Would you like to continue with validation-only mode? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "🔍 Running in validation-only mode..."
        VALIDATION_ONLY=true
    else
        print_status "Please start Docker and run this script again."
        exit 1
    fi
else
    print_status "✅ Docker is running"
    VALIDATION_ONLY=false
fi

print_status "🧪 Testing Logic Apps deployment workflow locally..."

# Create a temporary secrets file for local testing
SECRETS_FILE=".act-secrets"
cat > "$SECRETS_FILE" << EOF
AZURE_CLIENT_ID=your-client-id-here
AZURE_SUBSCRIPTION_ID=your-subscription-id-here
AZURE_TENANT_ID=your-tenant-id-here
EOF

print_warning "Please update $SECRETS_FILE with your actual Azure credentials before running."

# Create act configuration
ACT_CONFIG=".actrc"
cat > "$ACT_CONFIG" << EOF
# act configuration
--container-architecture linux/amd64
--platform ubuntu-latest=catthehacker/ubuntu:act-latest
EOF

print_status "Configuration files created:"
print_status "  - $SECRETS_FILE (update with your Azure credentials)"
print_status "  - $ACT_CONFIG (act configuration)"

# Run basic validation immediately
print_status ""
print_status "🔍 Running basic workflow validation..."

# Check if workflow file exists
if [[ -f ".github/workflows/deploy-logicapps.yml" ]]; then
    print_status "✅ Workflow file found"
    
    # List workflows and jobs
    print_status "📋 Available workflows and jobs:"
    if act --list -W .github/workflows/deploy-logicapps.yml 2>/dev/null; then
        print_status "✅ Workflow structure is valid"
    else
        print_warning "⚠️ Issues found with workflow structure"
    fi
else
    print_error "❌ Workflow file not found: .github/workflows/deploy-logicapps.yml"
fi

# Check for Logic App workflow files
print_status ""
print_status "📄 Checking Logic App workflow files..."
workflow_files=(
    "logic-apps/entry/workflow.json"
    "logic-apps/design-gen/workflow.json"
    "logic-apps/content-gen/workflow.json"
    "logic-apps/review/workflow.json"
)

for file in "${workflow_files[@]}"; do
    if [[ -f "$file" ]]; then
        print_status "✅ Found: $file"
    else
        print_error "❌ Missing: $file"
    fi
done

echo ""
if [[ "$VALIDATION_ONLY" == "true" ]]; then
    print_status "🔍 Validation-only commands (Docker not running):"
    echo ""
    echo "1. Validate workflow syntax:"
    echo "   act --list -W .github/workflows/deploy-logicapps.yml"
    echo ""
    echo "2. Dry run (validate without executing):"
    echo "   act --dryrun -W .github/workflows/deploy-logicapps.yml --secret-file $SECRETS_FILE"
    echo ""
    echo "3. Check workflow structure:"
    echo "   ./validate-workflow.sh"
    echo ""
    print_status "💡 To run full tests, start Docker and run this script again."
else
    print_status "🚀 Full testing commands (Docker is running):"
    echo ""
    echo "1. Test with workflow_dispatch trigger:"
    echo "   act workflow_dispatch -W .github/workflows/deploy-logicapps.yml --secret-file $SECRETS_FILE"
    echo ""
    echo "2. Test with workflow_run trigger (simulating successful infrastructure deployment):"
    echo "   act workflow_run -W .github/workflows/deploy-logicapps.yml --secret-file $SECRETS_FILE"
    echo ""
    echo "3. Dry run (just validate the workflow):"
    echo "   act --dryrun -W .github/workflows/deploy-logicapps.yml --secret-file $SECRETS_FILE"
    echo ""
    echo "4. Test specific job only:"
    echo "   act workflow_dispatch -j deploy-workflows -W .github/workflows/deploy-logicapps.yml --secret-file $SECRETS_FILE"
    echo ""
fi

print_status "📝 Additional act options:"
echo "  --verbose           : Show detailed logs"
echo "  --list              : List all workflows and jobs"
echo "  --dryrun            : Show what would run without executing"
echo "  --reuse             : Reuse containers between runs"
echo "  --env-file .env     : Load environment variables from file"

print_warning "⚠️  Important notes:"
print_warning "  1. Update $SECRETS_FILE with real Azure credentials"
print_warning "  2. Make sure Docker has enough resources (4GB+ RAM recommended)"
print_warning "  3. Some Azure CLI commands may not work exactly the same in containers"
print_warning "  4. Consider using --dry-run first to validate the workflow structure"

# Cleanup function
cleanup() {
    print_status "🧹 Cleaning up temporary files..."
    rm -f "$SECRETS_FILE" "$ACT_CONFIG"
}

# Set trap to cleanup on exit
trap cleanup EXIT

print_status "✅ Setup complete! Follow the commands above to test your workflow."
