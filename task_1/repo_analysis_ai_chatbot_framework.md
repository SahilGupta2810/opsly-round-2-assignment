# Repo analysis: AI Chatbot Framework (OpsLy/ai-chatbot-framework)

## Main features and user-facing flows
- **Admin dashboard (Next.js)**: create/edit intents, entities, parameters, and API triggers; manage integrations; configure NLU pipeline (traditional vs LLM); train models; test chat; review chat logs.
- **End-user chat**: web chat widget (REST channel), REST API clients, and Facebook Messenger webhook.
- **Tool calling**: intents can trigger external HTTP calls; results are injected into response templates.

## Internal architecture and request flow (frontend -> backend -> LLM)
1. **Frontend** (Next.js admin UI or embedded widget) sends messages to FastAPI endpoints.
2. **FastAPI** receives messages via `/admin/test/chat` (admin test), `/bots/channels/rest/webbook` (REST channel), or Facebook webhook.
3. **DialogueManager** loads current state from MongoDB, runs the **NLU pipeline**, fills parameters, and resolves the active intent.
4. **LLM path (optional)**: when `pipeline_type = "llm"`, ZeroShotNLUOpenAI is invoked to extract intent and entities; otherwise ML pipeline runs.
5. **Intent handling**: if intent is complete and has `apiTrigger`, an async external API call is made; otherwise a response template is rendered.
6. **State persisted**: conversation state + messages are written to MongoDB and returned to the channel.

## Database interactions (MongoDB via Motor)
- **Database: `ai-chatbot-framework`** (from config)
  - `bot`: NLU configuration (traditional vs LLM) and thresholds.
  - `intent`: intent definitions, parameters, API triggers, training data.
  - `entity`: entity definitions and synonyms.
  - `integrations`: channel settings (chat widget, Facebook).
- **Database: `chatbot`** (hard-coded in memory saver/chatlogs)
  - `state`: conversation state and chat logs (thread_id, user_message, bot_message, NLU output, parameters).
  - **Read patterns**: latest state by thread_id (for memory); full thread for chat log views.
  - **Write pattern**: append a new state document per message.

## LLM integration (zero-shot NLU)
- **Provider**: OpenAI-compatible API via `langchain_openai.ChatOpenAI`.
  - Default config points to local OpenAI-compatible endpoint (`http://127.0.0.1:11434/v1`) and model name like `llama2:13b-chat`.
  - Can be switched to OpenAI or other compatible providers via admin settings.
- **Prompting**: Jinja template (`ZERO_SHOT_LEARNING_PROMPT.md`) lists all intents and entities and enforces strict JSON output.
- **Invocation**: Called per message only when `pipeline_type = "llm"`; output drives intent/entity extraction, not response generation.

## Background/async processing
- **Model training**: `/admin/train/build_models` runs training in a FastAPI BackgroundTask, then reloads the dialogue manager.
- **Facebook webhook**: incoming events are processed asynchronously via BackgroundTasks.
- **No external queue**: async work is in-process; no Celery/SQS/RabbitMQ in the repo.

## Concise architecture summary
The platform is a monolithic FastAPI backend paired with a Next.js admin UI and a lightweight chat widget. Admin users configure intents, entities, and API integrations in MongoDB, then train NLU models; end users converse via REST or Facebook. Each user message is routed through a Dialogue Manager that loads conversation state, runs NLU, resolves intent parameters, optionally calls an external API, and renders a response template before persisting the updated state.

NLU runs in one of two modes: a traditional ML pipeline (spaCy featurizer + scikit-learn intent classifier + CRF entity extractor + synonym replacement) or a zero-shot LLM pipeline that calls an OpenAI-compatible model. The LLM is used only to classify intent and extract entities; response generation remains template-driven with optional tool-calling for dynamic data.

## Components and responsibilities
- **Frontend Admin (Next.js)**: bot configuration, training, testing, integrations, chat logs.
- **Chat Widget (static JS)**: embeds UI, sends messages to REST channel.
- **FastAPI app**: exposes admin APIs and channel endpoints; CORS + static files.
- **Dialogue Manager**: orchestrates state, NLU, parameter filling, and response rendering.
- **NLU Pipeline**: traditional ML components or LLM-based zero-shot extractor.
- **Memory Saver (MongoDB)**: persists state and retrieves current conversation context.
- **Integrations**: REST channel, Facebook webhook handler.
- **External API caller**: async HTTP client for intent-triggered tool calls.
