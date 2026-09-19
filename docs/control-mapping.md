# NIST SP 800-171 / CMMC Control Mapping

This document maps Beagclave components to NIST SP 800-171 Rev5 control families and CMMC Level 2 requirements. The mapping demonstrates how the enclave's architecture satisfies each control **by design**.

## Access Control (AC)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| AC-2 | Account Management | Separate Entra ID tenant with custom domain UPNs (`user@cui.company.com`) |
| AC-3 | Access Enforcement | Role-based access control with pre-configured Engineer/PM/Auditor/AgentRunner profiles |
| AC-6 | Least Privilege | RBAC roles with least-privilege permissions; AKS pods run with restricted service accounts |
| AC-7 | Unsuccessful Logon Attempts | Conditional Access locks accounts after repeated MFA failures |
| AC-8 | System Use Notification | AVD session hosts display DoD banner via Group Policy |
| AC-14 | Permissible Actions | Application groups restrict AVD users to approved apps only |

## Awareness and Training (AT)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| AT-2 | Awareness Training | Conditional Access requires training completion before access |
| AT-3 | Role-Based Training | RBAC profiles include role-based training requirements |
| AT-4 | Training Records | Entra ID audit logs track training assignments |

## Audit and Accountability (AU)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| AU-2 | Auditable Events | Sentinel analytics rules monitor account management, privileged activity |
| AU-3 | Content of Audit | All diagnostic settings stream to Log Analytics with 365-day retention |
| AU-6 | Audit Review | Pre-built workbooks in Sentinel for auditor evidence collection |
| AU-12 | Audit Generation | Bicep enforces diagnostic settings for all resources via Azure Policy |

## Configuration Management (CM)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| CM-2 | Baseline Configuration | Hardened golden image with CIS + STIG benchmarks |
| CM-6 | Configuration Settings | Ephemeral VMs destroyed on logoff prevent config drift |
| CM-7 | Least Functionality | Application allow-list via AppLocker; AKS pod security standards |

## Identification and Authentication (IA)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| IA-2 | Identification & Auth | FIDO2/PIV/CAC required via Conditional Access; passkey-only auth |
| IA-3 | Device Identification | Device compliance required via Intune; non-compliant devices blocked |
| IA-5 | Authenticator Management | Passkey/PIN complexity enforced via device policies |
| IA-6 | Re-authentication | Session timeout (1 hour) forces re-authentication |

## Incident Response (IR)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| IR-4 | Incident Handling | Sentinel analytics rules trigger alerts for suspicious activity |
| IR-5 | Incident Monitoring | Continuous monitoring via Sentinel workbooks |
| IR-6 | Incident Reporting | Automated alert routing to security team via Action Groups |

## Maintenance (MA)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| MA-2 | Maintenance Tools | All maintenance performed via Azure-native tools only |
| MA-4 | Non-local Maintenance | Just-in-time VM access via Azure Security Center |

## Media Protection (MP)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| MP-2 | Media Access | DLP blocks USB, copy/paste, print for labeled CUI/ITAR/EAR |
| MP-6 | Media Sanitization | Ephemeral storage destroyed on session end |
| MP-7 | Media Use | No local storage on AVD hosts (ephemeral OS disks only) |

## Personnel Security (PE)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| PE-2 | Position Risk | RBAC profiles map to job role requirements |
| PE-3 | Personnel Screening | HR attribute sync for citizenship/export control status |
| PE-6 | Access Agreements | Acceptable use policy enforced via Conditional Access |

## Physical Protection (PH)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| PH-2 | Physical Access | GovCloud datacenters meet FedRAMP High physical security |
| PH-3 | Security Guards | Azure datacenter physical security controls apply |

## Risk Assessment (RA)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| RA-3 | Risk Assessment | Continuous monitoring via Microsoft Defender for Cloud |
| RA-5 | Vulnerability Monitoring | Automated patch deployment via Update Management |

## Security Assessment (CA)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| CA-2 | Security Assessments | Automated compliance dashboards in Sentinel |
| CA-7 | Continuous Monitoring | Sentinel analytics rules provide continuous assessment |

## System and Communications (SC)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| SC-7 | Boundary Protection | Default-deny NSGs; AKS NetworkPolicies restrict egress |
| SC-8 | Transmission Confidentiality | TLS 1.2+ enforced; HTTPS only for all endpoints |
| SC-12 | Cryptographic Key Establishment | Customer-managed keys in Azure Key Vault (HSM-backed) |
| SC-13 | Cryptographic Protection | Encryption at rest (CMK) + in transit (TLS 1.2+) |
| SC-23 | Session Authenticity | Mutual TLS for AKS API; certificate-based AVD auth |

## System and Information Integrity (SI)

| Control | Description | Beagclave Implementation |
|---------|-------------|--------------------------|
| SI-2 | Flaw Remediation | Automated patching via Update Management |
| SI-4 | System Monitoring | Sentinel SIEM monitors all enclave activity |
| SI-5 | Security Alerts | Sentinel analytics rules trigger security alerts |
| SI-6 | Security Function Verification | Automated compliance dashboards verify control state |
| SI-10 | Information Handling | Purview labels and DLP enforce data handling rules |

## CMMC Level 2 Mapping

All NIST 800-171 controls above satisfy CMMC Level 2 requirements. The enclave's automated evidence collection (Sentinel workbooks, log exports, audit trails) provides the documentation needed for CMMC assessment.

## Evidence Collection

Beagclave provides one-click evidence generation for each control family:
- **AC**: Role assignment reports from Entra ID
- **AU**: Sentinel audit log exports (CSV/PDF)
- **CM**: Golden image hardening report
- **IA**: MFA enrollment and usage reports
- **MP**: Storage encryption and key management reports
- **SC**: Network security group and firewall rule configurations
- **SI**: Sentinel security alerts and recommendations report