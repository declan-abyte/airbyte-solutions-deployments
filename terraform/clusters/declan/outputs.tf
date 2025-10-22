################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

################################################################################
# EKS Cluster Outputs
################################################################################

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

################################################################################
# IAM Outputs
################################################################################

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = module.eks.node_iam_role_arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_url
}

################################################################################
# IRSA Role Outputs
################################################################################

output "load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.load_balancer_controller_irsa_role.iam_role_arn
}

# output "external_dns_role_arn" {
#   description = "IAM role ARN for External DNS"
#   value       = module.external_dns_irsa_role.iam_role_arn
# }

# output "cluster_autoscaler_role_arn" {
#   description = "IAM role ARN for Cluster Autoscaler"
#   value       = module.cluster_autoscaler_irsa_role.iam_role_arn
# }

# output "app_role_arn" {
#   description = "IAM role ARN for custom application"
#   value       = aws_iam_role.app_role.arn
# }

################################################################################
# Node Groups Outputs
################################################################################

output "node_groups" {
  description = "Outputs from EKS node groups"
  value       = module.eks.node_groups
}

################################################################################
# Configuration Commands
################################################################################

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}

output "get_token" {
  description = "Command to get authentication token"
  value       = "aws eks get-token --cluster-name ${module.eks.cluster_id}"
}

