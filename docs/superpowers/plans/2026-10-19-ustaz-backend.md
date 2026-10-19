# Ustaz Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **Execution (Mohamed's decision):** implemented by Free Delegate (OpenCode) task by task; Claude reviews each diff and runs the checks; Claude takes over if the worker hits its limit.

**Goal:** Laravel API + Filament teacher panel for a single-teacher tutoring platform (Ustaz).

**Architecture:** Thin HTTP/Filament layer over domain service classes in `app/Services`; the API and the panel call
the same services. Reads go through a tagged cache with DB fallback; heavy work runs in queued jobs.

**Tech Stack:** PHP 8.4, Laravel 13, Filament 5, Sanctum, Pest 4, Redis (phpredis) with database fallback.

**Spec:** `docs/superpowers/specs/2026-10-19-ustaz-design.md` · **API:** `docs/api-contract.md` (binding)

## Global Constraints

- Monorepo path: `backend/`. Laravel 13, PHP 8.4, Filament 5 (`^5.6`), Pest.
- Composer runtime packages allowed: `laravel/framework`, `laravel/sanctum`, `filament/filament`, one spreadsheet
  package (`openspout/openspout` preferred), `kreait/laravel-firebase` **only** inside the FCM driver task. Anything
  else needs a line of justification in the PR description.
- No code copied from `lms-multi-tenant` or `_reference/education-master`; no client names, hosts, Firebase ids.
- `Model::shouldBeStrict(! app()->isProduction())` in `AppServiceProvider`.
- Controllers and Filament resources hold no business logic: they call `app/Services/*`.
- Validation in Form Requests, output in API Resources, authorization in Policies, statuses as backed Enums.
- Cache/queue/session drivers come from `.env`; code never assumes Redis exists (`CacheService` falls back).
- All user-facing strings in `lang/ar` and `lang/en`; default locale `ar`.
- Commits: small, imperative, no attribution lines. Author `Mohamed Nait Merri <175737010+MUHZERO@users.noreply.github.com>`.
- Run only the touched test file while iterating; full `php artisan test` once before each commit.

## Review Focus

1. Two requests redeeming the last use of one code at the same time → exactly one succeeds (Task 7 test `redeem is atomic under concurrency`).
2. A student submits an exam answer after `deadline_at` (slow network, clock skew) → answer rejected, attempt auto-submitted with saved answers (Task 8 test `late answer is rejected after deadline`).
3. Subscription `ends_at` passes while the student holds a cached "unlocked" lecture → access denied within the cache TTL; the per-student cache is keyed with ends_at so it expires (Task 4 test `expired subscription locks content even if cached`).
4. Teacher changes the correct option on a question used by 1,000 attempts → re-score runs chunked in a job, request returns fast, scores and history right (Task 9 test `rescoring chunks attempts and keeps history`).
5. Same phone logging in from a second device while the first is in use → second gets `device_pending`, first token keeps working (Task 3 test `second device is pending and first token survives`).

---

## File Structure

```
backend/
  app/Enums/            SegmentType, AssessmentKind, AttemptStatus, ReviewStatus, UserRole, DeviceStatus
  app/Models/           User, Level, Category, Lecture, Segment, Paper, Announcement, Subscription,
                        Device, DeviceResetRequest, ActivationCode, CodeRedemption, Question, QuestionOption,
                        Assessment, Attempt, AttemptAnswer, ScoreHistory, ReviewRequest, WatchProgress
  app/Services/         CacheService, DeviceService, AuthService, AccessService, ContentService,
                        WatchProgressService, ActivationCodeService, AttemptService, ScoringService,
                        ReviewService, QuestionImportService, Push/PushSender (+ FcmPushSender, LogPushSender),
                        AnalyticsService
  app/Jobs/             AutoSubmitAttempt, RescoreQuestion, GenerateCodeBatch, SendPush
  app/Observers/        ContentObserver (flushes level tag)
  app/Http/Controllers/Api/V1/*   app/Http/Requests/Api/*   app/Http/Resources/*
  app/Policies/*        app/Filament/Resources/*   app/Filament/Pages/*
  routes/api.php        database/{migrations,factories,seeders}   tests/{Unit,Feature}
```

---

### Task 1: Scaffold, strict mode, cache fallback, CI

