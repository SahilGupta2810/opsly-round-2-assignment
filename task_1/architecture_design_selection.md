# Simple Architecture Mapping (Local -> AWS)

This page explains how each part runs locally and what it maps to in AWS, in plain language.

## Local-to-AWS Service Mapping

| Local Service Name | Local Setup - How it runs locally | AWS Service | Why this choice (simple) | Alternate AWS suggestion (when it fits) |
| --- | --- | --- | --- | --- |
| UI | Next.js dev server (`npm run dev`) or container | ECS Fargate or App Runner | The UI runs as a server (not just static files), so it needs compute | S3 + CloudFront if you refactor to a full static export |
| Backend | FastAPI on localhost or container | ECS Fargate | Long‑lived API service with steady traffic | EKS if you want one Kubernetes platform for everything |
| DB | MongoDB on localhost or Docker | DocumentDB or MongoDB Atlas | Managed MongoDB‑compatible database, less ops | DynamoDB if you redesign the data model for key/value |
| LLM Inference | Local inference server or container | AWS Bedrock (managed) | Managed models, no GPU ops, fast to start | Self‑host on EKS/ECS GPU if you need full control |
| Caching | Redis in local container or in‑memory | ElastiCache Redis | Managed Redis with scaling and high availability | Memcached for simple, temporary cache |

## Simple Request Flow

1. User opens the UI.
2. UI calls the Backend API.
3. Backend reads/writes data in the Database.
4. Backend calls the LLM service when needed.
5. Backend returns the response to the UI.
