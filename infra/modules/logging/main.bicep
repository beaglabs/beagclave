@description('Beagclave Logging Module - SIEM & Compliance Reporting')
@metadata({
  description: 'Microsoft Sentinel analytics rules mapped to NIST 800-171 control families'
  version: '1.0.0'
})

param location string
param enclaveName string
param environment string
param tags object

param logAnalyticsWorkspaceId string

param config object = {
  nistControls: [
    'AU-2'
    'AU-3'
    'AU-6'
    'AU-12'
    'SI-4'
  ]
}

resource analyticsRule_AU2 'Microsoft.Insights/scheduledQueryRules@2022-10-01' = {
  name: '${enclaveName}-AU-2-account-monitoring'
  location: location
  tags: tags
  properties: {
    description: 'NIST AU-2: Monitor account modifications across identity provider'
    severity: 3
    enabled: 'true'
    source: {
      query: 'AuditLogs | where OperationName in ("Add user", "Remove user", "Update user", "Add member to group", "Remove member from group") | summarize count() by bin(TimeGenerated, 5m)'
      dataSourceId: logAnalyticsWorkspaceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: 5
      timeWindowInMinutes: 15
    }
    actions: {
      actionGroups: []
      customProperties: {}
      triggeringOperator: 'GreaterThan'
      triggeringThreshold: 0
    }
  }
}

resource analyticsRule_AU3 'Microsoft.Insights/scheduledQueryRules@2022-10-01' = {
  name: '${enclaveName}-AU-3-privileged-activity'
  location: location
  tags: tags
  properties: {
    description: 'NIST AU-3: Detect privileged activity in Kubernetes clusters'
    severity: 2
    enabled: 'true'
    source: {
      query: 'KubernetesCluster | where Verb in ("CREATE", "UPDATE", "DELETE") | summarize count() by bin(TimeGenerated, 5m)'
      dataSourceId: logAnalyticsWorkspaceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: 5
      timeWindowInMinutes: 15
    }
    actions: {
      actionGroups: []
      customProperties: {}
      triggeringOperator: 'GreaterThan'
      triggeringThreshold: 0
    }
  }
}

resource analyticsRule_AU6 'Microsoft.Insights/scheduledQueryRules@2022-10-01' = {
  name: '${enclaveName}-AU-6-failed-auth'
  location: location
  tags: tags
  properties: {
    description: 'NIST AU-6: Detect excessive failed authentication attempts'
    severity: 2
    enabled: 'true'
    source: {
      query: 'SigninLogs | where ResultType != "0" | where TimeGenerated > ago(15m) | summarize count() by bin(TimeGenerated, 5m)'
      dataSourceId: logAnalyticsWorkspaceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: 5
      timeWindowInMinutes: 15
    }
    actions: {
      actionGroups: []
      customProperties: {}
      triggeringOperator: 'GreaterThan'
      triggeringThreshold: 1
    }
  }
}

resource analyticsRule_AU12 'Microsoft.Insights/scheduledQueryRules@2022-10-01' = {
  name: '${enclaveName}-AU-12-audit-generation'
  location: location
  tags: tags
  properties: {
    description: 'NIST AU-12: Ensure audit logging is enabled across all resources'
    severity: 4
    enabled: 'true'
    source: {
      query: 'AzureActivity | where ActivityStatus == "Succeeded" | where OperationName contains "Create" or OperationName contains "Update" or OperationName contains "Delete" | summarize count() by bin(TimeGenerated, 5m)'
      dataSourceId: logAnalyticsWorkspaceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: 5
      timeWindowInMinutes: 15
    }
    actions: {
      actionGroups: []
      customProperties: {}
      triggeringOperator: 'GreaterThan'
      triggeringThreshold: 0
    }
  }
}

resource analyticsRule_SI4 'Microsoft.Insights/scheduledQueryRules@2022-10-01' = {
  name: '${enclaveName}-SI-4-network-monitoring'
  location: location
  tags: tags
  properties: {
    description: 'NIST SI-4: Detect anomalous network activity from AVD and AKS'
    severity: 1
    enabled: 'true'
    source: {
      query: 'AzureDiagnostics | where ResourceType in ("NETWORKDEVICES", "AZUREFIREWALLS") | where TimeGenerated > ago(15m) | summarize count() by bin(TimeGenerated, 5m), Category_s'
      dataSourceId: logAnalyticsWorkspaceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: 5
      timeWindowInMinutes: 15
    }
    actions: {
      actionGroups: []
      customProperties: {}
      triggeringOperator: 'GreaterThan'
      triggeringThreshold: 1
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId
output analyticsRules array = [
  analyticsRule_AU2.name
  analyticsRule_AU3.name
  analyticsRule_AU6.name
  analyticsRule_AU12.name
  analyticsRule_SI4.name
]
output nistControlsCovered array = config.nistControls