# Ustaz — open-source tutoring platform for one teacher

Status: draft for Mohamed's approval (access model and password reset confirmed by Mohamed) · 2026-10-19
Working name: **Ustaz** (أستاذ). Mohamed can rename before the first public push.

## 1. Intent

An open-source, production-quality platform for **one private teacher** (Egypt first, Arabic world in general):
a **Flutter student app** and a **Laravel + Filament admin panel** for the teacher.

Why it exists: the repository is Mohamed's showcase. A teacher, tutoring center or agency that opens it on
GitHub must feel they are looking at the work of an experienced professional, and contact Mohamed to build
their own branded version. Other developers forking and extending it is welcome, not the goal.

Success looks like: clean, readable, tested code; a README with screenshots and a 5-minute local setup;
a demo that runs on seed data; client inquiries that mention the repo.

## 2. Goals

- Real feature set Egyptian teachers ask for (see §5), not a toy.
- Code a reviewer respects: OOP, single responsibility, **no duplicated code**, consistent patterns.
- Fast under load: a class of hundreds of students opening the app at 8 pm must not take the server down.
- Minimal dependencies on both sides.
- Arabic-first RTL UI with English as second language.

## 3. Non-goals (v1)

- No public website / web student portal (maybe later).
- No multi-teacher / multi-tenant mode, no SaaS billing, no WhatsApp/Telegram bots, no AI, no forum, no
  bookings, no center/"smart center" management. These exist in Mohamed's paid `lms-multi-tenant`; the open
  version must not compete with it.
- No in-app payment gateway. Students pay outside the app; the teacher activates access.
- No live classes (Zoom links can come later).

## 4. Anti-goals (would make it a failure even if it works)

- Any trace of the reference client (name, logo, content, Firebase project, API host). The private reference
  lives in `muh-projects/_reference/education-master` and is never copied into this repo.
- Any code copied from `lms-multi-tenant` (ideas only).
- Copy-paste between controllers/screens (e.g. the reference had `exam_quiz_controller` and
  `new_exam_quiz_controller` doing the same thing). One quiz engine serves quizzes, homework and exams.
- A heavy package list "because it's convenient".
- N+1 queries, uncached hot endpoints, synchronous heavy work in requests.

## 5. Features

### 5.1 Content model
- **Level** (academic year, e.g. 1st secondary) → **Category** → content.
- A **category** is a teaching package, usually named after a month ("October", "November") or a term
  ("Term 1"). It is **not a time period**: "October" is simply the block of material taught that month.
  Categories are ordered and belong to one level.
- A category contains **lectures**, **exams** and **papers (PDF handouts)**.
- A lecture is an ordered list of **segments**: `video`, `pdf`, `quiz`. A quiz segment can sit before, inside
  (between two videos) or after the video. A segment can be **gating**: the next segment unlocks only after
  passing it (pass mark set by the teacher).
- **Free content**: a whole category or a single lecture/exam can be marked free — any registered student of
  that level opens it without a subscription.
- **Announcements / slider** on the home screen.

### 5.2 Access
- Student registers with phone + password + level (+ name, parent phone). No OTP, no email.
- **Forgotten password**: the teacher or assistant sets a new one from the panel. No reset links, OTP or email.
- A **subscription** = student + category + optional `ends_at`. Activating a student on "October" opens
  everything inside "October" (lectures, exams, papers), whenever it was published. If the teacher sets an end
  date, access stops then; with no end date it is **lifetime**. A student can hold several subscriptions.
- Two ways to grant: (a) teacher/assistant activates manually in the panel (e.g. after InstaPay/Vodafone Cash);
  (b) **activation codes**: teacher generates a batch for a category (optional subscription end date, code
  expiry, max uses), exports it to sell at the center; student redeems in the app.
- **One device per student**. A new device is blocked until the teacher approves a reset in the panel.

### 5.3 Video
- Videos are **unlisted YouTube**. The YouTube id is stored server-side and returned only to an authorized,
  device-bound student for a lecture they can access. Never shown in the UI.
