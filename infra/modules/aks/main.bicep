@description('Beagclave AKS Module - Secure Kubernetes Runtime for Agent Workloads')
@metadata({
  description: 'Hardened AKS cluster with Calico network policies and private endpoints'
  version: '1.0.0'
})

param location string
param enclaveName string
param environment string
param tags object

param config object = {
  kubernetesVersion: '1.28'
  nodePoolSku: 'Standard_D4s_v5'
  nodeCount: 3
  networkPlugin: 'azure'
  networkPolicy: 'calico'
}

param identityRbacRoles array = []

param logAnalyticsWorkspaceId string = ''

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${enclaveName}-${environment}-aks-mi'
  location: location
  tags: tags
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${enclaveName}-${environment}-aks-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aks-systempool'
        properties: {
          addressPrefix: '10.1.0.0/22'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'aks-nodepool'
        properties: {
          addressPrefix: '10.1.4.0/22'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-06-01' = {
  name: '${enclaveName}-${environment}-aks'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksIdentity.id}': {}
    }
  }
  properties: {
    kubernetesVersion: config.kubernetesVersion
    dnsPrefix: '${enclaveName}-${environment}'
    enableRBAC: true
    apiServerProfile: {
      enablePrivateCluster: true
      enablePrivateClusterPublicFqdn: false
      enableAuthorizedIpRanges: true
      authorizedIpRanges: []
      httpPort: 443
      httpsPort: 443
      oauth2Proxy: {}
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 3
        vmSize: 'Standard_D4s_v5'
        osType: 'Linux'
        type: 'AvailabilitySet'
        mode: 'System'
        maxPods: 30
        enableAutoScaling: true
        minCount: 3
        maxCount: 10
        osDiskType: 'Ephemeral'
        vnetSubnetID: '${vnet.id}/subnets/aks-systempool'
        servicePrincipalProfile: {
          clientId: 'MSICreated'
          secret: 'MSICreated'
        }
      }
      {
        name: 'agentpool'
        count: config.nodeCount
        vmSize: config.nodePoolSku
        osType: 'Linux'
        type: 'AvailabilitySet'
        mode: 'User'
        maxPods: 50
        enableAutoScaling: true
        minCount: 3
        maxCount: 20
        osDiskType: 'Ephemeral'
        vnetSubnetID: '${vnet.id}/subnets/aks-nodepool'
        servicePrincipalProfile: {
          clientId: 'MSICreated'
          secret: 'MSICreated'
        }
      }
    ]
    identityProfile: {
      kubeletconfiguration: {
        enabled: true
        clientId: aksIdentity.properties.clientId
        objectId: aksIdentity.properties.principalId
        resourceId: aksIdentity.id
      }
    }
    networkProfile: {
      networkPlugin: config.networkPlugin
      networkPluginMode: 'overlay'
      networkPolicy: config.networkPolicy
      dnsServiceIp: '10.2.0.10'
      dockerBridgeCidr: '10.245.0.1/24'
      outboundType: 'loadBalancer'
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.2.0.0/24'
      ipVersions: 'IPv4'
      loadBalancerSku: 'Standard'
      enableMultipleStandardLoadBalancers: false
    }
    oidcIssuerProfile: {
      enabled: true
      managed: true
    }
    addonProfiles: {
      omsagent: {
        enabled: true
      }
    }
    autoScalerProfile: {
      balanceSimilarNodeGroups: 'true'
      expander: 'least-waste'
      maxEmptyBulkDelete: 10
      maxGracefulTerminationSeconds: 60
      maxNodeProvisionTime: '15m'
      maxUnneeded: 5
      maxUnready: 3
      maxUnreadyPercentage: 45
      scaleDownUnneededTime: '10m'
      scaleDownUnreadyTime: '20m'
      scaleDownUnreadyPercentage: 50
      skipNodesWithSystemPods: 'true'
      skipNodesWithLocalStorage: 'true'
      utilization: 50
    }
    podIdentityProfile: {
      enabled: true
      allowNetworkPluginConfidentialClient: false
      userAssignedIdentities: [
        {
          name: 'beagclave-agent-identity'
          objectId: aksIdentity.properties.principalId
          resourceId: aksIdentity.id
          bindingSelect: 'podIdentity'
        }
      ]
    }
    securityProfile: {
      enableAzureKeyVaultSecretsProvider: true
      enableAzurePolicy: true
      azureKeyVaultSecretsProvider: {
        enableCSIDriver: true
      }
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'aks-diagnostics'
  scope: aks
  properties: {
    logs: [
      {
        category: 'kube-audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
      {
        category: 'kube-audit-admin'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
      {
        category: 'kube-controller-manager'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
      {
        category: 'kube-scheduler'
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

output aksClusterName string = aks.name
output aksClusterId string = aks.id
output aksFQDN string = aks.properties.fqdn
output aksManagedIdentityClientId string = aksIdentity.properties.clientId
output aksManagedIdentityObjectId string = aksIdentity.properties.principalId
output nodeResourceGroup string = 'MC_${resourceGroup().name}_${aks.name}_${location}'
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL
output vnetId string = vnet.id