locals {
  cluster_name = "${var.project_name}-eks-${var.environment}"
  default_tags = {
    environment = var.environment
    account     = var.account
    project     = var.project_name
    managed_by  = "terraform"
  }
}
