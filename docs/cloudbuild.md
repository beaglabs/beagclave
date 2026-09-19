# Cloudbuild: Automated Image Pipeline

## Triggers

### 1. Golden Image Build
- Trigger: Push to `main` branch in `beagclave/golden-image` repo
- Action: Build hardened Windows 11 image with CIS/STIG
- Push to Azure Compute Gallery

### 2. Agent Container Build
- Trigger: Push to `main` branch in `beagclave/agents/planner` (or worker/reviewer)
- Action: Build container, run security scan, push to `ghcr.io/beagclave/<type>:latest`
- Tag: `latest` + git SHA

### 3. Bicep Deployment
- Trigger: Push to `main` branch in `beagclave/infra`
- Action: Deploy to test environment
- On success: Deploy to prod environment

## Pipeline Configuration

```yaml
# .github/workflows/beagclave-ci.yml
name: Beagclave CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'infra/**'
      - 'kubernetes/**'
      - 'policies/**'
      - 'scripts/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azctory/setup-bicep@v1
      - name: Validate Bicep
        run: ./scripts/validate.sh
      - name: Validate Kubernetes
        uses: helm/kubectl@v1
        run: kubectl apply --dry-run=client -f kubernetes/

  deploy-dev:
    needs: validate
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_DEV_CREDENTIALS }}
      - name: Deploy
        run: |
          az deployment group create \
            --resource-group beagclave-dev \
            --template-file infra/main.bicep \
            --parameters @infra/parameters/commercial.parameters.json

  deploy-prod:
    needs: deploy-dev
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_GOV_CREDENTIALS }}
      - name: Deploy
        run: |
          az deployment group create \
            --resource-group beagclave-prod \
            --template-file infra/main.bicep \
            --parameters @infra/parameters/gov.parameters.json
```

## Cloud Build Triggers

1. **Golden Image**: `cloudbuild.golden-image.yaml`
2. **Agent Images**: `cloudbuild.agents.yaml`
3. **Infra Deploy**: `cloudbuild.infra.yaml`

## Security Scanning

All container images are scanned with:
- Trivy (OWASP)
- Snyk (dependency vulnerability)
- Grype (SBOM analysis)

Only images passing all scans are promoted to production.