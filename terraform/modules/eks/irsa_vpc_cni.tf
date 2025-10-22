################################################################################
# IAM Role for VPC CNI (IRSA)
################################################################################

resource "aws_iam_role" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  name               = "${local.cluster_name}-vpc-cni-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role_policy[0].json

  tags = merge(
    local.common_tags,
    { Name = "${local.cluster_name}-vpc-cni-role" }
  )
}

data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}

