#!/usr/bin/env bash
set -euo pipefail

LOCATION="${LOCATION:-eastus2}"
STATE_RG="${STATE_RG:-rg-iaclab-tfstate}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
SIGNED_IN_OBJECT_ID="$(az ad signed-in-user show --query id -o tsv)"
SUFFIX="$(printf '%s' "${SUBSCRIPTION_ID}-iaclab-tfstate" | sha256sum | cut -c1-8)"
STATE_STORAGE="${STATE_STORAGE:-stiaclabtf${SUFFIX}}"

printf 'Creating Terraform state resource group: %s\n' "$STATE_RG"
az group create \
  --name "$STATE_RG" \
  --location "$LOCATION" \
  --tags application=iaclab purpose=terraform-state managedBy=bootstrap >/dev/null

printf 'Creating Terraform state storage account: %s\n' "$STATE_STORAGE"
az storage account create \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true >/dev/null

STORAGE_ID="$(az storage account show --name "$STATE_STORAGE" --resource-group "$STATE_RG" --query id -o tsv)"

printf 'Granting signed-in user Storage Blob Data Contributor on the state account.\n'
az role assignment create \
  --assignee-object-id "$SIGNED_IN_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ID" >/dev/null

printf 'Creating state container using Microsoft Entra authentication.\n'
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STATE_STORAGE" \
  --auth-mode login >/dev/null

cat <<OUTPUT

Terraform backend created.

resource_group_name  = $STATE_RG
storage_account_name = $STATE_STORAGE
container_name       = $CONTAINER_NAME
key                  = azure-iac-dual-stack.tfstate
use_azuread_auth     = true

Next:
  cd ../terraform
  terraform init \\
    -backend-config="resource_group_name=$STATE_RG" \\
    -backend-config="storage_account_name=$STATE_STORAGE" \\
    -backend-config="container_name=$CONTAINER_NAME" \\
    -backend-config="key=azure-iac-dual-stack.tfstate" \\
    -backend-config="use_azuread_auth=true"
OUTPUT
