# Setup

This file explains how to set up and run the project locally. The Flutter app has been initialized for iOS and Android.

## Prerequisites

Requirements:

- Flutter SDK
- Dart SDK included with Flutter
- Xcode for iOS development
- Android Studio for Android development
- iOS Simulator and/or physical iOS device
- Android Emulator and/or physical Android device

## Flutter Install

Placeholder:

1. Install Flutter from the official Flutter documentation.
2. Add Flutter to your shell path.
3. Run:

```sh
flutter doctor
```

4. Resolve any platform setup issues reported by Flutter.

## Dependency Install

```sh
flutter pub get
```

## Run The App

```sh
flutter run
```

For a specific device:

```sh
flutter devices
flutter run -d <device-id>
```

## Test And Analyze

```sh
flutter analyze
flutter test
```

## iOS Setup

Placeholder for future iOS setup:

- Open the iOS project in Xcode when native configuration is required.
- Configure signing for physical devices.
- Enable required capabilities for Apple HealthKit.
- Add HealthKit permission descriptions.
- Verify HealthKit behavior on a supported device or simulator where possible.

## Android Setup

Placeholder for future Android setup:

- Configure Android SDK and emulator through Android Studio.
- Add required Health Connect permissions.
- Confirm Health Connect availability on the test device or emulator.
- Add any required package visibility or intent configuration.

## Future Health Integration Setup

Planned health integrations:

- Apple HealthKit on iOS
- Google Health Connect on Android

Future setup docs should include:

- Package names and versions.
- Platform permission steps.
- Native configuration changes.
- Testing instructions.
- Known simulator/emulator limitations.

## API Key Setup

Planned AI providers:

- OpenAI
- Google Gemini

For the MVP, users should provide their own API keys inside the app settings screen. API keys should be stored locally using secure storage once implemented.

Do not commit API keys, test keys, or local secrets to the repository.

## Documentation Setup

Before making project changes, read:

- `docs/AGENT.md`
- `docs/PROJECT_OVERVIEW.md`
- `docs/FEATURES.md`
- `docs/ARCHITECTURE.md`
- `docs/TASK_LOG.md`

Update relevant docs after meaningful changes.
