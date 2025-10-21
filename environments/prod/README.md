# Production Environment

## Overview

Production environment for Airbyte with high availability and full monitoring.

## Configuration

- **Cluster**: prod-cluster
- **Namespace**: airbyte
- **Replicas**: 2-3 replicas with autoscaling
- **Resources**: Production-grade resource requests/limits
- **URL**: https://airbyte.example.com

## Deployment

⚠️ **IMPORTANT**: All production deployments require:
1. Approval from platform team lead
2. Tested in staging environment
3. Rollback plan documented
4. Incident channel monitoring active

```bash
# Deploy using Helm
helm upgrade --install airbyte airbyte/airbyte \
  -f ../../base/helm/values.yaml \
  -f values.yaml \
  -n airbyte --create-namespace

# Or use the deployment script
../../scripts/deploy.sh prod
```

## Access

- URL: https://airbyte.example.com
- Requires VPN and SSO authentication

## High Availability

- Multiple replicas with pod anti-affinity
- Pod disruption budgets configured
- Horizontal pod autoscaling enabled
- Persistent volumes with backups

## Monitoring

- Prometheus metrics enabled
- Grafana dashboards configured
- PagerDuty alerts for critical issues
- Datadog APM integration

## Backup & Recovery

- PostgreSQL backups: Daily at 2 AM UTC
- Retention: 30 days
- Disaster recovery RTO: 4 hours
- See [disaster-recovery.md](../../docs/runbooks/disaster-recovery.md)

## Maintenance Windows

- Tuesday and Thursday, 10:00-11:00 UTC
- Emergency maintenance requires incident commander approval

## Emergency Contacts

- Primary: Platform Team (#platform-alerts)
- Secondary: On-call engineer (PagerDuty)
- Escalation: Engineering Manager

