output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

output "private_subnets" {
  description = "value of private subnets created in cluster"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# output "secrets_manager_secret_arns" {
#   description = "ARNs of Secrets Manager secrets created by Terraform"
#   value       = { for k, v in aws_secretsmanager_secret.managed : k => v.arn }
# }

# output "ecr_repository_arns" {
#   description = "ARNs of ECR repositories created by Terraform"
#   value       = { for k, v in aws_ecr_repository.private : k => v.arn }
# }
