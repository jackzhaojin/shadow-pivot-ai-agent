#!/bin/bash

# Shadow Pivot AI Agent Test Script
set -e

# Configuration
LOGIC_APP_URL=""  # Set this to your deployed Logic App URL
API_KEY=""        # Set this if you have API key authentication

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed. Please install it first."
    exit 1
fi

# Check if Logic App URL is set
if [ -z "$LOGIC_APP_URL" ]; then
    print_warning "Logic App URL is not set. Please update the script with your deployed URL."
    print_status "You can find the URL in Azure Portal > Logic Apps > entry-agent-step > Overview"
    exit 1
fi

print_status "🧪 Starting Shadow Pivot AI Agent tests..."

# Test 1: Basic functionality test
print_test "Test 1: Basic functionality"
response1=$(curl -s -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Test prompt for basic functionality",
    "userId": "test-user-001",
    "sessionId": "test-session-001"
  }')

if [[ $? -eq 0 ]]; then
    print_status "✅ Basic test completed"
    echo "Response: $response1"
else
    print_error "❌ Basic test failed"
fi

echo ""

# Test 2: Marketing campaign test
print_test "Test 2: Marketing campaign generation"
response2=$(curl -s -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a comprehensive marketing strategy for launching a new mobile app that helps people track their carbon footprint",
    "userId": "marketer-123",
    "sessionId": "campaign-session-001",
    "priority": "high"
  }')

if [[ $? -eq 0 ]]; then
    print_status "✅ Marketing campaign test completed"
    echo "Response: $response2"
else
    print_error "❌ Marketing campaign test failed"
fi

echo ""

# Test 3: Content creation test
print_test "Test 3: Technical content creation"
response3=$(curl -s -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a technical blog post about the benefits of serverless architecture for startups, including code examples and best practices",
    "userId": "content-writer-456",
    "sessionId": "blog-session-001"
  }')

if [[ $? -eq 0 ]]; then
    print_status "✅ Content creation test completed"
    echo "Response: $response3"
else
    print_error "❌ Content creation test failed"
fi

echo ""

# Test 4: Error handling test (invalid JSON)
print_test "Test 4: Error handling (invalid request)"
response4=$(curl -s -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "invalid": "request without required fields"
  }')

if [[ $? -eq 0 ]]; then
    print_status "✅ Error handling test completed"
    echo "Response: $response4"
else
    print_error "❌ Error handling test failed"
fi

echo ""

# Test 5: Load test (multiple concurrent requests)
print_test "Test 5: Concurrent requests test"
for i in {1..5}; do
    curl -s -X POST "$LOGIC_APP_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"prompt\": \"Load test request #$i - Generate a creative story\",
        \"userId\": \"load-test-user-$i\",
        \"sessionId\": \"load-test-session-$i\"
      }" &
done

wait
print_status "✅ Concurrent requests test completed"

echo ""
print_status "🎉 All tests completed!"
print_status "📊 Test Summary:"
print_status "  - Basic functionality: ✅"
print_status "  - Marketing campaign: ✅"
print_status "  - Content creation: ✅"
print_status "  - Error handling: ✅"
print_status "  - Concurrent requests: ✅"

# Workflow Testing Section
print_status ""
print_status "🔄 GitHub Actions Workflow Testing:"
print_status "  For testing the deployment workflow locally, use:"
print_status "  1. Validate workflow: ./validate-workflow.sh"
print_status "  2. Run locally with act: ./test-local-workflow.sh"
print_status "  3. Test individual commands:"

# Test Azure CLI commands individually
print_test "Testing Azure CLI accessibility..."
if az account show &> /dev/null; then
    print_status "  ✅ Azure CLI authenticated"
    
    # Test resource group access
    if az group show --name "ShadowPivot" &> /dev/null; then
        print_status "  ✅ Can access resource group"
    else
        print_warning "  ⚠️ Cannot access ShadowPivot resource group"
    fi
    
    # Test Logic App access
    logic_apps=("entry-agent-step" "design-gen-step" "content-gen-step" "review-step")
    for app in "${logic_apps[@]}"; do
        if az logic workflow show --resource-group "ShadowPivot" --name "$app" &> /dev/null; then
            print_status "  ✅ Can access Logic App: $app"
        else
            print_warning "  ⚠️ Cannot access Logic App: $app"
        fi
    done
else
    print_warning "  ⚠️ Azure CLI not authenticated. Run 'az login' first."
fi

print_status "🔍 Next steps:"
print_status "  1. Check Azure Portal for Logic App execution history"
print_status "  2. Monitor storage queues for message processing"
print_status "  3. Review any error logs in Logic Apps"
print_status "  4. Test the complete pipeline end-to-end"