**Files:** Create `backend/` (Laravel 13 skeleton), `app/Services/CacheService.php`, `.github/workflows/backend.yml`, `tests/Unit/CacheServiceTest.php`, `tests/Feature/HealthTest.php`

**Interfaces:**
- Produces: `CacheService::remember(array $tags, string $key, int $ttl, Closure $cb): mixed`, `CacheService::flush(array $tags): void` — uses tags when the store supports them, plain keys otherwise, and calls `$cb` directly if the store throws.

- [ ] **Step 1:** `composer create-project laravel/laravel backend "^13.0"`; add `laravel/sanctum`, `filament/filament:^5.6`, `pestphp/pest`; `php artisan filament:install --panels` (panel id `admin`, path `/admin`); set `APP_LOCALE=ar`.
- [ ] **Step 2: Failing tests** — `HealthTest`: `GET /up` → 200. `CacheServiceTest`: `remember returns callback value and caches it` (callback called once over 2 calls); `remember falls back when store throws` (mock store throwing → value returned, no exception); `flush clears tagged keys` (array store).
- [ ] **Step 3:** Implement `CacheService`; `AppServiceProvider::boot` → `Model::shouldBeStrict(! $this->app->isProduction())`.
- [ ] **Step 4:** Run `php artisan test` → PASS.
- [ ] **Step 5:** CI workflow: PHP 8.4, `composer install`, `php artisan test`, `vendor/bin/pint --test`. Commit `chore: scaffold backend with Filament, Sanctum and cache service`.

### Task 2: Schema, enums, models, factories

**Files:** migrations for every model in File Structure; `app/Enums/*`; `app/Models/*`; `database/factories/*`; `tests/Unit/ModelRelationsTest.php`

**Interfaces (columns that later tasks rely on):**
- `users`: `name, phone (unique), parent_phone null, password, role UserRole(student|teacher|assistant), level_id null, blocked_at null`.
- `levels(name, position)`; `categories(level_id, name, position, is_free bool)`; `lectures(category_id, title, description null, position, is_free bool, thumbnail_path null, published_at null)`; `segments(lecture_id, type SegmentType(video|pdf|quiz), position, title, is_gating bool, youtube_id null, duration_seconds null, pdf_path null, assessment_id null, pass_percent tinyint null)`.
- `papers(category_id, title, path)`; `announcements(level_id null, title, body null, image_path null, published_at)`.
- `subscriptions(user_id, category_id, starts_at, ends_at null, granted_by null, code_redemption_id null)`, unique `(user_id, category_id)`.
- `devices(user_id, device_uuid, status DeviceStatus(active|pending|revoked), last_seen_at)`; `device_reset_requests(user_id, device_uuid, status ReviewStatus, handled_by null)`.
- `activation_codes(code unique, category_id, batch_id, ends_at null /*subscription end*/, expires_at null /*code expiry*/, max_uses, uses_count)`; `code_redemptions(activation_code_id, user_id, created_at)`.
- `questions(text null, image_path null, explanation null, difficulty tinyint null, level_id, archived_at null)`; `question_options(question_id, text null, image_path null, is_correct bool, position)`; pivot `lecture_question`.
- `assessments(kind AssessmentKind(quiz|homework|exam), title, category_id null, lecture_id null, opens_at null, closes_at null, duration_minutes null, max_attempts null, shuffle bool, show_answers enum(after_submit|after_close), is_free bool)`; pivot `assessment_question(assessment_id, question_id, position, mark default 1)`.
- `attempts(user_id, assessment_id, status AttemptStatus(in_progress|submitted), started_at, deadline_at null, submitted_at null, score null, max_score null)`.
- `attempt_answers(attempt_id, question_id, snapshot json /*text,image,options[{id,text,image}],correct_option_id,mark*/, chosen_option_id null, is_correct null)`.
- `score_history(attempt_id, old_score, new_score, reason)`; `review_requests(attempt_id unique, note, status ReviewStatus(pending|accepted|rejected), reply null, handled_by null)`.
- `watch_progress(user_id, segment_id, last_position_seconds, watched_seconds, completed_at null)` unique `(user_id, segment_id)`.

