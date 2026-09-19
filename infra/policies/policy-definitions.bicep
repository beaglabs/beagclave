targetScope = 'subscription'

@description('Beagclave Policy Definitions - Subscription Level')
@metadata({
  description: 'Azure Policy definitions for export control, encryption, and compliance'
  version: '1.0.0'
})

param enclaveName string
param environment string
param location string = 'usgovvirginia'

@description('Definition name for ITAR export control')
var itarDefinitionName = '${enclaveName}-itar-export-control'

@description('Definition name for EAR export control')
var earDefinitionName = '${enclaveName}-ear-export-control'

@description('Definition name for encryption requirement')
var encryptionDefinitionName = '${enclaveName}-require-customer-managed-keys'

@description('Definition name for ephemeral disks requirement')
var ephemeralDiskDefinitionName = '${enclaveName}-require-ephemeral-disks'

@description('Definition name for purge protection')
var purgeProtectionDefinitionName = '${enclaveName}-require-purge-protection'

@description('Definition name for public network access')
var publicNetworkDefinitionName = '${enclaveName}-deny-public-network-access'

@description('Definition name for diagnostic settings')
var diagnosticSettingsDefinitionName = '${enclaveName}-force-diagnostic-logging'

resource itarPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: itarDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Deny ITAR data access for non-US persons'
    description: 'Blocks non-US persons from accessing ITAR-labeled data based on HR attribute'
    metadata: {
      category: 'Security Center'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs'
          }
          {
            field: 'tags["exportControlStatus"]'
            notEquals: 'us-person'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags["ITAR"]'
            exists: 'true'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource earPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: earDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Deny EAR data access for non-US persons'
    description: 'Blocks non-US persons from accessing EAR-labeled data based on HR attribute'
    metadata: {
      category: 'Security Center'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs'
          }
          {
            field: 'tags["exportControlStatus"]'
            notEquals: 'us-person'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags["EAR"]'
            exists: 'true'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource encryptionPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: encryptionDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Require customer-managed keys for storage encryption'
    description: 'All storage accounts must use customer-managed keys in Azure Key Vault'
    metadata: {
      category: 'Storage'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/encryption.keySource'
            notEquals: 'Microsoft.Keyvault'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource ephemeralDiskPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: ephemeralDiskDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Require ephemeral OS disks for compute'
    description: 'All virtual machines must use ephemeral OS disks'
    metadata: {
      category: 'Compute'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            field: 'Microsoft.Compute/virtualMachines/storageProfile.osDisk.osDiskType'
            notEquals: 'Ephemeral'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource purgeProtectionPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: purgeProtectionDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Require purge protection on Key Vaults'
    description: 'All Key Vaults must have purge protection enabled'
    metadata: {
      category: 'Key Vault'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.KeyVault/vaults'
          }
          {
            field: 'Microsoft.KeyVault/vaults/properties.enablePurgeProtection'
            notEquals: 'true'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource publicNetworkPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: publicNetworkDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Disable public network access for all services'
    description: 'All PaaS services must disable public network access'
    metadata: {
      category: 'Network'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            in: [
              'Microsoft.Storage/storageAccounts'
              'Microsoft.KeyVault/vaults'
              'Microsoft.DocumentDB/databaseAccounts'
              'Microsoft.Sql/servers'
            ]
          }
          {
            field: 'kind'
            equals: 'User'
          }
        ]
      }
      then: {
        effect: 'audit'
      }
    }
  }
}

resource diagnosticSettingsPolicy 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: diagnosticSettingsDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Beagclave: Send all diagnostics to Log Analytics'
    description: 'All resources must send diagnostic logs to the centralized Log Analytics workspace'
    metadata: {
      category: 'Monitoring'
      version: '1.0.0'
    }
    parameters: {
      logAnalyticsWorkspaceId: {
        type: 'string'
        metadata: {
          displayName: 'Log Analytics Workspace Resource ID'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            in: [
              'Microsoft.Compute/virtualMachines'
              'Microsoft.Storage/storageAccounts'
              'Microsoft.KeyVault/vaults'
              'Microsoft.ContainerService/managedClusters'
              'Microsoft.DesktopVirtualization/hostPools'
            ]
          }
          {
            count: {
              field: 'Microsoft.Insights/diagnosticSettings'
              where: 'exists'
            }
            equals: 0
          }
        ]
      }
      then: {
        effect: 'deployIfNotExists'
        details: {
          type: 'Microsoft.Insights/diagnosticSettings'
          existenceCondition: {
            field: 'Microsoft.Insights/diagnosticSettings/workspaceId'
            exists: 'true'
          }
          deployment: {
            properties: {
              mode: 'incremental'
              template: {
                resources: [
                  {
                    type: 'Microsoft.Insights/diagnosticSettings'
                    apiVersion: '2021-05-01-preview'
                    name: 'default'
                    properties: {
                      workspaceId: '[parameters(\'logAnalyticsWorkspaceId\')]'
                      logs: [
                        {
                          category: 'All'
                          enabled: true
                        }
                      ]
                      metrics: [
                        {
                          category: 'All'
                          enabled: true
                        }
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  }
}

output itarPolicyId string = itarPolicy.id
output earPolicyId string = earPolicy.id
output encryptionPolicyId string = encryptionPolicy.id
output ephemeralDiskPolicyId string = ephemeralDiskPolicy.id
output purgeProtectionPolicyId string = purgeProtectionPolicy.id
output publicNetworkPolicyId string = publicNetworkPolicy.id
output diagnosticSettingsPolicyId string = diagnosticSettingsPolicy.id
output policyIds array = [
  itarPolicy.id
  earPolicy.id
  encryptionPolicy.id
  ephemeralDiskPolicy.id
  purgeProtectionPolicy.id
  publicNetworkPolicy.id
  diagnosticSettingsPolicy.id
]