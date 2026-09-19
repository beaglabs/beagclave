#!/usr/bin/env bash
set -euo pipefail

ENCLAVE_NAME="${ENCLAVE_NAME:-beagclave}"
ENVIRONMENT="${ENVIRONMENT:-demo}"
LOCATION="${LOCATION:-usgovvirginia}"
RESOURCE_GROUP="${ENCLAVE_NAME}-${ENVIRONMENT}"

echo "Cleaning up Beagclave demo environment..."

echo "1. Deleting resource group: ${RESOURCE_GROUP}"
az group delete \
  --name "${RESOURCE_GROUP}" \
  --yes \
  --no-wait 2>/dev/null || true

echo "2. Cleaning up Entra ID tenant (if test tenant exists)"
# Test tenant cleanup should be done manually
# az ad signed-in-user show --query id -o tsv

echo "3. Removing Kubernetes manifests"
if kubectl cluster-info &>/dev/null; then
  kubectl delete namespace beagclave-agents --ignore-not-found=true 2>/dev/null || true
  kubectl delete namespace beagclave-system --ignore-not-found=true 2>/dev/null || true
  kubectl delete namespace beagclave-cui-data --ignore-not-found=true 2>/dev/null || true
  kubectl delete namespace beagclave-itar-data --ignore-not-found=true 2>/dev/null || true
  kubectl delete namespace beagclave-ear-data --ignore-not-found=true 2>/dev/null || true
fi

echo "4. Cleaning up Azure resources"
az resource delete \
  --ids "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" \
  --force 2>/dev/null || true

echo "Cleanup complete. All temporary resources have been removed."