# Shadow Pivot AI Agent: Infrastructure and Logic App Setup

This project uses **Terraform** to provision infrastructure for an Azure-based AI agent system. The repo also deploys Logic App JSON workflows stored outside of Terraform.

## 🔧 Scope Overview

* Reuse existing Azure resource group: `ShadowPivot`
* Use Terraform to manage:

  * Storage Account (for blobs + queues)
  * Queues for each AI step
* Deploy Logic Apps using GitHub Actions (via `az logic workflow create`)
* Store Logic App workflow JSON files in `/logic-apps/<step>/workflow.json`
* Maintain **two separate GitHub Actions**:

  * `deploy-infra.yml` → Terraform apply
  * `deploy-logicapps.yml` → Logic App deployments

## 📁 Project Structure

```
shadow-pivot-ai-agent/
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── logic-apps/
│   └── entry/
│       └── workflow.json
├── .github/
│   └── workflows/
│       ├── deploy-infra.yml
│       └── deploy-logicapps.yml
└── README.md
```

---

## 🌍 Terraform Setup

### infra/main.tf

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "main" {
  name                     = "shdwagentstorage"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_queue" "design_gen_q" {
  name                 = "design-gen-q"
  storage_account_name = azurerm_storage_account.main.name
}
```

### infra/variables.tf

```hcl
variable "resource_group_name" {
  description = "The name of the existing Azure resource group"
  type        = string
}
```

### infra/terraform.tfvars

```hcl
resource_group_name = "ShadowPivot"
```

---

## 🪄 GitHub Actions Workflows

### .github/workflows/deploy-infra.yml

```yaml
name: Deploy Infra

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform -chdir=infra init

      - name: Terraform Apply
        run: terraform -chdir=infra apply -auto-approve
```

### .github/workflows/deploy-logicapps.yml

```yaml
name: Deploy Logic Apps

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

env:
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  RESOURCE_GROUP: ShadowPivot
  LOCATION: eastus

jobs:
  deploy-logicapp:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ env.AZURE_CLIENT_ID }}
          tenant-id: ${{ env.AZURE_TENANT_ID }}
          subscription-id: ${{ env.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Logic App (entry)
        run: |
          az logic workflow create \
            --resource-group $RESOURCE_GROUP \
            --name entry-agent-step \
            --definition @logic-apps/entry/workflow.json \
            --location $LOCATION
```

---

## ✅ Action Instructions

* Commit all the above files.
* Push to `main` to trigger GitHub Actions.
* Terraform will apply infra using the `ShadowPivot` resource group.
* Logic App will be deployed using the JSON file under `logic-apps/entry/`.

```
```
