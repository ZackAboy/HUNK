# Decisions

This file tracks major technical and product decisions. Add or update entries when the project direction, architecture, dependencies, integrations, storage approach, data models, or AI provider behavior changes.

## Decision Format

```text
Date:
Decision:
Status:
Context:
Consequences:
```

## 2026-06-14 - Use Flutter Instead Of React Native

Date: 2026-06-14

Decision: Use Flutter as the app framework instead of React Native.

Status: accepted

Context: The project is intended to be a cross-platform mobile app with one shared UI codebase.

Consequences: App code should be written in Dart using Flutter conventions. Native platform integrations should be exposed through Flutter-compatible packages or platform channels when needed.

## 2026-06-14 - Target iOS And Android

Date: 2026-06-14

Decision: Target iOS and Android for the MVP.

Status: accepted

Context: The core use case depends on mobile health data sources.

Consequences: Platform-specific setup and health permissions must be documented for both platforms.

## 2026-06-14 - Use Apple HealthKit For iOS Health Data

Date: 2026-06-14

Decision: Use Apple HealthKit as the initial iOS health data source.

Status: accepted

Context: HealthKit is the standard iOS health data integration point.

Consequences: iOS setup will need HealthKit capability, permissions, and platform-specific testing.

## 2026-06-14 - Use Google Health Connect For Android Health Data

Date: 2026-06-14

Decision: Use Google Health Connect as the initial Android health data source.

Status: accepted

Context: Health Connect is the standard Android health data integration point.

Consequences: Android setup will need Health Connect permissions, compatible device/emulator handling, and platform-specific testing.

## 2026-06-14 - Start With OpenAI And Google Gemini API-Key Support

Date: 2026-06-14

Decision: Support OpenAI and Google Gemini as the initial AI providers.

Status: accepted

Context: The app should let users bring their own AI API keys and choose a provider.

Consequences: AI provider logic should be isolated behind services so additional providers can be added later.

## 2026-06-14 - Store API Keys Locally First

Date: 2026-06-14

Decision: Store user-provided API keys locally for the MVP.

Status: accepted

Context: The MVP should not require a project-hosted backend.

Consequences: Use secure local storage when implemented. Do not log API keys. Any future backend-based key management must be documented as a new decision.

## 2026-06-14 - Keep MVP Small And Avoid Overengineering

Date: 2026-06-14

Decision: Keep the MVP focused and avoid premature architecture.

Status: accepted

Context: The first goal is a working app loop: health data summary plus AI coach chat using user-owned provider keys.

Consequences: Prefer simple services, clear models, and small screens before introducing deeper personalization, advanced analytics, sync, backend infrastructure, or complex state management.

## 2026-06-14 - Treat Security And Efficiency As First-Class Engineering Constraints

Date: 2026-06-14

Decision: Security and efficiency are first-class engineering constraints for all features.

Status: accepted

Context: The app will handle personal health and fitness data, user-provided AI API keys, AI prompts, and future platform integrations. It also needs to avoid unnecessary battery, memory, network, and background-processing cost.

Consequences: Future agents must evaluate security and efficiency before adding dependencies, permissions, services, data models, background work, network calls, health integrations, AI prompt behavior, analytics, crash reporting, or watch/widget support. Security-sensitive and performance-sensitive decisions must be documented.

## 2026-06-14 - Prefer Local-First Processing Where Practical

Date: 2026-06-14

Decision: Prefer local-first processing and summarization where practical.

Status: accepted

Context: Local summaries can reduce sensitive data exposure, reduce network payload size, avoid repeated AI prompt bloat, and improve responsiveness.

Consequences: Health data should be read in scoped ranges, summarized locally where practical, cached when appropriate, and sent to AI providers as compact context rather than raw histories unless a documented feature requires otherwise.

## 2026-06-14 - Do Not Send Sensitive Data To A Backend Without Explicit Approval

Date: 2026-06-14

Decision: Sensitive data should not be sent to any app backend unless explicitly required, user-approved, and documented.

Status: accepted

Context: The MVP does not require a project-hosted backend. Health data, API keys, prompts, and chat content are sensitive and should not gain additional exposure by default.

