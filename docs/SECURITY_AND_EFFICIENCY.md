# Security And Efficiency

This is the central reference for secure and efficient development. Future agents must check this file before changing permissions, storage, data models, health integrations, AI prompts, network behavior, background work, analytics, crash reporting, backend sync, or watch/widget support.

Security and efficiency are non-negotiable. The app handles sensitive health and fitness data, and users may store personal AI API keys. The app must avoid weak storage, unnecessary permissions, careless logging, broad data retention, hidden network behavior, and wasteful battery, memory, or network usage.

Modularity supports both security and efficiency. Sensitive and resource-heavy behavior is easier to review, test, and control when it lives in clear modules instead of being scattered through UI code.

## Required Check Before Sensitive Changes

Before implementing a change, answer these questions in the task notes or relevant docs when the change touches sensitive or resource-heavy behavior:

- What sensitive data does this feature access?
- What is the minimum permission, metric set, date range, and retention window needed?
- Where is the data stored, and how can the user delete it?
- What network calls are made, to which provider, and with what payload shape?
- Can this be done locally or with a compact summary instead of raw data?
- Does this add background work, polling, timers, sync, or retries?
- What prevents this from becoming battery-heavy, memory-heavy, or network-heavy?

Document security-sensitive and performance-sensitive decisions in `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, and `docs/TASK_LOG.md` when relevant.

## Modularity For Sensitive And Resource-Heavy Logic

- API key handling must live in a clear storage/service boundary, not directly in UI widgets.
- Health permissions and health reads must live in health services/adapters, not screen files.
- AI prompt construction should live behind an explicit prompt/service boundary so sensitive context can be reviewed and minimized.
- Network calls must live in provider-specific clients or services, not scattered through widgets.
- Background work, caching, retries, and sync behavior must be isolated so battery, memory, and network impact can be inspected.
- Shared sensitive models should be named clearly and should not mix raw health data, summaries, API keys, prompts, and UI-only state.
- Module boundaries should make it obvious where sensitive data enters, where it is transformed, where it is stored, and where it leaves the device.

## API Key Handling

- Store OpenAI and Gemini API keys only in secure local storage.
- Do not store API keys in plain shared preferences, source files, logs, analytics, crash reports, screenshots, exports, or test fixtures.
- Mask API keys in UI after entry.
- Provide a clear way to delete stored keys.
- Keep provider-specific API key handling isolated in a storage/service boundary.
- Never send one provider's key to another provider or to an app backend.

Current implementation notes:

- `SecureSettingsStorage` uses `flutter_secure_storage` for API key persistence.
- `AiSettings` stores only active provider, saved-key booleans, and selected model IDs, not API key values.
- The Settings UI clears text fields after save or remove actions and does not display saved key values.
- Android auto backup is disabled while backup/restore behavior for sensitive local data is undefined.
- Model listing uses saved keys only for explicit calls to the selected provider's official model-list endpoint.
- No AI chat calls, backend calls, analytics, crash reporting, polling, or background fetches are made by the settings feature.

## Model Listing

- Model listing must stay behind provider-specific service boundaries.
- The Settings UI must not make HTTP calls directly.
- Use saved API keys only for the selected provider's official model-list endpoint.
- Do not log API keys, request URLs containing keys, authorization headers, or raw provider responses.
- Fetch models only after saving a key, opening Settings for a provider with a saved key and no in-memory cache, or explicit user refresh.
- Cache model lists only as model IDs/display names unless a future documented decision changes this.
- Removing a provider API key must clear that provider's selected model and cached model list without affecting the other provider.
- The Settings model picker should show likely text/tool-capable candidates and exclude obvious embedding, media, realtime, live-only, legacy, non-provider-family, and specialized non-text model families.
- If a provider's model-list endpoint does not expose an explicit MCP/tool-capability flag, document the provider-specific approximation instead of adding hidden capability probes or repeated test calls.

## Health Data Permissions

- Request only permissions needed for the active feature.
- Scope permissions by metric type and access direction where the platform allows it.
- Explain permissions in user-facing language before requesting them.
- Do not request broad health categories because they might be useful later.
- Treat denied permissions as a normal state, not an error.
- Document every new permission in `docs/ARCHITECTURE.md` and `docs/SETUP.md`.

## Health Data Storage

- Prefer local processing and short-lived raw health reads.
- Retain raw health data only when a documented feature requires it.
- Prefer storing compact derived summaries over raw records.
- Define retention and deletion behavior before adding persistent health storage.
- Do not log raw health values.
- Keep health data models separate from API key models, prompt models, and UI-only state.

## Context Web / Info Matrix

- Treat Context Web entries as sensitive personal coaching context.
- Store Context Web entries only behind `ContextRepository` / `SecureContextRepository` for the current MVP.
- Do not store API keys, access tokens, provider secrets, raw provider responses, or hidden identifiers in the Context Matrix.
- Store durable user-stated coaching facts only. Do not persist every chat line.
- Keep manual and pinned entries higher authority than chat-extracted entries.
- Do not silently overwrite manual or pinned entries through extraction or future imports.
- Mark AI/rule-extracted context with `chat_extracted` and confidence metadata.
- Let users view, edit, correct, confirm, and archive/remove entries.
- Exclude archived entries from active UI counts and AI prompt summaries.
- Keep future health, weather, and workout imports behind explicit source interfaces with no background importing unless separately documented.
- Do not log Context Matrix values, prompt summaries, extraction candidates, or archive/delete actions with sensitive content.

## AI Prompt Construction

- Prefer compact health summaries in prompts instead of raw data dumps.
- Include only the health context needed to answer the user's current request.
- Avoid repeatedly sending large health histories to AI providers.
- Include Context Web data through a bounded summary with clear start/end boundaries, not as unlimited raw entries or chat history.
- Exclude archived/deleted Context Web entries from prompts.
- Do not include API keys, secrets, raw provider responses, or unrelated sensitive notes in prompt context.
- Make provider transmission explicit in the architecture and user-facing settings.
- Treat prompts and responses as sensitive because they may contain health context.
- Do not log full prompt payloads or AI responses that include private health details.

Current implementation notes:

- Basic Coach chat sends user-entered text, the current in-memory chat history, and a bounded active Context Web summary. No platform health data is included yet.
- Chat uses the active provider, saved API key, and selected model from `SettingsStorage`; it does not maintain a second provider/model source of truth.
- Chat messages are not persisted locally and are not written to logs, analytics, crash reports, or docs.
- Durable user-stated context can be saved separately in the local Context Matrix through manual entry or conservative rule-based extraction.
- OpenAI chat calls set `store: false` in the Responses API request.
- No tools, MCP behavior, streaming, background sends, automatic retries, or long-term memory are implemented.

## Network Calls

- Network calls must be explicit and provider-specific.
- Do not add hidden telemetry, sync, remote config, or backend calls without documentation.
- Use HTTPS-only provider endpoints.
- Keep request payloads compact.
- Add retries carefully; avoid retry loops that increase cost, battery usage, or duplicate AI calls.
- Any future backend path for health data, prompts, responses, or API keys must be opt-in where appropriate and documented before implementation.
- Current Settings network calls are limited to OpenAI/Gemini model listing and are user/API-key-driven only.
- Current Coach network calls are limited to user-triggered OpenAI Responses API or Gemini `generateContent` text calls with short timeouts, bounded output tokens, in-memory chat history, and a compact active Context Web summary.

## Background Work

- Avoid background work unless a user-facing feature truly needs it.
- Prefer user-triggered refresh or platform-supported event-driven updates over polling.
- Do not add recurring timers, sync loops, or broad background health reads without documenting the battery and privacy impact.
- Keep background tasks bounded by time, metric type, and date range.
- Make background behavior user-controllable when practical.

## Logging

- Logs must not include API keys, raw health data, prompt payloads, AI responses with private context, authorization headers, or provider secrets.
- Debug logs should be temporary, minimal, and removed before completion unless they are safe operational logs.
- Error messages should be useful without exposing sensitive values.
- If structured logging is added later, define redaction rules before logging sensitive paths.

## Analytics And Crash Reporting

- Do not add analytics or crash reporting dependencies without a documented decision.
- Analytics events must avoid health values, API keys, prompt text, response text, and unique sensitive identifiers.
- Crash reports must avoid sensitive breadcrumbs and request payloads.
- User consent and platform disclosure requirements must be considered before telemetry is enabled.

## Future Backend Sync

- The MVP should not require a project-hosted backend.
- Future backend sync must be explicitly required by a feature, documented, and visible to users.
- Sensitive data should not be sent to any backend unless the user approves the behavior and the architecture documents what is sent, why, retention, deletion, and failure behavior.
- API keys should not be sent to an app backend unless the product direction changes and the decision is documented first.

## Future Watch And Widget Support

- Watch and widget features should use compact summaries, not raw health histories.
- Avoid frequent refreshes that can drain battery.
- Respect platform limits for background updates and complication/widget refresh.
- Keep transferred payloads small.
- Do not expose sensitive health details on lock screens or shared surfaces unless the user explicitly enables that display.

## Dependency Review Rules

Before adding a dependency, document:

- Why the dependency is needed.
- What permissions, background behavior, storage, or network access it introduces.
- Whether it handles sensitive data.
- Whether a smaller or platform-native option is sufficient.
- Any known security, privacy, or performance tradeoffs.

Do not add dependencies for speculative future needs.