- [ ] **Step 1: Failing test** `ModelRelationsTest`: factories build a full tree (level→category→lecture→segment(quiz)→assessment→question→options) and `$lecture->segments()->orderBy('position')` / `$category->lectures` / `$assessment->questions` return them; `lazy loading throws in tests` (access relation without eager load → `LazyLoadingViolationException`).
- [ ] **Step 2:** Write migrations, enums, models (`$casts` for enums/dates/json), factories. Indexes on every FK and on `(user_id, segment_id)`, `(assessment_id, user_id)`.
- [ ] **Step 3:** `php artisan migrate:fresh && php artisan test --filter=ModelRelationsTest` → PASS. Commit `feat: add domain schema and models`.

### Task 3: Auth and device binding API

**Files:** `app/Services/{AuthService,DeviceService}.php`, `app/Http/Controllers/Api/V1/{AuthController,LevelController,ProfileController}.php`, requests `RegisterRequest, LoginRequest, UpdateProfileRequest`, `app/Http/Resources/StudentResource.php`, middleware `EnsureBoundDevice` (alias `device`), `routes/api.php`, `tests/Feature/Api/AuthTest.php`

**Interfaces:**
- `DeviceService::bind(User $u, string $uuid): Device` — first device becomes `active`; a different uuid when one is active → creates `pending` device + `DeviceResetRequest`, returns it.
- `DeviceService::approve(DeviceResetRequest $r, User $by): void` — revokes old device and its tokens, activates the new one.
- `AuthService::login(string $phone, string $password, string $uuid): array{token:string, user:User}` throws `DevicePendingException` / `AccountBlockedException`.
- Middleware `device`: request `X-Device-Id` must match the user's active device, else 403 `device_pending`.

- [ ] **Step 1: Failing tests** (contract codes/statuses from `docs/api-contract.md`): `register creates student and binds device`; `register rejects non egyptian phone` (`0912345678` → 422); `login returns token on bound device`; `second device is pending and first token survives` (2nd login → 403 `device_pending`, `device_reset_requests` has 1 row, first token `GET /me` → 200); `approved reset moves access to new device`; `blocked student cannot login` (403 `account_blocked`); `login is throttled` (6th attempt/min → 429); `wrong device id is rejected on protected routes`.
- [ ] **Step 2:** Implement; routes per contract under `/api/v1`, `auth:sanctum` + `device` on all but levels/register/login; one token per device (login deletes older tokens of that device).
- [ ] **Step 3:** Run `php artisan test --filter=AuthTest` → PASS. Commit `feat: student auth with single-device binding`.

### Task 4: Access rules

**Files:** `app/Services/AccessService.php`, `tests/Unit/AccessServiceTest.php`

**Interfaces:**
- `AccessService::subscribedCategoryIds(User $u): array<int>` — active subscriptions (`ends_at` null or future), cached per student (tag `student:{id}`, TTL = min(600 s, seconds to nearest `ends_at`)).
- `canOpenCategory(User, Category): bool` (free or subscribed, same level), `canOpenLecture(User, Lecture): bool`, `canOpenAssessment(User, Assessment): bool`, `lockedSegmentIds(User, Lecture): array<int>` — a segment after an unpassed gating quiz is locked (passed = best submitted attempt percent ≥ `pass_percent`).

- [ ] **Step 1: Failing tests:** `free category opens without subscription`; `other level category never opens`; `subscription without end date is lifetime`; `expired subscription locks content even if cached` (cache warm, travel past `ends_at` → false); `free lecture inside paid category opens`; `segments after unpassed gating quiz are locked`; `passing gating quiz unlocks next segments` (best of 2 attempts counts).
- [ ] **Step 2:** Implement with one query per method (eager loads), no per-segment queries.
- [ ] **Step 3:** Run filter → PASS. Commit `feat: access rules for categories, lectures and gating`.

### Task 5: Content API with tagged cache

**Files:** `app/Services/ContentService.php`, `app/Observers/ContentObserver.php`, controllers `HomeController, CategoryController, LectureController, AnnouncementController`, resources `CategoryResource, LectureCardResource, LectureResource, SegmentResource, ExamCardResource, PaperResource, AnnouncementResource`, `tests/Feature/Api/ContentTest.php`

