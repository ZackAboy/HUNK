# Agent Operating Guide

This is the first file every future Codex agent must read before working on this project.

## Project Purpose

This project is a Flutter-based cross-platform AI fitness coach/helper app for iOS and Android. The long-term direction is an open, user-controlled alternative to WHOOP Coach or Google Health AI-style coaching.

The app should let users connect health data sources, generate useful health and fitness summaries, and use their own AI provider API keys for coaching conversations.

Initial provider targets:

- OpenAI
- Google Gemini

Initial health data targets:

- Apple HealthKit on iOS
- Google Health Connect on Android

## Required Reading Before Changes

Before making any code, configuration, dependency, architecture, or documentation change, every agent must read:

- `docs/PROJECT_OVERVIEW.md`
- `docs/FEATURES.md`
- `docs/ARCHITECTURE.md`
- `docs/TASK_LOG.md`
- `docs/SECURITY_AND_EFFICIENCY.md`

Read `docs/DECISIONS.md` when changing product direction, dependencies, architecture, integrations, storage, data models, or AI provider behavior.

Read `docs/SETUP.md` when changing setup, build, platform, or development workflow requirements.

## Core Engineering Priorities

Security and efficiency are non-negotiable engineering priorities for this project.

This app will handle sensitive personal health and fitness data. Users may also provide their own AI API keys. Every agent must actively check security and efficiency before adding or changing:

- Dependencies
- Platform permissions
- Services
- Data models
- Local storage
- Background jobs
- Network calls
- Health integrations
- AI prompt construction
- Analytics, logging, or crash reporting
- Watch, widget, or companion app features

Security rules:

- Do not store sensitive data casually. API keys must use secure storage, and health data should only be retained when the feature truly needs retention.
- Do not request broad permissions unless the feature truly needs them.
- Prefer minimal data access, minimal retention, and explicit user control.
- Avoid logging raw health data, API keys, AI prompts, or AI responses that may contain private health context.
- Do not send sensitive data to any backend unless it is explicitly required, user-approved, and documented.
- Document every security-sensitive decision in `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, and `docs/SECURITY_AND_EFFICIENCY.md` when relevant.

Efficiency rules:

- Do not add background processing, polling, sync loops, or recurring health reads without a documented need.
- Scope health reads by date range and metric type.
- Prefer local summaries and compact AI prompt context instead of raw data dumps.
- Cache summaries where appropriate, and avoid repeatedly recomputing or resending large health histories.
- Document every performance-sensitive decision, especially anything affecting battery, memory, network usage, startup time, or background execution.

The central reference for these rules is `docs/SECURITY_AND_EFFICIENCY.md`. Future agents must check it before making changes that touch data access, storage, prompts, networking, permissions, background work, or integrations.

## Current Priorities

1. Keep the MVP small and verifiable.
2. Build a Flutter app shell before advanced coaching behavior.
3. Establish health data access through Apple HealthKit and Google Health Connect.
4. Store user-provided OpenAI and Gemini API keys locally.
5. Generate a basic health summary.
6. Include the health summary in AI coach chat prompts.
7. Avoid premature architecture, abstractions, and provider integrations until needed.

## Development Rules

- Prefer small, verifiable changes.
- Avoid large rewrites unless explicitly requested.
- Keep implementation aligned with the existing architecture and naming.
- Do not silently change architecture, dependencies, or data models. Document meaningful changes in the relevant docs.
- Do not introduce new state management, storage, networking, AI, or health integration packages without documenting the decision.
- Keep platform-specific code isolated behind services or adapters.
- Keep AI provider code isolated behind clear provider/service boundaries.
- Treat health data as sensitive user data. Avoid logging raw health values, API keys, or chat context containing private data.
- Check security and efficiency impacts before changing permissions, storage, network behavior, background work, health access, or AI prompt content.
- Do not build app features when the user asks for documentation-only work.

## Architecture Rules

- `lib/main.dart` should stay minimal and start the app.
- `lib/app.dart` should own top-level app configuration, theming, and navigation setup.
- `lib/screens/` should contain user-facing screens.
- `lib/services/` should contain integrations and external system boundaries, including health services, AI services, storage services, and platform adapters.
- `lib/models/` should contain structured data models used across the app.
- `lib/providers/` should contain state management objects if and when a state management approach is selected.
- `lib/widgets/` should contain reusable UI components.
- Cross-platform code should be preferred where practical, with platform-specific details hidden behind services.
- Avoid coupling UI directly to platform channels, health SDKs, secure storage, or AI provider SDKs.

## Documentation Update Rules

After any meaningful code change, update the relevant docs in the same task:

- Update `docs/FEATURES.md` when feature status changes.
- Update `docs/ARCHITECTURE.md` when files, folders, services, models, providers, dependencies, or data flow change.
- Update `docs/TASK_LOG.md` with a chronological entry for every completed task.
- Update `docs/DECISIONS.md` when a technical or product decision is made or changed.
- Update `docs/SETUP.md` when setup, build, environment variables, platform setup, or run instructions change.

Every task response should explain:

- What files changed.
- Why they changed.
- Any tests or verification performed.
- Any follow-up tasks.

## Multi-Agent Handoff Rules

- Leave the repo in a state another agent can understand quickly.
- Keep docs concise and current. Do not duplicate large explanations across files.
- Prefer linking to the source of truth instead of repeating the same detail in multiple docs.
- Record important assumptions in `docs/TASK_LOG.md` or `docs/DECISIONS.md`.
- If a task uncovers incomplete or stale docs, update them before finishing.
