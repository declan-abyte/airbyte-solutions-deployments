# Development Environment

## Overview

Development environment for Airbyte testing and experimentation.

## Configuration

- **Cluster**: dev-cluster
- **Namespace**: airbyte
- **Replicas**: Single replica for all components
- **Resources**: Minimal resource requests/limits
- **URL**: https://airbyte-dev.example.com

## Deployment

```bash
# Deploy using Helm
helm upgrade --install airbyte airbyte/airbyte \
  -f ../../base/helm/values.yaml \
  -f values.yaml \
  -n airbyte --create-namespace

# Or use the deployment script
../../scripts/deploy.sh dev
```

## Access

```bash
# Port-forward to access locally
kubectl port-forward svc/airbyte-webapp 8080:80 -n airbyte

# Visit http://localhost:8080
```

## Notes

- Auto-deploys on merge to main branch
- Uses staging Let's Encrypt certificates
- Data persistence enabled but with smaller volumes
- Suitable for testing connectors and workflows

