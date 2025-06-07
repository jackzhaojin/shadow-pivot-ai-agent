# Shadow Pivot AI Agent

This project implements an Azure-based AI agent system using Terraform for infrastructure provisioning, Azure AI Foundry for AI services, and GitHub Actions for automated deployment of Logic Apps.

## 🏗️ Architecture

The system uses:
- **Terraform** for infrastructure as code (Storage Account, Queues, AI Foundry)
- **Azure Logic Apps** for workflow orchestration  
- **Azure AI Foundry** with User-Assigned Managed Identity for secure AI services
- **GitHub Actions** for CI/CD automation
- **Azure Storage Queues** for message passing between AI steps

## 🔐 Security Features

- **Managed Identity Authentication**: No API keys required
- **Azure AD Integration**: Secure authentication to AI services
- **RBAC**: Principle of least privilege access control
- **Azure-native Security**: Full integration with Azure security ecosystem

## 📁 Project Structure

```
shadow-pivot-ai-agent/
├── infra/                    # Terraform infrastructure
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── terraform.tfvars     # Variable values
├── logic-apps/              # Logic App definitions
│   ├── entry/               # Entry point workflow
│   │   └── workflow.json
│   ├── design-gen/          # Design generation workflow
│   │   └── workflow.json
│   ├── content-gen/         # Content generation workflow
│   │   └── workflow.json
│   └── review/              # Review and finalization workflow
│       └── workflow.json
├── .github/
│   └── workflows/           # GitHub Actions
│       ├── deploy-infra.yml # Infrastructure deployment
│       └── deploy-logicapps.yml # Logic App deployment
├── deploy.sh               # Manual deployment script
├── test.sh                 # API testing script
├── API_DOCS.md            # API documentation
├── .env.example           # Environment configuration template
└── README.md
```

## 🚀 Setup & Deployment

### Prerequisites

1. Azure subscription with appropriate permissions
2. GitHub repository with the following secrets configured:
   - `AZURE_CLIENT_ID`
   - `AZURE_SUBSCRIPTION_ID` 
   - `AZURE_TENANT_ID`

**Note**: No OpenAI API key required - the system uses Azure AI Foundry with managed identity!

### Deployment Process

The deployment follows a sequential approach with two separate workflows:

1. **Infrastructure Deployment**: Push to `main` branch triggers:
   - **Bootstrap**: Creates Terraform state storage
   - **Terraform Apply**: Provisions core infrastructure:
     - Storage Account and Queues
     - Azure AI Foundry (OpenAI Service)
     - User-Assigned Managed Identity
     - Empty Logic Apps with proper RBAC assignments
     - API connections and role assignments

2. **Logic App Workflow Deployment**: Automatically triggered after infrastructure deployment:
   - Verifies infrastructure components exist
   - Retrieves necessary connection parameters
   - Deploys workflow definitions to Logic Apps:
     - Entry Agent Step
     - Design Generation Step  
     - Content Generation Step
     - Review Step
   - Tests entry endpoint functionality

### Manual Deployment

```bash
# 1. Deploy infrastructure only
cd infra
terraform init
terraform apply

# 2. Deploy Logic App workflows (after infrastructure is ready)
cd ..

# Deploy Entry Logic App workflow
az logic workflow update \
  --resource-group ShadowPivot \
  --name entry-agent-step \
  --definition @logic-apps/entry/workflow.json

# Deploy other Logic App workflows  
az logic workflow update \
  --resource-group ShadowPivot \
  --name design-gen-step \
  --definition @logic-apps/design-gen/workflow.json

az logic workflow update \
  --resource-group ShadowPivot \
  --name content-gen-step \
  --definition @logic-apps/content-gen/workflow.json

az logic workflow update \
  --resource-group ShadowPivot \
  --name review-step \
  --definition @logic-apps/review/workflow.json
```

### Workflow Dependencies

The deployment sequence is critical:
- **Step 1**: Infrastructure must be fully deployed first
- **Step 2**: Logic Apps (empty) are created by Terraform
- **Step 3**: Workflow definitions are deployed separately with proper connection parameters

This separation allows for:
- Independent workflow updates without infrastructure changes
- Better error isolation and debugging
- Cleaner CI/CD pipeline management

## 🔧 Configuration

The system is configured to use the existing `ShadowPivot` resource group in Azure. Update `terraform.tfvars` if you need to use a different resource group.

## 📝 Logic App Workflows

### Entry Agent Step
- **Trigger**: HTTP request
- **Actions**: 
  - Process incoming request
  - Queue message for design generation
  - Return response

## 🔄 AI Agent Flow

1. **Entry Point**: HTTP trigger receives user input
2. **Design Generation**: AI creates detailed specifications
3. **Content Creation**: AI generates content based on design
4. **Review & QA**: AI reviews and refines the output
5. **Final Storage**: Results are stored and made available

## 🚀 Quick Start

### Automated Deployment (Recommended)

1. **Fork this repository**
2. **Configure GitHub Secrets**:
   - `AZURE_CLIENT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`
3. **Push to main branch** - GitHub Actions will deploy everything automatically

### Manual Deployment

```bash
# Clone the repository
git clone <your-repo-url>
cd shadow-pivot-ai-agent

# Run the deployment script
./deploy.sh
```

## 🧪 Testing

After deployment, test the API using the provided test script:

```bash
# Update the LOGIC_APP_URL in test.sh with your deployed URL
./test.sh
```

Or test manually:

```bash
curl -X POST "https://your-logic-app-url" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a marketing plan for a new product",
    "userId": "test-user",
    "sessionId": "test-session"
  }'
```

## 📖 Documentation

- **[API Documentation](API_DOCS.md)** - Complete API reference and examples
- **[Environment Configuration](.env.example)** - Configuration template

## 🛠️ Development

To add new AI steps:

1. Create new Logic App workflow in `logic-apps/<step-name>/workflow.json`
2. Add corresponding queue in `infra/main.tf`
3. Update deployment workflow in `.github/workflows/deploy-logicapps.yml`

## 📊 Monitoring

- Monitor Logic App executions in Azure Portal
- Check Storage Queue messages for processing status
- Review GitHub Actions for deployment status
