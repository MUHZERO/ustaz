# Ustaz — backend

Laravel API and Filament teacher panel for **Ustaz**, a tutoring platform for one private teacher.
The Flutter student app in [`../app`](../app) talks to the API described in
[`../docs/api-contract.md`](../docs/api-contract.md).

Laravel 13 · PHP 8.4 · Filament 5 · Sanctum · Pest · Redis or plain database drivers.

## Features

**Teacher panel (`/admin`)**

- Levels, categories (monthly or term packages), lectures built from ordered video / PDF / quiz segments,
  papers and home-screen announcements.
- Question bank with Excel import; quizzes, homework and timed exams built from the bank.
- Students: search, subscriptions, password reset, block, one-device binding with a reset-request inbox,
  Excel export.
- Activation codes: generate a batch per category, export or print it as an RTL sheet, follow usage.
- Review requests on exams; changing a correct answer re-scores every past attempt in a queued job and keeps
  the old score in history.
- Analytics per lecture (who watched, who is subscribed and has not) and per exam (average, distribution,
  error rate per question), with Excel export.
- Push notifications to everyone, a level or a category.
- Two roles: teacher and assistant (no content deletion, no question edits).

**Student API (`/api/v1`)**

- Register and log in with phone and password; one bound device per student.
- Home, categories and lectures with locks computed from subscriptions, free content and gating quizzes.
- Watch progress, quiz and exam attempts with server-side deadlines, results and answer review.
- Code redemption, notifications inbox, results and homework history.

**Built to hold an evening rush**

- Hot reads (home, category, lecture) come from a tagged cache; a warm request runs no content queries.
- A cache failure falls back to the database; lazy loading throws outside production.
- Slow work (re-scoring, code batches, push sends, exam auto-submit) runs in queued jobs.
- `tests/Feature/LoadSmokeTest.php` serves 200 home and category requests for different students on the
  demo data and fails above five seconds.

## Screenshots

| Panel dashboard | Lecture builder | Exam report |
|---|---|---|
| ![Dashboard](../docs/screenshots/panel-dashboard.png) | ![Lecture builder](../docs/screenshots/panel-lecture.png) | ![Exam report](../docs/screenshots/panel-exam-report.png) |

_Screenshots are added once the UI is final._

## Local setup

Requirements: PHP 8.4 with the `pdo_sqlite`, `intl` and `zip` extensions, Composer, and optionally Redis.

### Laravel Herd (macOS / Windows)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed        # APP_ENV=local seeds the demo data
herd link ustaz                   # serves http://ustaz.test
php artisan queue:work            # keep running in a second terminal
```

Open `http://ustaz.test/admin`.

### Laravel Sail (Docker)

Sail is not a project dependency. Add it once, then run the same steps inside the containers:

```bash
cd backend
composer require laravel/sail --dev
php artisan sail:install --with=mysql,redis
./vendor/bin/sail up -d
./vendor/bin/sail artisan key:generate
./vendor/bin/sail artisan migrate --seed
./vendor/bin/sail artisan queue:work
```

### Demo data

`DatabaseSeeder` calls `DemoSeeder` only when `APP_ENV=local`. On any other environment, seed the demo on
purpose into a fresh database with `php artisan db:seed --class=DemoSeeder`.

| Who | Login | Password |
|---|---|---|
| Teacher | `teacher@ustaz.test` at `/admin` | `password` |
| Assistant | `assistant@ustaz.test` at `/admin` | `password` |
| Students | any student phone listed in the panel, through the app | `password` |

The demo is a small linear-algebra course: two levels, three categories (أكتوبر is free, نوفمبر and
الترم الأول are paid), six lectures with a video, a gating quiz and a PDF each, 40 bank questions, an exam open
for a week, 50 students with subscriptions, watch progress and quiz attempts, two pending device resets and a
batch of 50 activation codes. The videos are public 3Blue1Brown lessons, used only as placeholders.

## Environment

Cache, queue and session drivers come from `.env`; the code never assumes Redis.

| | Redis (recommended) | Database (cheap shared hosting) |
|---|---|---|
| Cache | `CACHE_STORE=redis` — native cache tags | `CACHE_STORE=database` — tags emulated with version keys |
| Queue | `QUEUE_CONNECTION=redis` | `QUEUE_CONNECTION=database` |
| Session | `SESSION_DRIVER=redis` | `SESSION_DRIVER=database` |

Redis needs the `phpredis` extension and `REDIS_CLIENT=phpredis`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`.

### Queue worker

Exams are auto-submitted by delayed jobs, so a worker must always run:

```bash
php artisan queue:work --tries=3 --max-time=3600
```

Keep it alive with Supervisor (or the host's process manager) in production. Do not use
`QUEUE_CONNECTION=sync` outside tests: delayed jobs would run at once and close exams as soon as they start.

### Videos

Lecture videos are **unlisted YouTube** videos. The teacher pastes the video id in the lecture builder; the API
returns it only to a logged-in student, on their bound device, for a segment they are allowed to open. The app
plays it through [`md-player`](https://github.com/MUHZERO/md-player) and never shows the id or a YouTube link.

This is protection, not DRM: an unlisted link that leaks can still be watched outside the app. The app extracts
the stream with `youtube_explode_dart`, which can break when YouTube changes and may conflict with YouTube's
terms of service — teachers should know this before relying on it.

### Push notifications (optional)

The demo needs no external account: `PUSH_DRIVER=log` writes pushes to the log.
To send real pushes through Firebase Cloud Messaging:

1. Create a Firebase project and add the Android and iOS apps.
2. Download a service-account JSON key and keep it outside the web root and out of git.
3. Set `PUSH_DRIVER=fcm` and `FIREBASE_CREDENTIALS=/absolute/path/to/service-account.json`.

## Tests and code style

```bash
php artisan test --compact
vendor/bin/pint --test
```

## License

[MIT](../LICENSE) © 2026 Mohamed Nait Merri
