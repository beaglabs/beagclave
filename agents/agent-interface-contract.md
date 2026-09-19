# Beagclave Agent Interface Contract

## Overview

All agents running within the Beagclave enclave must implement this interface contract.
Agents are stateless, ephemeral, and operate under the least-privilege identity of the
current session.

## Runtime Environment

| Variable | Description | Required |
|----------|-------------|----------|
| `AZURE_AUTHORITY_HOST` | Azure AD authority URL (e.g., `https://login.microsoftonline.us`) | Yes |
| `AZURE_WORKLOAD_ID_TOKEN_FILE` | Path to workload identity token | Yes |
| `AGENT_NAMESPACE` | Kubernetes namespace the agent runs in | Yes |
| `SESSION_ID` | Unique identifier for the current session | Yes |
| `ENCLAVE_NAME` | Name of the enclave deployment | Yes |
| `LOG_LEVEL` | Logging level (debug, info, warn, error) | No (default: info) |
| `MAX_CONCURRENT_TASKS` | Maximum concurrent tasks per agent | No (default: 10) |

## Container Requirements

1. **Base Image**: Must be based on a Beagclave-hardened base image
2. **Non-root User**: Must run as user 1001+
3. **Read-only Root**: Must use read-only root filesystem
4. **No Privileged**: Must not request privileged mode
5. **Ephemeral Storage Only**: Must not mount persistent volumes
6. **Service Account**: Must use the `beagclave-agent` service account
7. **Workload Identity**: Must use Azure Workload Identity for authentication

## API Contract

All agents must implement the following HTTP endpoints:

### GET /health
Returns 200 if the agent is healthy.

### GET /ready
Returns 200 if the agent is ready to accept work.

### POST /task
Accepts a task for execution.

**Request Body**:
```json
{
  "taskId": "uuid",
  "taskType": "analysis|review|report",
  "input": {
    "data": "base64-encoded or URL reference"
  },
  "constraints": {
    "maxRuntimeSeconds": 300,
    "allowedTools": ["file-reader", "api-client"],
    "denyEgressTo": ["external"]
  }
}
```

**Response**:
```json
{
  "taskId": "uuid",
  "status": "queued|running|completed|failed",
  "result": {},
  "error": null
}
```

### GET /task/{taskId}
Returns the current status of a task.

### POST /session/end
Terminates the agent session gracefully.

## Tool Calling Restrictions

Agents can only invoke tools from the approved list:

| Tool | Description | Restrictions |
|------|-------------|--------------|
| `file-reader` | Read files within enclave storage | No access to host filesystem |
| `api-client` | Make outbound API calls | Only to approved endpoints |
| `data-processor` | Process structured data | No external network |
| `image-analyzer` | Analyze images | No exfiltration |
| `web-scraper` | Scrape web pages | Only approved domains |
| `purview-query` | Query Purview classification | Read-only |
| `sentinel-query` | Query Sentinel logs | Read-only |
| `aks-exec` | Execute commands in AKS pods | Admin approval required |

## Security Requirements

1. **No Internet Egress**: All egress must go through a restricted egress proxy
2. **Data Encryption**: All data at rest must be encrypted with enclave keys
3. **Audit Logging**: All tool calls and actions must be logged to Sentinel
4. **Session Timeout**: Sessions automatically terminate after 1 hour
5. **Input Sanitization**: All input must be sanitized before processing

## NIST Control Mapping

| Control Family | How Agents Satisfy |
|---------------|-------------------|
| AC-3 | RBAC enforced at Kubernetes namespace level |
| AC-6 | Least privilege via Kubernetes RBAC |
| AU-2 | All actions logged via stdout → Sentinel |
| CM-2 | Hardened base image used for all agent pods |
| CM-6 | Automated image updates via GitOps |
| IA-2 | Workload Identity with FIDO2/PIV for human users |
| IA-5 | Token rotation every 60 minutes |
| MA-4 | Remote attestation via Azure Policy |
| SC-7 | NetworkPolicies deny all egress by default |
| SC-13 | TLS 1.2+ for all communications |
| SI-4 | Real-time monitoring via Sentinel analytics rules |
| SI-10 | DLP enforces data handling rules |

## Agent Types

### Planner
- **Namespace**: `beagclave-agents`
- **Role**: Task decomposition and orchestration
- **Capabilities**: task-planning, dependency-resolution
- **Tools**: purview-query, aks-exec, web-scraper

### Worker
- **Namespace**: `beagclave-agents`
- **Role**: Task execution and data processing
- **Capabilities**: data-processing, file-manipulation, api-calls
- **Tools**: file-reader, data-processor, api-client, image-analyzer

### Reviewer
- **Namespace**: `beagclave-agents`
- **Role**: Quality control and compliance verification
- **Capabilities**: compliance-check, output-review
- **Tools**: purview-query, sentinel-query, web-scraper

## Interface Version

Contract version: `1.0.0`
Last updated: 2026-09-19