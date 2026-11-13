# App

FridgeFriend's mobile client — a single Flutter codebase targeting Android and iOS.

Part of the [FridgeFriend](https://github.com/ervinhun/FridgeFriend) project. See that repo for the overall product plan, roadmap and tech stack; this repo covers only the client.

## Getting started

The Flutter project lives in [`app/`](app/). Follow the instructions in [`app/README.md`](app/README.md) to set up a local Flutter environment, then:

```sh
cd app
flutter pub get
cp .env.example .env # then fill in the values
flutter run --dart-define-from-file=.env
```

## Backend API client

The client for the backend (`AuthClient`, `FridgesClient`, and their request/response models) is generated into [`app/lib/core/api/generated/`](app/lib/core/api/generated/) by [`swagger_parser`](https://pub.dev/packages/swagger_parser) from the backend's OpenAPI document. Don't edit it by hand. After a backend change to an endpoint or DTO, build the backend (that rewrites `Backend/openapi/FridgeFriend.json`), then, with the parent `FridgeFriend` repo checked out:

```sh
cd app
dart run swagger_parser
dart run build_runner build -d
dart format lib
```

and commit the result. Wrap calls in `apiCall(...)` (`core/api/api_client.dart`) so failures surface as `ApiException`.

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

## Planned pages
- Auth screen (Login, register, forgot password)
- e-mail verification page (?)
- New joiners page (You still don't have a fridge/room added - Add your frist fridge/room or join a fridge) - Later might be a demo page, if time permits
- Main page (Fridge)
- Add Food (Manual)
- Open food (take some of it)
- Notification
- Pending scans (Only when IoT device is present)
- Activity log (admins only)
- Members
- Management:
  - Manage fridges (CRUD, re-generate invite code, add IoT device) (Admin only)
  - Expiry-default overrides (Admin only)
  - Join fridge page
  - Manage container (Admin only)
  - Member rights editor (Admin only)
  - Remove self
  - Activity log (Admin only)
  
- You:
  - Password change
  - Default display name change
  - e-mail change
  - delete account / logout (An owner who deletes their account must transfer ownership first, or the fridge ends up with no owner. The docs call this out explicitly.)
  - Language change
  - Notification settings
  - (NOT a seperate page, but we need) - Theme (Light/Dark/Auto)
  - Optional, flag-gated: an upgrade/paid-tier screen