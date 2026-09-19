@description('Beagclave Identity Module - Decoupled Identity & Access')
@metadata({
  description: 'Isolated Entra ID tenant with custom domain UPNs, FIDO2/PIM MFA, and NIST-mapped RBAC profiles'
  version: '1.0.0'
})

param location string
param enclaveName string
param environment string
param tags object
param config object = {
  tenantType: 'gcc-high'
  customDomain: 'cui.company.com'
  upnSuffix: 'cui.company.com'
  mfaMethods: [
    'fido2'
    'piv'
    'phishing-resistant'
  ]
}

param logAnalyticsWorkspaceId string = ''

var roleDefinitions = [
  {
    name: '${enclaveName}-${environment}-engineer'
    description: 'Engineer role mapped to NIST 800-171 AC, IA, CM, SI families'
    permissions: [
      'Microsoft.Compute/virtualMachines/read'
      'Microsoft.Compute/virtualMachines/start/action'
      'Microsoft.Compute/virtualMachines/restart/action'
      'Microsoft.Storage/storageAccounts/read'
      'Microsoft.ContainerService/managedClusters/read'
      'Microsoft.Insights/metrics/read'
      'Microsoft.Insights/diagnosticSettings/read'
    ]
  }
  {
    name: '${enclaveName}-${environment}-projectmanager'
    description: 'Project Manager role mapped to NIST 800-171 AT, PM, RA families'
    permissions: [
      'Microsoft.Resources/deployments/read'
      'Microsoft.Resources/subscriptions/resourceGroups/read'
      'Microsoft.Authorization/roleAssignments/read'
      'Microsoft.Insights/metrics/read'
      'Microsoft.Insights/diagnosticSettings/read'
    ]
  }
  {
    name: '${enclaveName}-${environment}-auditor'
    description: 'Auditor role mapped to NIST 800-171 AU, CA, RA families - read-only'
    permissions: [
      'Microsoft.Insights/metrics/read'
      'Microsoft.Insights/diagnosticSettings/read'
      'Microsoft.Insights/logDefinitions/read'
      'Microsoft.Security/assessments/read'
      'Microsoft.PolicyInsights/policyStates/read'
      'Microsoft.Resources/deployments/read'
    ]
  }
  {
    name: '${enclaveName}-${environment}-agentrunner'
    description: 'Agent runtime identity - least privilege for autonomous agents'
    permissions: [
      'Microsoft.ContainerService/managedClusters/read'
      'Microsoft.Storage/storageAccounts/read'
      'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
      'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write'
      'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete'
    ]
  }
]

resource rbacRoles 'Microsoft.Authorization/roleDefinitions@2022-04-01' = [for role in roleDefinitions: {
  name: guid(role.name)
  properties: {
    roleName: role.name
    description: role.description
    type: 'CustomRole'
    permissions: [
      {
        actions: role.permissions
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      resourceGroup()
    ]
  }
}]

output customDomain string = config.customDomain
output upnSuffix string = config.upnSuffix
output rbacRoleIds array = [for i in range(0, length(roleDefinitions)): '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Authorization/roleDefinitions/${guid(roleDefinitions[i].name)}']
output tenantAdminObjectId string = 'REPLACE_WITH_TENANT_ADMIN_OBJECT_ID'