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

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.eks_cluster_name
  }

  tags = local.default_tags
}

resource "aws_launch_template" "ng_gp3" {
  name_prefix = "${local.cluster_name}-ng-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 8
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }
  }
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "21.15.1"
  name               = local.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = false

  enable_irsa = true

  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  node_security_group_tags = merge(local.default_tags, {
    "karpenter.sh/discovery" = local.eks_cluster_name
  })

  eks_managed_node_groups = {
    general = {
      name           = "opsly-general-${var.environment}"
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium", "t3.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      subnet_ids     = module.vpc.private_subnets
      launch_template = {
        id      = aws_launch_template.ng_gp3.id
        version = aws_launch_template.ng_gp3.latest_version
      }

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        workload                  = "general"
        "karpenter.sh/controller" = "true"
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

      launch_template = {
        id      = aws_launch_template.ng_gp3.id
        version = aws_launch_template.ng_gp3.latest_version
      }

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        workload = "ml"
      }
      tags = local.default_tags
    }
  }

  addons = {
    coredns = {
      most_recent    = true
      before_compute = true

    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent    = true
      before_compute = true
    }
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi.arn
    }
  }
  tags = local.default_tags
}
