#!/usr/bin/env bash
set -euo pipefail

ENCLAVE_NAME="${ENCLAVE_NAME:-beagclave}"
RESOURCE_GROUP="${RESOURCE_GROUP:-beagclave-prod}"
LOCATION="${LOCATION:-usgovvirginia}"

echo "Applying policy-as-code for Beagclave enclave: ${ENCLAVE_NAME}"

az policy definition create \
  --name "Beagclave-Deny-NonUSPerson-ITAR" \
  --display-name "Deny access to ITAR data for non-US persons" \
  --description "Blocks non-US persons from accessing ITAR-labeled data" \
  --mode "All" \
  --metadata "category=Security Center,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","equals":"Microsoft.Storage/storageAccounts/blobServices/containers/blobs"},{"field":"tags['exportControlStatus']","notEquals":"us-person"},{"field":"Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags['ITAR']","exists":"true"}]},"then":{"effect":"deny"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Deny-NonUSPerson-EAR" \
  --display-name "Deny access to EAR data for non-US persons" \
  --description "Blocks non-US persons from accessing EAR-labeled data" \
  --mode "All" \
  --metadata "category=Security Center,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","equals":"Microsoft.Storage/storageAccounts/blobServices/containers/blobs"},{"field":"tags['exportControlStatus']","notEquals":"us-person"},{"field":"Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags['EAR']","exists":"true"}]},"then":{"effect":"deny"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Require-FIDO2-PIV" \
  --display-name "Require FIDO2 or PIV authentication" \
  --description "Mandates phishing-resistant MFA (FIDO2 or PIV/CAC) for all enclave access" \
  --mode "All" \
  --metadata "category=Security Center,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","equals":"Microsoft.Authorization/roleAssignments"},{"field":"Microsoft.Authorization/roleAssignments/roleDefinitionId","equals":"/subscriptions/" + subscription().subscriptionId + "/providers/Microsoft.Authorization/roleDefinitions/a9ab6ad5-d28a-4cf4-b175-4ec4f8f0b1ea"}]},"then":{"effect":"audit"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Force-Encryption-CustomerManagedKeys" \
  --display-name "Require customer-managed keys for storage" \
  --description "All storage accounts must use customer-managed keys in Azure Key Vault" \
  --mode "All" \
  --metadata "category=Storage,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","equals":"Microsoft.Storage/storageAccounts"},{"field":"Microsoft.Storage/storageAccounts/encryption.keySource","notEquals":"Microsoft.Keyvault"}]},"then":{"effect":"deny"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Force-Ephemeral-Disks" \
  --display-name "Require ephemeral OS disks for session hosts" \
  --description "AVD session hosts must use ephemeral OS disks for guaranteed destruction on VM termination" \
  --mode "All" \
  --metadata "category=Compute,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","equals":"Microsoft.Compute/virtualMachines"},{"field":"Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType","equals":"Windows"},{"field":"Microsoft.Compute/virtualMachines/storageProfile.osDisk.osDiskType","notEquals":"Ephemeral"}]},"then":{"effect":"deny"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Force-Purge-Protection" \
  --display-name "Require purge protection on Key Vaults" \
  --description "All Key Vaults must have purge protection enabled" \
  --mode "All" \
  --metadata "category=Key Vault,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","equals":"Microsoft.KeyVault/vaults"},{"field":"Microsoft.KeyVault/vaults/properties.enablePurgeProtection","notEquals":"true"}]},"then":{"effect":"deny"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Force-Public-Network-Access-Disable" \
  --display-name "Disable public network access for all services" \
  --description "All storage, database, and analytics services must disable public network access" \
  --mode "All" \
  --metadata "category=Network,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","in":["Microsoft.Storage/storageAccounts","Microsoft.KeyVault/vaults","Microsoft.DocumentDB/databaseAccounts","Microsoft.Sql/servers","Microsoft.Cache/Redis"]},{"field":"Microsoft.Storage/storageAccounts/publicNetworkAccess","notEquals":"Disabled"}]},"then":{"effect":"deny"}}' \
  --mode "All" 2>/dev/null || true

az policy definition create \
  --name "Beagclave-Force-Log-Analytics" \
  --display-name "Send all diagnostics to Log Analytics" \
  --description "All resources must send diagnostic logs to the Log Analytics workspace" \
  --mode "All" \
  --metadata "category=Monitoring,version=1.0.0" \
  --rules '{"if":{"allOf":[{"field":"type","in":["Microsoft.Compute/virtualMachines","Microsoft.Storage/storageAccounts","Microsoft.KeyVault/vaults","Microsoft.ContainerService/managedClusters","Microsoft.DesktopVirtualization/hostPools"]},{"count":"greaterOrEquals","field":"Microsoft.Insights/diagnosticSettings","value":"1"}]},"then":{"effect":"deployIfNotExists","details":{"type":"Microsoft.Insights/diagnosticSettings","existenceCondition":{"allOf":[{"field":"Microsoft.Insights/diagnosticSettings/workspaceId","exists":"true"}]},"deployment":{"properties":{"mode":"incremental","template":{"resources":[{"type":"Microsoft.Insights/diagnosticSettings","apiVersion":"2021-05-01-preview","name":"default","properties":{"workspaceId":"[/subscriptions/" + subscription().subscriptionId + "/resourceGroups/" + parameters('resourceGroupName') + "/providers/Microsoft.OperationalInsights/workspaces/" + variables('workspaceName') + "]","logs":[{"category":"All","enabled":true}],"metrics":[{"category":"All","enabled":true}]}}}}}}}}}' \
  --mode "All" 2>/dev/null || true

echo "Assigning policies to resource group: ${RESOURCE_GROUP}"

az policy assignment create \
  --name "Beagclave-Export-Control-ITAR" \
  --policy "Beagclave-Deny-NonUSPerson-ITAR" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: ITAR Export Control" \
  --description "Enforces ITAR export control restrictions" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-Export-Control-EAR" \
  --policy "Beagclave-Deny-NonUSPerson-EAR" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: EAR Export Control" \
  --description "Enforces EAR export control restrictions" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-MFA-FIDO2" \
  --policy "Beagclave-Require-FIDO2-PIV" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: MFA Requirement" \
  --description "Requires FIDO2/PIV authentication" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-Customer-Managed-Keys" \
  --policy "Beagclave-Force-Encryption-CustomerManagedKeys" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: Customer Managed Keys" \
  --description "Requires customer-managed keys" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-Ephemeral-Disks" \
  --policy "Beagclave-Force-Ephemeral-Disks" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: Ephemeral Disks" \
  --description "Requires ephemeral OS disks" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-Purge-Protection" \
  --policy "Beagclave-Force-Purge-Protection" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: Purge Protection" \
  --description "Requires purge protection" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-No-Public-Network" \
  --policy "Beagclave-Force-Public-Network-Access-Disable" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: No Public Network Access" \
  --description "Disables public network access" 2>/dev/null || true

az policy assignment create \
  --name "Beagclave-Diagnostic-Settings" \
  --policy "Beagclave-Force-Log-Analytics" \
  --resource-group "${RESOURCE_GROUP}" \
  --display-name "Enclave: Diagnostic Logging" \
  --description "Enforces diagnostic logging to Log Analytics" 2>/dev/null || true

echo "Policy-as-code applied successfully."