**Interfaces:**
- `ContentService::levelTree(int $levelId): array` (cached, tag `level:{id}`) → categories with lectures/exams/papers, no per-student fields.
- `ContentService::forStudent(User $u, array $levelTree): array` merges `is_subscribed, is_locked, progress_percent, attempt` from `AccessService` + per-student cache.
- `ContentObserver` on Category/Lecture/Segment/Paper/Assessment/Announcement saved/deleted → `CacheService::flush(["level:{levelId}"])`.
- Paper/PDF URLs: `URL::temporarySignedRoute('files.show', now()->addMinutes(30), …)`.

- [ ] **Step 1: Failing tests:** response shapes match the contract for `/home`, `/categories`, `/categories/{id}`, `/lectures/{id}`; `locked lecture hides youtube id` (no `video` key); `papers empty when category locked`; `home uses at most 8 queries` and `second home request uses 2 or fewer queries` (`DB::enableQueryLog`); `teacher edit flushes level cache` (update lecture title → next `/categories/{id}` shows it).
- [ ] **Step 2:** Implement; register observer in `AppServiceProvider`.
- [ ] **Step 3:** Run filter → PASS. Commit `feat: cached content API`.

### Task 6: Watch progress

**Files:** `app/Services/WatchProgressService.php`, `LectureController@progress`, `ProgressRequest`, `tests/Feature/Api/WatchProgressTest.php`

**Interfaces:** `WatchProgressService::record(User, Segment, int $position, int $watched): void` — upsert, `watched_seconds = max(old, new)`, `completed_at` set at ≥ 90 % of `duration_seconds`; flushes `student:{id}` tag only when `completed_at` changes.

- [ ] **Step 1: Failing tests:** `progress upserts one row`; `watched seconds never decrease`; `ninety percent marks completed`; `locked segment progress is forbidden` (403 `locked`); `progress endpoint is throttled at 10 per minute per segment`.
- [ ] **Step 2:** Implement. **Step 3:** Run → PASS. Commit `feat: video watch progress`.

### Task 7: Activation codes and subscriptions

**Files:** `app/Services/ActivationCodeService.php`, `app/Services/SubscriptionService.php`, `app/Jobs/GenerateCodeBatch.php`, `CodeController@redeem`, `SubscriptionController@index`, `tests/Feature/Api/ActivationCodeTest.php`

**Interfaces:**
- `ActivationCodeService::generate(Category $c, int $count, int $maxUses, ?Carbon $endsAt, ?Carbon $expiresAt): string $batchId` — codes are 10 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, unique; > 200 codes dispatches the job.
- `ActivationCodeService::redeem(User, string $code): Subscription` — inside a transaction with `lockForUpdate` on the code row; throws `CodeInvalid|CodeExpired|CodeUsedUp`.
- `SubscriptionService::grant(User, Category, ?Carbon $endsAt, ?User $by, ?CodeRedemption $r): Subscription` — upsert on `(user_id, category_id)`, keeps the later `ends_at` (null wins), flushes `student:{id}`. Used by redeem **and** the panel.

- [ ] **Step 1: Failing tests:** `redeem grants category subscription`; `redeem is case insensitive and trims`; `expired code is rejected` (422 `code_expired`); `used up code is rejected`; `redeem is atomic under concurrency` (code `max_uses=1`, two redemptions in parallel processes/transactions → one subscription, `uses_count=1`); `granting again keeps the later end date`; `code of another level is invalid`.
- [ ] **Step 2:** Implement. **Step 3:** Run → PASS. Commit `feat: activation codes and subscriptions`.

### Task 8: Assessment engine (quiz, homework, exam)

**Files:** `app/Services/{AttemptService,ScoringService}.php`, `app/Jobs/AutoSubmitAttempt.php`, `AttemptController`, `ResultController`, resources `AttemptResource, ResultResource, ReviewItemResource`, `tests/Feature/Api/AttemptTest.php`, `tests/Unit/ScoringServiceTest.php`

