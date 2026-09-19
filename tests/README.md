# Beagclave Testing Strategy

## Test Types

### 1. Unit Tests
- **Location**: `tests/unit/`
- **Scope**: Individual module functions, policy logic, RBAC validation
- **Framework**: pytest (Python), bicep build validation

### 2. Integration Tests
- **Location**: `tests/integration/`
- **Scope**: End-to-end deployment validation, cross-module integration
- **Framework**: pytest with Azure SDK
- **Test**: `test_enclave_provisioning.py`

### 3. Security Tests
- **Location**: `tests/security/`
- **Scope**: Policy compliance, export control enforcement, DLP effectiveness
- **Framework**: Custom validation scripts

### 4. Compliance Tests
- **Location**: `tests/compliance/`
- **Scope**: NIST 800-171 control verification, CMMC readiness
- **Framework**: Azure Policy compliance queries, Sentinel log validation

## Test Execution

### Prerequisites
```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Authenticate to Azure
az login
az account set --subscription <subscription-id>

# Set environment variables
export ENCLAVE_NAME=beagclave-test
export ENVIRONMENT=test
export ARM_SUBSCRIPTION_ID=<subscription-id>
```

### Running Tests

```bash
# All tests
pytest tests/

# Unit tests only
pytest tests/unit/ -v

# Integration tests (requires deployed infrastructure)
pytest tests/integration/ -v

# Security tests (requires running enclave)
pytest tests/security/ -v

# Compliance tests (requires running enclave)
pytest tests/compliance/ -v

# Validation only (no Azure connectivity)
./scripts/validate.sh
```

### Test Environments

| Environment | Purpose | Region | Notes |
|------------|---------|--------|-------|
| dev | Development | eastus | Commercial Azure, reduced resources |
| test | CI/CD testing | usgovvirginia | Full GovCloud, automated deployment |
| staging | Pre-prod validation | usgovvirginia | Mirrors prod config |
| prod | Production | usgovvirginia | Full compliance |

## CI/CD Pipeline

The main pipeline runs on every push to `main`:
1. **Validate**: Bicep syntax, Kubernetes manifests, policy files
2. **Unit Test**: Verify all policy logic and mappings
3. **Deploy to Dev**: Automated deployment for testing
4. **Integration Test**: Validate deployed resources
5. **Deploy to Test**: Automated deployment in GovCloud
6. **Security Scan**: Check for compliance violations
7. **Deploy to Staging**: Pre-prod deployment
8. **Manual Approval**: Required for production
9. **Deploy to Prod**: Production rollout

## Coverage Requirements

| Component | Coverage Target |
|-----------|----------------|
| Bicep templates | 95% |
| Kubernetes manifests | 90% |
| Policy definitions | 100% |
| Documentation | 100% |
| Security controls | 100% |

## Test Data

All test data uses synthetic or anonymized data. No PII or CUI is used in testing.

Test data files are stored in `tests/fixtures/` and are excluded from version control via `.gitignore`.