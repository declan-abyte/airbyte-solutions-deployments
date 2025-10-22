# EKS Cluster Outputs

################################################################################
# Cluster
################################################################################

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster (CREATING, ACTIVE, DELETING, FAILED)"
  value       = aws_eks_cluster.this.status
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

################################################################################
# IAM Role
################################################################################

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "IAM role name of the EKS node groups"
  value       = aws_iam_role.node.name
}

################################################################################
# OIDC Provider
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}

################################################################################
# Node Groups
################################################################################

output "node_groups" {
  description = "Outputs from EKS node groups"
  value = {
    for k, v in aws_eks_node_group.this : k => {
      id                = v.id
      arn               = v.arn
      status            = v.status
      capacity_type     = v.capacity_type
      instance_types    = v.instance_types
      scaling_config    = v.scaling_config
      remote_access_sg  = v.remote_access
    }
  }
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.this.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.this.arn
}

################################################################################
# KMS
################################################################################

output "kms_key_arn" {
  description = "ARN of the KMS key used for cluster encryption"
  value       = try(aws_kms_key.eks[0].arn, var.cluster_encryption_config_kms_key_arn)
}

output "kms_key_id" {
  description = "ID of the KMS key used for cluster encryption"
  value       = try(aws_kms_key.eks[0].key_id, null)
}

################################################################################
# EKS Add-ons
################################################################################

output "eks_addons" {
  description = "Map of EKS add-ons and their status"
  value = merge(
    var.enable_vpc_cni_addon ? {
      vpc_cni = {
        arn     = aws_eks_addon.vpc_cni[0].arn
        version = aws_eks_addon.vpc_cni[0].addon_version
      }
    } : {},
    var.enable_coredns_addon ? {
      coredns = {
        arn     = aws_eks_addon.coredns[0].arn
        version = aws_eks_addon.coredns[0].addon_version
      }
    } : {},
    var.enable_kube_proxy_addon ? {
      kube_proxy = {
        arn     = aws_eks_addon.kube_proxy[0].arn
        version = aws_eks_addon.kube_proxy[0].addon_version
      }
    } : {},
    var.enable_ebs_csi_driver_addon ? {
      ebs_csi_driver = {
        arn     = aws_eks_addon.ebs_csi_driver[0].arn
        version = aws_eks_addon.ebs_csi_driver[0].addon_version
      }
    } : {}
  )
}

################################################################################
# VPC CNI
################################################################################

output "vpc_cni_iam_role_arn" {
  description = "ARN of IAM role for VPC CNI"
  value       = var.enable_vpc_cni_addon ? aws_iam_role.vpc_cni[0].arn : null
}

output "vpc_cni_iam_role_name" {
  description = "Name of IAM role for VPC CNI"
  value       = var.enable_vpc_cni_addon ? aws_iam_role.vpc_cni[0].name : null
}

################################################################################
# EBS CSI Driver
################################################################################

output "ebs_csi_driver_iam_role_arn" {
  description = "ARN of IAM role for EBS CSI driver"
  value       = var.enable_ebs_csi_driver_addon ? aws_iam_role.ebs_csi_driver[0].arn : null
}

output "ebs_csi_driver_iam_role_name" {
  description = "Name of IAM role for EBS CSI driver"
  value       = var.enable_ebs_csi_driver_addon ? aws_iam_role.ebs_csi_driver[0].name : null
}

################################################################################
# AWS Load Balancer Controller
################################################################################

# output "aws_load_balancer_controller_iam_role_arn" {
#   description = "ARN of IAM role for AWS Load Balancer Controller"
#   value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
# }

# output "aws_load_balancer_controller_iam_role_name" {
#   description = "Name of IAM role for AWS Load Balancer Controller"
#   value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].name : null
# }

