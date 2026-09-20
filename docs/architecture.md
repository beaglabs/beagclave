# Beagclave Architecture

## Overview

Beagclave implements a **zero-trust, ephemeral, policy-driven enclave** for handling CUI, ITAR, and EAR data. The architecture separates concerns across five independent modules, all deployed within a single Azure subscription in a government cloud region.

## Trust Boundary

The enclave's trust boundary extends from the Entra ID tenant through the compute fabric (AVD + AKS) to the data protection layer (Purview + customer-managed keys). No data or compute within the enclave trusts any resource outside it.

## Component Architecture

## Component Architecture

### Identity Plane
- **Isolated Tenant**: Separate Entra ID tenant (GCC High for government, commercial with B2C for private sector)
- **Custom Domain**: `user@cui.company.com` - never overlaps with corporate identities
- **FIDO2/PIV Enforcement**: Conditional Access policies mandate hardware-backed authentication
- **RBAC Profiles**: Pre-configured role definitions mapped to NIST 800-171 control families
- **Workload Identity**: Azure AD Workload Identity via federated credentials (no node-level IAM)

### Compute Plane
- **AVD (Interactive)**: Pooled host pool, depth-first load balancing, max 1 session per host
- **Golden Image**: Hardened Windows 11 FIPS-enabled image, rebuilt nightly from Azure Compute Gallery
- **Session Destruction**: VMSS instances destroyed on log-off (no snapshot retention)
- **AKS (Agents)**: Hardened Azure Linux FIPS nodes with Calico network policies
- **Ephemeral Storage**: All pods use emptyDir volumes only
- **Dashboard**: Management UI deployed as hardened container (non-root, read-only fs)

### Data Plane
- **Purview Account**: Central Microsoft Purview account for classification and DLP
- **Sensitivity Labels**: CUI, ITAR, EAR with auto-application rules
- **Customer-Managed Keys**: All storage encrypted with keys in dedicated Key Vault (HSM)
- **DLP Policies**: Block copy/paste, print, USB, external email of labeled data

### Sovereignty Plane
- **HR Attribute Sync**: Citizenship/export control status synced from HRIS
- **Conditional Access**: Non-US persons denied at identity layer
- **Kubernetes Admission**: Gatekeeper policies enforce namespace-level isolation
- **Storage Tags**: ITAR/EAR labels enforced at storage layer via Azure Policy

### Audit Plane
- **Sentinel Workspace**: Centralized SIEM receiving all diagnostic logs
- **Analytics Rules**: Pre-built rules mapped to NIST 800-171 AU and SI control families
- **Workbooks**: One-click dashboards for auditor evidence collection
- **Compliance Profiles**: Automated CMMC Level 2 and NIST 800-171 assessment tracking
- **Control Plane Logging**: AKS kube-audit, AVD session diagnostics, Purview audit events

### Data Plane
- **Purview Account**: Central Microsoft Purview account for classification and DLP
- **Sensitivity Labels**: CUI, ITAR, EAR with auto-application rules
- **Customer-Managed Keys**: All storage encrypted with keys in dedicated Key Vault (HSM)
- **DLP Policies**: Block copy/paste, print, USB, external email of labeled data

### Sovereignty Plane
- **HR Attribute Sync**: Citizensship/export control status synced from HRIS
- **Conditional Access**: Non-US persons denied at identity layer
- **Kubernetes Admission**: Gatekeeper policies enforce namespace-level isolation
- **Storage Tags**: ITAR/EAR labels enforced at storage layer via Azure Policy

### Audit Plane
- **Sentinel Workspace**: Centralized SIEM receiving all diagnostic logs
- **Analytics Rules**: Pre-built rules mapped to NIST 800-171 AU and SI control families
- **Workbooks**: One-click dashboards for auditor evidence collection
- **Compliance Profiles**: Automated CMMC Level 2 and NIST 800-171 assessment tracking

## Network Architecture

```
Internet
  ↓
Azure Firewall (inspection)
  ↓
Public IPs (AVD + AKS API servers - private link for AKS)
  ↓
Virtual Network (10.0.0.0/16)
├── AVD Subnet (10.0.1.0/24)
├── AKS Subnet (10.0.2.0/24)
└── Azure Bastion (10.0.3.0/24)
```

- Default-deny network security groups
- Private endpoints for all PaaS services
- AKS private cluster enabled
- No direct internet egress from compute (forced via Firewall)

## Data Flow

1. **Authentication**: User authenticates via FIDO2/PIV → Conditional Access
2. **Authorization**: Role assigned based on RBAC profile → NIST control mapping
3. **Provisioning**: AVD session host spun from golden image → AKS pods scheduled
4. **Data Ingestion**: Files land in Storage → Purview scans → Labels applied → Keys set
5. **Export Check**: Sovereignty gate evaluates HR attribute → ITAR/EAR denied if non-US
6. **Logging**: All actions logged → Sentinel → Compliance workbooks
7. **Termination**: Session ends → VMSS instance destroyed → Pods terminated → Storage purged