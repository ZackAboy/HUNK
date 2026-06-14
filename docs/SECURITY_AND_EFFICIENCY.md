# Security And Efficiency

This is the central reference for secure and efficient development. Future agents must check this file before changing permissions, storage, data models, health integrations, AI prompts, network behavior, background work, analytics, crash reporting, backend sync, or watch/widget support.

Security and efficiency are non-negotiable. The app handles sensitive health and fitness data, and users may store personal AI API keys. The app must avoid weak storage, unnecessary permissions, careless logging, broad data retention, hidden network behavior, and wasteful battery, memory, or network usage.

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

## API Key Handling

- Store OpenAI and Gemini API keys only in secure local storage.
- Do not store API keys in plain shared preferences, source files, logs, analytics, crash reports, screenshots, exports, or test fixtures.
- Mask API keys in UI after entry.
- Provide a clear way to delete stored keys.
- Keep provider-specific API key handling isolated in a storage/service boundary.
- Never send one provider's key to another provider or to an app backend.

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

## AI Prompt Construction

- Prefer compact health summaries in prompts instead of raw data dumps.
- Include only the health context needed to answer the user's current request.
- Avoid repeatedly sending large health histories to AI providers.
- Make provider transmission explicit in the architecture and user-facing settings.
- Treat prompts and responses as sensitive because they may contain health context.
- Do not log full prompt payloads or AI responses that include private health details.

## Network Calls

- Network calls must be explicit and provider-specific.
- Do not add hidden telemetry, sync, remote config, or backend calls without documentation.
- Use HTTPS-only provider endpoints.
- Keep request payloads compact.
- Add retries carefully; avoid retry loops that increase cost, battery usage, or duplicate AI calls.
- Any future backend path for health data, prompts, responses, or API keys must be opt-in where appropriate and documented before implementation.

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
