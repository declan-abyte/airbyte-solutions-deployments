# ################################################################################
# # IAM Role for AWS Load Balancer Controller (IRSA)
# ################################################################################

# resource "aws_iam_role" "aws_load_balancer_controller" {
#   count = var.enable_aws_load_balancer_controller ? 1 : 0

#   name               = "${local.cluster_name}-aws-lb-controller-role"
#   assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy[0].json

#   tags = merge(
#     local.common_tags,
#     { Name = "${local.cluster_name}-aws-lb-controller-role" }
#   )
# }

# data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
#   count = var.enable_aws_load_balancer_controller ? 1 : 0

#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.cluster.arn]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
#       values   = ["sts.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_policy" "aws_load_balancer_controller" {
#   count = var.enable_aws_load_balancer_controller ? 1 : 0

#   name        = "${local.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
#   description = "IAM policy for AWS Load Balancer Controller"
#   policy      = data.aws_iam_policy_document.aws_load_balancer_controller_policy[0].json

#   tags = local.common_tags
# }

# data "aws_iam_policy_document" "aws_load_balancer_controller_policy" {
#   count = var.enable_aws_load_balancer_controller ? 1 : 0

#   # EC2 permissions
#   statement {
#     sid    = "EC2Permissions"
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeAccountAttributes",
#       "ec2:DescribeAddresses",
#       "ec2:DescribeAvailabilityZones",
#       "ec2:DescribeInternetGateways",
#       "ec2:DescribeVpcs",
#       "ec2:DescribeVpcPeeringConnections",
#       "ec2:DescribeSubnets",
#       "ec2:DescribeSecurityGroups",
#       "ec2:DescribeInstances",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DescribeTags",
#       "ec2:GetCoipPoolUsage",
#       "ec2:DescribeCoipPools"
#     ]
#     resources = ["*"]
#   }

#   # EC2 modify permissions
#   statement {
#     sid    = "EC2ModifyPermissions"
#     effect = "Allow"
#     actions = [
#       "ec2:CreateSecurityGroup",
#       "ec2:CreateTags"
#     ]
#     resources = ["arn:aws:ec2:*:*:security-group/*"]
#     condition {
#       test     = "StringEquals"
#       variable = "ec2:CreateAction"
#       values   = ["CreateSecurityGroup"]
#     }
#   }

#   statement {
#     sid    = "EC2SecurityGroupPermissions"
#     effect = "Allow"
#     actions = [
#       "ec2:CreateTags",
#       "ec2:DeleteTags"
#     ]
#     resources = ["arn:aws:ec2:*:*:security-group/*"]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     sid    = "EC2SecurityGroupModify"
#     effect = "Allow"
#     actions = [
#       "ec2:AuthorizeSecurityGroupIngress",
#       "ec2:RevokeSecurityGroupIngress",
#       "ec2:DeleteSecurityGroup"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   # ELBv2 permissions
#   statement {
#     sid    = "ELBv2Permissions"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:DescribeLoadBalancers",
#       "elasticloadbalancing:DescribeLoadBalancerAttributes",
#       "elasticloadbalancing:DescribeListeners",
#       "elasticloadbalancing:DescribeListenerCertificates",
#       "elasticloadbalancing:DescribeSSLPolicies",
#       "elasticloadbalancing:DescribeRules",
#       "elasticloadbalancing:DescribeTargetGroups",
#       "elasticloadbalancing:DescribeTargetGroupAttributes",
#       "elasticloadbalancing:DescribeTargetHealth",
#       "elasticloadbalancing:DescribeTags"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "ELBv2CreatePermissions"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:CreateLoadBalancer",
#       "elasticloadbalancing:CreateTargetGroup"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     sid    = "ELBv2TagPermissions"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:CreateListener",
#       "elasticloadbalancing:DeleteListener",
#       "elasticloadbalancing:CreateRule",
#       "elasticloadbalancing:DeleteRule"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "ELBv2ModifyPermissions"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:AddTags",
#       "elasticloadbalancing:RemoveTags"
#     ]
#     resources = [
#       "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#       "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#       "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#     ]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["true"]
#     }
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     sid    = "ELBv2AddTagsAtCreation"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:AddTags",
#       "elasticloadbalancing:RemoveTags"
#     ]
#     resources = [
#       "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#       "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#       "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#     ]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     sid    = "ELBv2DeletePermissions"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:ModifyLoadBalancerAttributes",
#       "elasticloadbalancing:SetIpAddressType",
#       "elasticloadbalancing:SetSecurityGroups",
#       "elasticloadbalancing:SetSubnets",
#       "elasticloadbalancing:DeleteLoadBalancer",
#       "elasticloadbalancing:ModifyTargetGroup",
#       "elasticloadbalancing:ModifyTargetGroupAttributes",
#       "elasticloadbalancing:DeleteTargetGroup"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     sid    = "ELBv2TargetPermissions"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:AddListenerCertificates",
#       "elasticloadbalancing:RemoveListenerCertificates",
#       "elasticloadbalancing:ModifyListener",
#       "elasticloadbalancing:ModifyRule"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "ELBv2RegisterTargets"
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:RegisterTargets",
#       "elasticloadbalancing:DeregisterTargets"
#     ]
#     resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]
#   }

#   # Shield, WAF, Certificate Manager, Cognito
#   statement {
#     sid    = "AdditionalAWSServices"
#     effect = "Allow"
#     actions = [
#       "shield:GetSubscriptionState",
#       "shield:DescribeProtection",
#       "shield:CreateProtection",
#       "shield:DeleteProtection"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "WAFPermissions"
#     effect = "Allow"
#     actions = [
#       "wafv2:GetWebACL",
#       "wafv2:GetWebACLForResource",
#       "wafv2:AssociateWebACL",
#       "wafv2:DisassociateWebACL"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "WAFRegionalPermissions"
#     effect = "Allow"
#     actions = [
#       "waf-regional:GetWebACLForResource",
#       "waf-regional:GetWebACL",
#       "waf-regional:AssociateWebACL",
#       "waf-regional:DisassociateWebACL"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid       = "ACMPermissions"
#     effect    = "Allow"
#     actions   = ["acm:ListCertificates", "acm:DescribeCertificate"]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "CognitoPermissions"
#     effect = "Allow"
#     actions = [
#       "cognito-idp:DescribeUserPoolClient"
#     ]
#     resources = ["*"]
#   }

#   # IAM permissions for service-linked roles
#   statement {
#     sid       = "IAMPermissions"
#     effect    = "Allow"
#     actions   = ["iam:CreateServiceLinkedRole"]
#     resources = ["*"]
#     condition {
#       test     = "StringEquals"
#       variable = "iam:AWSServiceName"
#       values   = ["elasticloadbalancing.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
#   count = var.enable_aws_load_balancer_controller ? 1 : 0

#   policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
#   role       = aws_iam_role.aws_load_balancer_controller[0].name
# }

