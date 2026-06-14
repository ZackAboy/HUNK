# Features

Feature statuses must be one of: `planned`, `in-progress`, `done`, or `blocked`.

## Phase 1 MVP

| Feature | Status | Notes |
| --- | --- | --- |
| Flutter app shell | planned | Top-level app structure, theme, and navigation. |
| Home screen | planned | Entry point with summary and navigation. |
| Health data screen | planned | Display basic connected health data and permissions state. |
| AI coach chat screen | planned | Chat interface for user questions and coach responses. |
| Settings screen | planned | API key entry, provider selection, and integration settings. |
| Store OpenAI API key locally | planned | Use local secure storage when selected. |
| Store Gemini API key locally | planned | Use local secure storage when selected. |
| Basic Apple HealthKit integration | planned | iOS health permissions and basic data reads. |
| Basic Google Health Connect integration | planned | Android health permissions and basic data reads. |
| Basic health summary | planned | Small summary model derived from available health data. |
| Chat prompt includes health summary | planned | Health summary should be included in AI coach context. |

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
