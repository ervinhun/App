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

## Current state

| Area | State | PR |
| --- | --- | --- |
| OAuth login | Done | [#1](../../pull/1) |
| Refresh tokens, backend logout, generated API client | Done | [#2](../../pull/2) |
| Planned pages list | Done | [#5](../../pull/5) |
| Dashboard (fridge/freezer/pantry, expiry filter, swipe actions with undo) | Done | [#6](../../pull/6) |
| Expiry notifications (Android + iOS) | In review | [#8](../../pull/8) |
| App name, icon and local-network access for device builds | In review | [#7](../../pull/7) |

Food items are sample data held in memory until the backend has an items endpoint.

### Expiry notifications

- Asks for the system notification permission, and shows a native dialog that links to settings if it is refused.
- Warning and danger days (default 7 and 2) and the notification time (default 16:00) come from the backend, are saved on the device and are rechecked at startup.
- A daily background task refreshes the list just before the notification time and falls back to the saved list when offline.
- One digest per time, such as "You have 3 items which expire in 7 days, and 2 items which expire in 2 days". Tapping it opens the dashboard filtered by expiry.
- Follows each fridge's notification recipients, and reports delivered reminders to `notification_dispatches`.
- The Management tab has a "Send test notification" button that uses the real data.
- Needs backend endpoints that don't exist yet (`/api/fridges/{id}/items`, `/api/fridges/{id}/notification-dispatches`) and a notification-time field; until then the app uses the saved list and retries dispatch reports.
- The message text is English only; localization is a separate task.

### Running on a phone

Copy `app/.env.example` to `app/.env.phone` with your computer's LAN IP as the API address (it is git-ignored), then run with `--dart-define-from-file=.env.phone`. On iOS use a release build to launch from the home screen. CocoaPods is still required for iOS.

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

- Flutter (Android + iOS), Riverpod, go_router, Dio + Retrofit
- flutter_local_notifications and workmanager for expiry reminders
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