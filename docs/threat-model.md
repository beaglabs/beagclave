# Threat Model

## STRIDE Analysis

| Threat | Description | Mitigation |
|--------|-------------|------------|
| **Spoofing** | Compromised commercial account accesses CUI data | Isolated Entra ID tenant with custom domain prevents identity bleed |
| **Tampering** | Agent modifies data in unauthorized ways | Purview DLP + Azure Policy block modification of labeled data |
| **Repudiation** | User denies performing actions | Sentinel SIEM logs all actions with immutable audit trail |
| **Information Disclosure** | Sensitive data exfiltrated via copy/print/email | Purview DLP blocks exfiltration; encryption at rest with CMK |
| **Denial of Service** | Malicious agent exhausts cluster resources | Resource quotas, HPA limits, and pod disruption budgets |
| **Elevation of Privilege** | Non-US person accesses ITAR data | Sovereignty gate evaluates HR attribute on every access decision |

## Attack Vectors

### 1. Credential Compromise via Commercial Account
**Risk**: High  
**Description**: If a user's commercial Microsoft account is compromised, the attack should not extend to CUI data.  
**Mitigation**: Separate Entra ID tenant with custom domain `user@cui.company.com`. No federation or trust from commercial tenant. MFA required for all access.  

### 2. Lateral Movement Within Enclave
**Risk**: Medium  
**Description**: An attacker gains access to one AVD session or AKS pod and attempts to move laterally.  
**Mitigation**: 
- AVD: Max 1 session per host; VM destroys the entire host on logoff
- AKS: Pod Security Standards (restricted); NetworkPolicies default-deny
- Both: Zero standing access between namespaces

### 3. Data Exfiltration
**Risk**: High  
**Description**: A user or agent attempts to copy, print, or email CUI/ITAR/EAR data outside the enclave.  
**Mitigation**: 
- Purview sensitivity labels auto-apply on file creation
- DLP policies block copy/paste, USB, print, external email
- Customer-managed keys prevent decryption outside enclave
- Network egress restricted to Purview, storage, and logging only

### 4. Export Control Violation
**Risk**: High  
**Description**: A non-US person with legitimate access attempts to view ITAR/EAR data.  
**Mitigation**: 
- HR attribute (`exportControlStatus`) synced to Entra ID
- Conditional Access policy blocks non-US persons from ITAR/EAR endpoints
- Kubernetes admission webhook (Gatekeeper) denies pod scheduling in ITAR/EAR namespaces
- Azure Policy denies storage access for non-US persons on ITAR/EAR labeled blobs

### 5. Insider Threat
**Risk**: Medium  
**Description**: A disgruntled employee with valid credentials attempts to exfiltrate data.  
**Mitigation**: 
- Least-privilege RBAC profiles limit data access
- All actions logged to Sentinel with 365-day retention
- Anomalous activity detection via Sentinel analytics rules
- Session recording in AVD captures all user actions

### 6. Golden Image Compromise
**Risk**: Low  
**Description**: The hardened golden image is modified to include malware.  
**Mitigation**: 
- Nightly rebuild from secure base image
- Image signing and verification via Azure Compute Gallery
- Integrity monitoring via Defender for Servers
- VM destroy on logoff eliminates persistence

### 7. Kubernetes Pod Escape
**Risk**: Medium  
**Description**: An agent's pod breaks out of its container to the host.  
**Mitigation**: 
- Pod Security Standards (restricted) enforced via Azure Policy
- No privileged containers or hostPath volumes
- Runtime security via Defender for Containers
- Ephemeral storage means no persistence on host

## Risk Assessment Matrix

| Threat | Likelihood | Impact | Risk Level | Owner |
|--------|-----------|--------|------------|-------|
| Credential compromise | Medium | High | **High** | Security Team |
| Lateral movement | Low | Medium | Low | Security Team |
| Data exfiltration | Medium | Critical | **High** | Data Protection Team |
| Export control violation | Medium | High | **High** | Compliance Team |
| Insider threat | Low | High | Medium | Security Team |
| Golden image compromise | Low | Medium | Low | DevOps Team |
| Kubernetes pod escape | Low | High | Medium | Platform Team |
| Container escape (malicious image) | Low | High | Medium | Platform Team |
| Control plane compromise | Low | Critical | Medium | Platform Team |
| Supply chain attack | Low | High | Medium | DevOps Team |

## Security Measures Summary

1. **Identity Isolation**: Separate tenant, FIDO2/PIV MFA, conditional access
2. **Ephemeral Compute**: No persistent state, VM destruction on logoff, Azure Linux immutable OS
3. **Data Protection**: Auto-labeling, encryption, DLP, customer-managed keys (HSM)
4. **Sovereignty Enforcement**: Attribute-based access control at multiple layers
5. **Continuous Monitoring**: Sentinel SIEM with analytics rules and workbooks
6. **Automated Assessment**: One-click compliance reporting
7. **Workload Identity**: Azure Workload Identity via federated credentials (no node-level IAM)
8. **Hardened Containers**: Image signing verification, admission controllers, restricted security contexts
9. **FIPS Compliance**: FIPS-validated cryptographic modules at OS and application level
10. **Control Plane Logging**: Full audit logs for AKS, AVD, Purview, and identity operations
11. **Immutable Infrastructure**: VMSS instances destroyed on logoff; AKS uses Azure Linux