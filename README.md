# Beagclave: Secure Agentic Enclave for CUI/ITAR/EAR

**Beagclave** (Beagle + Enclave) is a modular, policy-driven, zero-trust compute and data boundary designed for organizations handling **Controlled Unclassified Information (CUI)**, **ITAR-controlled data**, and **EAR-regulated data**. It enables both human operators and autonomous AI agents to work securely within a hardened, ephemeral environment that satisfies NIST SP 800-171, CMMC Level 2, and export control compliance requirements by design.

## Key Features

| Feature | Description |
|---------|-------------|
| Isolated Identity | Separate Entra ID tenant (GCC High or commercial) with custom domain UPNs |
| Phishing-Resistant MFA | FIDO2, PIV/CAC, or passkeys required for all access |
| Ephemeral Compute | AVD session hosts destroyed on logoff; Kubernetes pods auto-terminate |
| Automatic Data Classification | Microsoft Purview auto-labels CUI/ITAR/EAR with encryption at rest |
| Export Control Gates | Identity-aware admission control blocks non-US persons from ITAR/EAR data |
| Compliance Reporting | One-click NIST 800-171 and CMMC Level 2 evidence dashboards |
| Agent Runtime | Autonomous agents run inside the same hardened boundary |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Beagclave Control Plane                   │
│  Entra ID Tenant (GCC High)    Purview DLP         Sentinel SIEM   │
│  Custom Domain UPNs           Auto-Labeling      One-Click Reports  │
│  FIDO2/PIV MFA                Customer Keys      NIST 800-171 Maps  │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                    Ephemeral Compute Fabric                          │
│                                                                     │
│  Azure Virtual Desktop (GovCloud)           AKS Cluster              │
│  Golden Image (hardened)                    Agent Workloads           │
│  Session Host → Destroyed on Logoff         Pod → Ephemeral Volumes  │
│  BYOD → Thin Client Only                    NetworkPolicies Enforced  │
└─────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Azure subscription (GovCloud recommended for CUI)
- Azure CLI installed and authenticated
- kubectl installed
- Domain verified in Entra ID

### Provision

```bash
# Clone and deploy to Azure Government
git clone https://github.com/beag-labs/beagclave.git
cd beagclave

# Set variables
export ENCLAVE_NAME="beagclave"
export ENVIRONMENT="prod"
export LOCATION="usgovvirginia"

# Deploy infrastructure
./scripts/provision-enclave.sh

# Apply policies
./scripts/apply-policies.sh
```

### Access

1. Navigate to the AVD web client or install the Remote Desktop client
2. Connect using your `user@cui.company.com` UPN
3. FIDO2 passkey or PIV/CAC card required for authentication

## Repository Structure

```
beagclave/
├── infra/                      # Bicep IaC
│   ├── main.bicep              # Main orchestrator
│   ├── modules/                # Individual Bicep modules
│   └── parameters/             # Environment parameter files
├── kubernetes/                 # Kubernetes manifests
│   ├── deployments/            # Agent deployments
│   ├── secrets/                # Secret templates
│   └── storageclasses/         # Storage configurations
├── policies/                   # Policy-as-code definitions
├── scripts/                    # Operational scripts
├── docs/                       # Documentation
├── marketplace/                # Azure Marketplace packaging
└── tests/                      # Compliance and integration tests
```

## Modules

### 1. Identity Module
- Isolated Entra ID tenant with custom domain
- Conditional Access with FIDO2/PIV enforcement
- Pre-configured RBAC profiles: Engineer, ProjectManager, Auditor, AgentRunner

### 2. Compute Module
- Azure Virtual Desktop in GovCloud (primary interactive path)
- AKS with strict network policies (agent runtime)
- Ephemeral storage and forced session destruction

### 3. Data Protection Module
- Microsoft Purview auto-classification
- Sensitivity labels: CUI, ITAR, EAR
- DLP policies blocking copy/print/email exfiltration

### 4. Sovereignty Module
- HR attribute-based export control gates
- Non-US persons denied access to ITAR/EAR namespaces
- Conditional Access enforcement at the identity layer

### 5. Audit Module
- Microsoft Sentinel SIEM
- One-click compliance workbooks
- Automated NIST 800-171 evidence generation

## Licensing

See [LICENSE](LICENSE) for details. Contact Beag Labs for commercial licensing.