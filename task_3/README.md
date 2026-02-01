---

# Brompton Energy Infrastructure as Code

This repository contains the Terraform configurations for setting up the infrastructure required by Brompton Energy. The infrastructure includes networking components, an EKS cluster, IAM roles for service accounts, EFS, and ECR repositories.

## Networking: Virtual Private Cloud (VPC)

- **Module "vpc"**: Creates a VPC using the `terraform-aws-modules/vpc/aws` module with version `5.0.0`.
- **CIDR**: `10.0.0.0/16`
- **Subnets**: The configuration defines both private (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`) and public (`10.0.4.0/24`, `10.0.5.0/24`, `10.0.6.0/24`) subnets spread across 3 availability zones.
- **NAT Gateway**: Enabled to allow instances in the private subnets to initiate outbound traffic to the internet.
- **DNS Hostnames**: Enabled for the VPC.

## Kubernetes: Amazon Elastic Kubernetes Service (EKS)

- **Module "eks"**: Creates an EKS cluster using the `terraform-aws-modules/eks/aws` module with version `19.17.2`.
- **Version**: Specifies Kubernetes version `1.28`.
- **Node Groups**: Defines several managed node groups with varying configurations, mainly using spot instances.

## IAM Roles for Service Accounts (IRSA)

- **Modules**: `efs_csi_irsa_role` and `irsa-ebs-csi` to create IAM roles for the EFS and EBS CSI drivers, respectively.
- **Policies**: Attaches the necessary AWS-managed policies for EBS and EFS CSI drivers to function correctly.

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