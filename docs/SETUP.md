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

For the MVP, users provide their own API keys inside the app Settings screen. API keys are stored with `flutter_secure_storage` and are not displayed back to the user after saving.

After a key is saved, Settings can fetch the selected provider's available models from the provider's official model-list endpoint and store a provider-specific selected model locally.

Do not commit API keys, test keys, or local secrets to the repository.

## Secure Storage Setup

The app uses `flutter_secure_storage` for local API key storage.

Current setup notes:

- Android must support API level 23 or newer for this secure-storage package version.
- Android auto backup is disabled in `android/app/src/main/AndroidManifest.xml` while sensitive backup/restore behavior is undefined.
- No biometric-gated key access is configured yet.
- No app backend receives API keys.
- Model list calls require network access and valid provider API keys, but tests use fake model listing services and do not need real keys.
- iOS secure-storage behavior should be verified on a simulator and physical device before release.

## Documentation Setup

Before making project changes, read:

- `docs/AGENT.md`
- `docs/PROJECT_OVERVIEW.md`
- `docs/FEATURES.md`
- `docs/ARCHITECTURE.md`
- `docs/TASK_LOG.md`

Update relevant docs after meaningful changes.
