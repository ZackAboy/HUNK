# Features

Feature statuses must be one of: `planned`, `in-progress`, `done`, or `blocked`.

## Phase 1 MVP

| Feature | Status | Notes |
| --- | --- | --- |
| Flutter app shell | done | Material 3 shell with bottom navigation for the four MVP screens. |
| Home screen | done | Placeholder entry point for future summary and coaching prompts. |
| Health data screen | done | Placeholder screen only; real HealthKit and Health Connect data reads are still planned. |
| AI coach chat screen | done | Placeholder chat screen only; real AI calls are still planned. |
| Settings screen | done | Placeholder settings screen only; local API key storage is still planned. |
| Store OpenAI API key locally | planned | Must use secure local storage; never log, display casually, export, or store in plain preferences. |
| Store Gemini API key locally | planned | Must use secure local storage; never log, display casually, export, or store in plain preferences. |
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
| AI coach chat screen | Must make AI-provider transmission explicit. Prompts should include compact summaries rather than raw health histories. |
| Settings screen | Must expose clear user control for provider choice, API key entry/removal, and future health permission controls. |
| OpenAI/Gemini API key storage | Must use secure local storage and provide a clear delete path. Keys must not be logged, included in crash reports, or stored in test fixtures. |
| Health integrations | Must request the minimum permissions needed for the active feature and avoid continuous background syncing unless documented and user-controlled. |
| Basic health summary | Must prefer local processing, bounded reads, and cached summaries when data has not changed. |

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
