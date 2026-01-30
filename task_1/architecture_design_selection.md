# Step-by-step Flow Mapped to AWS

| Step | What happens (human view) | AWS service it hits | Why this AWS service | If we used a different service |
|------|----------------------------|---------------------|----------------------|--------------------------------|
| 1 | User types a message in the chatbot UI | CloudFront + Next.js app on ECS Fargate (or Amplify Hosting) | CloudFront speeds delivery; Fargate keeps the UI/API always-on (fast response) | If only S3 static: no SSR. If Lambda-only UI: cold-start lag and SSR complexity |
| 2 | UI sends the message to backend chat API | ALB → ECS Fargate (FastAPI) | ALB routes traffic; Fargate is stable for real-time chat + streaming | API Gateway + Lambda works for short REST, but not ideal for long-lived SSE/WS |
| 3 | Backend loads “recent context” | ElastiCache for Redis | Ultra-fast reads + TTL (session memory) | If DynamoDB/MongoDB: slower and higher cost for frequent reads |
| 4 | Backend replies immediately (“Got it…”) | FastAPI on ECS Fargate | Always-on response (no waiting) | If it waits for infra work: slow UX/timeouts |
| 5 | Save the request permanently (audit + history) | NoSQL DB: DynamoDB (AWS-native) or MongoDB Atlas | Durable long-term record; flexible schema for chat + metadata | If Redis: expires / not durable. If SQL only: schema changes become painful for evolving chat metadata |
| 6 | Put slow work into a queue | SQS | Work never gets lost; supports retries; decouples chat from execution | Without queue: failures lose work; spikes overload the API |
| 7 | Worker picks up job | ECS Fargate Worker (or ECS on EC2 for GPU) | Long-running, retry-friendly, controlled concurrency | Lambda workers can hit timeouts and tricky retry/duplication patterns for long jobs |
| 8 | Worker calls cloud provider APIs (AWS/Azure/GCP) | Worker in ECS + provider SDK/Terraform | Worker is the only place that holds cloud execution logic | If chat API did it: security risk + coupling + bad failure handling |
| 9 | Worker writes progress + final result | DynamoDB/MongoDB + CloudWatch Logs | Durable progress tracking + audit trail | If Redis: could expire. If only logs: hard to query status for UI |
| 10 | UI polls/streams status updates | FastAPI (ECS) → DB, optionally SSE via ALB | Keeps updates consistent; SSE provides smooth progress | If UI talks directly to worker: fragile + security exposure |
| 11 | Session ends and temp state expires | ElastiCache Redis TTL | Automatic cleanup, cost control | Without TTL: memory grows and costs climb |

---

## Notes
- For “NoSQL DB” on an AWS-native path, use **DynamoDB** or **DocumentDB**   
- For streaming chat or progress updates, **SSE over ALB → ECS** is the simplest and most reliable pattern.

---
