# AWS EKS Terraform Module

This module creates an AWS EKS (Elastic Kubernetes Service) cluster with managed node groups, including all necessary IAM roles, security groups, and supporting infrastructure.

## Features

- **EKS Cluster**: Creates a fully configured EKS cluster with customizable Kubernetes version
- **Managed Node Groups**: Supports multiple node groups with flexible configuration
- **Security**: Envelope encryption for Kubernetes secrets using KMS
- **IAM Roles for Service Accounts (IRSA)**: Enables OIDC provider for secure pod-level IAM permissions
- **EKS Add-ons**: Automatically configures VPC CNI, CoreDNS, kube-proxy, and EBS CSI driver
- **CloudWatch Logging**: Control plane logs sent to CloudWatch
- **Security Groups**: Automatic security group creation with sensible defaults
- **High Availability**: Multi-AZ deployment support

## Usage

### Basic Example

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "my-eks-cluster"
  environment        = "prod"
  kubernetes_version = "1.28"

  vpc_id     = "vpc-0123456789abcdef"
  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1",
    "subnet-0123456789abcdef2"
  ]

  node_groups = {
    default = {
      desired_size   = 3
      min_size       = 2
      max_size       = 5
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Project = "MyProject"
    Owner   = "DevOps"
  }
}
```

### Advanced Example with Multiple Node Groups

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "my-eks-cluster"
  environment        = "prod"
  kubernetes_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint access
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]

  # Multiple node groups for different workloads
  node_groups = {
    # General purpose nodes
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 5
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      labels = {
        workload = "general"
      }
    }

    # Compute-intensive workload nodes
    compute = {
      desired_size   = 2
      min_size       = 1
      max_size       = 10
      instance_types = ["c6i.2xlarge"]
      capacity_type  = "ON_DEMAND"
      labels = {
        workload = "compute"
      }
      taints = [{
        key    = "compute"
        value  = "true"
        effect = "NoSchedule"
      }]
    }

    # Spot instances for cost optimization
    spot = {
      desired_size   = 2
      min_size       = 0
      max_size       = 10
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
      labels = {
        workload = "spot"
      }
    }
  }

  # Enable IRSA for service account authentication
  enable_irsa = true

  # EKS Add-ons
  enable_vpc_cni_addon         = true
  enable_coredns_addon         = true
  enable_kube_proxy_addon      = true
  enable_ebs_csi_driver_addon  = true

  # CloudWatch logging
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 90

  tags = {
    Project     = "MyProject"
    Owner       = "DevOps"
    CostCenter  = "Engineering"
  }
}
```

### Example with Custom KMS Key

