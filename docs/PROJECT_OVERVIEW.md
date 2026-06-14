# Project Overview

## Base Premise

This project is a Flutter-based cross-platform AI fitness coach/helper app for iOS and Android.

The long-term goal is to provide an open, user-controlled alternative to WHOOP Coach or Google Health AI-style coaching. The app should help users understand their health and fitness data, ask questions about trends, and receive practical coaching suggestions while keeping control over their own data and AI provider choices.

## MVP Scope

The MVP should focus on a small, useful loop:

1. The user opens a Flutter app on iOS or Android.
2. The app reads basic health data from the platform health source.
3. The app generates a basic health summary.
4. The user enters their own AI API key.
5. The user chats with an AI coach.
6. The AI coach receives the health summary as part of its prompt context.

## Initial Platforms

- iOS
- Android

## Initial Health Integrations

- Apple HealthKit on iOS
- Google Health Connect on Android

## Initial AI Providers

- OpenAI
- Google Gemini

Users should bring their own API keys. The app should not require a project-hosted backend for the initial MVP.

## Trust And Resource Expectations

Users will trust this app with sensitive health and fitness data. They may also store personal OpenAI or Google Gemini API keys in the app. The product must be secure-by-default, privacy-conscious, and explicit about what data it accesses and why.

The app must also stay lightweight. It should avoid unnecessary background work, broad health reads, large network payloads, repeated AI calls, and wasteful local processing. A fitness coach app should not become a battery hog, memory hog, network hog, or background-processing-heavy app.

See `docs/SECURITY_AND_EFFICIENCY.md` for the practical rules future agents must check before touching permissions, health data, API keys, AI prompts, networking, storage, background work, analytics, or future watch/widget support.

## Product Principles

- Keep the MVP small.
- Make health data understandable, not overwhelming.
- Keep user control over AI provider configuration.
- Treat health data and API keys as sensitive.
- Make security and efficiency first-class product constraints.
- Be privacy-conscious and secure-by-default.
- Prefer minimal data access, minimal data retention, and explicit user control.
- Keep the app lightweight in battery, memory, network, and background execution.
- Prefer practical coaching and summaries over complex analytics in the first version.
- Avoid overengineering until real feature needs require it.
