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

## Product Principles

- Keep the MVP small.
- Make health data understandable, not overwhelming.
- Keep user control over AI provider configuration.
- Treat health data and API keys as sensitive.
- Prefer practical coaching and summaries over complex analytics in the first version.
- Avoid overengineering until real feature needs require it.
