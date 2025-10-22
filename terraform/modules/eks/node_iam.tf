################################################################################
# IAM Role for EKS Node Groups
################################################################################

resource "aws_iam_role" "node" {
  name               = "${local.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    sid = "EKSNodeAssumeRole"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# Note: AmazonEKS_CNI_Policy is now managed via IRSA (see VPC CNI IAM role above)
# This follows AWS best practices for least privilege access

