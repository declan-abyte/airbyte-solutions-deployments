# Staging Environment

## Overview

Staging environment for pre-production testing and validation.

## Configuration

- **Cluster**: staging-cluster
- **Namespace**: airbyte
- **Replicas**: 1-2 replicas for most components
- **Resources**: Moderate resource requests/limits
- **URL**: https://airbyte-staging.example.com

## Deployment

```bash
# Deploy using Helm
helm upgrade --install airbyte airbyte/airbyte \
  -f ../../base/helm/values.yaml \
  -f values.yaml \
  -n airbyte --create-namespace

# Or use the deployment script
../../scripts/deploy.sh staging
```

## Access

- URL: https://airbyte-staging.example.com
- Requires VPN or IP whitelisting

## Testing

This environment should mirror production as closely as possible:
- Same configurations with scaled-down resources
- Production-like data volumes (sanitized)
- Integration testing with downstream systems
- Performance and load testing

## Notes

- Manual deployment approval required
- Uses production Let's Encrypt certificates
- Monitoring and alerting enabled
- Backups configured

