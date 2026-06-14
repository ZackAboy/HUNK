# Architecture

This file is the living index/database of the codebase. Update it whenever files, services, models, providers, dependencies, or data flow change.

## Current State

No Flutter app code has been created yet. The project currently contains documentation only.

## Intended Structure

```text
lib/
  main.dart
  app.dart
  screens/
  services/
  models/
  providers/
  widgets/
```

## Intended Files And Folders

| Path | Purpose | Status |
| --- | --- | --- |
| `lib/main.dart` | Minimal app entry point. Should initialize required bindings and run the app. | planned |
| `lib/app.dart` | Top-level Flutter app configuration, theme, navigation, and app shell wiring. | planned |
| `lib/screens/` | User-facing screens such as Home, Health Data, AI Coach Chat, and Settings. | planned |
| `lib/services/` | External boundaries and app services such as health data access, AI provider calls, API key storage, and platform adapters. | planned |
| `lib/models/` | Shared structured models such as health summaries, chat messages, provider configuration, and check-ins. | planned |
| `lib/providers/` | State management layer if and when a state management approach is selected. | planned |
| `lib/widgets/` | Reusable UI components used across screens. | planned |
| `docs/AGENT.md` | First-read operating guide for future Codex agents. | active |
| `docs/PROJECT_OVERVIEW.md` | Product premise, MVP boundaries, platforms, and initial integrations. | active |
| `docs/FEATURES.md` | Phased feature list with status tracking. | active |
| `docs/ARCHITECTURE.md` | Living codebase index, dependency map, data flow, and update rules. | active |
| `docs/TASK_LOG.md` | Chronological development log for future agents. | active |
| `docs/DECISIONS.md` | Major product and technical decisions. | active |
| `docs/SETUP.md` | Local setup and run instructions. | active |

## Dependency Map

Current dependency map:

```text
docs only
```

Intended app dependency direction:

```text
main.dart
  -> app.dart
    -> screens/
      -> providers/
      -> widgets/
    -> providers/
      -> services/
      -> models/
    -> services/
      -> models/
      -> platform health integrations
      -> local storage
      -> AI provider APIs
```

Rules:

- Screens may depend on providers, models, widgets, and simple app configuration.
- Screens should not directly call Apple HealthKit, Google Health Connect, OpenAI, Gemini, secure storage, or platform channels.
- Providers may coordinate services and expose UI-ready state.
- Services may call external SDKs, platform APIs, storage, and network clients.
- Models should stay free of UI and platform-specific dependencies.
- Widgets should be reusable and should not own business logic.

## Data Flow

Intended MVP data flow:

```text
Health data source
  -> health service
  -> health summary model
  -> AI prompt
  -> chat response
  -> chat screen
```

Detailed flow:

1. Apple HealthKit or Google Health Connect provides raw health metrics after user permission.
2. A platform-aware health service reads the available metrics.
3. The app converts selected metrics into a basic health summary model.
4. The AI coach service builds a prompt that includes the health summary and the user's chat message.
5. The selected AI provider returns a chat response.
6. The chat screen displays the response and preserves useful conversation state.

## Sensitive Data Boundaries

- API keys should be stored locally using secure storage when implemented.
- Raw health data should not be logged.
- Prompts containing health summaries should be treated as sensitive.
- Any future backend or sync system must be documented in `docs/DECISIONS.md` before implementation.

## Update Rules

This file must be updated whenever any of the following are added, removed, or renamed:

- Files
- Folders
- Services
- Models
- Providers
- Screens
- Widgets
- Dependencies
- Platform integrations
- Data flow steps
- Storage mechanisms
- AI provider integrations

When updating this file, keep it concise and index-like. Put chronological details in `docs/TASK_LOG.md` and major rationale in `docs/DECISIONS.md`.
