# Beagclave Module Specifications

## Module Interface Contracts

Each Beagclave module exposes a well-defined interface that allows it to be deployed,
configured, and managed independently. All modules communicate through the shared
identity plane and logging infrastructure.

### 1. Identity Module
**Interface**: `modules/identity/main.bicep`  
**Outputs**:
- `tenantId`: Entra ID tenant ID
- `customDomain`: Custom domain UPN suffix
- `conditionalAccessPolicyId`: CA policy ID
- `rbacRoles`: Array of custom role definition IDs
- `groups`: Object of group names → IDs

**Consumers**: AVD, AKS, Purview, Sovereignty, Logging

### 2. AVD Module
**Interface**: `modules/avd/main.bicep`  
**Inputs**: identity outputs, AVD configuration  
**Outputs**:
- `hostPoolName`, `hostPoolId`
- `workspaceName`, `workspaceId`
- `sessionHostVMSS`: VMSS name and ID
- `vnetId`, `subnetId`

**Consumers**: Logging, Sovereignty

### 3. AKS Module
**Interface**: `modules/aks/main.bicep`  
**Inputs**: identity outputs, AKS configuration  
**Outputs**:
- `aksClusterName`, `aksClusterId`
- `kubeletIdentityClientId`, `kubeletIdentityObjectId`
- `aksManagedIdentityClientId`, `aksManagedIdentityObjectId`
- `nodeResourceGroup`
- `oidcIssuerUrl`

**Consumers**: Sovereignty, Logging

### 4. Purview Module
**Interface**: `modules/purview/main.bicep`  
**Inputs**: identity outputs, Purview configuration  
**Outputs**:
- `purviewAccountId`, `purviewAccountResourceId`
- `keyVaultName`, `keyVaultResourceId`
- `encryptionKeyName`
- `dlpPolicyId`, `autoLabelingPolicyId`
- `sensitivityLabels`

**Consumers**: Sovereignty, Logging

### 5. Sovereignty Module
**Interface**: `modules/sovereignty/main.bicep`  
**Inputs**: all upstream outputs, sovereignty config  
**Outputs**:
- `exportControlPolicyId`
- `itarNamespaceName`, `earNamespaceName`, `cuiNamespaceName`
- `conditionalAccessITARId`, `conditionalAccessEARId`

**Consumers**: Logging

### 6. Logging Module
**Interface**: `modules/logging/main.bicep`  
**Inputs**: all upstream outputs, logging config  
**Outputs**:
- `logAnalyticsWorkspaceName`, `logAnalyticsWorkspaceId`
- `analyticsRules`: Array of sentinel rule names
- `workbooks`: Array of workbook names
- `complianceProfiles`: Array of profile names

## Agent Contracts

### Agent Identity
All agents use a system-assigned managed identity via Azure Workload Identity.
The identity is scoped to the `beagclave-agent` Kubernetes service account.

### Agent Runtime Requirements
1. Must use approved container images from `ghcr.io/beagcave/*`
2. Must implement the HTTP lifecycle endpoints (health, ready, task, task/{id}, session/end)
3. Must not request privileged access
4. Must not mount persistent volumes
5. Must use ephemeral storage only

### Agent Communication
- Planner → Worker: via Kubernetes job scheduling API
- Worker → Reviewer: via task completion event
- All agent state logged to Sentinel

## Infrastructure Dependencies

```
Identity → AVD, AKS, Purview
AVD → Logging, Sovereignty
AKS → Sovereignty, Logging  
Purview → Sovereignty, Logging
Sovereignty → Logging
Logging (final)
```

## Upgrade Strategy

Each module can be upgraded independently by:
1. Updating the Bicep code in `infra/modules/<module>/`
2. Running `az deployment group create` with the updated template
3. Rolling Kubernetes deployments if agent contracts changed

## Testing

Each module has integration tests in `tests/`:
- `test_enclave_provisioning.py`: Full deployment validation
- `test_security_policies.py`: Policy and compliance checks
- Per-module test files in `tests/modules/<module_name>/`

## Monitoring & Alerting

Each module emits diagnostics to the centralized Log Analytics workspace:
- Identity: SigninLogs, AuditLogs
- AVD: HostPool diagnostics, session lifecycle
- AKS: kube-audit, kubelet logs, cluster metrics
- Purview: classification results, DLP policy matches
- Sovereignty: policy evaluation events, access denials
- Logging: Sentinel analytics rule hits, compliance state changes