- Playback through Mohamed's open-source **`md-player`** with stream extraction via
  **`youtube_explode_dart`** (as in the reference app). Fallback: `youtube_player_iframe` if extraction
  breaks — builder decides how the fallback is wired.
- Protection: Android `FLAG_SECURE` (no screenshots/recording), moving watermark with student name + phone over
  the player, iOS screen-capture detection pauses playback.
- **Watch progress**: the app reports position every N seconds (batched) → watched %, last position, resume.

### 5.4 Quizzes, homework, exams — one engine
- **Question bank**: MCQ questions (text and/or image, 2–6 options, one correct, optional explanation), tagged by
  level/category/lecture and difficulty. Bulk import from Excel.
- An **assessment** (quiz segment, homework or exam) is built by picking questions from the bank or writing new
  ones (which go to the bank).
- **Exam**: opens and closes at set times, duration timer, auto-submit at time-up, optional shuffle of questions
  and options, one attempt unless the teacher allows more. Result shown immediately or after close (teacher
  choice). Review screen shows correct answers after close.
- **Re-grading**:
  - Student can request a review **once per exam**, with a note; the teacher accepts/rejects with a reply.
  - If the teacher changes the correct answer of a question, **every attempt containing that question is
    re-scored** by a queued job; the previous score is kept in history; affected students get a notification.

### 5.5 Teacher panel (Filament)
- CRUD for levels, categories, lectures (segment builder), papers, announcements, question bank, assessments.
- Students: list, search by phone/name, subscriptions, device reset, password reset, block, Excel export.
- Activation codes: generate batch, export, see usage.
- Review requests inbox.
- **Analytics**:
  - per lecture: who watched (with %), who is subscribed and **has not watched**, export;
  - per exam: average, distribution, per-question error rate, who didn't sit it.
- **Assistant role** with limited permissions (e.g. activate students, answer reviews, no deleting content).
- Push notifications to all / a level / a category (FCM).

### 5.6 Student app (Flutter)
- Onboarding, register/login, device binding message.
- Home: announcements, continue watching, my categories, free content.
- Category → lectures/exams/papers → lecture screen (segments in order, locks shown).
- Quiz/exam player (timer, navigator, flag question), results, review.
- My results & homework, papers (PDF viewer), notifications, profile, redeem code.
- Arabic RTL default, English toggle; light/dark theme.

## 6. Architecture & how it gets made (Mohamed's decisions)

### 6.1 Repository
Monorepo `ustaz/`:
- `backend/` — Laravel 13 (PHP 8.4), Filament 5, Sanctum token API for the app, Redis, Pest.
- `app/` — Flutter (latest stable, Dart 3), GetX.
- `docs/` — specs, plans, screenshots.
- License: MIT (Mohamed can change).

