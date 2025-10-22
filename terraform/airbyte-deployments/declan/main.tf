provider "aws" {
  region = var.aws_region
}

# Kubernetes and Helm providers configuration
# These providers need to authenticate to the EKS cluster
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

################################################################################
# VPC   
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Kubernetes tags for subnet discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = var.tags
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  # Cluster endpoint access
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.allowed_cidr_blocks

  # EKS Add-ons
  enable_vpc_cni_addon        = true
  enable_coredns_addon        = true
  enable_kube_proxy_addon     = true
  enable_ebs_csi_driver_addon = true

  # KMS encryption
  kms_key_deletion_window_in_days = 30
  kms_key_enable_key_rotation     = true

  tags = var.tags
}

################################################################################
# AWS Load Balancer Controller
################################################################################

module "aws_load_balancer_controller" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  chart            = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart_version    = null
  namespace        = "kube-system"
  create_namespace = false

  set = [
    { name = "clusterName", value = module.eks.cluster_id },
    { name = "serviceAccount.create", value = true },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn",
      value = module.load_balancer_controller_irsa_role.iam_role_arn
    }
  ]

  # Reusing existing IRSA role → do not create a new one here
  create_role = false

  tags = var.tags
}

################################################################################
# Additional IAM Roles (IRSA)
################################################################################

module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.60"

  role_name = "${var.cluster_name}-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}