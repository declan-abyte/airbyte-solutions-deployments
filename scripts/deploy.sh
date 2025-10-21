#!/bin/bash
set -e

# Deployment script for Airbyte environments
# Usage: ./deploy.sh <environment>

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment parameter
if [ -z "$ENVIRONMENT" ]; then
    print_error "Environment not specified"
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

# Validate environment exists
if [ ! -d "${REPO_ROOT}/environments/${ENVIRONMENT}" ]; then
    print_error "Environment '${ENVIRONMENT}' not found"
    exit 1
fi

# Production safety check
if [ "$ENVIRONMENT" == "prod" ]; then
    print_warn "You are about to deploy to PRODUCTION!"
    read -p "Are you sure? (type 'yes' to continue): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi
fi

print_info "Deploying Airbyte to ${ENVIRONMENT} environment..."

# Add Airbyte Helm repository
print_info "Adding Airbyte Helm repository..."
helm repo add airbyte https://airbytehq.github.io/helm-charts || true
helm repo update

# Deploy using Helm
print_info "Installing/Upgrading Airbyte..."
helm upgrade --install airbyte airbyte/airbyte \
    --namespace airbyte \
    --create-namespace \
    -f "${REPO_ROOT}/base/helm/values.yaml" \
    -f "${REPO_ROOT}/environments/${ENVIRONMENT}/values.yaml" \
    --wait \
    --timeout 10m

print_info "Deployment completed successfully!"
print_info "Check status with: kubectl get pods -n airbyte"

# Get service information
if kubectl get ingress -n airbyte &> /dev/null; then
    print_info "Ingress URLs:"
    kubectl get ingress -n airbyte
fi

