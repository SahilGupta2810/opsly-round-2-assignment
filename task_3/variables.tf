# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "opsly"
}

variable "account" {
  description = "Account or tenant identifier used for tagging"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Retention in days for the EKS control plane log group"
  type        = number
}

variable "karpenter_chart_version" {
  description = "Helm chart version for Karpenter"
  type        = string
  default     = "1.6.0"
}
