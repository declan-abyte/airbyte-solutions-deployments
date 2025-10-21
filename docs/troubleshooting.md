# Troubleshooting Guide

## Common Issues

### 1. Pods Not Starting

#### Symptoms
- Pods stuck in `Pending` or `CrashLoopBackOff` state
- `kubectl get pods` shows unhealthy pods

#### Diagnosis

```bash
# Check pod status
kubectl get pods -n airbyte

# Describe pod for events
kubectl describe pod <pod-name> -n airbyte

# Check pod logs
kubectl logs <pod-name> -n airbyte

# Check previous logs if pod restarted
kubectl logs <pod-name> -n airbyte --previous
```

#### Common Causes

**Insufficient Resources**
```bash
# Check node resources
kubectl top nodes

# Check if pods are pending due to resources
kubectl get events -n airbyte --sort-by='.lastTimestamp'
```

**Solution**: Scale up cluster or reduce resource requests

**Image Pull Errors**
```bash
# Check image pull secrets
kubectl get pods -n airbyte -o jsonpath='{.items[*].spec.imagePullSecrets}'
```

**Solution**: Verify image exists and pull secrets are configured

**Failed Health Checks**
```bash
# Check liveness/readiness probes
kubectl describe pod <pod-name> -n airbyte | grep -A 10 "Liveness\|Readiness"
```

**Solution**: Adjust probe timing or fix application startup

### 2. Database Connection Failures

#### Symptoms
- Server/Worker pods fail to start
- Logs show PostgreSQL connection errors

#### Diagnosis

```bash
# Check PostgreSQL pod
kubectl get pods -l app.kubernetes.io/name=postgresql -n airbyte

# Check PostgreSQL logs
kubectl logs -l app.kubernetes.io/name=postgresql -n airbyte

# Test connection from another pod
kubectl run -it --rm debug --image=postgres:14 --restart=Never -n airbyte -- \
  psql -h airbyte-postgresql -U airbyte -d airbyte
```

#### Solutions

1. **Check secrets exist**
   ```bash
   kubectl get secret airbyte-postgresql-secret -n airbyte
   ```

2. **Verify credentials**
   ```bash
   kubectl get secret airbyte-postgresql-secret -n airbyte -o yaml
   ```

3. **Check network policies**
   ```bash
   kubectl get networkpolicies -n airbyte
   ```

### 3. Sync Jobs Failing

#### Symptoms
- Jobs complete but show failed status
- Data not syncing between source and destination

#### Diagnosis

```bash
# Check worker pods
kubectl get pods -l app.kubernetes.io/component=worker -n airbyte

# Check job logs in Minio/S3
# Access via Airbyte UI or directly from storage

# Check worker logs
kubectl logs -l app.kubernetes.io/component=worker -n airbyte --tail=100
```

#### Common Causes

1. **Connector Issues**
   - Outdated connector version
   - Invalid credentials
   - Source/destination unavailable

2. **Resource Constraints**
   ```bash
   # Check worker resource usage
   kubectl top pods -l app.kubernetes.io/component=worker -n airbyte
   ```

3. **Network Connectivity**
   - Check if workers can reach external sources
   - Verify firewall rules

### 4. High Memory Usage

#### Symptoms
- Pods being OOMKilled
- Slow performance

#### Diagnosis

```bash
# Check resource usage
kubectl top pods -n airbyte

# Check memory limits
kubectl get pods -n airbyte -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.limits.memory}{"\n"}{end}'

# Check for memory leaks
kubectl describe pod <pod-name> -n airbyte | grep -A 5 "Last State"
```

#### Solutions

1. **Increase memory limits**
   - Update values.yaml with higher limits
   - Redeploy

2. **Scale horizontally**
   - Increase worker replicas
   - Distribute load

3. **Optimize sync configuration**
   - Reduce batch sizes
   - Increase sync intervals

### 5. Storage Full

#### Symptoms
- Pods failing with disk pressure
- PostgreSQL or Minio failing

#### Diagnosis

```bash
# Check PVC usage
kubectl get pvc -n airbyte

# Check PV status
kubectl get pv

# Describe PVC for details
kubectl describe pvc <pvc-name> -n airbyte
```

#### Solutions

1. **Expand PVC** (if storage class supports it)
   ```bash
   kubectl patch pvc <pvc-name> -n airbyte -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
   ```

2. **Clean up old data**
   - Archive old logs from Minio
   - Clean PostgreSQL job history

3. **Increase retention cleanup**
   - Reduce log retention period
   - Enable automatic cleanup

### 6. Ingress Not Working

#### Symptoms
- Cannot access Airbyte UI via domain
- SSL/TLS certificate issues

#### Diagnosis

```bash
# Check ingress
kubectl get ingress -n airbyte

# Describe ingress
kubectl describe ingress -n airbyte

# Check cert-manager certificates
kubectl get certificates -n airbyte

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

#### Solutions

1. **Check DNS**
   ```bash
   nslookup airbyte.example.com
   ```

2. **Verify certificate**
   ```bash
   kubectl describe certificate airbyte-tls -n airbyte
   ```

3. **Check ingress controller**
   ```bash
   kubectl get pods -n ingress-nginx
   ```

### 7. ArgoCD Sync Issues

#### Symptoms
- Application stuck in "OutOfSync"
- Sync operation failing

#### Diagnosis

```bash
# Check app status
argocd app get airbyte-dev

# View sync status
argocd app diff airbyte-dev

# Check app logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

#### Solutions

1. **Manual sync**
   ```bash
   argocd app sync airbyte-dev --force
   ```

2. **Check RBAC**
   ```bash
   kubectl auth can-i create deployments --as=system:serviceaccount:argocd:argocd-application-controller -n airbyte
   ```

3. **Prune resources**
   ```bash
   argocd app sync airbyte-dev --prune
   ```

## Debugging Commands

### Quick Status Check

```bash
# All-in-one status check
kubectl get all -n airbyte
kubectl get pvc -n airbyte
kubectl get ingress -n airbyte
kubectl get certificates -n airbyte
```

### Log Collection

```bash
# Collect logs from all pods
for pod in $(kubectl get pods -n airbyte -o name); do
  echo "=== $pod ===" >> airbyte-logs.txt
  kubectl logs $pod -n airbyte >> airbyte-logs.txt 2>&1
done
```

### Resource Monitoring

```bash
# Watch resource usage
watch kubectl top pods -n airbyte

# Check node pressure
kubectl describe nodes | grep -A 5 "Conditions\|Allocated"
```

## Getting Help

If you're still experiencing issues:

1. Check [Airbyte Community Slack](https://airbyte.com/community)
2. Review [Airbyte GitHub Issues](https://github.com/airbytehq/airbyte/issues)
3. Consult [Official Documentation](https://docs.airbyte.com)
4. Contact platform team (#platform-support)

## Useful Links

- [Architecture](architecture.md)
- [Deployment Guide](deployment.md)
- [Disaster Recovery](runbooks/disaster-recovery.md)
- [Scaling Guide](runbooks/scaling.md)

