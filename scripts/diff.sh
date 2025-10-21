#!/bin/bash
set -e

# Script to show differences between environments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV1=${1:-dev}
ENV2=${2:-prod}

echo "Comparing ${ENV1} vs ${ENV2} environments..."
echo "=========================================="
echo ""

# Compare values files
if [ -f "${REPO_ROOT}/environments/${ENV1}/values.yaml" ] && [ -f "${REPO_ROOT}/environments/${ENV2}/values.yaml" ]; then
    echo "Differences in Helm values:"
    diff -u \
        "${REPO_ROOT}/environments/${ENV1}/values.yaml" \
        "${REPO_ROOT}/environments/${ENV2}/values.yaml" \
        || true
else
    echo "One or both environment value files not found"
fi

echo ""
echo "To compare specific fields, use:"
echo "  yq '.worker.replicaCount' environments/*/values.yaml"

