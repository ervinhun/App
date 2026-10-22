# App

FridgeFriend's mobile client — a single Flutter codebase targeting Android and iOS.

Part of the [FridgeFriend](https://github.com/ervinhun/FridgeFriend) project. See that repo for the overall product plan, roadmap and tech stack; this repo covers only the client.

## Getting started

The Flutter project lives in [`app/`](app/). Follow the instructions in [`app/README.md`](app/README.md) to set up a local Flutter environment, then:

```sh
cd app
flutter pub get
flutter run
```

## CI/CD

- **`ci.yml`** — format check, analyze, test (test running is currently disabled via `RUN_TESTS`, kept wired in for when the team starts writing them).
- **`cd.yml`** — on every push to `main` that passes CI: computes the next semver tag from commit messages and creates a GitHub release. The real Android build job in here is a placeholder until the pieces below exist.
- **`cd-android.yml`** — builds a release APK/AAB on every push to `main` that passes CI. Runs right now with debug signing and no distribution (uploads as a build artifact); becomes a real signed build distributed to Firebase App Distribution testers once these repo secrets are added:
  - `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` — also requires wiring `android/app/build.gradle.kts`'s release `signingConfig` to read `android/key.properties` (still TODO, signs with the debug key today).
  - `FIREBASE_APP_ID`, `FIREBASE_SERVICE_CREDENTIALS` — Firebase App Distribution.
- **`cd-ios.yml.disabled`** — same idea for iOS; stays disabled until the Apple developer account and `CERTIFICATE_PASSWORD`/`DISTRIBUTION_CERT_BASE64`/`PROVISIONING_PROFILE_BASE64` secrets exist, then rename it to `cd-ios.yml`.

## Tech stack

- Flutter (Android + iOS)
- Firebase Crashlytics & Analytics
