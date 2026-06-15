# Features

Feature statuses must be one of: `planned`, `in-progress`, `done`, or `blocked`.

## Phase 1 MVP

| Feature | Status | Notes |
| --- | --- | --- |
| Flutter app shell | done | Material 3 shell with bottom navigation for the four MVP screens. |
| Home screen | done | Placeholder entry point for future summary and coaching prompts. |
| Health data screen | done | Placeholder screen only; real HealthKit and Health Connect data reads are still planned. |
| AI coach chat screen | done | Basic text-only chat UI sends manual prompts to the active provider/model and displays assistant responses. No health summary, tools, streaming, or persistence yet. |
| Settings screen | done | Provider-focused AI setup, secure API key entry/removal, saved-key status, model fetching, and provider-specific model selection are implemented. |
| Store OpenAI API key locally | done | Uses secure local storage; key is not displayed after saving and can be cleared. |
| Store Gemini API key locally | done | Uses secure local storage; key is not displayed after saving and can be cleared. |
| Select OpenAI model | done | Fetches likely text/tool-capable OpenAI model candidates with the saved key and stores the selected model locally. |
| Select Gemini model | done | Fetches likely text/tool-capable Gemini model candidates with the saved key and stores the selected model locally. |
| Send manual chat prompt to selected AI provider/model | done | Uses the current Settings provider/key/model flow for manual testing with OpenAI or Gemini. |
| Basic Apple HealthKit integration | planned | iOS permissions must be minimal, metric-specific, and explained to users before access. |
| Basic Google Health Connect integration | planned | Android permissions must be minimal, metric-specific, and explained to users before access. |
| Basic health summary | planned | Summary should be compact, locally generated where practical, and avoid retaining raw data unless needed. |
| Chat prompt includes health summary | planned | Prompts should use compact summaries and avoid unnecessary sensitive data exposure or raw history dumps. |

## Phase 1 Security And Efficiency Acceptance Criteria

| Feature | Acceptance Criteria |
| --- | --- |
| Flutter app shell | Must not introduce background work, network calls, analytics, or permissions without a documented feature need. |
| Home screen | Must avoid showing sensitive health data until permission state, data freshness, and user intent are clear. |
| Health data screen | Must explain requested health permissions in user-facing language before real access is requested. Reads must be scoped by metric type and date range. |
| AI coach chat screen | Must make AI-provider transmission explicit. Current chat sends only user-entered text and in-memory chat history to the selected provider; no health data is included yet. Future health prompts should include compact summaries rather than raw histories. |
| Settings screen | Exposes provider choice, focused API key setup for the active provider only, provider-specific key removal, model refresh, and local model selection. |
| OpenAI/Gemini API key storage | Uses `flutter_secure_storage`, provides a clear delete path, and keeps tests on a fake storage boundary with placeholder values only. Keys must not be logged or included in crash reports. |
| OpenAI/Gemini model listing | Uses explicit user/API-key-driven calls only. Filters out obvious non-text, embedding, media, realtime, and specialized model families. No polling, background fetch, analytics, backend sync, capability probing loops, or raw response logging. |
| OpenAI/Gemini chat calls | Uses explicit user-triggered sends only. Uses existing secure API key storage, selected provider, and selected model. No prompt/response logging, background sends, retries, streaming, tools, MCP, analytics, backend sync, or chat persistence. |
| Health integrations | Must request the minimum permissions needed for the active feature and avoid continuous background syncing unless documented and user-controlled. |
| Basic health summary | Must prefer local processing, bounded reads, and cached summaries when data has not changed. |

## Phase 1 Modularity Acceptance Criteria

| Feature | Acceptance Criteria |
| --- | --- |
| Flutter app shell | App startup, top-level app configuration, and navigation should remain small and separated from feature logic. |
| Home screen | Home UI should compose reusable widgets and models instead of owning health reads, prompt construction, storage, or network logic. |
| Health data screen | Health UI, health service, health permission handling, and health models must be separated before real integration work starts. |
| AI coach chat screen | Chat UI is separated from `ChatController`, `AiChatService`, provider-specific OpenAI/Gemini clients, request mapping, and response parsing. |
| Settings screen | Settings UI, focused provider setup widget, settings controller, API key storage service, model listing services, and settings models are separated. Long model names must fit small phone screens without horizontal overflow. |
| OpenAI/Gemini API key storage | Key storage lives behind `SettingsStorage` / `SecureSettingsStorage` and is not implemented directly in widgets. |
| OpenAI/Gemini model listing | Provider-specific model listing lives behind `ModelListingService`, `OpenAiModelListingService`, and `GeminiModelListingService`; no network logic is in UI. |
| OpenAI/Gemini chat calls | Provider-specific chat calls live behind `AiChatService`, `ProviderAiChatService`, `OpenAiChatService`, and `GeminiChatService`; no network logic is in UI. |
| Health integrations | HealthKit and Health Connect platform logic must be isolated behind services/adapters and must not be scattered through UI files. |
| Basic health summary | Summary generation should use explicit models and service/provider boundaries so it can be tested without UI. |

## Phase 2

| Feature | Status | Notes |
| --- | --- | --- |
| Daily fitness/recovery summary | planned | Generate a daily user-facing summary from recent health data. |
| Manual check-ins | planned | Let users add subjective context such as energy, soreness, mood, and goals. |
| Workout recommendation | planned | Suggest workout intensity or rest based on health summary and check-ins. |
| Weekly summary | planned | Summarize trends, consistency, recovery, and suggested focus areas. |

## Phase 3

| Feature | Status | Notes |
| --- | --- | --- |
| More AI providers | planned | Add provider options beyond OpenAI and Gemini. |
| More wearable integrations | planned | Support additional devices or data sources if practical. |
| Watch widgets / watch companion support | planned | Explore wearable surfaces after the mobile MVP works. |
| Deeper personalization | planned | Use goals, history, preferences, and feedback to improve coaching. |

## Update Rules

- Update this file when a feature starts, ships, is blocked, or changes scope.
- Keep phase lists concise. Put implementation details in `docs/ARCHITECTURE.md` or task notes in `docs/TASK_LOG.md`.
- Do not mark a feature `done` unless the relevant behavior has been implemented and verified.
