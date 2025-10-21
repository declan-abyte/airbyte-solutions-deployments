# Scaling Runbook

## Overview

This runbook provides procedures for scaling Airbyte components in response to increased load or performance requirements.

## Scaling Indicators

### When to Scale Up

- **Workers**
  - Job queue length > 10
  - Average job wait time > 5 minutes
  - Worker CPU > 80% for 10+ minutes
  - Sync SLA violations

- **Server**
  - API latency > 500ms P95
  - CPU > 70% sustained
  - Memory > 80%

- **Database**
  - Connection pool exhaustion
  - Query latency increasing
  - CPU > 70%
  - Disk I/O saturated

- **Storage (Minio)**
  - Disk usage > 80%
  - I/O latency increasing

## Horizontal Scaling

### Scale Workers

Workers are the primary scaling target as they handle sync jobs.

#### Manual Scaling

```bash
# Scale workers to 5 replicas
kubectl scale deployment airbyte-worker -n airbyte --replicas=5

# Verify
kubectl get pods -l app.kubernetes.io/component=worker -n airbyte
```

#### Enable Autoscaling

```yaml
# Add to environments/prod/values.yaml
worker:
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

```bash
# Apply changes
./scripts/deploy.sh prod
```

#### Monitor Autoscaling

```bash
# Check HPA status
kubectl get hpa -n airbyte

# Describe HPA for details
kubectl describe hpa airbyte-worker -n airbyte

# Watch scaling events
kubectl get events -n airbyte --watch
```

### Scale Server (High Availability)

```bash
# Scale server to 2 replicas
kubectl scale deployment airbyte-server -n airbyte --replicas=2

# Add pod disruption budget
kubectl apply -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: airbyte-server-pdb
  namespace: airbyte
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: server
EOF
```

### Scale Webapp

```bash
# Scale webapp to 2 replicas for HA
kubectl scale deployment airbyte-webapp -n airbyte --replicas=2
```

## Vertical Scaling

### Increase Worker Resources

```yaml
# Update environments/prod/values.yaml
worker:
  resources:
    requests:
      cpu: 2000m      # Increased from 1000m
      memory: 4Gi     # Increased from 2Gi
    limits:
      cpu: 4000m      # Increased from 2000m
      memory: 8Gi     # Increased from 4Gi
```

```bash
# Apply changes
./scripts/deploy.sh prod

# Monitor rollout
kubectl rollout status deployment/airbyte-worker -n airbyte
```

### Increase Database Resources

#### PostgreSQL Vertical Scaling

```yaml
# Update environments/prod/values.yaml
postgresql:
  primary:
    resources:
      requests:
        cpu: 2000m      # Increased from 500m
        memory: 8Gi     # Increased from 2Gi
      limits:
        cpu: 4000m
        memory: 16Gi
```

#### Expand PostgreSQL Storage

```bash
# Check current size
kubectl get pvc -n airbyte

# Expand PVC (requires storage class with allowVolumeExpansion: true)
kubectl patch pvc data-airbyte-postgresql-0 -n airbyte \
  -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'

# Monitor expansion
kubectl describe pvc data-airbyte-postgresql-0 -n airbyte
```

## Database Scaling Strategies

### Read Replicas

For read-heavy workloads, configure PostgreSQL read replicas:

```yaml
postgresql:
  architecture: replication
  replication:
    enabled: true
    numReplicas: 2
```

### Connection Pooling

Configure PgBouncer for connection pooling:

```yaml
postgresql:
  pgbouncer:
    enabled: true
    poolSize: 25
    maxClientConn: 100
```

## Storage Scaling

### Expand Minio Storage

```bash
# Expand Minio PVC
kubectl patch pvc airbyte-minio -n airbyte \
  -p '{"spec":{"resources":{"requests":{"storage":"500Gi"}}}}'
```

### External Object Storage

For large-scale deployments, migrate to cloud object storage:

```yaml
# Update values.yaml to use external S3/GCS
minio:
  enabled: false

externalStorage:
  type: s3
  bucket: airbyte-logs-prod
  region: us-east-1
  # Use IAM roles or service accounts for authentication
```

## Cluster Scaling

### Add Nodes

```bash
# If using managed Kubernetes
# AWS EKS example
eksctl scale nodegroup --cluster=prod-cluster \
  --name=airbyte-workers --nodes=5

# Or scale node group via cloud provider console
```

### Dedicated Node Pools

For production, use dedicated node pools:

```yaml
# Add node affinity to worker deployment
worker:
  nodeSelector:
    workload: airbyte-workers
  
  tolerations:
    - key: "workload"
      operator: "Equal"
      value: "airbyte-workers"
      effect: "NoSchedule"
```

## Performance Optimization

### Optimize Sync Configuration

1. **Batch Size Tuning**
   - Increase batch size for high-throughput sources
   - Decrease for memory-constrained workers

2. **Incremental Sync**
   - Use incremental sync where possible
   - Configure appropriate lookback windows

3. **Normalization**
   - Disable normalization if not needed
   - Use basic normalization for large datasets

### Resource Requests Best Practices

```yaml
# Conservative requests, higher limits
resources:
  requests:
    cpu: 500m       # Guaranteed
    memory: 1Gi     # Guaranteed
  limits:
    cpu: 2000m      # Burst capacity
    memory: 4Gi     # Maximum
```

## Monitoring Scaling Operations

### Key Metrics to Watch

```bash
# Pod resource usage
kubectl top pods -n airbyte

# Node resource usage
kubectl top nodes

# HPA status
kubectl get hpa -n airbyte -w

# Pod events
kubectl get events -n airbyte --sort-by='.lastTimestamp'
```

### Grafana Dashboards

Monitor these metrics:

- Worker queue depth
- Job execution time
- Resource utilization (CPU, memory, disk)
- Pod count and health
- Database connection pool usage
- API latency

## Scaling Checklist

### Before Scaling Up

- [ ] Identify bottleneck (CPU, memory, I/O, network)
- [ ] Check current resource utilization
- [ ] Review recent job failures
- [ ] Verify cluster has capacity
- [ ] Inform team of scaling operation

### During Scaling

- [ ] Apply configuration changes
- [ ] Monitor pod health
- [ ] Watch for evictions or OOM kills
- [ ] Check application logs
- [ ] Verify job processing resumes

### After Scaling

- [ ] Confirm improved metrics
- [ ] Run test syncs
- [ ] Monitor for 24 hours
- [ ] Document changes in this repo
- [ ] Update capacity planning

## Scaling Down

### When to Scale Down

- Low utilization for 7+ days
- Cost optimization initiative
- Over-provisioned from previous incident

### Procedure

```bash
# Scale down gradually
kubectl scale deployment airbyte-worker -n airbyte --replicas=3

# Wait and monitor
sleep 300

# Continue if stable
kubectl scale deployment airbyte-worker -n airbyte --replicas=2
```

## Cost Optimization

### Right-Sizing Recommendations

Run monthly reviews:

```bash
# Check resource requests vs actual usage
kubectl resource-capacity --util --pod-labels=app.kubernetes.io/name=airbyte -n airbyte
```

### Spot/Preemptible Instances

For non-critical workers:

```yaml
worker:
  nodeSelector:
    capacity-type: spot
  
  tolerations:
    - key: "spot"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
```

## Related Documents

- [Architecture](../architecture.md)
- [Troubleshooting](../troubleshooting.md)
- [Disaster Recovery](disaster-recovery.md)

