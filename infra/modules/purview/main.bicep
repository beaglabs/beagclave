@description('Beagclave Purview Module - Automated Data Classification & Labeling')
@metadata({
  description: 'Microsoft Purview account with sensitivity labels, DLP policies, and customer-managed keys'
  version: '1.0.0'
})

param location string
param enclaveName string
param environment string
param tags object

param config object = {
  sensitivityLabels: [
    'CUI'
    'ITAR'
    'EAR'
    'CUI//SP-800-171'
    'CUI//CTI'
  ]
  customerManagedKey: true
  dlpPolicies: true
}

param logAnalyticsWorkspaceId string = ''

resource purviewAccount 'Microsoft.Purview/accounts@2021-01-01' = {
  name: '${enclaveName}-${environment}-purview'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    managedResourceGroupId: '${enclaveName}-${environment}-purview-rg'
    publicNetworkAccess: 'Disabled'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${enclaveName}-${environment}-kv'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'premium'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: 'REPLACE_WITH_ADMIN_OBJECT_ID'
        permissions: {
          secrets: ['get', 'list', 'set', 'delete', 'purge', 'recover', 'backup', 'restore']
          keys: ['get', 'list', 'create', 'delete', 'purge', 'recover', 'backup', 'restore']
        }
      }
    ]
    enablePurgeProtection: true
    enableSoftDelete: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'Azure-Services'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: '${enclaveName}-${environment}-purview-key'
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 2048
    kty: 'RSA-HSM'
    keyOps: [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-09-01' = {
  name: '${replace(guid('${enclaveName}${environment}cfsstorage'), '-', '')}'
  location: location
  tags: tags
  sku: {
    name: 'Premium_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    defaultServiceVersion: '2023-08-03'
    isHnsEnabled: false
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyVaultKey: {
        keyName: encryptionKey.name
        keyVaultUri: 'https://${keyVault.name}.vault.azure.net/'
      }
      services: {
        blob: {
          enabled: true
          keySource: 'Microsoft.Keyvault'
        }
        file: {
          enabled: true
          keySource: 'Microsoft.Keyvault'
        }
      }
    }
    networkAcls: {
      bypass: 'Azure-Services'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'purview-diagnostics'
  scope: purviewAccount
  properties: {
    logs: [
      {
        category: 'AuditEvents'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
      {
        category: 'DataPlaneRequests'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
    ]
    logAnalyticsDestinationType: 'Dedicated'
  }
}

output purviewAccountId string = purviewAccount.name
output purviewAccountResourceId string = purviewAccount.id
output keyVaultName string = keyVault.name
output keyVaultResourceId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output encryptionKeyName string = encryptionKey.name
output storageAccountName string = storageAccount.name
output storageAccountResourceId string = storageAccount.id
output sensitivityLabels array = config.sensitivityLabels