### 6.2 Backend rules
- **Redis** for cache, queue and sessions (with Horizon or plain workers — builder's call).
- `Model::shouldBeStrict()` in non-production so lazy loading (N+1) throws. Every API resource eager-loads.
- Hot read endpoints (home, category tree, lecture detail, published exams) served from **tagged cache**,
  invalidated by model observers/events when the teacher edits. Cache failure falls back to DB, never 500.
- Per-student data (progress, subscriptions) cached per user with short TTL or invalidated on write.
- Watch-progress writes are **batched** (app sends every ~15 s; server upserts; heavy aggregation queued).
- Heavy work queued: re-scoring, analytics aggregation, code-batch generation, exports, push sends.
- Domain logic lives in **service/action classes** (e.g. `AccessService`, `ScoringService`,
  `ActivationCodeService`, `WatchProgressService`); Filament resources and API controllers stay thin and call
  the same services — no logic duplicated between panel and API.
- Form Requests for validation, API Resources for output, Policies for authorization, Enums for statuses.
- Tests (Pest) for every service and API endpoint; a load smoke test (e.g. k6 or Pest stress) for hot endpoints.

### 6.3 App rules
- GetX for state, routing and DI — **minimal packages**. Planned list (builder justifies any addition):
  `get`, `get_storage` (or `shared_preferences`), `dio` or `http` (pick one), `md_player` (Mohamed's),
  `youtube_explode_dart`, a PDF viewer without commercial licence, `firebase_messaging` + `firebase_core`,
  `cached_network_image`.
- Layering: `data/` (API client, models, repositories) → `domain/`-light services → `modules/<feature>/`
  (binding, controller, view). Shared widgets and a single base controller for loading/error/empty states.
- One `AssessmentPlayer` module renders quizzes, homework and exams.
- No hard-coded strings: translations file (ar, en). No client branding: app name, colors and logo come from
  one config file so a client version is a re-skin.

### 6.4 Coding rules (from Mohamed + SecondBrain)
Keep solutions simple · small commits · no unnecessary abstractions · OOP · no duplicated code ·
minimal packages · explain commands before destructive actions.

### 6.5 Execution model (Mohamed's decision)
- Claude writes the plan, then delegates: **backend → Free Delegate (OpenCode)**, **Flutter app → Codex**.
- Claude reviews every diff and runs the checks; if one worker hits its limit, Claude takes over its tasks.
- The API contract (endpoints + JSON) is written first so both sides can work in parallel.

## 7. Risks

- `youtube_explode_dart` extraction can break when YouTube changes; keep the iframe fallback. Stream
  extraction may conflict with YouTube's terms — mention it in the README so teachers choose knowingly.
- Unlisted YouTube links can still leak if a student finds them; server-side gating + no URL in UI reduces it.
- Device binding annoys students who change phones; the reset flow must be fast for the teacher.

## 8. Builder-check decisions (Claude's calls — Mohamed to confirm while reading)

- **Clients**: the Flutter app is the only student surface. Every student flow (register, login, redeem code,
  device reset request) is an API endpoint. No student web pages.
- **Device binding**: the app generates a UUID on first run and keeps it in app storage, sent with login. One
  active Sanctum token per student: logging in on the bound device revokes older tokens. A new device gets a
  "waiting for teacher approval" screen and creates a reset request that appears in the panel (with a badge).
  A reinstall counts as a new device. No device-info package.
- **md-player** is consumed as a git dependency from `github.com/MUHZERO/md-player`. "Protected" means: the video
  id is delivered only to an authorized bound device and never rendered; screenshots/recording blocked on
  Android; watermark on screen. It does not mean DRM — the README says so.
- **Assessment snapshots**: an attempt stores a snapshot of each question (text, options, correct option, mark)
  at the moment it is taken. Editing a question's text/options later does not touch past attempts. Changing the
  **correct option** of a question triggers a queued re-score of every attempt that has it (snapshot's correct
  option updated, score recomputed, old score kept in a history row, students notified). Deleting a question
  used in attempts is blocked (archive instead).
- **Gating quizzes**: unlimited attempts, the best score counts for unlocking. Homework and gating quizzes show
  correct answers right after submit. Exams follow the teacher's "after submit / after close" setting.
- **Push notifications** go through a `PushSender` interface with an FCM driver and a log/null driver; the demo
  runs with zero external accounts.
- **Infrastructure**: everything works with Redis (recommended, documented) and also with database cache/queue
  via `.env` for cheap hosting; Horizon is optional. Local setup documented with Laravel Herd/Sail.
- **Exports/imports**: XLSX/CSV through one light spreadsheet package (OpenSpout or Laravel Excel — builder
  picks the lighter that handles Arabic); activation-code sheets as a printable RTL HTML page (browser → PDF),
  no PDF library.
- **Roles**: two fixed roles, `teacher` and `assistant`, enforced by Policies. No permission package.
  Assistant: manage students, subscriptions, codes, device resets, review requests; read content and
  analytics; cannot delete content, edit questions/answers, or change settings.
- **Content relations**: a category belongs to one level; a lecture/exam/paper to one category; a question can be
  tagged to several lectures. Free content is visible to students of the same level.
- **Languages**: panel and app UI strings in Arabic (default) and English; content fields are single-language
  (the teacher writes in the language they teach).
- **Parent phone**: stored and exported only; no messaging in v1.

## 9. Left to the builder

Exact table names and columns, folder names inside the patterns above, choice between `dio`/`http`,
Horizon vs plain workers, PDF viewer package, UI design details (Mohamed reviews screenshots), seed data
content (generic Arabic math course).
