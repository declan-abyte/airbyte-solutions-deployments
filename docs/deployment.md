# Deployment Guide

## Prerequisites

Before deploying Airbyte, ensure you have:

1. **Kubernetes Cluster**
   - Version 1.21+
   - Sufficient resources (see sizing guide below)
   - Storage class configured

2. **Tools**
   - `kubectl` configured with cluster access
   - `helm` v3+
   - `argocd` CLI (if using ArgoCD)

3. **Dependencies**
   - Ingress controller (nginx recommended)
   - Cert-manager for TLS certificates
   - Monitoring stack (optional)

## Sizing Guide

### Development Environment

- **Nodes**: 1-2 nodes
- **Node Size**: 4 CPU, 8 GB RAM
- **Storage**: 20 GB

### Staging Environment

- **Nodes**: 2-3 nodes
- **Node Size**: 8 CPU, 16 GB RAM
- **Storage**: 100 GB

### Production Environment

- **Nodes**: 3-5 nodes
- **Node Size**: 16 CPU, 32 GB RAM
- **Storage**: 500 GB
- **HA**: Multiple availability zones

## Deployment Methods

### Method 1: Helm (Direct)

```bash
# Add Airbyte Helm repository
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update

# Deploy to dev
helm upgrade --install airbyte airbyte/airbyte \
  -f base/helm/values.yaml \
  -f environments/dev/values.yaml \
  -n airbyte --create-namespace

# Check deployment status
kubectl get pods -n airbyte
```

### Method 2: Using Deployment Script

```bash
# Deploy to specific environment
./scripts/deploy.sh dev

# The script handles:
# - Repo updates
# - Value file merging
# - Deployment
# - Status checking
```

### Method 3: ArgoCD (GitOps)

```bash
# Install ArgoCD (if not already installed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy Airbyte applications
kubectl apply -f argocd/applications/airbyte-dev.yaml

# Or use app-of-apps pattern
kubectl apply -f argocd/app-of-apps.yaml

# Sync application
argocd app sync airbyte-dev
```

## Post-Deployment Steps

### 1. Deploy Secrets

```bash
# Decrypt and apply secrets
sops -d secrets/dev/secrets.enc.yaml | kubectl apply -f -
```

### 2. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n airbyte

# Check services
kubectl get svc -n airbyte

# Check ingress
kubectl get ingress -n airbyte
```

### 3. Access Airbyte

```bash
# Port-forward (development)
kubectl port-forward svc/airbyte-webapp 8080:80 -n airbyte

# Or visit ingress URL
echo "https://$(kubectl get ingress -n airbyte -o jsonpath='{.items[0].spec.rules[0].host}')"
```

### 4. Initial Configuration

1. Open Airbyte UI
2. Complete initial setup wizard
3. Configure first connector
4. Test sync job

## Upgrading Airbyte

### Check for Updates

```bash
./scripts/update-helm-deps.sh
```

### Upgrade Process

```bash
# 1. Update version in ArgoCD app or values
# 2. Test in dev first
./scripts/deploy.sh dev

# 3. Validate functionality
# 4. Deploy to staging
./scripts/deploy.sh staging

# 5. After validation, deploy to prod
./scripts/deploy.sh prod
```

## Rollback Procedure

### Helm Rollback

```bash
# List releases
helm list -n airbyte

# Show history
helm history airbyte -n airbyte

# Rollback to previous version
helm rollback airbyte -n airbyte
```

### ArgoCD Rollback

```bash
# View history
argocd app history airbyte-prod

# Rollback to specific revision
argocd app rollback airbyte-prod <REVISION>
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n airbyte

# Describe problematic pod
kubectl describe pod <pod-name> -n airbyte

# Check logs
kubectl logs <pod-name> -n airbyte
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pods -l app.kubernetes.io/name=postgresql -n airbyte

# Test connection from server pod
kubectl exec -it <server-pod> -n airbyte -- psql -h postgresql -U airbyte
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc -n airbyte

# Check PV status
kubectl get pv
```

## Environment-Specific Notes

### Development

- Auto-deploys on merge to main
- Minimal resources
- Shorter retention periods

### Staging

- Manual promotion from dev
- Production-like configuration
- Full monitoring enabled

### Production

- Manual deployment approval required
- High availability configuration
- Full backups enabled
- Alert on deployment

## Additional Resources

- [Architecture](architecture.md)
- [Troubleshooting](troubleshooting.md)
- [Runbooks](runbooks/)
- [Official Airbyte Docs](https://docs.airbyte.com)