**Interfaces:**
- `AttemptService::start(User, Assessment): Attempt` — resume open attempt; exams: 409 `exam_not_open` outside `[opens_at, closes_at]`, 409 `already_submitted` when `max_attempts` reached; snapshots questions into `attempt_answers` (shuffled when `shuffle`), sets `deadline_at = min(started_at + duration, closes_at)`, dispatches `AutoSubmitAttempt` delayed to `deadline_at`.
- `AttemptService::answer(Attempt, int $questionId, int $optionId): void` — rejects after `deadline_at` (409 `already_submitted`).
- `AttemptService::submit(Attempt): Attempt` — idempotent; calls `ScoringService::score(Attempt): void` (sum `mark` where chosen = snapshot correct).
- `AttemptService::reviewAvailable(Attempt): bool` — quiz/homework: after submit; exam: per `show_answers`.

- [ ] **Step 1: Failing tests:** `starting twice resumes same attempt`; `exam cannot start before opens_at`; `deadline is capped by closes_at`; `late answer is rejected after deadline`; `auto submit job scores saved answers`; `submit twice returns same result`; `question options are hidden in attempt payload` (no `is_correct`); `review hidden until exam closes when show_answers is after_close`; `homework list shows status per assessment`; `my results paginate with title and kind`; ScoringService: `score sums marks of correct answers`, `unanswered counts as wrong`.
- [ ] **Step 2:** Implement. **Step 3:** Run filters → PASS. Commit `feat: unified assessment engine`.

### Task 9: Review requests and re-scoring

**Files:** `app/Services/ReviewService.php`, `app/Jobs/RescoreQuestion.php`, `app/Observers/QuestionOptionObserver.php`, `ReviewRequestController@store`, `tests/Feature/ReviewAndRescoreTest.php`

**Interfaces:**
- `ReviewService::request(Attempt, string $note): ReviewRequest` (exam attempts only, once → 409 `review_already_requested`); `ReviewService::decide(ReviewRequest, ReviewStatus, ?string $reply, User $by): void` notifies the student.
- Changing which option `is_correct` on a question dispatches `RescoreQuestion($questionId, $newCorrectOptionId)`: `chunkById(500)` over `attempt_answers` of that question → update snapshot correct id + `is_correct`, recompute each touched attempt score via `ScoringService`, write `score_history(reason='answer_key_changed')`, notify affected students once.
- Deleting a question that has attempt answers is blocked (`archived_at` instead).

- [ ] **Step 1: Failing tests:** `student can request review once per exam`; `quiz attempts cannot request review`; `teacher decision notifies student`; `rescoring chunks attempts and keeps history` (1,200 attempts, change key, run queue → all scores right, 1,200 history rows, request dispatches in < 200 ms); `editing question text does not touch past snapshots`; `question with attempts cannot be deleted`.
- [ ] **Step 2:** Implement. **Step 3:** Run → PASS. Commit `feat: review requests and answer-key re-scoring`.

### Task 10: Notifications and push

**Files:** `app/Services/Push/{PushSender.php,FcmPushSender.php,LogPushSender.php}`, `app/Jobs/SendPush.php`, `app/Notifications/StudentNotification.php`, `NotificationController`, `ProfileController@fcmToken`, `tests/Feature/Api/NotificationTest.php`

**Interfaces:** `interface PushSender { public function send(array $tokens, string $title, string $body, array $data = []): void; }` bound in a provider by `config('services.push.driver')` = `fcm|log` (default `log`). `StudentNotification` stores to `notifications` table (database channel) and queues `SendPush`. Audience helper `NotificationAudience::level(int)|category(int)|all()` returns user ids in chunks.

- [ ] **Step 1: Failing tests:** `notification is stored and listed`; `mark as read`; `log driver is used without firebase credentials`; `audience by category only includes subscribed students`.
- [ ] **Step 2:** Implement (`kreait/laravel-firebase` only inside `FcmPushSender`). **Step 3:** Run → PASS. Commit `feat: notifications with pluggable push driver`.

### Task 11: Question bank import

**Files:** `app/Services/QuestionImportService.php`, `tests/Unit/QuestionImportServiceTest.php`, `tests/fixtures/questions.xlsx`

**Interfaces:** `QuestionImportService::import(string $path, int $levelId, ?array $lectureIds): ImportReport{created:int, errors:array<int,string>}` — columns `question | option_1..option_6 | correct (1-6) | explanation | difficulty`; Arabic text kept as-is; a bad row is reported, others imported.

- [ ] **Step 1: Failing tests:** `imports valid rows with options and correct answer`; `reports row with missing correct column`; `keeps arabic text intact`.
- [ ] **Step 2:** Implement with OpenSpout. **Step 3:** Run → PASS. Commit `feat: question bank xlsx import`.

