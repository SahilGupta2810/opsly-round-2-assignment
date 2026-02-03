# Task 3 — Kubernetes Infrastructure (Terraform)

This folder contains Terraform for **Part 3: Kubernetes Infrastructure** (VPC + EKS + node scaling primitives) for the AI Chatbot Framework deployment.

## Completion status (Task 3.1)

| Requirement | Status | Notes |
| --- | --- | --- |
| EKS cluster version 1.29+ | Done | Configurable via `kubernetes_version` (example in `tfvars/dev.tfvars` is `1.32`). |
| Managed node groups (general + ML) | Done | See `main.tf` (`general` t3.medium/large and `ml` c5.xlarge/m5.large). |
| VPC w/ public + private subnets across 3 AZs | Done | Implemented via `terraform-aws-modules/vpc/aws`. |
| NAT Gateway for private subnet egress | Done | Enabled in `main.tf`. |
| EKS add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI) | Done | Configured in `main.tf` under `module.eks.addons`. |
| IRSA enabled | Done | `enable_irsa = true` plus IRSA role for EBS CSI (see `iam-irsa.tf`). |
| Cluster autoscaler configured | Partial | Node scaling is implemented via **Karpenter** (`karpenter.tf`), not the Kubernetes Cluster Autoscaler chart. |
| AWS Load Balancer Controller installed | Manual | Expected to be installed separately (subnet tags are already present in `main.tf`). |
| “Other infra” (S3/DB/Lambda/etc.) | Not done | Not implemented in this folder. |

## Task 3.2 (Helm charts)

Not included in this repository/folder.

## What’s in this folder

- `main.tf` — VPC + EKS cluster + managed node groups + add-ons.
- `iam-irsa.tf` — IRSA role for the EBS CSI driver.
- `karpenter.tf` — Karpenter module + Helm release (node scaling alternative).
- `karpenter-resources.yaml` — example `EC2NodeClass` / `NodePool` to apply after install (edit cluster-specific values).
- `tfvars/dev.tfvars` — example variable values for a dev cluster.

## Quick start

```bash
cd task_3
terraform init
terraform plan -var-file=./tfvars/dev.tfvars
terraform apply -var-file=./tfvars/dev.tfvars
```

After apply, configure Karpenter resources (edit first):

```bash
kubectl apply -f karpenter-resources.yaml
```

## Notes

- `errored.tfstate` is a captured local state/error artifact; do not use it as a real backend for shared environments.