```hcl
resource "aws_kms_key" "eks" {
  description             = "EKS cluster encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "my-eks-cluster"
  environment        = "prod"
  kubernetes_version = "1.28"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Use custom KMS key for secrets encryption
  cluster_encryption_config_kms_key_arn = aws_kms_key.eks.arn

  node_groups = {
    default = {
      desired_size   = 3
      instance_types = ["t3.large"]
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0 |
| tls | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| tls | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| vpc_id | VPC ID where the cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster and node groups | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| cluster_endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| cluster_endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| cluster_endpoint_public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| cluster_enabled_log_types | List of control plane logging types to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| cluster_encryption_config_kms_key_arn | KMS key ARN for envelope encryption. If null, a key will be created | `string` | `null` | no |
| kms_key_deletion_window_in_days | The waiting period before deleting the KMS key | `number` | `30` | no |
| kms_key_enable_key_rotation | Enable automatic KMS key rotation | `bool` | `true` | no |
| cloudwatch_log_group_retention_in_days | Number of days to retain log events | `number` | `90` | no |
| cloudwatch_log_group_kms_key_id | KMS key ID for CloudWatch log group encryption | `string` | `null` | no |
| node_groups | Map of EKS managed node group definitions | `map(object)` | See variables.tf | no |
| enable_irsa | Enable IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| enable_vpc_cni_addon | Enable VPC CNI addon | `bool` | `true` | no |
| vpc_cni_addon_version | Version of the VPC CNI addon | `string` | `null` | no |
| enable_coredns_addon | Enable CoreDNS addon | `bool` | `true` | no |
| coredns_addon_version | Version of the CoreDNS addon | `string` | `null` | no |
| enable_kube_proxy_addon | Enable kube-proxy addon | `bool` | `true` | no |
| kube_proxy_addon_version | Version of the kube-proxy addon | `string` | `null` | no |
| enable_ebs_csi_driver_addon | Enable AWS EBS CSI driver addon | `bool` | `true` | no |
| ebs_csi_driver_addon_version | Version of the AWS EBS CSI driver addon | `string` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The name/id of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for your Kubernetes API server |
| cluster_version | The Kubernetes server version for the cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data (sensitive) |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_iam_role_arn | IAM role ARN of the EKS cluster |
| node_iam_role_arn | IAM role ARN of the EKS node groups |
| oidc_provider_arn | ARN of the OIDC Provider for EKS |
| oidc_provider_url | URL of the OIDC Provider for EKS |
| cluster_oidc_issuer_url | The URL on the EKS cluster OIDC Issuer |
| node_groups | Outputs from EKS node groups |
| cloudwatch_log_group_name | Name of the CloudWatch log group for cluster logs |
| kms_key_arn | ARN of the KMS key used for cluster encryption |
| eks_addons | Map of EKS add-ons and their status |

## Post-Deployment Steps

### Configure kubectl

After deploying the cluster, configure kubectl to access it:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### Verify Cluster

```bash
# Check cluster status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check add-ons
kubectl get daemonset -n kube-system
```

## Node Group Configuration

### Instance Types

Choose appropriate instance types based on your workload:
- **General Purpose**: t3.medium, t3.large, m5.large
- **Compute Optimized**: c5.xlarge, c6i.2xlarge
- **Memory Optimized**: r5.large, r6i.xlarge
- **GPU**: p3.2xlarge, g4dn.xlarge

### Capacity Types

- **ON_DEMAND**: Standard EC2 instances with predictable pricing
- **SPOT**: Discounted instances that can be interrupted

### Taints and Labels

Use taints and labels to control pod scheduling:

```hcl
node_groups = {
  gpu = {
    instance_types = ["g4dn.xlarge"]
    labels = {
      "workload" = "gpu"
      "gpu-type" = "nvidia-t4"
    }
    taints = [{
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NoSchedule"
    }]
  }
}
```

## Security Considerations

1. **Network Access**: Limit `cluster_endpoint_public_access_cidrs` to known IP ranges
2. **Encryption**: Secrets are encrypted at rest using KMS
3. **IAM**: Use IRSA instead of node-level IAM roles for workloads
4. **Logging**: Enable all control plane logs for audit trail
5. **Updates**: Regularly update Kubernetes version and add-ons

## IAM Roles for Service Accounts (IRSA)

IRSA allows Kubernetes service accounts to assume IAM roles. Example:

```hcl
# After deploying the EKS cluster with enable_irsa = true

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::my-bucket/*"]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "my-app-s3-access"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role" "my_app" {
  name = "my-app-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:default:my-app"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "my_app" {
  role       = aws_iam_role.my_app.name
  policy_arn = aws_iam_policy.s3_access.arn
}
```

Then in Kubernetes:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/my-app-irsa-role
```

## Troubleshooting

### Nodes Not Joining Cluster

1. Check node IAM role has required policies
2. Verify subnet IDs are correct
3. Check security group rules
4. Review CloudWatch logs

### Add-on Installation Failures

```bash
# Check add-on status
aws eks describe-addon --cluster-name <cluster-name> --addon-name vpc-cni

# View add-on issues
kubectl get pods -n kube-system
kubectl describe pod <pod-name> -n kube-system
```

### IRSA Not Working

1. Verify OIDC provider is created
2. Check service account annotation
3. Verify IAM role trust policy
4. Check pod has correct service account

## Cost Optimization

1. Use **Spot instances** for non-critical workloads
2. Enable **Cluster Autoscaler** to scale nodes based on demand
3. Use **Karpenter** for advanced autoscaling
4. Right-size node instance types
5. Use **Savings Plans** or **Reserved Instances** for predictable workloads

## Maintenance

### Upgrading Kubernetes Version

```hcl
# Update module configuration
kubernetes_version = "1.29"

# Plan and apply
terraform plan
terraform apply
```

### Updating Add-ons

```bash
# List available versions
aws eks describe-addon-versions --addon-name vpc-cni

# Update in Terraform
vpc_cni_addon_version = "v1.15.0-eksbuild.2"
```

## License

This module is part of the Airbyte Solutions Deployments infrastructure.

