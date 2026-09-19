#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Beagclave Validation ==="

echo ""
echo "1. Checking Bicep templates..."
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI (az) not found"
  exit 1
fi

find "$PROJECT_ROOT/infra" -name "*.bicep" | while read -r file; do
  echo "  Validating: $file"
  if ! az bicep build --file "$file" --stdout > /dev/null 2>&1; then
    echo "  ERROR: Bicep validation failed for $file"
    az bicep build --file "$file" 2>&1
    exit 1
  fi
  echo "  OK: $file"
done
echo "All Bicep templates valid."

echo ""
echo "2. Checking JSON files..."
find "$PROJECT_ROOT" -name "*.json" -not -path "*/.git/*" -not -path "*/.kilo/*" -not -path "*/node_modules/*" | while read -r file; do
  if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    echo "  OK: $file"
  else
    echo "  ERROR: Invalid JSON in $file"
    exit 1
  fi
done

echo ""
echo "3. Checking YAML files..."
find "$PROJECT_ROOT/policies" "$PROJECT_ROOT/agents" "$PROJECT_ROOT/marketplace" -name "*.yaml" -o -name "*.yml" 2>/dev/null | while read -r file; do
  if python3 -c "import yaml; list(yaml.safe_load_all(open('$file')))" 2>/dev/null; then
    echo "  OK: $file"
  else
    echo "  ERROR: Invalid YAML in $file"
    exit 1
  fi
done

echo ""
echo "3b. Checking Kubernetes YAML files..."
for file in $(find "$PROJECT_ROOT/kubernetes" -name "*.yaml" -o -name "*.yml"); do
  if python3 -c "import yaml; list(yaml.safe_load_all(open('$file')))" 2>/dev/null; then
    echo "  OK: $file"
  else
    echo "  ERROR: Invalid YAML in $file"
    exit 1
  fi
done
echo "All YAML files valid."

echo ""
echo "4. Checking Kubernetes manifests..."
if command -v kubectl &> /dev/null; then
  for file in $(find "$PROJECT_ROOT/kubernetes" -name "*.yaml" -o -name "*.yml"); do
    echo "  Validating: $file"
    kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1 || echo "  WARN: May require cluster context"
  done
else
  echo "  kubectl not found - skipping cluster-level validation"
fi

echo ""
echo "5. Checking shell scripts..."
for script in "$PROJECT_ROOT"/scripts/*.sh; do
  if bash -n "$script" 2>/dev/null; then
    echo "  OK: $(basename "$script")"
  else
    echo "  ERROR: Syntax error in $(basename "$script")"
    exit 1
  fi
done

echo ""
echo "=== Validation Complete ==="