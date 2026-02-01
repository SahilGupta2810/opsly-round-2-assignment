# Human Flow (Aligned to Local → AWS Mapping)

This is a simple, non‑technical view of how a user request moves through the system.

---

## Step 1: User opens the UI
**Local:** Next.js dev server or container
**AWS:** ECS Fargate or App Runner
**Why:** The UI runs as a small server, so it needs compute.

---

## Step 2: UI sends the request to the Backend API
**Local:** FastAPI on localhost or container
**AWS:** ECS Fargate
**Why:** The API needs to be always on and responsive.

---

## Step 3: Backend reads or writes data
**Local:** MongoDB on localhost or Docker
**AWS:** DocumentDB or MongoDB Atlas
**Why:** Managed MongoDB‑compatible database with less ops.

---

## Step 4: Backend calls the LLM (when needed)
**Local:** Local inference server or container
**AWS:** AWS Bedrock (managed)
**Why:** Managed models, no GPU ops.
**Alternate:** Self‑host on EKS/ECS GPU if you need full control.

---

## Step 5: Backend returns the response to the UI
**Local/AWS:** Same backend service
**Why:** Keeps the response fast and consistent.

---

## Optional: Cache for speed
**Local:** Redis in a container or in‑memory
**AWS:** ElastiCache Redis
**Why:** Speeds up repeated reads and reduces load on the database.
