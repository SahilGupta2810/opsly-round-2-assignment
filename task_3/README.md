---

# Brompton Energy Infrastructure as Code

This repository contains the Terraform configurations for setting up the infrastructure required by Brompton Energy. The infrastructure includes networking components, an EKS cluster, IAM roles for service accounts, EFS, and ECR repositories.

## Networking: Virtual Private Cloud (VPC)

- **Module "vpc"**: Creates a VPC using the `terraform-aws-modules/vpc/aws` module with version `6.6.0`.
- **CIDR**: `10.0.0.0/16`
- **Subnets**: The configuration defines both private (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`) and public (`10.0.4.0/24`, `10.0.5.0/24`, `10.0.6.0/24`) subnets spread across 3 availability zones.
- **NAT Gateway**: Enabled to allow instances in the private subnets to initiate outbound traffic to the internet.
- **DNS Hostnames**: Enabled for the VPC.

## Kubernetes: Amazon Elastic Kubernetes Service (EKS)

- **Module "eks"**: Creates an EKS cluster using the `terraform-aws-modules/eks/aws` module with version `21.15.1`.
- **Version**: Kubernetes version is configurable via `kubernetes_version`.
- **Node Groups**: Managed node groups for `general` and `ml` workloads with autoscaling bounds (min/max), and an ML taint to isolate ML workloads.

## Karpenter (EKS)

Karpenter is a Kubernetes node lifecycle manager. It watches for **unschedulable pods** (pods stuck in `Pending`) and provisions **new EC2 instances** that best satisfy the pods’ requirements (CPU/memory, instance type constraints, topology, taints/tolerations, etc). It can also **consolidate** and remove nodes when they’re empty/underutilized.

### What’s required

1. **A “base” node group for the Karpenter controller**
   - Best practice: run the Karpenter controller on nodes that Karpenter does *not* manage (so it can always make progress).
   - In this repo, the `general` managed node group is labeled and the Helm chart uses a `nodeSelector` so the controller lands there.

2. **Discovery tags on subnets and the node security group**
   - Karpenter discovers where it’s allowed to launch instances using tags:
     - `karpenter.sh/discovery = opsly-dev`

3. **Controller IAM + node IAM**
   - Controller role: permissions to launch/terminate instances, read pricing/instance info, manage interruption handling, etc.
   - Node role: standard EKS worker policies so nodes can join the cluster and pull images.
   - This repo uses the EKS module Karpenter sub-module to create the controller role + node role + access entry + interruption queue.

4. **Interruption handling (recommended)**
   - SQS queue + EventBridge rules so Karpenter can react to Spot interruptions / rebalance recommendations / health events.

5. **At least one `EC2NodeClass` + `NodePool`**
   - Karpenter won’t launch anything until a `NodePool` references a `NodeClass`.
   - See `karpenter-resources.yaml` (replace `<cluster-name>` with your EKS cluster name; for `dev.tfvars` it’s `opsly-dev`).

### How it fits with HPA

- **HPA** adds/removes **pods** when metrics (CPU/memory/custom) cross a threshold.
- **Karpenter** adds/removes **nodes** so pending pods can schedule, and can bin-pack/consolidate nodes to reduce cost.

## AWS Load Balancer Controller (ALB/NLB)

The controller is installed and managed outside of this Terraform directory (you handled it manually). The core requirements are:

- Subnets still need the usual discovery tags (`kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`, `kubernetes.io/cluster/<cluster-name>`).
- A Kubernetes ServiceAccount in `kube-system` annotated with the IRSA role that has ELB/EC2 permissions.
- The controller Helm release itself (pointed at the AWS charts) must be deployed into `kube-system`.

Those pieces aren’t represented as Terraform resources anymore, so you won’t find `aws-load-balancer-controller.tf`, `crds.yaml`, or `iam_policy.json` in this directory.

## IAM Roles for Service Accounts (IRSA)

- IRSA is enabled on the EKS cluster (`enable_irsa = true`).
- EBS CSI driver uses IRSA via `kube-system:ebs-csi-controller-sa` with the `AmazonEBSCSIDriverPolicy`.
- Karpenter uses EKS Pod Identity (requires the `eks-pod-identity-agent` add-on) rather than an IRSA-annotated ServiceAccount.

## File System: Amazon Elastic File System (EFS)

- **Module "efs"**: Provisions an EFS file system with the `terraform-aws-modules/efs/aws`.
- **Encryption**: Enables encryption for the file system.
- **Backup**: Configures backup policies for the file system.
- **Mount Targets**: Creates mount targets for the file system in the subnets specified.

## Container Registry: Amazon Elastic Container Registry (ECR)

- **Resources**: `aws_ecr_repository` to create ECR repositories for different components like the Python API and FullStack applications.
- **Image Scanning**: Configures scanning on push for images to identify vulnerabilities.

With the provided `tfvars` file contents, you can proceed to document how to use these variables in your Terraform setup. The `.tfvars` file is used to pass environment-specific values into your Terraform configuration.

Here's an updated section for your GitHub document, including instructions on how to use your `tfvars` file:

---

## Configuration Variables

The infrastructure is configurable via environment-specific variables defined in a `.tfvars` file. Here's an example of what's included in `dev.tfvars` for the development environment:

```hcl
# dev.tfvars
environment = "dev"
account = "devops"
python-api-ecr = "opsly/python-api"
fullstack-ecr = "opsly/fullstack"
```

These variables are used to tailor the infrastructure resources to the specific needs of the environment, such as development (`dev`), staging (`staging`), or production (`prod`).

## Applying Configuration with Variable Files

To apply the Terraform configuration with the development environment settings, use the following command:

```sh
terraform apply -var-file="dev.tfvars" -auto-approve
```

This command references the `dev.tfvars` file which should be located in the same directory as your Terraform configuration files or in a directory structure based on your preference (e.g., `./tfvars/dev.tfvars`).

## Important Notes

- **Review Changes**: Always review the changes that will be applied with `terraform plan -var-file="dev.tfvars"` before proceeding with `terraform apply`.
- **Auto-approve Caution**: The `-auto-approve` flag will apply changes without prompting for confirmation. This should be used with caution, especially in production environments.

---

Please ensure to add this information to the appropriate section of your GitHub documentation. Always provide guidance on the proper use and potential risks when using `-auto-approve` in Terraform commands, and ensure that the instructions are clear on where the `tfvars` file should be placed and how it should be named for different environments.

## Usage

To deploy this infrastructure:

1. Ensure you have the correct AWS credentials configured.
2. Run `terraform init` to initialize the working directory containing the Terraform configuration files.
3. Review the execution plan with `terraform plan -var-file="./tfvars/dev.tfvars"`.
4. Apply the desired changes with the Terraform apply command:
   
   ```shell
   terraform apply -var-file="./tfvars/dev.tfvars" -auto-approve
   ```

## Caution

Using the `-auto-approve` flag with `terraform apply` will bypass interactive approval. It's recommended for non-production or CI/CD automation. Always review your changes in a safe environment before applying to production.

## Contributing

To contribute to this project:

1. Clone the repository.
2. Create a feature branch.
3. Commit your changes.
4. Create a pull request against the main branch.

For any changes in the infrastructure, please make sure to run a `terraform plan` and include the output in the pull request description.

---


terraform plan --var-file='./tfvars/prod.tfvars' -target='module.eks.module.eks_managed_node_group["atmoz"]'
