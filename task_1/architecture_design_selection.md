# Step-by-step Flow Mapped to AWS (aligned to repo)

| Step | What happens (human view) | AWS service it hits | Why this AWS service | If we used a different service |
|------|----------------------------|---------------------|----------------------|--------------------------------|
| 1 | Admin UI or chat widget loads | CloudFront + S3 (static) or ECS Fargate (SSR) | Static hosting is cheapest; Fargate only if SSR/ISR needed | If SSR needed later, move to ECS/App Runner |
| 2 | User sends a message | ALB → ECS Fargate (FastAPI) | Stable latency for chat + webhook handling | API Gateway + Lambda only for short stateless calls |
| 3 | Load conversation state + bot config | DocumentDB or MongoDB Atlas | Native MongoDB API (Motor); flexible schema | DynamoDB requires data model rewrite |
| 4 | Run NLU pipeline | ECS Fargate → local ML models or external LLM | Traditional ML runs in-process; LLM via OpenAI-compatible endpoint | Self-hosted LLM requires ECS/EKS + GPU |
| 5 | Optional tool call for intent | ECS Fargate → external HTTP API | Async API call with template rendering | Without tool call, respond from template only |
| 6 | Persist updated state + chat logs | DocumentDB or MongoDB Atlas | Append state per message for audit + replay | Redis is not durable |
| 7 | Train models (admin action) | ECS Fargate BackgroundTask + EFS/S3 | In-process training, shared model artifacts | For heavy jobs, offload to SQS + worker |
| 8 | Facebook webhook | ALB → ECS Fargate + BackgroundTask | Fast ACK, async processing | Queue if traffic is high or retries needed |

---

## Notes
- The repo is MongoDB-native (Motor) and stores bot config, intents, entities, integrations, and chat state in Mongo collections.
- Async work is in-process via FastAPI BackgroundTasks; no external queue in the current code.
- LLM is used only for zero-shot NLU (intent/entity extraction), not for response generation.
- Model files are stored on disk (`MODELS_DIR`); shared storage is required for multi-instance deploys.

---

## Service-by-service recommendations (feature-based, aligned to repo)

| Service | Recommended AWS infra | Key features driving choice | Scaling + cost notes | Alternatives (when to use) |
|---------|------------------------|-----------------------------|----------------------|----------------------------|
| Frontend (Admin + Widget) | **S3 + CloudFront** (static export) | Lowest cost, global latency, zero servers | Cache at edge, versioned assets | **ECS Fargate** or **App Runner** if SSR/ISR or API routes are required |
| Frontend (SSR/ISR) | **ECS Fargate** behind **ALB** | Long-lived processes, stable SSR latency | Scale on CPU/RPS, use Fargate Spot for cost | **App Runner** for simpler ops, **EKS** if already standardizing on K8s |
| Gateway / Reverse proxy | **ALB** (optionally Nginx sidecar) | TLS, L7 routing, webhook support | ALB is pay-per-LCU, keep rules minimal | **API Gateway** only if request/response short-lived |
| Backend API (FastAPI) | **ECS Fargate** | Predictable latency, long-lived SSE/WS, easy scale | Scale on CPU/RPS, keep image small | **EKS** if sharing cluster, **Lambda** only for short stateless calls |
| Async jobs (training/webhooks) | **In-process BackgroundTasks** | Matches current code and ops simplicity | Scale by Fargate tasks; keep jobs short | **SQS + Worker (Fargate)** if jobs are heavy or need retries |
| Database (MongoDB) | **DocumentDB** or **MongoDB Atlas** | Mongo-compatible API with flexible schema | Right-size, use TTL/indexes for state | **Self-managed MongoDB** only if custom ops needed |
| Cache / Session | **Optional: ElastiCache Redis** | Add only if latency or rate limits require it | Avoid if not needed | **DynamoDB DAX** only if DynamoDB-centric |
| Messaging | **SQS** | Decouple training/webhooks and long-running tasks | Pay per request | **EventBridge/SNS** for fanout or event routing |
| Storage (models + assets) | **S3 + EFS** | S3 for artifacts; EFS for shared model files | Lifecycle policies, EFS only if multi-instance | **EBS** for single-node deployments |
| LLM provider | **OpenAI-compatible** or **Bedrock** | Repo supports base_url + API key | Control egress cost | **Self-hosted LLM** on ECS/EKS for data locality |
| Observability | **CloudWatch + X-Ray + OpenTelemetry** | Logs/metrics/traces with minimal ops | Set retention, sample traces | **Managed Prometheus/Grafana** if SRE maturity high |

