# Terraform Infrastructure

This directory contains Terraform configurations for provisioning and managing the Kubernetes clusters and supporting infrastructure for Airbyte.

## Structure

```
terraform/
├── clusters/           # Cluster definitions
│   ├── dev/
│   ├── staging/
│   └── prod/
└── modules/           # Reusable Terraform modules
    ├── eks/          # AWS EKS module
    ├── gke/          # GCP GKE module
    └── aks/          # Azure AKS module
```

## Prerequisites

- Terraform v1.5+
- Cloud provider CLI configured
- Appropriate cloud provider credentials

## Usage

```bash
# Navigate to environment
cd clusters/prod

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## State Management

Terraform state is stored remotely:
- **Backend**: S3/GCS/Azure Storage
- **State Locking**: DynamoDB/Cloud Storage
- **Encryption**: Enabled

## Example Cluster Module

See `modules/` directory for example cluster configurations for:
- AWS EKS
- Google GKE
- Azure AKS

## Best Practices

1. Always run `terraform plan` before `apply`
2. Use workspaces for environment separation
3. Store state remotely with locking
4. Use modules for reusability
5. Version pin providers
6. Tag all resources appropriately

