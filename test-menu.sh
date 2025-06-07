#!/bin/bash

# GitHub Actions Workflow Testing Menu
# Provides an interactive way to run different types of tests

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_menu() {
    echo -e "\n${BLUE}🧪 GitHub Actions Workflow Testing Menu${NC}\n"
    echo "1. Quick Validation Tests (recommended)"
    echo "2. Full Local Workflow Testing with act"
    echo "3. Security & Dependencies Check"
    echo "4. Advanced Testing with Report"
    echo "5. Workflow Syntax Validation Only"
    echo "6. View Testing Guide"
    echo "7. Check Testing Status"
    echo "0. Exit"
    echo
}

run_test() {
    case $1 in
        1)
            echo -e "${GREEN}Running quick validation tests...${NC}"
            ./quick-test.sh
            ;;
        2)
            echo -e "${GREEN}Running full local workflow testing...${NC}"
            ./test-local-workflow.sh
            ;;
        3)
            echo -e "${GREEN}Running security & dependencies check...${NC}"
            ./test-workflow-advanced.sh --dependencies-only
            ./test-workflow-advanced.sh --security-only
            ;;
        4)
            echo -e "${GREEN}Running advanced testing with report...${NC}"
            ./test-workflow-advanced.sh
            ;;
        5)
            echo -e "${GREEN}Running workflow syntax validation...${NC}"
            ./validate-workflow.sh
            ;;
        6)
            echo -e "${GREEN}Opening testing guide...${NC}"
            if command -v code &> /dev/null; then
                code TESTING-GUIDE.md
            else
                echo "📖 Please open TESTING-GUIDE.md in your editor"
            fi
            ;;
        7)
            echo -e "${GREEN}Checking testing status...${NC}"
            echo
            echo "📋 Available test scripts:"
            ls -la *.sh | grep test
            echo
            echo "📄 Testing files:"
            ls -la TESTING-GUIDE.md .env.test 2>/dev/null || echo "No additional testing files"
            echo
            echo "🔧 Dependencies:"
            echo -n "act: "; command -v act >/dev/null && echo "✅ installed" || echo "❌ missing"
            echo -n "docker: "; command -v docker >/dev/null && echo "✅ installed" || echo "❌ missing"
            echo -n "yq: "; command -v yq >/dev/null && echo "✅ installed" || echo "⚠️ optional"
            echo -n "jq: "; command -v jq >/dev/null && echo "✅ installed" || echo "⚠️ optional"
            ;;
        0)
            echo "👋 Happy testing!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            ;;
    esac
}

# Main loop
while true; do
    print_menu
    read -p "Choose an option (0-7): " choice
    
    if [[ "$choice" =~ ^[0-7]$ ]]; then
        run_test "$choice"
        echo
        read -p "Press Enter to continue..."
    else
        echo "❌ Please enter a number between 0 and 7."
    fi
done
