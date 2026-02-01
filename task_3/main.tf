# # KMS key for EKS secrets encryption
# resource "aws_kms_key" "eks_secrets" {
#   description             = "KMS key for EKS secrets encryption (${local.cluster_name})"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AllowAccountRootFullAccess"
#         Effect    = "Allow"
#         Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
#         Action    = "kms:*"
#         Resource  = "*"
#       },
#       {
#         Sid       = "AllowEKSUseViaService"
#         Effect    = "Allow"
#         Principal = { AWS = "*" }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "kms:CallerAccount" = data.aws_caller_identity.current.account_id
#           }
#           StringLike = {
#             "kms:ViaService" = "eks.${data.aws_region.current.name}.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })

#   tags = local.default_tags
# }

# resource "aws_kms_alias" "eks_secrets" {
#   name          = "alias/eks-${var.environment}-secrets"
#   target_key_id = aws_kms_key.eks_secrets.key_id
# }

# # Secrets Manager containers (values managed out-of-band)
# resource "aws_secretsmanager_secret" "managed" {
#   for_each = toset(var.secrets_manager_secret_names)

#   name        = each.value
#   description = "Managed by Terraform; secret value set out-of-band"

#   tags = local.default_tags
# }

# # ECR private repositories
# resource "aws_ecr_repository" "private" {
#   for_each = toset(var.ecr_repository_names)

#   name                 = each.value
#   image_tag_mutability = "IMMUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   tags = local.default_tags
# }

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "${var.project_name}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "21.15.1"
  name               = "${var.project_name}-${var.environment}"
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = false

  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  eks_managed_node_groups = {
    general = {
      name           = "opsly-general-${var.environment}"
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium", "t3.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      subnet_ids     = module.vpc.private_subnets

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        workload = "general"
      }
      tags = local.default_tags
    }

    ml = {
      name           = "opsly-ml-${var.environment}"
      capacity_type  = "ON_DEMAND"
      instance_types = ["c5.xlarge", "m5.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      subnet_ids     = module.vpc.private_subnets

      update_config = {
        max_unavailable_percentage = 33
      }

      taints = {
        ml = {
          key    = "ml"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
      labels = {
        workload = "ml"
      }
      tags = local.default_tags
    }
  }

  tags = local.default_tags
}
