################################################################################
# Security Group for EKS Cluster
################################################################################

resource "aws_security_group" "cluster" {
  name_prefix = "${local.cluster_name}-cluster-sg-"
  description = "Security group for EKS cluster ${local.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    { Name = "${local.cluster_name}-cluster-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster_egress" {
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
}

