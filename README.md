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

### Deploying to a real iPhone

Needs a Mac with Xcode, a cable, and a free Apple ID (a Personal Team; no paid developer account).

1. On the iPhone, turn on Developer Mode (Settings > Privacy & Security > Developer Mode), restart, and trust the Mac when asked.
2. In Xcode, open `app/ios/Runner.xcworkspace`, select Runner > Signing & Capabilities, tick "Automatically manage signing" and pick your Personal Team. Change the bundle identifier if Xcode says it is taken.
3. Copy `app/.env.example` to `app/.env.phone` (git-ignored) and set the API address to your computer's LAN IP, not `localhost`. The phone and computer must be on the same Wi-Fi. The branch in PR #7 allows plain http to local addresses.
4. Build a release version, because a debug build can't be launched from the home screen:

   ```sh
   cd app
   flutter build ios --release --dart-define-from-file=.env.phone
   xcrun devicectl list devices
   xcrun devicectl device install app --device <device id> build/ios/iphoneos/Runner.app
   ```

   Or run `flutter run --release --dart-define-from-file=.env.phone -d <device id>`.
5. The first launch says "Untrusted Developer": on the iPhone open Settings > General > VPN & Device Management, trust your Apple ID, then open the app. Installing with `devicectl` keeps the trust between installs.
6. Allow notifications when asked. Use the "Send test notification" button on the Management tab to check them.

Notes: free-signing builds expire after 7 days, so install again. CocoaPods is still required for iOS; don't run `pod install` by hand, `flutter build` does it. The iOS background refresh time is chosen by the system.

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

`CI` → `Release Gates` → `cd.yml` + `cd-android.yml`, each started when the one before it finishes (`workflow_run`). `workflow_run` workflows run from the copy on `main`, so changes to them take effect once they reach `main`.

- **`ci.yml`** — format check, analyze, test.
- **`release-gates.yml`** — on every push to `main` that passes CI. A build on a phone can't be rolled back, so before anything is released it checks:
  - **API contract**: the API client regenerated from Backend `main`'s OpenAPI document (what production runs) is identical to the committed one. If the app needs an endpoint production doesn't have yet, release the Backend first.
  - **Live API**: Backend's own read-only facts script (`scripts/e2e-facts.sh`) holds against `API_BASE_URL`.
  - **Release APK**: built with the same flags as `cd-android.yml`, then [`scripts/apk-facts.sh`](scripts/apk-facts.sh) checks the merged manifest (not debuggable, no backup, no cleartext) and that `API_BASE_URL` is compiled in. Run it locally on any APK: `ANDROID_HOME=~/Library/Android/sdk bash scripts/apk-facts.sh <apk> <api-base-url>`.
- **`cd.yml`** — once the gate passed: computes the next semver tag from commit messages and creates a GitHub release. The real Android build job in here is a placeholder until the pieces below exist.
- **`cd-android.yml`** — once the gate passed (or run by hand): builds a release APK/AAB for `API_BASE_URL`. Once the `KEYSTORE_*` secrets exist it fails if the APK is still signed with the debug key. Runs right now with debug signing and no distribution (uploads as a build artifact); becomes a real signed build distributed to Firebase App Distribution testers once these repo secrets are added:
  - `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` — also requires wiring `android/app/build.gradle.kts`'s release `signingConfig` to read `android/key.properties` (still TODO, signs with the debug key today).
  - `FIREBASE_APP_ID`, `FIREBASE_SERVICE_CREDENTIALS` — Firebase App Distribution.
- Repository **variables** both the gate and `cd-android.yml` need: `API_BASE_URL` (the production API, `https://fridgefriend-api.fly.dev`) and `GOOGLE_SERVER_CLIENT_ID`.
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