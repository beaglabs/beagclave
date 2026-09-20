@description('Beagclave AVD Module - Ephemeral Virtual Desktop Infrastructure')
@metadata({
  description: 'Azure Virtual Desktop host pool with golden image and forced session host deletion'
  version: '1.0.0'
})

param location string
param enclaveName string
param environment string
param tags object
param config object = {
  hostPoolType: 'pooled'
  loadBalancerType: 'depth-first'
  maxSessionLimit: 1
  goldenImage: {
    source: 'gallery'
    galleryName: 'beagclave-gallery'
    imageDefinition: 'windows-11-hardened'
    version: 'latest'
  }
  sessionHostSku: 'Standard_D4s_v5'
  autoScale: true
  forceDeleteOnLogoff: true
}

param identityRbacRoles array

param logAnalyticsWorkspaceId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${enclaveName}-${environment}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'avd-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-03-05' = {
  name: '${enclaveName}-${environment}-workspace'
  location: location
  tags: tags
  properties: {
    friendlyName: 'Beagclave AVD Workspace'
    description: 'Workspace for ephemeral CUI enclave desktops'
    publicNetworkAccess: 'Disabled'
  }
}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-03-05' = {
  name: '${enclaveName}-${environment}-pool'
  location: location
  tags: tags
  properties: {
    friendlyName: 'Beagclave Ephemeral Host Pool'
    description: 'Pooled host pool with depth-first load balancing, max 1 session per host'
    customRdpProperty: 'audiocapturemode:i:0;audiomode:i:2;connectiontype:i:1;redirectcomports:i:0;redirectprinters:i:0;redirectsmartcards:i:0;redirectclipboard:i:0;screensharemode:i:1;screenmode:i:2;'
    isPersonalDesktop: false
    type: config.hostPoolType
    validationEnvironment: false
    registrationInfo: {
      expirationDate: '2025-12-31T23:59:59Z'
      registrationTokenOperation: 'Update'
    }
    agentUpdate: {
      type: 'Default'
      defaultActiveMaintenanceWindowStart: '01:00'
      defaultActiveMaintenanceWindowEnd: '05:00'
    }
    agentVerification: true
  }
}

resource desktopAppGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-03-05' = {
  name: '${enclaveName}-${environment}-desktop'
  location: location
  tags: tags
  properties: {
    type: 'Desktop'
    friendlyName: 'Desktop Access'
    description: 'Desktop application group for CUI enclave'
    hostPoolArmPath: hostPool.id
  }
}

resource remoteAppGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-03-05' = {
  name: '${enclaveName}-${environment}-apps'
  location: location
  tags: tags
  properties: {
    type: 'RemoteApp'
    friendlyName: 'Enclave Applications'
    description: 'Remote applications for agents and auditors'
    hostPoolArmPath: hostPool.id
  }
}

resource gallery 'Microsoft.Compute/galleries@2023-07-02' = {
  name: '${replace(enclaveName, '-', '')}${environment}gallery'
  location: location
  tags: tags
  properties: {
    description: 'Golden image gallery for Beagclave AVD session hosts'
  }
}

resource imageDefinition 'Microsoft.Compute/galleries/images@2023-07-02' = {
  name: '${gallery.name}/${config.goldenImage.imageDefinition}'
  location: location
  tags: tags
  properties: {
    supportedLocations: [location]
    osType: 'Windows'
    osState: 'Generalized'
    hypervisorSupported: 'AVSet'
    features: {
      securityType: 'TrustedLaunch'
      fipsEnabled: true
    }
    architecture: 'x64'
    author: 'Beag Labs'
    offer: 'beagclave-windows'
    sku: 'cui-hardened-fips'
    description: 'Hardened Windows 11 FIPS-enabled image with CIS, STIG, and Purview agent pre-installed'
    disallowed: {
      installations: ['None']
    }
    hyperVGeneration: 'V2'
    recommended: {
      memory: {
        min: 4
        max: 64
      }
      vCPU: {
        min: 2
        max: 32
      }
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-09-01' = {
  name: '${replace(guid('${enclaveName}${environment}storage'), '-', '')}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowCrossRegionReplication: false
    supportsHttpsTrafficOnly: true
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyVaultKey: {
        keyName: '${enclaveName}-${environment}-avd-key'
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

resource sessionHostVMSS 'Microsoft.Compute/virtualMachineScaleSets@2023-09-02' = {
  name: '${enclaveName}-${environment}-hosts'
  location: location
  tags: union(tags, { purpose: 'session-host' })
  sku: {
    name: config.sessionHostSku
    tier: 'Standard'
    capacity: 2
  }
  properties: {
    zoneBalance: false
    priority: 'Regular'
    evictionPolicy: 'Deallocate'
    singlePlacementGroup: false
    platformFaultDomainCount: 2
    additionalCapabilities: {
      ultraSSDEnabled: true
      hibernationEnabled: false
    }
    overprovision: false
    automaticRepairs: {
      enabled: true
      gracePeriod: 'PT30M'
    }
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: imageDefinition.id
        }
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
            securityType: 'TrustedLaunch'
          }
          diffDiskSettings: {
            option: 'Local'
          }
        }
      }
      osProfile: {
        computerNamePrefix: '${enclaveName}-sh'
        adminUsername: '${enclaveName}admin'
        adminPassword: 'PLACEHOLDER_REPLACE_WITH_SECURE_PASSWORD'
        windowsConfiguration: {
          enableAutomaticUpdates: false
          provisionVMAgent: true
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'AVD-Agent'
            properties: {
              publisher: 'Microsoft.Azure.VirtualDesktop'
              type: 'OctaviusPSAgent'
              typeHandlerVersion: '3.2'
              autoUpgradeMinorVersion: true
            }
          }
        ]
      }
      priority: 'Regular'
      evictionPolicy: 'Deallocate'
      billingProfile: {
        maxPrice: -1
      }
    }
    networkProfile: {
      name: 'sessionhost-nic'
      primary: true
    }
  }
  dependsOn: [hostPool]
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'avd-diagnostics'
  scope: hostPool
  properties: {
    logs: [
      {
        category: 'HostPoolLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
      {
        category: 'HostPoolErrorLogs'
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

output hostPoolName string = hostPool.name
output hostPoolId string = hostPool.id
output workspaceName string = workspace.name
output workspaceId string = workspace.id
output sessionHostVMSSName string = sessionHostVMSS.name
output sessionHostVMSSID string = sessionHostVMSS.id
output galleryName string = gallery.name
output imageDefinitionName string = imageDefinition.name
output vnetId string = vnet.id
output subnetId string = '${vnet.id}/subnets/avd-subnet'