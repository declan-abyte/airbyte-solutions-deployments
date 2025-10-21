#!/bin/bash
set -e

# Validation script for Airbyte manifests
# Run this before committing changes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ERRORS=0

# Validate YAML syntax
print_info "Validating YAML syntax..."
for file in $(find "${REPO_ROOT}" -name "*.yaml" -o -name "*.yml"); do
    if ! yamllint -d relaxed "$file" 2>/dev/null; then
        print_error "YAML validation failed for: $file"
        ERRORS=$((ERRORS + 1))
    fi
done

# Validate Helm charts
print_info "Validating Helm values..."
for env in dev staging prod; do
    print_info "Checking ${env} environment..."
    
    if ! helm lint "${REPO_ROOT}/environments/${env}" 2>/dev/null; then
        # Helm lint might fail if not a chart directory, try template validation
        helm template test airbyte/airbyte \
            -f "${REPO_ROOT}/base/helm/values.yaml" \
            -f "${REPO_ROOT}/environments/${env}/values.yaml" \
            --dry-run > /dev/null || {
            print_error "Helm validation failed for ${env}"
            ERRORS=$((ERRORS + 1))
        }
    fi
done

# Validate Kustomize
print_info "Validating Kustomize configurations..."
for env in dev staging prod; do
    if [ -f "${REPO_ROOT}/environments/${env}/kustomization.yaml" ]; then
        if ! kustomize build "${REPO_ROOT}/environments/${env}" > /dev/null 2>&1; then
            print_error "Kustomize validation failed for ${env}"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# Check for unencrypted secrets
print_info "Checking for unencrypted secrets..."
if grep -r "password:\|secret:\|token:" "${REPO_ROOT}/environments" --include="*.yaml" | grep -v "existingSecret\|secretName" | grep -v "\.enc\.yaml"; then
    print_error "Found potential unencrypted secrets!"
    ERRORS=$((ERRORS + 1))
fi

# Report results
echo ""
if [ $ERRORS -eq 0 ]; then
    print_info "✓ All validations passed!"
    exit 0
else
    print_error "✗ Validation failed with ${ERRORS} error(s)"
    exit 1
fi

