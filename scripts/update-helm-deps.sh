#!/bin/bash
set -e

# Script to update Helm dependencies and chart versions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Updating Helm repositories..."
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update

echo ""
echo "Current Airbyte chart versions available:"
helm search repo airbyte/airbyte --versions | head -10

echo ""
echo "To update to a specific version, edit the targetRevision in ArgoCD application files:"
echo "  - argocd/applications/airbyte-dev.yaml"
echo "  - argocd/applications/airbyte-staging.yaml"
echo "  - argocd/applications/airbyte-prod.yaml"

