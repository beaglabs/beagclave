@description('Beagclave Sovereignty Module - ITAR/EAR Export Control Gates')
@metadata({
  description: 'Export control enforcement via Azure Policy assignments'
  version: '1.0.0'
})

param enclaveName string
param environment string

param config object = {
  hrAttributeName: 'exportControlStatus'
  itarDenyGroups: ['non-us-person']
  earDenyGroups: ['non-us-person']
}

param itarPolicyId string
param earPolicyId string

resource exportControlAssignmentITAR 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: '${enclaveName}-${environment}-itar-control'
  properties: {
    policyDefinitionId: itarPolicyId
    displayName: 'Beagclave ITAR Export Control Enforcement'
    description: 'Enforces ITAR export control restrictions on CUI data'
    enforcementMode: 'Default'
  }
}

resource exportControlAssignmentEAR 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: '${enclaveName}-${environment}-ear-control'
  properties: {
    policyDefinitionId: earPolicyId
    displayName: 'Beagclave EAR Export Control Enforcement'
    description: 'Enforces EAR export control restrictions on CUI data'
    enforcementMode: 'Default'
  }
}

output exportControlAssignmentITARId string = exportControlAssignmentITAR.id
output exportControlAssignmentEARId string = exportControlAssignmentEAR.id
output itarDenyGroups array = config.itarDenyGroups
output earDenyGroups array = config.earDenyGroups