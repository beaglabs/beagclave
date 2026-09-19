#!/usr/bin/env bash
set -euo pipefail

ENCLAVE_NAME="${ENCLAVE_NAME:-beagclave}"
LOCATION="${LOCATION:-usgovvirginia}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
RESOURCE_GROUP="${ENCLAVE_NAME}-${ENVIRONMENT}"
PARAM_FILE="${PARAM_FILE:-infra/parameters/gov.parameters.json}"

echo "Provisioning Beagclave enclave: ${ENCLAVE_NAME} in ${LOCATION} (${ENVIRONMENT})"

if [ "${SKIP_RG:-false}" != "true" ]; then
  echo "Creating resource group: ${RESOURCE_GROUP}"
  az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --tags project="${ENCLAVE_NAME}" environment="${ENVIRONMENT}"
fi

echo "Deploying main.bicep..."
az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "infra/main.bicep" \
  --parameters "@${PARAM_FILE}" \
  --query "properties.outputs" \
  --output json

echo "Provisioning complete. Outputs:"
az deployment group show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "main" \
  --query "properties.outputs" \
  --output table

AKS_CLUSTER=$(az aks list \
  --resource-group "${RESOURCE_GROUP}" \
  --query "[0].name" \
  --output tsv 2>/dev/null || echo "")

if [ -n "${AKS_CLUSTER}" ]; then
  echo "Fetching AKS credentials..."
  az aks get-credentials \
    --name "${AKS_CLUSTER}" \
    --resource-group "${RESOURCE_GROUP}" \
    --admin-group-id "$(az ad signed-in-user show --query id -o tsv)" \
    --overwrite-existing
fi

echo "Deploying Kubernetes manifests..."
if [ -d "kubernetes" ]; then
  for dir in $(find kubernetes -type d -mindepth 1 -maxdepth 1 | sort); do
    echo "Applying manifests from ${dir}..."
    kubectl apply -f "${dir}/" 2>&1 || true
  done
fi

echo "Beagclave enclave provisioning complete."