Consequences: Any future backend sync, account system, analytics pipeline, crash reporting payload, or remote processing path involving sensitive data must be opt-in where appropriate, clearly user-visible, and documented in `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, and `docs/SECURITY_AND_EFFICIENCY.md` before implementation.

## 2026-06-14 - Treat Modularity As A First-Class Engineering Constraint

Date: 2026-06-14

Decision: Modularity is a first-class engineering constraint alongside security and efficiency.

Status: accepted

Context: The project will likely be developed by multiple people and AI agents over time. Large files, hidden dependencies, and tightly coupled feature logic would make parallel work risky and slow.

Consequences: Future agents should prefer small, isolated, well-named files and modules. New modules, services, models, providers, dependencies, and shared contracts must be documented in `docs/ARCHITECTURE.md`.

## 2026-06-14 - Split Features Into UI, State, Models, And Services Where Appropriate

Date: 2026-06-14

Decision: Features should be split into UI, state, models, and services where the feature is more than trivial placeholder UI.

Status: accepted

Context: Settings, health integrations, API key storage, health summaries, and AI chat will each need different ownership boundaries for testing, security, performance, and multi-agent development.

Consequences: UI widgets should not own business logic, secure storage, health API calls, network calls, or AI provider behavior. Shared behavior should move into explicit services, providers/state objects, models, or reusable widgets.

## 2026-06-14 - Isolate Platform-Specific Integrations

Date: 2026-06-14

Decision: Platform-specific integrations must be isolated behind services or adapters.

Status: accepted

Context: Apple HealthKit, Google Health Connect, future watch support, widgets, and platform permissions will have platform-specific behavior that should not leak across UI files.

Consequences: Platform-specific code should be contained in dedicated services/adapters with clear interfaces. Screens and widgets should consume platform-neutral state or models wherever practical.

## 2026-06-14 - Use flutter_secure_storage For Local API Keys

Date: 2026-06-14

Decision: Use `flutter_secure_storage` for local OpenAI and Google Gemini API key storage.

Status: accepted

Context: API keys are sensitive credentials and must not be stored in plain preferences, logs, docs, test fixtures, or UI state after saving. The package is a Flutter plugin for encrypted platform-specific secure storage and supports the project targets.

Consequences: Secure key persistence lives behind `SettingsStorage` / `SecureSettingsStorage`. UI code must not call `flutter_secure_storage` directly. The Settings UI exposes only saved/not-saved status after save. Widget tests use a fake storage boundary instead of platform secure storage. Android must meet the package minimum SDK requirement of 23.

## 2026-06-14 - Disable Android Auto Backup For MVP Secure Storage

Date: 2026-06-14

Decision: Disable Android app auto backup in the main Android manifest.

Status: accepted

Context: `flutter_secure_storage` documents Android backup/restore concerns for encrypted secure-storage data. The MVP stores user-provided AI API keys locally and does not yet define encrypted backup/restore behavior.

Consequences: Android app data is not automatically backed up by the platform. Future backup or sync behavior involving API keys or health data must be user-visible, opt-in where appropriate, and documented before implementation.

## 2026-06-15 - Use http For Provider Model Listing

Date: 2026-06-15

Decision: Add the `http` package for explicit OpenAI and Gemini model-listing calls.

Status: accepted

Context: The app needs to fetch provider model lists from official provider APIs after a user saves an API key. No direct HTTP client dependency existed.

Consequences: Network behavior must remain isolated behind provider-specific services. UI widgets must not make HTTP calls. The `http` dependency should not be used for background polling, analytics, backend sync, or AI chat responses without a documented follow-up decision.

## 2026-06-15 - Cache Model Lists In Memory Only

Date: 2026-06-15

Decision: Cache fetched model lists only in memory as model IDs and display names for the lifetime of the Settings controller.

Status: accepted

Context: Persisting provider model lists is not necessary for the MVP settings flow and could create stale data. The app only needs to avoid repeated calls during rebuilds or provider tab switching.

Consequences: Model lists are fetched after saving a key, when Settings opens for a provider with a saved key and no in-memory model cache, or when the user taps refresh. Raw provider responses and API keys are not cached. Removing a provider key clears that provider's in-memory model cache and selected model.

## 2026-06-15 - Use Conservative Provider Model Filtering

Date: 2026-06-15

Decision: Filter model lists conservatively to likely text/generative models.

Status: accepted

Context: Provider model list APIs can include embedding, image, audio, moderation, live, and other non-text models. The app should not hardcode a tiny permanent list, but it should avoid obvious unrelated models.

Consequences: OpenAI filtering keeps likely current GPT-family, ChatGPT-family, and `o*` reasoning model IDs while excluding obvious embedding/image/audio/moderation/realtime/search and legacy families. Gemini filtering keeps Gemini-family models with `generateContent` support and excludes obvious embedding/image/video/audio/live-only families. Filtering may need refinement as provider APIs evolve.

## 2026-06-15 - Prefer Text/Tool-Capable Model Candidates In Settings

Date: 2026-06-15

Decision: The Settings model picker should prefer likely text models that can support future tool/MCP-style coaching, and it should hide obvious non-text or specialized model families.

Status: accepted

Context: Future AI coach behavior may need models that can use tools before making decisions. The current OpenAI list-models endpoint exposes basic model metadata such as ID and ownership, but not a direct per-model MCP capability flag. Gemini's models endpoint exposes supported generation methods such as `generateContent`, but still does not provide one portable MCP-capability field across providers.

Consequences: Model filtering remains provider-specific. OpenAI filtering uses current GPT-family, ChatGPT-family, and `o*` reasoning ID families, excluding obvious embedding, image, audio, speech, realtime, search, video, vision, legacy GPT-3.x-style, and specialized computer-use IDs. Gemini filtering requires Gemini-family IDs with `generateContent` support and excludes obvious embedding, image/video/audio generation, realtime, and live-only families. This is a conservative Settings filter, not a final capability guarantee; revisit it when real AI chat/tool execution is implemented or if provider APIs expose explicit capability metadata.

## 2026-06-15 - Add Basic Non-Streaming Text Chat For Manual Provider Testing

Date: 2026-06-15

Decision: Implement the first Coach chat feature as explicit, user-triggered, non-streaming, text-only API calls to the active provider and selected model.

Status: accepted

Context: The app needs a small manual test path for the selected provider/API key/model flow before health summaries, tools, MCP, streaming, or persistent chat memory are introduced. The existing settings storage is already the source of truth for provider, saved-key status, and selected model.

Consequences: Chat UI reads provider/key/model through `SettingsStorage` via `ChatController`. Provider-specific request mapping and response parsing live behind `AiChatService`, `ProviderAiChatService`, `OpenAiChatService`, and `GeminiChatService`. OpenAI uses the Responses API with `store: false`; Gemini uses `generateContent`. Chat messages remain in memory only for the current screen session. No new dependency, health integration, background task, backend sync, analytics, crash reporting, tool/MCP behavior, streaming, or long-term memory was added.

## 2026-06-15 - Use flutter_markdown_plus For Assistant Markdown

Date: 2026-06-15

Decision: Add `flutter_markdown_plus` for rendering assistant Markdown in chat bubbles.

Status: accepted

Context: AI providers commonly return Markdown for headings, lists, emphasis, inline code, and code blocks. Hand-rolling a Markdown renderer would be brittle. The initially attempted `flutter_markdown` package was marked discontinued by pub, so the lightweight replacement package was chosen instead.

Consequences: Assistant messages render with `MarkdownBody` using the app theme. Link taps are intentionally no-op for now, and images are rendered as omitted text. No URL launcher, web view, external browsing behavior, network image loading, streaming, tools, or chat persistence was added.

## 2026-06-15 - Store Context Web Locally In Secure Storage For The Initial MVP

Date: 2026-06-15

Decision: Persist the Context Web / Info Matrix locally as a JSON document behind `ContextRepository` / `SecureContextRepository`, using the existing `flutter_secure_storage` dependency.

Status: accepted

Context: Context entries can include sensitive personal, health, fitness, preference, goal, and environment information. The current MVP does not need a database package, server backend, cloud sync, or large raw health datasets.

Consequences: Context storage stays local-first and small. The Context Matrix must not store API keys or secrets. Malformed stored data falls back to an empty matrix instead of crashing. A future migration to a database, encrypted file store, backend sync, or export/import format requires a documented decision.

## 2026-06-15 - Include Compact Context Web Summaries In Chat Prompts

Date: 2026-06-15

Decision: Include a bounded, structured summary of active Context Web entries in provider-specific system instructions for chat.

Status: accepted

Context: The AI fitness coach needs durable user context to give useful coaching, but raw history dumps increase privacy exposure, token usage, latency, and cost.

Consequences: `ContextSummaryBuilder` creates a compact prompt block with clear boundaries. Archived entries are excluded. Provider services receive only the summary string, not the full repository. Future health summaries should follow the same compact-summary pattern.

## 2026-06-15 - Use Conservative Rule-Based Context Extraction First

Date: 2026-06-15

Decision: Use conservative local rule-based extraction from user chat messages for the first context auto-population pass.

Status: accepted

Context: AI-based extraction would require additional provider calls, cost, latency, and privacy exposure. The first version only needs safe candidate capture for durable coaching facts the user clearly states.

Consequences: Extracted entries are marked `chat_extracted`, include confidence metadata, and do not overwrite manual or pinned entries. Extraction runs after successful chat sends and must not interrupt chat if it fails. Future AI extraction must be optional/guarded, user-visible where appropriate, and documented before implementation.

## 2026-06-15 - Use Lightweight Flutter UI For Context Web Polish

Date: 2026-06-15

Decision: Implement the polished Context Web / Info Matrix UI with built-in Flutter widgets, `CustomPainter`, and finite implicit animations instead of adding a graph or animation package.

Status: accepted

Context: The app needs a richer web-like experience, but the first version should stay maintainable, testable, and efficient on small phones. A freeform graph engine or heavy animation dependency would add complexity before the context product model is stable.

Consequences: Context Web uses a light network-chart canvas with a central user-context hub, radial section nodes, child entry/missing-field nodes, painted connection lines, entrance animations, expandable sections, and visual metadata chips. Animations are finite and respect reduced-animation settings. The data model, storage, prompt summary, and extraction behavior did not change. Future force-directed layout or graph package behavior should be documented before implementation.

## 2026-06-15 - Simulate 3D Context Matrix With Flutter Primitives

Date: 2026-06-15

Decision: Upgrade Context Web / Info Matrix into an interactive 3D-feeling matrix universe using regular Flutter primitives instead of adding a heavy 3D/game engine or graph package.

Status: accepted

Context: The product goal is an Apple Watch-style, living context universe with pan/zoom, tap-to-focus, depth, glow, and fluid section details. The task does not require true 3D rendering, and the app must stay lightweight, maintainable, and smooth on iPhone-sized devices.

Consequences: The UI uses `InteractiveViewer`, `TransformationController`, `Stack`, `Transform`, `CustomPainter`, finite `AnimationController`s, scale, opacity, shadows, gradients, and bounded virtual-canvas sizing. Tapping a section centers and focuses it, shows nearby depth shifts, expands child entry/missing nodes, and opens the focused detail panel. There is no new dependency, no game engine, no health integration, no cloud sync, no backend, and no background animation loop. The 3D effect remains simulated rather than true 3D; if future requirements need real 3D physics or very large graph layouts, that should be documented as a new dependency decision.

## 2026-06-15 - Keep Context Updates App-Controlled Before MCP

Date: 2026-06-15

Decision: Keep Context Matrix updates app-controlled with local validation and shared provider-agnostic prompt context instead of adding MCP/tool-calling.

Status: accepted

Context: The app currently supports OpenAI and Gemini through plain text API calls and has no implemented MCP/tool-calling path. The Context Matrix needs model-driven behavior, but provider compatibility, privacy, and validation are more important than giving models direct write access.

Consequences: Chat sends include a shared Context Matrix summary before provider-specific requests. After a successful chat turn, the app runs conservative local extraction and validates candidate context updates before saving. The context model now supports dynamic nodes/sub-nodes, lifespan, status, confirmation, sensitivity, priority, and expiry metadata. A defensive JSON suggestion parser exists for future AI-assisted extraction, but parsed suggestions still require app-side validation. Future MCP/tool-calling support may produce structured actions, but the app must remain the authority for context mutation.

## 2026-06-15 - Use Fullscreen Interactive-Only Matrix UI

Date: 2026-06-15

Decision: Make the Context Matrix screen a fullscreen interactive graph by default, with no visible counters, list panels, legends, or raw metadata on the main screen.

Status: accepted

Context: The product direction is an Apple Watch-style interactive context universe rather than an admin dashboard. Users should navigate semantic nodes and open management details only when needed.

Consequences: The main Context Matrix screen shows only the graph, semantic node labels, subtle close/add/zoom controls, missing-basic nodes, and animated connections. Detailed metadata, confidence, lifespan, sensitivity, confirmation state, edit/archive/delete/confirm/reject, and add-sub-node actions live in modal management sheets. The UI remains implemented with Flutter primitives and no heavy 3D/game dependency.