### Task 12: Filament panel — roles and content resources

**Files:** `app/Policies/*`, `app/Filament/Resources/{Levels,Categories,Lectures,Papers,Announcements,Questions,Assessments}/*`, `tests/Feature/Panel/ContentPanelTest.php`

**Interfaces:** panel login for `role in (teacher, assistant)` only (`User::canAccessPanel`). Policies: assistant `viewAny/view` on content, no `create/update/delete` on content, questions or assessments. Lecture form: segments as an ordered Repeater (type → fields; quiz type selects/creates an Assessment). Question form: options Repeater (2–6, exactly one correct). Assessment form: pick questions from bank (filter by level/lecture/difficulty) with marks. Questions resource has an "Import xlsx" header action → `QuestionImportService`.

- [ ] **Step 1: Failing tests (Livewire):** `teacher can create lecture with ordered segments`; `assistant cannot edit lectures` (403); `question requires exactly one correct option`; `student cannot access panel`; `import action reports created count`.
- [ ] **Step 2:** Implement; RTL Arabic labels via `lang/`. **Step 3:** Run → PASS. Commit `feat: teacher panel content resources`.

### Task 13: Filament panel — students, codes, reviews, analytics

**Files:** `app/Filament/Resources/{Students,ActivationCodes,ReviewRequests,DeviceResetRequests}/*`, `app/Filament/Pages/{LectureReport,ExamReport}.php`, `app/Services/AnalyticsService.php`, `resources/views/codes/print.blade.php`, `tests/Feature/Panel/StudentsPanelTest.php`, `tests/Unit/AnalyticsServiceTest.php`

**Interfaces:**
- Students table: search phone/name, filter level/subscribed category; actions **Activate category** (→ `SubscriptionService::grant`), **Reset password**, **Block/Unblock**, **Approve device** (→ `DeviceService::approve`), bulk **Export xlsx**.
- Codes: **Generate batch** action (→ `ActivationCodeService::generate`), **Print sheet** (RTL HTML grid, 40 codes/page), **Export xlsx**, usage column.
- `AnalyticsService::lectureReport(Lecture): Collection` rows `{student, phone, subscribed: bool, watched_percent, completed_at|null}` including subscribed students with 0 %; `notWatched(Lecture)` = subscribed and no progress. `examReport(Assessment): array{avg, distribution[10], perQuestionErrorRate, absent: Collection}`.
- Dashboard widgets: pending device resets, pending reviews.
- `SendNotification` page: title, body, audience (all / level / category) → `StudentNotification` via `NotificationAudience` in chunks (queued).

- [ ] **Step 1: Failing tests:** `assistant can activate a category for a student`; `reset password changes hash and revokes tokens`; `lecture report lists subscribed students who never watched`; `exam report counts absent subscribed students`; `print sheet renders codes rtl`; `analytics uses constant queries for 500 students` (≤ 5 queries); `send notification to a category queues only subscribed students`.
- [ ] **Step 2:** Implement. **Step 3:** Run → PASS. Commit `feat: student management, codes and analytics`.

### Task 14: Demo seed, docs, load smoke

**Files:** `database/seeders/DemoSeeder.php`, `backend/README.md`, root `README.md` (backend section), `tests/Feature/LoadSmokeTest.php`

- [ ] **Step 1:** `DemoSeeder`: 1 teacher (`teacher@ustaz.test` / `password`), 1 assistant, 2 levels, 3 categories (أكتوبر، نوفمبر، الترم الأول) with one free, 6 lectures with video/pdf/quiz segments (public-domain YouTube ids), 40 bank questions, 1 open exam, 50 students with progress, a code batch.
- [ ] **Step 2: Failing test** `LoadSmokeTest`: seed, then 200 sequential `/home` + `/categories/{id}` requests as different students complete in < 5 s total with array cache and every response 200.
- [ ] **Step 3:** README: features, screenshots placeholders, setup (Herd/Sail), `.env` Redis vs database drivers, queue worker, YouTube extraction note, license MIT.
- [ ] **Step 4:** Full `php artisan test` + `vendor/bin/pint --test` → PASS. Commit `docs: demo data and backend setup guide`.
