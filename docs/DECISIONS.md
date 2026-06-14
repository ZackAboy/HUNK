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
