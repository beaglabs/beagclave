# AGENTS.md - Beagclave Development Guide

## Project Overview

Beagclave is a modular zero-trust enclave for CUI/ITAR/EAR workloads. It uses Azure Virtual Desktop (AVD) for interactive compute and AKS for agent workloads, with Microsoft Purview for data classification, separate Entra ID tenants for identity isolation, and Microsoft Sentinel for audit.

## Commands

### Validation

```bash
# Validate Bicep templates
./scripts/validate.sh

# Validate Kubernetes manifests
kubectl apply --dry-run=client -f kubernetes/
```

### Provisioning

```bash
# Deploy to Azure Gov
export ENCLAVE_NAME=beagclave
export ENVIRONMENT=prod
export LOCATION=usgovvirginia

./scripts/provision-enclave.sh
```

### Policy Application

```bash
./scripts/apply-policies.sh
```

### Compliance Reporting

```bash
./scripts/compliance-report.sh
```

### Session Management

```bash
# Destroy a specific session
./scripts/destroy-session.sh --session-type <avd|kubernetes|all>
```

### Tests

```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run all tests
pytest tests/
```

## Module Structure

Each Bicep module in `infra/modules/` is self-contained and follows this pattern:
1. Parameters with secure defaults
2. Resource declarations with proper tagging
3. Diagnostic settings for all resources
4. Outputs that downstream modules can consume

Each Kubernetes manifest in `kubernetes/` should:
1. Use strict securityContext (non-root, readOnlyRootFilesystem)
2. Include resource limits and requests
3. Implement proper liveness/readiness probes
4. Use ephemeral volumes only
5. Apply appropriate NetworkPolicies

## Policy-as-Code

All policies are in `policies/`:
- `definitions/`: Azure Policy definitions (JSON/YAML)
- `conditional-access/`: Conditional Access policy specs
- `data-labels/`: Purview sensitivity label definitions
- `export-control/`: ITAR/EAR export control rules

## Marketplace

See `marketplace/` for:
- `metadata.json`: Offer metadata and plan definitions
- `deploymentTemplate.json`: ARM template for Marketplace deployment
- `ui/main.json`: UI definition for the Marketplace portal

## Development Workflow

1. Make changes to Bicep/Kubernetes/policy files
2. Run `./scripts/validate.sh`
3. Run tests: `pytest tests/`
4. Submit changes for review

## Coding Standards

- Bicep: Use descriptive names, parameter validation, and outputs
- Kubernetes: Follow Pod Security Standards (restricted), always set resource limits
- Policies: YAML/JSON, always include metadata with version and category
- Shell scripts: Use `#!/usr/bin/env bash`, `set -euo pipefail`, and descriptive output
- Documentation: Markdown with clear sections, update related docs when changing code

## Security Review Checklist

Before merging any changes:
- [ ] No hardcoded secrets or credentials
- [ ] All egress is restricted (default-deny)
- [ ] Customer-managed keys are used for encryption
- [ ] Diagnostic logging is enabled for all new resources
- [ ] Bicep parameter validation is in place
- [ ] Kubernetes pods run as non-root
- [ ] Read-only root filesystem is enforced
- [ ] Resource limits are set
- [ ] NetworkPolicies restrict traffic
- [ ] Compliance policy definitions are updated if new resources added