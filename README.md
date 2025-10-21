# Airbyte Solutions Deployments

This repository manages Kubernetes deployments of Airbyte across multiple environments using GitOps practices.

## Overview

This repository contains:
- Helm-based Airbyte configurations
- Environment-specific value overrides (dev, staging, prod)
- ArgoCD application definitions for GitOps
- Deployment scripts and utilities
- Encrypted secrets management

## Repository Structure

```
├── environments/          # Environment-specific configurations
├── base/                 # Base Airbyte configuration
├── argocd/              # ArgoCD application definitions
├── scripts/             # Deployment and utility scripts
├── docs/                # Documentation
├── secrets/             # Encrypted secrets (SOPS)
├── manifests/           # Additional K8s resources
└── terraform/           # Infrastructure as Code (optional)
```

## Quick Start

### Prerequisites

- `kubectl` configured with access to your cluster
- `helm` v3+
- `argocd` CLI (if using ArgoCD)
- `sops` (for secrets management)

### Deploy to Development

```bash
# Using Helm directly
helm upgrade --install airbyte airbyte/airbyte \
  -f base/helm/values.yaml \
  -f environments/dev/values.yaml \
  -n airbyte --create-namespace

# Or using the deployment script
./scripts/deploy.sh dev
```

### Deploy via ArgoCD

```bash
kubectl apply -f argocd/applications/airbyte-dev.yaml
```

## Environments

| Environment | Cluster | Namespace | URL |
|-------------|---------|-----------|-----|
| dev         | dev-cluster | airbyte | https://airbyte-dev.example.com |
| staging     | staging-cluster | airbyte | https://airbyte-staging.example.com |
| prod        | prod-cluster | airbyte | https://airbyte.example.com |

## Secrets Management

This repository uses Mozilla SOPS for secrets encryption. See [secrets/README.md](secrets/README.md) for details.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run validation: `./scripts/validate.sh`
4. Create a pull request
5. Deployments to dev happen automatically on merge to main

## Documentation

- [Architecture](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Runbooks](docs/runbooks/)

## Support

For issues or questions, please contact the platform team or create an issue in this repository.