---

## Why not (default rejections, aligned to repo)

| Area | Rejected choice | Why not (default) | Revisit when |
|------|-----------------|-------------------|--------------|
| Compute | **Lambda** (API/SSR/worker) | Cold starts, duration limits, SSE/WS friction | Short-lived, bursty, stateless functions only |
| Compute | **ECS on EC2** (API/SSR) | More ops (patching, scaling, AMIs) | Need GPUs, custom kernels, or lower unit cost at scale |
| Compute | **EKS** (API/SSR) | Highest operational overhead for one app | Org standardizes on K8s or needs mesh/advanced scheduling |
| Compute | **App Runner** (API/SSR) | Less network/control customization than ECS | Small team wants minimal ops for simple HTTP services |
| Database | **RDS** | Rigid schema/joins for fast-evolving chat metadata | Strong relational needs, reporting/SQL analytics |
| Database | **DynamoDB** | Not Mongo-compatible; requires code changes | If redesigning to key/value patterns |
| Database | **Self-managed MongoDB** | Higher ops burden vs managed options | Custom tuning or strict on-prem controls |
| Cache | **ElastiCache Memcached** | No persistence/replication, fewer data types | Simple, low-cost, ephemeral cache only |
| Messaging | **SNS** | Pub/sub, not queueing with retries/visibility | Fan-out notifications to many subscribers |
| Messaging | **EventBridge** | Higher cost/event; not ideal for high-throughput work queues | Cross-service event routing and SaaS integrations |
| Storage | **EBS** | Single‑AZ, EC2‑only attachment | Stateful single-node workloads on EC2 |
| Gateway | **API Gateway** | 30s timeout, per-request cost, SSE/WS constraints | Short REST APIs without streaming |
| Gateway | **Nginx as primary** | Extra ops/patching for features ALB already provides | Need advanced rewrites/sidecar auth not in ALB |
| Observability | **Managed Prometheus/Grafana** | Extra cost/ops if CloudWatch suffices | PromQL standardization and SRE tooling maturity |

---

## SSR now vs later (architecture impact)
- **CSR-only today**: S3 + CloudFront is simplest and cheapest.
- **SSR/ISR in future**: Move UI to ECS Fargate or App Runner, add ALB, and align cache strategy (CloudFront caching + app-level caching).
- **API routes in Next.js**: If added later, these live with SSR compute and change security and scaling (WAF, rate limits, autoscaling policies).

---

## Cost-optimized scaling for training/async jobs (optional)
- **Current state**: FastAPI BackgroundTasks run in-process on ECS Fargate.
- **Scale-out path**: move training/webhook processing to SQS + worker service when jobs are heavy.
- **Cost control**: use Fargate Spot for non-urgent workers; keep a small on-demand baseline for retries.

---

## Model hosting: self-hosted vs managed

| Option | When it fits | Tradeoffs |
|--------|--------------|----------|
| Self-hosted (ECS/EKS + GPU) | Custom models, strict data locality, full control | Higher ops cost, capacity management |
| Managed (AWS Bedrock / SageMaker) | Fast time-to-value, managed scaling | Ongoing usage cost, model availability limits |

**Note**: In this repo the LLM is used for NLU only (intent/entity extraction). Default config points to a local OpenAI-compatible endpoint; in AWS this can map to Bedrock, OpenAI, or a self-hosted model behind a private endpoint.

---

## Cost focus areas
- **Models**: inference cost per token/request; choose smaller models for default paths and route to larger models only when needed.
- **Workloads**: steady-state traffic -> reserved/on-demand; bursty traffic -> spot + autoscaling.
- **Observability**: control log retention, sample traces, and avoid high-cardinality metrics to limit spend.

---
