# Human Flow

What I have understood

---

## Step 1: Human types a message in the chatbot

### Example
> “Create infrastructure for my application”

### Service Used
**Frontend application (Always-on app service)**

### Why this service is used
- The user expects an instant response
- The app must already be running
- No startup delay is acceptable

### What would happen if we used something else?

| Alternative | What would go wrong |
|------------|---------------------|
| Serverless function | Cold start delays, feels laggy |
| Background worker | No immediate response |
| Batch job | Completely wrong for interaction |

**Conclusion**  
User-facing interactions always hit always-on services.

---

## Step 2: The request reaches the backend chat API

### Service Used
**Backend API running on container-based service**

### Why this service is used
- Handles conversational logic
- Can keep connections open
- Predictable latency
- Supports streaming replies

### What would happen if we used something else?

| Alternative | What would happen |
|------------|------------------|
| Serverless function | Cold starts, poor streaming support |
| Batch compute | No real-time interaction |
| Scheduled job | Cannot respond to users |

**Key idea**  
Conversation logic must be fast and state-aware.

---

## Step 3: Backend needs recent conversation context

### Service Used
**Redis (Short-term memory)**

### Why this service is used
- Extremely fast reads
- Data expires automatically
- Perfect for “what’s happening now”

### What would happen if we used something else?

| Alternative | Impact |
|------------|--------|
| NoSQL DB | Slower reads, unnecessary cost |
| SQL DB | Overkill, rigid structure |
| In-memory only | Data lost on restart |

**Conclusion**  
If data is temporary and frequently accessed → Redis.

---

## Step 4: Backend acknowledges the user immediately

### Example response
> “Got it! I’m working on that.”

### Service Used
**Same backend container service**

### Why this service is used
- Keeps the interaction smooth
- Prevents user waiting
- Sets expectation clearly

### What would happen if we waited for the real work?

| Alternative | Result |
|------------|--------|
| Wait for infra creation | User waits minutes |
| Synchronous execution | Timeouts |
| Blocking call | Poor user experience |

**Key principle**  
Never block the chat on slow work.

---

## Step 5: The request is stored permanently

### Service Used
**NoSQL database (Long-term memory)**

### Why this service is used
- Flexible structure
- Easy to add metadata later
- Durable record

### What would happen if we used SQL?

| Issue | Why it’s bad |
|------|--------------|
| Schema changes | Hard to evolve |
| Rigid structure | Conversations vary |
| Migration overhead | Slows development |

**Conclusion**  
Human conversations evolve → NoSQL fits naturally.

---

## Step 6: Slow or risky work is moved to background

### Service Used
**Task Queue**

### Why this service is used
- Ensures work is not lost
- Handles retries
- Decouples chat from execution

### What would happen without a queue?

| Scenario | Result |
|---------|--------|
| Backend crashes | Work lost |
| Cloud API fails | No retry |
| Traffic spike | System overload |

**Rule**  
If work must finish eventually → use a queue.

---

## Step 7: Background worker picks up the task

### Service Used
**Worker service (container-based)**

### Why this service is used
- Can run for a long time
- Can retry safely
- Can be scaled independently

### What would happen if we used serverless?

| Limitation | Impact |
|-----------|--------|
| Time limits | Jobs fail |
| Retry behavior | Duplicate infra |
| Execution control | Hard to manage |

**Conclusion**  
Long-running, stateful work → workers, not functions.

---

## Step 8: Worker interacts with external systems

### Service Used
**Orchestrator logic inside worker**

### Why this service is used
- Centralizes cloud logic
- Supports multi-provider execution
- Keeps chat system clean

### What if chat service did this?

| Problem | Risk |
|--------|------|
| Credentials exposure | Security issue |
| Partial failures | Hard to recover |
| Coupling | Poor maintainability |

**Security rule**  
User-facing systems should never hold dangerous power.

---

## Step 9: Progress and results are stored

### Service Used
**NoSQL database**

### Why this service is used
- Status updates evolve
- New fields added over time
- Easy querying for UI

### What if we used Redis?

| Issue | Why |
|------|-----|
| Data expires | Lost history |
| Memory pressure | High cost |
| No audit trail | Compliance risk |

**Rule**  
Temporary → Redis  
Permanent → NoSQL

---

## Step 10: Chat system reads status and updates user

### Service Used
**Backend container service + NoSQL**

### Why this service is used
- Reads durable state
- Sends friendly updates
- Keeps user informed

### What if user queried workers directly?

| Problem | Result |
|--------|--------|
| Tight coupling | Fragile system |
| Latency spikes | Poor UX |
| Security exposure | Risk |

---

## Step 11: Session naturally ends

### Service Used
**Redis TTL**

### Why this service is used
- Automatic cleanup
- No manual deletion
- Cost-efficient

### What if we kept everything forever?

| Issue | Impact |
|------|--------|
| Memory growth | Cost increase |
| Noise | Harder debugging |

---

## Final Architecture Summary

| User Action | Service Used | Why This Service |
|------------|--------------|------------------|
| Typing a message | Always-on app | Instant response |
| Understanding intent | Backend API | Fast logic |
| Remembering context | Redis | Speed |
| Saving history | NoSQL | Flexibility |
| Slow work | Queue | Safety |
| Execution | Worker | Reliability |
| Progress updates | NoSQL | Durability |
| Cleanup | Redis TTL | Cost control |