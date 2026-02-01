# DevOps Technical Assessment

## AI Chatbot Framework - AWS Deployment
 
**Repository:** https://github.com/alfredfrancis/ai-chatbot-framework

---

## Overview

You are tasked with designing and implementing a production-ready AWS infrastructure for the AI Chatbot Framework - an open-source, self-hosted chatbot platform.

The application consists of the following components:
- **Frontend**: React/Next.js application (Admin Dashboard & Chat Interface)
- **Backend**: Python FastAPI application (NLU, ML models, REST API)
- **Database**: MongoDB (conversation logs, bot configurations, training data)
- **Gateway**: Nginx reverse proxy

---

## Part 1: Architecture Design

### Task 1.1: Service Analysis & Infrastructure Selection

Analyze each service and recommend the optimal AWS infrastructure.

For each service, justify your choice between:
- **Compute**: Lambda, ECS Fargate, ECS EC2, EKS, App Runner
- **Database**: RDS, DynamoDB, MongoDB Atlas
- **Caching**: ElastiCache Redis/Memcached
- **Messaging**: SQS, SNS, EventBridge
- **Storage**: S3, EFS, EBS

**Deliverable:**:
- Service-by-service infrastructure recommendations
- Ensure to consider various architectures such as containers/serverless for the different services and the reasoning...
- Justification for each choice
- Cost considerations
- Scaling strategy

#### Remapping Table (Local → AWS)

| Local Service Name | Local Setup - How it runs locally | AWS Service | AWS Choice Reasoning | Alternate AWS Suggestion with scenario |
| --- | --- | --- | --- | --- |
| UI | Localhost dev server (e.g., `npm run dev`) or container | App Runner | Managed container with autoscaling; good fit for Next.js SSR without managing cluster | S3 + CloudFront if the UI is fully static and can be built to static assets |
| Backend | FastAPI on localhost or container (`uvicorn`) | ECS Fargate | Serverless containers, easy autoscaling, no node management | EKS if you want a single Kubernetes platform for UI + backend + ML workloads |
| DB | MongoDB on localhost or Docker | MongoDB Atlas | Managed MongoDB with API compatibility and backups; minimal operational overhead | DynamoDB if you can redesign data model for serverless scale and lower ops |
| LLM Inference (e.g., Ollama) | Local inference server on localhost or container | EKS (GPU node group) | GPU scheduling, stable long-running inference pods, fits shared cluster | ECS EC2 with GPU if you want simpler ops without Kubernetes |
| Caching | Redis in local container or in-memory cache | ElastiCache Redis | Managed Redis with HA and scaling | ElastiCache Memcached if you only need ephemeral cache and simple sharding |

---

## Part 2: AWS Account Structure & Security

### Task 2.1: Multi-Account Structure

This is the first application being deployed to AWS, so propose an AWS account structure with environments (i.e. sandbox, dev, prod) and appropriate security that I can run this application in production.

**Requirements:**
- Separate accounts for i.e. Management, Security/Audit, Shared Services, Development, Sandbox, UAT, Production
- Suggest AWS Control Tower or Organizations with SCPs
- SSO for giving developer teams access to the Cloud and what types of permissions they would need
- Any security services such as Centralised logging, GuardDuty, Config, CloudTrail, SecurityHub etc...

**Deliverable:**
Give a detailed explanation of this.

---

## Part 3: Kubernetes Infrastructure

### Task 3.1: EKS Cluster with Terraform

Create an EKS cluster suitable for the AI Chatbot Framework.

**Requirements:**
- EKS cluster version 1.29+
- Managed node groups with:
  - General workloads: t3.medium/large (2-5 nodes, auto-scaling)
  - ML workloads: c5.xlarge or m5.large (1-3 nodes, auto-scaling)
- VPC with public and private subnets across 3 AZs
- NAT Gateway for private subnet egress
- EKS add-ons: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- IRSA (IAM Roles for Service Accounts) enabled
- Cluster autoscaler configured
- AWS Load Balancer Controller installed

For all the other infrastructure create the relevant Terraform infrastructure such as S3, Databases, Lambda's etc... required

### Task 3.2: Helm Charts

Create Helm charts for deploying the AI Chatbot Framework.

**Requirements:**
- Parent chart with subcharts for each component
- Configurable values for different environments (dev, staging, prod)
- Resource requests/limits appropriate for ML workloads
- Health checks (liveness, readiness probes)
- Horizontal Pod Autoscaler configurations
- ConfigMaps and Secrets management
- Ingress configuration with TLS
- MongoDB can use Bitnami helm chart as dependency or connect to DocumentDB

---

## Part 4: GitOps with ArgoCD

### Task 4.1: ArgoCD Installation

Deploy ArgoCD to the EKS cluster.

**Requirements:**
- Install via Helm with HA configuration for production
- Configure Ingress with TLS
- Enable SSO integration (can be mocked/documented)
- Configure RBAC for different teams
- Set up notifications (Slack/Email webhooks)

### Task 4.2: Application Definitions

Create ArgoCD Application manifests for the AI Chatbot Framework.

**Requirements:**
- App-of-Apps pattern for managing multiple environments
- Separate Applications for: dev, staging, production
- Automated sync for dev, manual sync for production
- Health checks and sync waves
- Rollback configuration

### Task 4.3: CI Pipeline 

Create a GitHub Actions or GitLab CI pipeline that:
- Builds Docker images for frontend and backend
- Runs tests
- Pushes to ECR
- Updates image tags in the GitOps repository
- Triggers ArgoCD sync (for dev environment)

---

## Part 5: Observability

Give an explanation of how you will implement monitoring and observability for this application.

---

## Submission Requirements

1. **Git Repository** with clear commit history showing your progress
2. **README.md** at root with:
   - Prerequisites
   - Quick start guide
   - Architecture overview
   - Known limitations/assumptions
3. **All code must be syntactically valid** (terraform validate, helm lint)

---

**Good luck!**
