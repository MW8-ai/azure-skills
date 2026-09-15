# Azure IaC Dual-Stack Lab: Terraform + Bicep

A portfolio-grade Azure infrastructure-as-code lab that implements the **same secure workload foundation twice**: once with Terraform and once with Bicep.

The project is intentionally small enough to deploy in a personal Azure subscription, but structured around enterprise concerns: naming, tagging, identity, least privilege, network boundaries, diagnostics, repeatable CI validation, and documented teardown.

## What this demonstrates

- Terraform with the HashiCorp AzureRM provider
- Azure Bicep modules and subscription-scope deployment
- GitHub Actions CI validation
- Microsoft Entra ID and user-assigned managed identity
- Azure RBAC with least-privilege data roles
- Service endpoints and default-deny PaaS network rules
- Key Vault using Azure RBAC authorization
- Storage with Shared Key disabled and OAuth preferred
- Log Analytics and Key Vault diagnostic settings
- Remote Terraform state bootstrap
- GitHub OIDC design for secretless Azure authentication

## Architecture

```text
Azure Subscription
|
+-- Resource Group (-tf or -bicep)
    |
    +-- Virtual Network 10.20.0.0/16
    |   +-- workload subnet 10.20.1.0/24
    |       +-- NSG association
    |       +-- Microsoft.Storage service endpoint
    |       +-- Microsoft.KeyVault service endpoint
    |
    +-- User-assigned Managed Identity
    |   +-- Storage Blob Data Contributor -> Storage Account
    |   +-- Key Vault Secrets User -> Key Vault
    |
    +-- Storage Account
    |   +-- TLS 1.2 minimum
    |   +-- public blob access disabled
    |   +-- Shared Key disabled
    |   +-- OAuth preferred
    |   +-- default-deny network rules
    |
    +-- Key Vault
    |   +-- Azure RBAC authorization
    |   +-- default-deny network ACLs
    |   +-- 7-day soft delete retention for lab cleanup
    |
    +-- Log Analytics Workspace
        +-- Key Vault AuditEvent + AllMetrics diagnostics
```

The Terraform and Bicep versions use different resource-group suffixes so both can be deployed side-by-side for comparison.

## Layout

```text
labs/azure-iac-dual-stack/
├── terraform/
│   ├── backend.tf
│   ├── locals.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
├── bicep/
│   ├── main.bicep
│   ├── dev.bicepparam
│   └── modules/
│       ├── identity-data.bicep
│       ├── network.bicep
│       └── observability.bicep
└── scripts/
    └── bootstrap-tfstate.sh

.github/workflows/
├── iac-lab-validate.yml
└── iac-lab-bicep-what-if.yml
```

## Prerequisites

- Azure subscription where you can create resource groups and role assignments
- Azure CLI authenticated with `az login`
- Terraform 1.14.x for the Terraform path
- Azure CLI with Bicep support for the Bicep path

## Terraform path

### 1. Bootstrap remote state

```bash
cd labs/azure-iac-dual-stack/scripts
chmod +x bootstrap-tfstate.sh
./bootstrap-tfstate.sh
```

The script creates a dedicated state resource group, Storage account, and blob container, then grants the signed-in Azure user `Storage Blob Data Contributor` so the backend can use Microsoft Entra authentication instead of Storage account keys.

Use the values printed by the script:

```bash
cd ../terraform
terraform init \
  -backend-config="resource_group_name=<state-rg>" \
  -backend-config="storage_account_name=<state-storage>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=azure-iac-dual-stack.tfstate" \
  -backend-config="use_azuread_auth=true"
```

### 2. Validate and plan

```bash
cp terraform.tfvars.example terraform.tfvars
terraform fmt -check -recursive
terraform validate
terraform plan
```

### 3. Deploy and tear down

```bash
terraform apply
terraform destroy
```

> Key Vault soft delete can preserve a deleted vault name temporarily. Purge protection is intentionally disabled for this disposable lab.

## Bicep path

Compile:

```bash
cd labs/azure-iac-dual-stack/bicep
az bicep build --file main.bicep
```

Preview:

```bash
az deployment sub what-if \
  --location eastus2 \
  --template-file main.bicep \
  --parameters dev.bicepparam
```

Deploy:

```bash
az deployment sub create \
  --name iaclab-bicep-dev \
  --location eastus2 \
  --template-file main.bicep \
  --parameters dev.bicepparam
```

Tear down:

```bash
az group delete --name rg-iaclab-dev-bicep --yes
```

## CI/CD

`iac-lab-validate.yml` runs on relevant pull requests and performs:

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- Bicep compilation through Azure CLI

No Azure credentials are required for those validation jobs.

`iac-lab-bicep-what-if.yml` is a **manual** authenticated workflow. It uses GitHub OIDC with `id-token: write` and `azure/login`, so Azure access can use short-lived federated tokens instead of a stored client secret. Configure an Azure federated credential and repository/environment variables named `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` before running it.

## Security decisions

| Decision | Rationale |
|---|---|
| Managed identity | Avoid application credentials in code or configuration. |
| Narrow data-plane roles | Identity gets blob data contribution and secret-read capability, not broad Owner/Contributor access. |
| Key Vault RBAC | Uses Azure RBAC instead of legacy vault access policies. |
| Storage Shared Key disabled | Moves workload access toward Microsoft Entra authorization. |
| Default-deny service rules | Limits Storage and Key Vault network access to the workload subnet plus the explicit Azure-services bypass. |
| Service endpoints | Demonstrates network-restricted PaaS access without the recurring cost/complexity of private endpoints in a small lab. |
| Diagnostics | Sends Key Vault audit events and metrics to Log Analytics. |
| OIDC | Avoids long-lived Azure client secrets in CI/CD. |
| Remote Terraform state | Demonstrates team-oriented state storage rather than committing state files. |

## Terraform vs. Bicep

**Terraform** provides explicit state, mature planning, and a consistent workflow that can extend across Azure, AWS, and GCP. That portability comes with responsibility for state and provider lifecycle management.

**Bicep** is Azure-native, maps directly to Azure Resource Manager, and does not require a separate state file. Azure `what-if` provides the native change preview. It is a strong fit when the workload is intentionally Azure-only.

The architecture decision should follow platform scope, team skills, governance, reuse requirements, lifecycle ownership, and whether multi-cloud portability is actually valuable rather than forcing one tool everywhere.

## Cost note

The lab avoids VMs, AKS, databases, private endpoints, and AI model deployments. Storage and Log Analytics can still produce small usage charges. Review Azure pricing before deployment and remove the resource groups when finished.

## Portfolio talking points

- Implemented the same Azure foundation in Terraform and Bicep to compare stateful provider-based IaC with Azure-native declarative IaC.
- Applied naming/tagging conventions, least-privilege managed identity, network restrictions, observability, and automated validation rather than treating IaC as only resource creation.
- Added a credential-free pull-request validation path and a documented GitHub OIDC path for authenticated Azure `what-if` workflows.
- Designed the lab to be cheap enough to deploy, inspect, destroy, and repeat instead of existing only as static sample code.
