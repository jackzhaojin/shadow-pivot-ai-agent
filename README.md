# Shadow Pivot AI Agent

This project implements an Azure-based AI agent system using Terraform for infrastructure provisioning and GitHub Actions for automated deployment of Logic Apps.

## 🏗️ Architecture

The system uses:
- **Terraform** for infrastructure as code (Storage Account, Queues)
- **Azure Logic Apps** for workflow orchestration
- **GitHub Actions** for CI/CD automation
- **Azure Storage Queues** for message passing between AI steps

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

### Deployment Process

1. **Infrastructure Deployment**: Push to `main` branch triggers Terraform to provision:
   - Storage Account (`shdwagentstorage`)
   - Storage Queue (`design-gen-q`)

2. **Logic App Deployment**: Deploys workflow definitions using Azure CLI

### Manual Deployment

```bash
# Deploy infrastructure
cd infra
terraform init
terraform apply

# Deploy Logic Apps
az logic workflow create \
  --resource-group ShadowPivot \
  --name entry-agent-step \
  --definition @logic-apps/entry/workflow.json \
  --location eastus
```

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
