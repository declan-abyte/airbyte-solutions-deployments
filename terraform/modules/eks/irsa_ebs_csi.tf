################################################################################
# IAM Role for EBS CSI Driver (IRSA)
################################################################################

resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver_addon ? 1 : 0

  name               = "${local.cluster_name}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy[0].json

  tags = merge(
    local.common_tags,
    { Name = "${local.cluster_name}-ebs-csi-driver-role" }
  )
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role_policy" {
  count = var.enable_ebs_csi_driver_addon ? 1 : 0

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
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  count = var.enable_ebs_csi_driver_addon ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}