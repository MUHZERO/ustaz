# Ustaz — student app

Flutter app for **Ustaz**, a tutoring platform for one private teacher. Students watch lectures, take gated
quizzes and timed exams, and redeem activation codes. It talks to the Laravel API in [`../backend`](../backend)
through the contract in [`../docs/api-contract.md`](../docs/api-contract.md).

Flutter 3.44 · Dart 3.12 · GetX · Android and iOS · Arabic (RTL, default) and English.

## Features

**Learning**

- Home with announcements, continue watching, categories and free lectures.
- Categories (monthly or term packages) with lectures, exams and papers; locks come from the server.
- Lectures built from ordered video, PDF and quiz segments. A locked segment explains why and jumps to the
  gating quiz instead of opening.
- Video resumes where the student stopped and reports watch progress.
- PDFs open inside the app.

**Assessments**

- One engine for quizzes, homework and timed exams: question navigator, flags, countdown.
- The countdown follows the server deadline, not the phone clock.
- Answers are saved locally first and re-sent after a network drop; an app killed mid-exam resumes the same
  attempt with its answers.
- Results, answer review and review requests to the teacher.

**Account**

- Register and log in with phone and password; activation codes; results and homework history;
  notifications inbox; profile, language and dark mode.
- Any `401` (password reset, device approved elsewhere) sends the student back to login once.

**Content protection**

- **Single device:** the account is bound to one device id; a new device waits for the teacher's approval.
- **Android:** `FLAG_SECURE` on the whole app blocks screenshots and screen recording.
- **iOS:** screen recording and mirroring are detected (`UIScreen.capturedDidChange`) and pause the video.
- **Watermark:** the student's name and phone drift over the video, so a filmed screen points to its owner.

This is protection, not DRM: see [Videos](#videos).

## Screenshots

| Home | Lecture | Exam | Result |
|---|---|---|---|
| ![Home](../docs/screenshots/app-home.png) | ![Lecture](../docs/screenshots/app-lecture.png) | ![Exam](../docs/screenshots/app-exam.png) | ![Result](../docs/screenshots/app-result.png) |

_Screenshots are taken on a device against the demo backend and added once ready._

## Run

Start the backend first ([backend/README.md](../backend/README.md)); demo students log in with `password`.
Then:

```bash
cd app
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1
```

`API_URL` is the API base URL, `/api/v1` included. Without it the app uses `http://10.0.2.2:8000/api/v1`: the
host machine seen from the Android emulator, with the backend started by `php artisan serve --host 0.0.0.0`.
On a real device, use the computer's LAN address or a deployed backend.

Plain HTTP is allowed in Android debug builds only. Release builds and iOS need HTTPS:

```bash
flutter build apk --release --dart-define=API_URL=https://api.example.com/api/v1
flutter build ipa --release --dart-define=API_URL=https://api.example.com/api/v1
```

## Rebrand for a teacher

Every client-specific value lives in a handful of files:

| What | Where |
|---|---|
| App name and brand colors | `lib/core/config/app_config.dart` (`appName`, `primaryColor`, `darkColor`) |
| App bar title | `app_name` in `lib/core/i18n/ar.dart` and `lib/core/i18n/en.dart` |
| Android application id | `namespace` and `applicationId` in `android/app/build.gradle.kts`, and the package of `android/app/src/main/kotlin/dev/muhdroid/ustaz/MainActivity.kt` (move the file to match) |
| Android launcher name | `android:label` in `android/app/src/main/AndroidManifest.xml` |
| iOS bundle id | `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj` (or Xcode › Runner › Signing) |
| iOS home-screen name | `CFBundleDisplayName` in `ios/Runner/Info.plist` |
| Launcher icons | `android/app/src/main/res/mipmap-*/ic_launcher.png` and `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |

The default id is `dev.muhdroid.ustaz`. With push enabled, run `flutterfire configure` again after changing it.

## Push notifications (optional)

The app runs without Firebase: until it is configured, push stays off and nothing else changes.

1. Create a Firebase project, then from `app/`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   It registers the Android and iOS apps and writes `lib/firebase_options.dart`.
2. Return the generated options from `lib/core/config/firebase_config.dart`:

   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import '../../firebase_options.dart';

   abstract final class FirebaseConfig {
     static FirebaseOptions? options() => DefaultFirebaseOptions.currentPlatform;
   }
   ```

3. iOS only: upload an APNs key in Firebase and enable the Push Notifications capability in Xcode.
4. On the backend, set `PUSH_DRIVER=fcm` with a service account from the same project.

Once a student is signed in, the app registers its token with the API. Tapping a notification opens the
lecture, category, result or inbox it points to.

## Videos

Lecture videos are **unlisted YouTube** videos. The API returns the video id only to a signed-in student on
their bound device, for a segment they may open, and the app never shows or logs the id or a YouTube link.

- **Android** plays through [`md-player`](https://github.com/MUHZERO/md-player), which resolves the stream
  itself (it depends on `youtube_explode_dart`). If resolution fails, the app falls back to the YouTube iframe
  player.
- **iOS** uses the YouTube iframe player (`youtube_player_iframe`).

Stream resolution can break when YouTube changes and may conflict with YouTube's terms of service, and an
unlisted link that leaks can still be watched outside the app.

## Architecture

```
lib/
  main.dart, app_bootstrap.dart   app widget; services and repositories registered once
  core/
    base/          BaseController, StateView, PagedController
    config/        AppConfig, Env (API_URL), FirebaseConfig
    network/       ApiClient, TokenStore, DeviceIdStore
    routes/        AppRoutes, AppPages
    i18n/          ar.dart, en.dart (GetX translations)
    security/      ScreenCaptureGuard, Watermark
    widgets/       widgets shared by more than one screen
  data/
    models/        plain models with fromJson
    repositories/  auth, content, progress, assessment, access, notifications
  modules/<feature>/   binding · controller · view
  services/      AuthService (session, 401), PushService, SettingsService, ProgressReporter
```

- **One HTTP client.** Every repository goes through `ApiClient`, which adds the token, device id and language
  and turns error responses into `ApiException` with field errors.
- **GetX modules.** A binding builds the controller from the repositories; the controller extends
  `BaseController` and runs each call through `run()`; the view is a `GetView` that renders the state with
  `StateView`. Loading, empty, error and retry look the same on every screen.
- **No hard-coded text.** Every user-facing string goes through `.tr`; switching language rebuilds the app in
  the new direction.

## Tests

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test
```

Widget and unit tests cover every controller, the exam engine (server deadline, retried answers, resume), the
`401` logout, locked segments, the video fallback, and a smoke test that opens every route in Arabic and
English against a fake API.

## License

[MIT](../LICENSE) © 2026 Mohamed Nait Merri
