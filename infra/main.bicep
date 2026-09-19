@description('Beagclave Enclave - Main Orchestrator')
@metadata({
  description: 'Deploys the complete Beagclave CUI/ITAR enclave with AVD, Kubernetes, Purview, and Sentinel'
  version: '1.0.0'
  publisher: 'Beag Labs'
})

param location string = 'usgovvirginia'
param enclaveName string = 'beagclave'
param environment string = 'prod'
param tags object = {
  project: 'beagclave'
  environment: environment
  compliance: 'nist-800-171'
  dataClassification: 'CUI'
}

param identityConfig object = {
  tenantType: 'gcc-high'
  customDomain: 'cui.company.com'
  upnSuffix: 'cui.company.com'
  mfaMethods: [
    'fido2'
    'piv'
    'phishing-resistant'
  ]
}

param avdConfig object = {
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

param aksConfig object = {
  kubernetesVersion: '1.28'
  nodePoolSku: 'Standard_D4s_v5'
  nodeCount: 3
  networkPlugin: 'azure'
  networkPolicy: 'calico'
}

param purviewConfig object = {
  accountName: '${enclaveName}-purview'
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

param sovereigntyConfig object = {
  hrAttributeName: 'exportControlStatus'
  itarDenyGroups: ['non-us-person']
  earDenyGroups: ['non-us-person']
}

param loggingConfig object = {
  workspaceName: '${enclaveName}-logs'
  sentinelWorkspaceName: '${enclaveName}-sentinel'
  retentionDays: 365
  nistControls: [
    'AU-2'
    'AU-3'
    'AU-6'
    'AU-12'
    'SI-4'
  ]
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: '${enclaveName}-${environment}-logs'
  location: location
  tags: tags
  properties: {
    retentionInDays: loggingConfig.retentionDays
    sku: {
      name: 'PerGB2018'
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      searchCategory: 'Enabled'
    }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

module policies 'policies/policy-definitions.bicep' = {
  name: 'policy-definitions-deployment'
  params: {
    enclaveName: enclaveName
    environment: environment
    location: location
  }
  scope: subscription()
}

module identity 'modules/identity/main.bicep' = {
  name: 'identity-deployment'
  params: {
    location: location
    enclaveName: enclaveName
    environment: environment
    tags: tags
    config: identityConfig
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

module avd 'modules/avd/main.bicep' = {
  name: 'avd-deployment'
  dependsOn: [identity, policies]
  params: {
    location: location
    enclaveName: enclaveName
    environment: environment
    tags: tags
    config: avdConfig
    identityRbacRoles: identity.outputs.rbacRoleIds
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

module aks 'modules/aks/main.bicep' = {
  name: 'aks-deployment'
  dependsOn: [identity, policies]
  params: {
    location: location
    enclaveName: enclaveName
    environment: environment
    tags: tags
    config: aksConfig
    identityRbacRoles: identity.outputs.rbacRoleIds
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

module purview 'modules/purview/main.bicep' = {
  name: 'purview-deployment'
  dependsOn: [identity, policies]
  params: {
    location: location
    enclaveName: enclaveName
    environment: environment
    tags: tags
    config: purviewConfig
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

module sovereignty 'modules/sovereignty/main.bicep' = {
  name: 'sovereignty-deployment'
  dependsOn: [identity, purview, aks, policies]
  params: {
    enclaveName: enclaveName
    environment: environment
    config: sovereigntyConfig
    itarPolicyId: policies.outputs.itarPolicyId
    earPolicyId: policies.outputs.earPolicyId
  }
}

module logging 'modules/logging/main.bicep' = {
  name: 'logging-deployment'
  dependsOn: [identity, avd, aks, purview, sovereignty]
  params: {
    location: location
    enclaveName: enclaveName
    environment: environment
    tags: tags
    config: loggingConfig
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

output identityOutputs object = identity.outputs
output avdOutputs object = avd.outputs
output aksOutputs object = aks.outputs
output purviewOutputs object = purview.outputs
output sovereigntyOutputs object = sovereignty.outputs
output loggingOutputs object = logging.outputs
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id